import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali/app_theme.dart';
import 'package:dhali/consumer_workflow.dart';
import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_selectionarea/flutter_markdown_selectionarea.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dhali/marketplace/model/marketplace_list_data.dart';
import 'package:dhali/config.dart' show Config;

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
  final BaseRequest Function(String method, String path) getRequest;
  final Future<Response> Function(Uri path)? getReadme;

  @override
  State<AssetPage> createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> {
  @override
  Widget build(BuildContext context) {
    Future<Response> future;
    var uri = Uri.parse(
        "${Config.config!["ROOT_CONSUMER_URL"]}/${widget.asset.assetID}/${Config.config!['GET_READMES_ROUTE']}");
    if (widget.getReadme == null) {
      future = get(
        uri,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => Response("Page not found. Consider refreshing", 404),
      ); // Set the timeout to 5 seconds.;
    } else {
      // typically executed when mocking
      future = widget.getReadme!(uri);
    }
    return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.asset.assetName,
                style: const TextStyle(color: Colors.black, fontSize: 28),
              ),
              Text(
                widget.asset.assetCategories.isNotEmpty
                    ? "Categories: ${widget.asset.assetCategories}"
                    : "Categories: NONE",
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
              border: Border.all(width: 5),
            ),
            margin: const EdgeInsets.all(20),
            alignment: Alignment.center,
            child: FutureBuilder(
                builder:
                    (BuildContext context, AsyncSnapshot<Response> snapshot) {
                  if (snapshot.hasData) {
                    return SelectionArea(
                        child: Markdown(
                      onTapLink: (text, url, title) {
                        if (url != null) {
                          launchUrl(Uri.parse(url));
                        }
                      },
                      selectable: true,
                      key: const Key("asset_page_readme"),
                      styleSheet: MarkdownStyleSheet(
                        p: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontSize: 18),
                        h1: Theme.of(context).textTheme.displayLarge!.copyWith(
                            fontSize: 30, fontWeight: FontWeight.bold),
                        h2: Theme.of(context).textTheme.displayMedium!.copyWith(
                            fontSize: 26, fontWeight: FontWeight.bold),
                        h3: Theme.of(context).textTheme.displaySmall!.copyWith(
                            fontSize: 22, fontWeight: FontWeight.bold),
                        h4: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                                fontSize: 18, fontWeight: FontWeight.bold),
                        h5: Theme.of(context).textTheme.headlineSmall!.copyWith(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        h6: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontSize: 14, fontWeight: FontWeight.bold),
                        code: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 18,
                              backgroundColor: Colors.grey[200],
                            ),
                        codeblockDecoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                      data: snapshot.data!.body,
                    ));
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
                                      '~${widget.asset.pricePerRun.ceil()} drops/run'),
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
                                      '${Config.config!["ROOT_RUN_URL"]}/${widget.asset.assetID}/run'),
                            ],
                          ),
                        )
                      ],
                    )),
                Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                          backgroundColor: AppTheme.dhali_blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4))),
                      onPressed: () => {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return consumerJourney(
                                  assetDescriptor: widget.asset,
                                  getFirestore: widget.getFirestore,
                                  context: context,
                                  runURL:
                                      "${Config.config!["ROOT_RUN_URL"]}/${widget.asset.assetID}/run",
                                  getWallet: widget.getWallet,
                                  getRequest: widget.getRequest);
                            })
                      },
                      icon: const Icon(
                        Icons.navigate_next_outlined,
                        size: 25,
                      ),
                      label: const Text(
                        "Run",
                        style: TextStyle(fontSize: 15),
                      ),
                    ))
              ],
            )));
  }
}
