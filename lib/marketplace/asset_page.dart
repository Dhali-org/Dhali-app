import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali/analytics/analytics.dart';
import 'package:dhali/config.dart' show Config;
import 'package:dhali/marketplace/model/marketplace_list_data.dart';
import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';
import 'package:http/http.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:swagger_documentation_widget/swagger_documentation_widget.dart';

import 'package:dhali_wallet/widgets/buttons.dart' as buttons;

class AssetPage extends StatefulWidget {
  const AssetPage(
      {super.key,
      required this.uuid,
      required this.getWallet,
      required this.getRequest,
      required this.getFirestore,
      this.administrateEntireAPI,
      this.getReadme});
  final FirebaseFirestore? Function() getFirestore;
  final String uuid;
  final DhaliWallet? Function() getWallet;
  final Future<void> Function()? administrateEntireAPI;
  final BaseRequest Function<T extends BaseRequest>(String method, String path)
      getRequest;
  final Future<Response> Function(Uri path)? getReadme;

  @override
  State<AssetPage> createState() => _AssetPageState();
}

bool _isSwaggerParsable(String s) {
  try {
    var parsed = json.decode(s); // Try parsing it as JSON
    if (parsed is Map &&
        (parsed.containsKey("swagger") || parsed.containsKey("openapi"))) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    // If JSON parsing throws an error, it's not a valid JSON
    return false;
  }
}

class _AssetPageState extends State<AssetPage> {
  void _setReadmeFuture() {
    var uri = Uri.parse(
        "${Config.config!["ROOT_CONSUMER_URL"]}/${widget.uuid}/${Config.config!['GET_READMES_ROUTE']}");
    if (widget.getReadme == null) {
      Future<Response> timeoutFuture;
      // This will make two requests at most. If the second fails, the user will
      // be shown a 404 error.
      timeoutFuture = get(
        uri,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => Response("Page not found.", 404),
      );
      future = get(
        uri,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => get(uri).timeout(
          const Duration(seconds: 10),
          onTimeout: () => timeoutFuture,
        ),
      );
    } else {
      // typically executed when mocking
      future = widget.getReadme!(uri);
    }
  }

  late Future<Response> future;
  @override
  Widget build(BuildContext context) {
    _setReadmeFuture();
    final collection = widget
        .getFirestore()!
        .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"]);

    var elementStream = collection.doc(widget.uuid).snapshots();

    return StreamBuilder(
        stream: elementStream,
        builder: (BuildContext context,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(
              key: Key("asset_circular_spinner"),
            ));
          }

          gtag(
              command: "event",
              target: "AssetSelected",
              parameters: {"uuid": widget.uuid});

          var elementData = snapshot.data!.data()!;

          double paidOut = elementData.containsKey(
                  Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["TOTAL_PAID_OUT"])
              ? double.parse(elementData[Config
                  .config!["MINTED_NFTS_DOCUMENT_KEYS"]["TOTAL_PAID_OUT"]])
              : 0;
          double earnings = elementData.containsKey(
                  Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["TOTAL_PAID_OUT"])
              ? elementData[Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
                  ["TOTAL_EARNED"]]
              : 0;

          MarketplaceListData apiMetadata = MarketplaceListData(
              paidOut: paidOut,
              earnings: earnings,
              assetID: widget.uuid,
              assetName: elementData[Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
                  ["ASSET_NAME"]],
              assetCategories: elementData[
                  Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["CATEGORY"]],
              averageRuntime: elementData[
                  Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
                      ["AVERAGE_INFERENCE_TIME_MS"]],
              numberOfSuccessfullRequests: elementData[
                  Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
                      ["NUMBER_OF_SUCCESSFUL_REQUESTS"]],
              pricePerRun: elementData[
                  Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
                      ["EXPECTED_INFERENCE_COST"]]);

          return _getAssetPageScaffold(apiMetadata);
        });
  }

  Widget _getAssetPageScaffold(MarketplaceListData apiMetadata) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                apiMetadata.assetName,
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                apiMetadata.assetCategories.isNotEmpty
                    ? "Categories: ${apiMetadata.assetCategories}"
                    : "",
                key: const Key("categories_in_asset_page"),
                style: const TextStyle(fontSize: 20),
              ),
              if (widget.administrateEntireAPI != null)
                buttons.getTextButton("Edit",
                    onPressed: () =>
                        widget.administrateEntireAPI!().then((value) {
                          setState(() {
                            // Update the displayed readme after admin has
                            // complete
                            _setReadmeFuture();
                          });
                        }))
            ],
          ),
        ),
        body: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              border: Border.all(width: 2),
            ),
            margin: const EdgeInsets.all(5),
            alignment: Alignment.center,
            child: FutureBuilder(
                builder:
                    (BuildContext context, AsyncSnapshot<Response> snapshot) {
                  if (snapshot.hasData) {
                    final body = snapshot.data!.body;
                    if (_isSwaggerParsable(body)) {
                      return Container(
                          margin: const EdgeInsets.all(5),
                          child: SwaggerDocumentationWidget(
                              jsonContent: body, title: "API Documentation"));
                    }
                    return Container(
                        margin: const EdgeInsets.all(5),
                        child: MarkdownWidget(
                            data: snapshot.data!.body,
                            config: MarkdownConfig(configs: [
                              const PreConfig(
                                  theme: a11yLightTheme, language: 'dart'),
                            ])));
                  } else {
                    return const Center(
                        child: CircularProgressIndicator(
                      key: Key("asset_circular_spinner"),
                    ));
                  }
                },
                future: future)),
        bottomNavigationBar: Container(
            margin: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                    flex: 3,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        SelectableText.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 15),
                            children: <TextSpan>[
                              const TextSpan(
                                  text: 'Runtime: ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      '~${apiMetadata.averageRuntime.ceil()}ms'),
                            ],
                          ),
                        ),
                        SelectableText.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 15),
                            children: <TextSpan>[
                              const TextSpan(
                                  text: 'Cost: ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      '~${(apiMetadata.pricePerRun / 1000000).toStringAsFixed(4)} XRP/run'),
                            ],
                          ),
                        ),
                        SelectableText.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 15),
                            children: <TextSpan>[
                              const TextSpan(
                                  text: 'Earnings: ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      '~${(apiMetadata.earnings / 1000000).toStringAsFixed(4)} XRP'),
                            ],
                          ),
                        ),
                        SelectableText.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 15),
                            children: <TextSpan>[
                              const TextSpan(
                                  text: 'Paid out: ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      '~${(apiMetadata.paidOut / 1000000).toStringAsFixed(4)} XRP'),
                            ],
                          ),
                        ),
                        SelectableText.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 15),
                            children: <TextSpan>[
                              const TextSpan(
                                  text: 'Used: ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      '${apiMetadata.numberOfSuccessfullRequests} times'),
                            ],
                          ),
                        ),
                        SelectableText.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 15),
                            children: <TextSpan>[
                              const TextSpan(
                                  text: 'Endpoint: ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      '${Config.config!["ROOT_RUN_URL"]}/${apiMetadata.assetID}'),
                            ],
                          ),
                        )
                      ],
                    )),
              ],
            )));
  }
}
