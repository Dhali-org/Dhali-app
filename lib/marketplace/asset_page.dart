import 'package:dhali/app_theme.dart';
import 'package:dhali/consumer_workflow.dart';
import 'package:dhali/wallet/xrpl_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart';

import 'model/marketplace_list_data.dart';
import 'package:dhali/config.dart' show Config;

class AssetPage extends StatefulWidget {
  const AssetPage(
      {super.key,
      required this.asset,
      required this.getWallet,
      required this.getRequest,
      this.getReadme});
  final MarketplaceListData asset;
  final XRPLWallet? Function() getWallet;
  final BaseRequest Function(String method, String path) getRequest;
  final Future<Response> Function(Uri path)? getReadme;

  @override
  State<AssetPage> createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> {
  @override
  Widget build(BuildContext context) {
    var future;
    var uri = Uri.parse(
        "${Config.config!["ROOT_CONSUMER_URL"]}/${widget.asset.assetID}/${Config.config!['GET_READMES_ROUTE']}");
    if (widget.getReadme == null) {
      future = get(
        uri,
      );
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
                style: TextStyle(color: Colors.black, fontSize: 28),
              ),
              Text(
                widget.asset.assetCategories.isNotEmpty
                    ? "Categories: ${widget.asset.assetCategories}"
                    : "Categories: NONE",
                key: Key("categories_in_asset_page"),
                style: TextStyle(color: Colors.black, fontSize: 20),
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
                    return Markdown(
                        key: const Key("asset_page_readme"),
                        data: snapshot.data!.body);
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
              children: [
                Expanded(
                    child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      "Average runtime: ${widget.asset.averageRuntime}ms",
                      style: TextStyle(color: Colors.black, fontSize: 20),
                    ),
                    Text(
                      "Rating: ${widget.asset.rating}",
                      style: TextStyle(color: Colors.black, fontSize: 20),
                    ),
                    SelectableText(
                      "Endpoint URL: ${Config.config!["ROOT_RUN_URL"]}/${widget.asset.assetID}/run",
                      style: TextStyle(color: Colors.black, fontSize: 20),
                    )
                  ],
                )),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 20),
                      backgroundColor: AppTheme.grey,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4))),
                  onPressed: () => {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return consumerJourney(
                              assetDescriptor: widget.asset,
                              context: context,
                              runURL:
                                  "${Config.config!["ROOT_RUN_URL"]}/${widget.asset.assetID}/run",
                              getWallet: widget.getWallet,
                              getRequest: widget.getRequest);
                        })
                  },
                  icon: const Icon(
                    Icons.navigate_next_outlined,
                    size: 32,
                  ),
                  label: Text(
                    "Run (${widget.asset.pricePerRun} XRP/request)",
                    style: TextStyle(fontSize: 30),
                  ),
                )
              ],
            )));
  }
}
