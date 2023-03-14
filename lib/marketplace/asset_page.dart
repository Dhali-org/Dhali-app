import 'package:dhali/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart';

import 'model/marketplace_list_data.dart';
import 'package:dhali/config.dart' show Config;

class AssetPage extends StatefulWidget {
  const AssetPage({super.key, required this.asset});
  final MarketplaceListData asset;

  @override
  State<AssetPage> createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> {
  @override
  Widget build(BuildContext context) {
    var future = get(
      Uri.parse(
          "${Config.config!["ROOT_CONSUMER_URL"]}/${widget.asset.assetID}/${Config.config!['POST_DEPLOY_README_ROUTE']}"),
    );
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
                "Categories: ${widget.asset.assetName}",
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
                    return Markdown(data: snapshot.data!.body);
                  } else {
                    return const Center(child: CircularProgressIndicator());
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
                  onPressed: () => {},
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
