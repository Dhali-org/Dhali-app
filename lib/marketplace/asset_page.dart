import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:http/http.dart';
import 'package:dhali/analytics/analytics.dart';
import 'package:dhali/config.dart' show Config;
import 'package:dhali/marketplace/model/marketplace_list_data.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';

class AssetPage extends StatefulWidget {
  const AssetPage(
      {super.key,
      required this.asset,
      required this.getWallet,
      required this.getRequest,
      required this.getFirestore,
      this.getReadme});
  final MarketplaceListData asset;
  final DhaliWallet? Function() getWallet;
  final FirebaseFirestore? Function() getFirestore;
  final BaseRequest Function<T extends BaseRequest>(String method, String path)
      getRequest;
  final Future<Response> Function(Uri path)? getReadme;

  @override
  State<AssetPage> createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> {
  @override
  Widget build(BuildContext context) {
    Future<Response> future;
    Future<Response> timeoutFuture;
    var uri = Uri.parse(
        "${Config.config!["ROOT_CONSUMER_URL"]}/${widget.asset.assetID}/${Config.config!['GET_READMES_ROUTE']}");
    if (widget.getReadme == null) {
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
        onTimeout: () => timeoutFuture,
      ); // Set the timeout to 5 seconds.;
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
                style: const TextStyle(color: Colors.black, fontSize: 18),
              ),
              Text(
                widget.asset.assetCategories.isNotEmpty
                    ? "Categories: ${widget.asset.assetCategories}"
                    : "",
                key: const Key("categories_in_asset_page"),
                style: const TextStyle(color: Colors.black, fontSize: 20),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
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
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                color: Colors.black, fontSize: 15),
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
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                color: Colors.black, fontSize: 15),
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
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                color: Colors.black, fontSize: 15),
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
                            style: const TextStyle(
                                color: Colors.black, fontSize: 15),
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
