import 'dart:convert';

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
      required this.asset,
      required this.getWallet,
      required this.getRequest,
      this.administrateEntireAPI,
      this.getReadme});
  final MarketplaceListData asset;
  final DhaliWallet? Function() getWallet;
  final void Function()? administrateEntireAPI;
  final BaseRequest Function<T extends BaseRequest>(String method, String path)
      getRequest;
  final Future<Response> Function(Uri path)? getReadme;

  @override
  State<AssetPage> createState() => _AssetPageState();
}

bool _isJsonParsable(String s) {
  // I couldn't find a "better" way of doing this...
  try {
    json.decode(s); // Try parsing it as JSON
    return true; // If no error, it's parsable
  } catch (e) {
    // If JSON parsing throws an error, it's not a valid JSON
    return false;
  }
}

class _AssetPageState extends State<AssetPage> {
  @override
  Widget build(BuildContext context) {
    Future<Response> future;
    var uri = Uri.parse(
        "${Config.config!["ROOT_CONSUMER_URL"]}/${widget.asset.assetID}/${Config.config!['GET_READMES_ROUTE']}");
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

    gtag(command: "event", target: "AssetSelected", parameters: {
      "uuid": widget.asset.assetID,
      "name": widget.asset.assetName
    });

    return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.asset.assetName,
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                widget.asset.assetCategories.isNotEmpty
                    ? "Categories: ${widget.asset.assetCategories}"
                    : "",
                key: const Key("categories_in_asset_page"),
                style: const TextStyle(fontSize: 20),
              ),
              if (widget.administrateEntireAPI != null)
                buttons.getTextButton("Edit",
                    onPressed: () => widget.administrateEntireAPI!())
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
                    if (_isJsonParsable(body)) {
                      return Container(
                          margin: const EdgeInsets.all(5),
                          child: SwaggerDocumentationWidget(
                              jsonContent: snapshot.data!.body,
                              title: "API Documentation"));
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
                                      '~${widget.asset.averageRuntime.ceil()}ms'),
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
                                      '~${(widget.asset.pricePerRun / 1000000).toStringAsFixed(4)} XRP/run'),
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
                                      '~${(widget.asset.earnings / 1000000).toStringAsFixed(4)} XRP'),
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
                                      '~${(widget.asset.paidOut / 1000000).toStringAsFixed(4)} XRP'),
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
                                      '${widget.asset.numberOfSuccessfullRequests} times'),
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
                                      '${Config.config!["ROOT_RUN_URL"]}/${widget.asset.assetID}'),
                            ],
                          ),
                        )
                      ],
                    )),
              ],
            )));
  }
}
