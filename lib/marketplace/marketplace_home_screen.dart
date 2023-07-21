import 'dart:async';
import 'dart:math';

import 'package:dhali/analytics/analytics.dart';
import 'package:dhali/marketplace/model/asset_model.dart';
import 'package:dhali/utils/Uploaders.dart';
import 'package:dhali/utils/not_implemented_dialog.dart';
import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:http/http.dart';
import 'package:dhali/app_theme.dart';
import 'package:dhali/marketplace/marketplace_dialogs.dart';
import 'package:dhali/marketplace/marketplace_list_view.dart';
import 'package:dhali/marketplace/model/marketplace_list_data.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:dhali/marketplace/asset_page.dart';
import 'package:dhali/marketplace/filters_screen.dart';
import 'package:dhali/marketplace/marketplace_app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali/config.dart' show Config;
import 'package:uuid/uuid.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen(
      {Key? key,
      required this.assetScreenType,
      required this.getRequest,
      required this.getWallet,
      required this.setWallet,
      required this.getFirestore})
      : super(key: key);

  final void Function(XRPLWallet) setWallet;
  final DhaliWallet? Function() getWallet;
  final FirebaseFirestore? Function() getFirestore;

  final BaseRequest Function(String method, String path) getRequest;
  final assetScreenType;
  @override
  _AssetScreenState createState() => _AssetScreenState();
}

class _AssetScreenState extends State<MarketplaceHomeScreen>
    with TickerProviderStateMixin {
  AnimationController? animationController;
  List<MarketplaceListData> marketplaceList =
      MarketplaceListData.marketplaceList;
  final ScrollController _scrollController = ScrollController();
  Stream<QuerySnapshot<Map<String, dynamic>>>? stream;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 5));

  @override
  void initState() {
    if (widget.assetScreenType == AssetScreenType.MyAssets) {
      stream = widget
          .getFirestore()!
          .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"])
          .limit(20)
          .snapshots();
    } else {
      stream = widget
          .getFirestore()!
          .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"])
          .limit(20)
          .snapshots();
    }
    animationController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    super.initState();
  }

  Future<bool> getData() async {
    await Future<dynamic>.delayed(const Duration(milliseconds: 200));
    return true;
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MarketplaceAppTheme.buildLightTheme(),
      child: Container(
        child: Scaffold(
          floatingActionButtonLocation: widget.getWallet() != null
              ? FloatingActionButtonLocation.centerFloat
              : null,
          floatingActionButton: widget.getWallet() != null
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 50.0),
                  child: getFloatingActionButton(widget.assetScreenType))
              : null,
          body: Stack(
            children: <Widget>[
              InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: NestedScrollView(
                        controller: _scrollController,
                        headerSliverBuilder:
                            (BuildContext context, bool innerBoxIsScrolled) {
                          return <Widget>[
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                  (BuildContext context, int index) {
                                return getSearchBarUI();
                              }, childCount: 1),
                            ),
                            SliverPersistentHeader(
                              pinned: true,
                              floating: true,
                              delegate: ContestTabHeader(
                                getFilterBarUI(),
                              ),
                            ),
                          ];
                        },
                        body: Container(
                            color: MarketplaceAppTheme.buildLightTheme()
                                .colorScheme
                                .background,
                            child: widget.assetScreenType ==
                                    AssetScreenType.MyAssets
                                ? widget.getWallet() == null
                                    ? const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                            Text(
                                              "Link a wallet through the Wallet"
                                              " page\n and start earning!",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 25,
                                                  color: Colors.grey),
                                            ),
                                            SizedBox(height: 50),
                                            Image(
                                              opacity:
                                                  AlwaysStoppedAnimation(0.2),
                                              height: 220,
                                              width: 220,
                                              image: AssetImage(
                                                  'assets/images/broken_link.png'),
                                            )
                                          ])
                                    : getFilteredAssetStreamBuilder()
                                : getAssetStreamBuilder(
                                    assetStream: widget
                                        .getFirestore()!
                                        .collection(Config.config![
                                            "MINTED_NFTS_COLLECTION_NAME"])
                                        .limit(20)
                                        .snapshots())),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getFilteredAssetStreamBuilder() {
    return widget.getWallet() != null
        ? FutureBuilder(
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (!snapshot.hasData) {
                return const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          key: Key("loading_asset_key"),
                          "Loading assets: ",
                          style: TextStyle(fontSize: 25)),
                      CircularProgressIndicator()
                    ]);
              } else {
                var nfTokenIDs =
                    (snapshot.data["result"]["account_nfts"] as List<dynamic>)
                        .map((x) => x["NFTokenID"])
                        .toList();

                final collection = widget
                    .getFirestore()!
                    .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"]);

                if (nfTokenIDs.isNotEmpty) {
                  // Firestore doesn't support 'in' clauses with more than 10
                  // arguments, so we need to create multiple queries and merge
                  // the streams to handle this case:
                  const maxChunkSize = 9;
                  if (nfTokenIDs.length > maxChunkSize) {
                    List<Stream<QuerySnapshot<Map<String, dynamic>>>> streams =
                        [];
                    for (int i = 0; i < nfTokenIDs.length; i += maxChunkSize) {
                      List<dynamic> chunk = nfTokenIDs.sublist(
                          i,
                          i + maxChunkSize > nfTokenIDs.length
                              ? nfTokenIDs.length
                              : i + maxChunkSize);

                      // TODO: This limits to 20 - needs to handle cases with more than 20:
                      final stream = collection
                          .where(
                              Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
                                  ["NFTOKEN_ID"],
                              whereIn: chunk)
                          .limit(20)
                          .snapshots();

                      // Add the documents from the current chunk query to the result list
                      streams.add(stream);
                    }

                    Stream<List<QuerySnapshot<Map<String, dynamic>>>> stream =
                        CombineLatestStream(
                            streams,
                            (values) => values
                                as List<QuerySnapshot<Map<String, dynamic>>>);

                    return getAssetStreamBuilderFromList(assetStream: stream);
                  } else {
                    return getAssetStreamBuilder(
                        assetStream: collection
                            .where(
                                Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
                                    ["NFTOKEN_ID"],
                                whereIn: nfTokenIDs)
                            .limit(20)
                            .snapshots());
                  }
                } else {
                  return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Monetise your first asset to start earning!",
                          key: Key("my_asset_not_found"),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                              color: Colors.grey),
                        ),
                        Image(
                          opacity: AlwaysStoppedAnimation(.5),
                          height: 320,
                          width: 320,
                          image: AssetImage(
                              'assets/images/light_empty_wallet.png'),
                        )
                      ]);
                }
              }
            },
            future: widget.getWallet()!.getAvailableNFTs(),
          )
        : Container();
  }

  Widget getAssetStreamBuilderFromList(
      {Stream<List<QuerySnapshot<Map<String, dynamic>>>>? assetStream}) {
    return StreamBuilder(
        stream: assetStream,
        builder: (BuildContext context,
            AsyncSnapshot<List<QuerySnapshot>> snapshot) {
          if (snapshot.hasData) {
            List<QueryDocumentSnapshot<Object?>> docs = [];
            for (var docsFromStream in snapshot.data!) {
              docs.addAll(docsFromStream.docs);
            }
            return getAssetGridView(docs);
          } else {
            return Center(
                child: Container(
                    child: const Text("An error occured loading your assets")));
          }
        });
  }

  Widget getAssetStreamBuilder(
      {Stream<QuerySnapshot<Map<String, dynamic>>>? assetStream}) {
    return StreamBuilder(
        stream: assetStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            return getAssetGridView(snapshot.data!.docs);
          } else {
            return const SizedBox();
          }
        });
  }

  Widget getAssetGridView(List<QueryDocumentSnapshot<Object?>> docs) {
    return GridView.builder(
      key: const Key("asset_grid_view"),
      itemCount: docs.length,
      padding: const EdgeInsets.only(top: 8),
      scrollDirection: Axis.vertical,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 600, childAspectRatio: 3),
      itemBuilder: (BuildContext context, int index) {
        final int count = docs.length > 10 ? 10 : docs.length;
        final Animation<double> animation = Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(
                parent: animationController!,
                curve: Interval(min((1 / count) * index, 1.0), 1.0,
                    curve: Curves.fastOutSlowIn)));
        animationController?.forward();
        Map<String, dynamic> elementData =
            docs[index].data() as Map<String, dynamic>;
        MarketplaceListData element = MarketplaceListData(
            assetID: docs[index].id,
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
            pricePerRun: elementData[Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
                ["EXPECTED_INFERENCE_COST_PER_MS"]]);
        return MarketplaceListView(
          callback: displayAsset,
          marketplaceData: element,
          animation: animation,
          animationController: animationController!,
        );
      },
    );
  }

  Widget getListUI() {
    return Container(
      decoration: BoxDecoration(
        color: MarketplaceAppTheme.buildLightTheme().colorScheme.background,
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              offset: const Offset(0, -2),
              blurRadius: 8.0),
        ],
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height - 156 - 50,
            child: FutureBuilder<bool>(
              future: getData(),
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                } else {
                  return ListView.builder(
                    itemCount: marketplaceList.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (BuildContext context, int index) {
                      final int count = marketplaceList.length > 10
                          ? 10
                          : marketplaceList.length;
                      final Animation<double> animation =
                          Tween<double>(begin: 0.0, end: 1.0).animate(
                              CurvedAnimation(
                                  parent: animationController!,
                                  curve: Interval((1 / count) * index, 1.0,
                                      curve: Curves.fastOutSlowIn)));
                      animationController?.forward();

                      return MarketplaceListView(
                        callback: displayAsset,
                        marketplaceData: marketplaceList[index],
                        animation: animation,
                        animationController: animationController!,
                      );
                    },
                  );
                }
              },
            ),
          )
        ],
      ),
    );
  }

  void displayAsset(MarketplaceListData asset) {
    Navigator.pushNamed(context, '/assets/${asset.assetID}',
        arguments: AssetPage(
          getFirestore: widget.getFirestore,
          asset: asset,
          getRequest: widget.getRequest,
          getWallet: widget.getWallet,
        ));
  }

  Widget getMarketplaceViewList() {
    final List<Widget> marketplaceListViews = <Widget>[];
    for (int i = 0; i < marketplaceList.length; i++) {
      final int count = marketplaceList.length;
      final Animation<double> animation =
          Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animationController!,
          curve: Interval((1 / count) * i, 1.0, curve: Curves.fastOutSlowIn),
        ),
      );
      marketplaceListViews.add(
        MarketplaceListView(
          callback: displayAsset,
          marketplaceData: marketplaceList[i],
          animation: animation,
          animationController: animationController!,
        ),
      );
    }
    animationController?.forward();
    return Column(
      children: marketplaceListViews,
    );
  }

  Widget getSearchBarUI() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: MarketplaceAppTheme.buildLightTheme()
                      .colorScheme
                      .background,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(38.0),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        offset: const Offset(0, 2),
                        blurRadius: 8.0),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 4, bottom: 4),
                  child: TextField(
                    onChanged: (String txt) {},
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                    cursorColor:
                        MarketplaceAppTheme.buildLightTheme().primaryColor,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Asset name, asset type, solution space, etc',
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: MarketplaceAppTheme.buildLightTheme().primaryColor,
              borderRadius: const BorderRadius.all(
                Radius.circular(38.0),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                    color: Colors.grey.withOpacity(0.4),
                    offset: const Offset(0, 2),
                    blurRadius: 8.0),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.all(
                  Radius.circular(32.0),
                ),
                onTap: () {
                  showNotImplentedWidget(
                      context: context, feature: "Helper: Search for assets");
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Icon(FontAwesomeIcons.magnifyingGlass,
                      size: 20,
                      color: MarketplaceAppTheme.buildLightTheme()
                          .colorScheme
                          .background),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getFilterBarUI() {
    return Stack(
      children: <Widget>[
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              color:
                  MarketplaceAppTheme.buildLightTheme().colorScheme.background,
              boxShadow: <BoxShadow>[
                BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    offset: const Offset(0, -2),
                    blurRadius: 8.0),
              ],
            ),
          ),
        ),
        Container(
          color: MarketplaceAppTheme.buildLightTheme().colorScheme.background,
          child: Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
            child: Row(
              children: <Widget>[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.grey.withOpacity(0.2),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(4.0),
                    ),
                    onTap: () {
                      showNotImplentedWidget(
                          context: context, feature: "Helper: Filter assets");
                      return;
                      FocusScope.of(context).requestFocus(FocusNode());
                      Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                            builder: (BuildContext context) =>
                                const FiltersScreen(),
                            fullscreenDialog: true),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Row(
                        children: <Widget>[
                          const Text(
                            'Filter',
                            style: TextStyle(
                              fontWeight: FontWeight.w100,
                              fontSize: 16,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(Icons.sort,
                                color: MarketplaceAppTheme.buildLightTheme()
                                    .primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Divider(
            height: 1,
          ),
        )
      ],
    );
  }

  Widget getAppBarUI() {
    return Container(
      decoration: BoxDecoration(
        color: MarketplaceAppTheme.buildLightTheme().colorScheme.background,
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              offset: const Offset(0, 2),
              blurRadius: 8.0),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top, left: 8, right: 8),
        child: Row(
          children: <Widget>[
            Container(
              alignment: Alignment.centerLeft,
              width: AppBar().preferredSize.height + 40,
              height: AppBar().preferredSize.height,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(32.0),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                  // child: Padding(
                  //   padding: const EdgeInsets.all(8.0),
                  //   child: Icon(Icons.arrow_back),
                  // ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  getTitle(widget.assetScreenType),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: AppBar().preferredSize.height + 40,
              height: AppBar().preferredSize.height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(32.0),
                      ),
                      onTap: () {},
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.favorite_border),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(32.0),
                      ),
                      onTap: () {},
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(FontAwesomeIcons.locationDot),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget? getFloatingActionButton(assetScreenType) {
    Widget? actionButton;
    switch (assetScreenType) {
      case AssetScreenType.Marketplace:
        actionButton = null;
        break;
      case AssetScreenType.MyAssets:
        actionButton = Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FloatingActionButton.extended(
                  backgroundColor: AppTheme.dhali_blue,
                  foregroundColor: AppTheme.white,
                  hoverColor: AppTheme.dhali_blue_highlight,
                  focusColor: AppTheme.dhali_blue_highlight,
                  label: const Text('Monetise GitHub project'),
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext _) {
                          return const AlertDialog(
                            title: Text("Unable to proceed"),
                            content: Text("This feature is coming soon!"),
                          );
                        });
                  },
                ),
                SizedBox(
                  width: 10,
                ),
                FloatingActionButton.extended(
                  onPressed: () {
                    gtag(command: "event", target: "AddNewAssetClicked");
                    showDialog(
                        context: context,
                        builder: (BuildContext _) {
                          if (widget.getWallet() == null) {
                            return const AlertDialog(
                              title: Text("Unable to proceed"),
                              content: Text(
                                  "Please link a wallet using the Wallet page"),
                            );
                          }
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            child: AssetNameWidget(
                                step: 1,
                                steps: 4,
                                onDroppedFile: ((file) {}),
                                onNextClicked: (name) {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext _) {
                                        return Dialog(
                                            backgroundColor: Colors.transparent,
                                            child: ImageCostWidget(
                                              step: 2,
                                              steps: 4,
                                              defaultEarningsPerInference: 20,
                                              onNextClicked: (assetEarnings) {
                                                showDialog(
                                                    context: context,
                                                    builder: (BuildContext _) {
                                                      return Dialog(
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          child:
                                                              DropzoneDeployWidget(
                                                                  step: 3,
                                                                  steps: 4,
                                                                  onDroppedFile:
                                                                      ((file) {}),
                                                                  onNextClicked:
                                                                      (asset,
                                                                          readme) {
                                                                    asset.modelName =
                                                                        name;
                                                                    readme.modelName =
                                                                        name;
                                                                    showDialog(
                                                                        context:
                                                                            context,
                                                                        builder:
                                                                            (BuildContext
                                                                                _) {
                                                                          return Dialog(
                                                                              backgroundColor: Colors.transparent,
                                                                              child: ImageScanningWidget(
                                                                                  step: 3,
                                                                                  steps: 4,
                                                                                  file: asset,
                                                                                  onNextClicked: (asset) {
                                                                                    showDialog(
                                                                                        context: context,
                                                                                        builder: (BuildContext _) {
                                                                                          final assetDeploymentCost = Config.config!["DHALI_DEPLOYMENT_COST_PER_CHUNK_DROPS"] * ((asset.size / Config.config!["MAX_NUMBER_OF_BYTES_PER_DEPLOY_CHUNK"]).floor() + 3); // TODO: Why? We add a buffer of 3 to guarantee success
                                                                                          final readmeDeploymentCost = Config.config!["DHALI_DEPLOYMENT_COST_PER_CHUNK_DROPS"] * ((readme.size / Config.config!["MAX_NUMBER_OF_BYTES_PER_DEPLOY_CHUNK"]).floor() + 3); // TODO: Why? We add a buffer of 3 to guarantee success
                                                                                          final dhaliEarnings = Config.config!["DHALI_EARNINGS_PERCENTAGE_PER_INFERENCE"];
                                                                                          double deploymentCost = assetDeploymentCost + readmeDeploymentCost;
                                                                                          return Dialog(
                                                                                              backgroundColor: Colors.transparent,
                                                                                              child: DeploymentCostWidget(
                                                                                                step: 4,
                                                                                                steps: 4,
                                                                                                file: asset,
                                                                                                deploymentCost: deploymentCost,
                                                                                                assetEarnings: assetEarnings,
                                                                                                dhaliEarnings: dhaliEarnings,
                                                                                                yesClicked: ((asset, earningsInferenceCost) {
                                                                                                  DhaliWallet? wallet = widget.getWallet()!;

                                                                                                  showDialog(
                                                                                                      context: context,
                                                                                                      builder: (BuildContext _) {
                                                                                                        if (wallet == null) {
                                                                                                          // Should never make it here!
                                                                                                          return const AlertDialog(
                                                                                                            title: Text("Unable to proceed"),
                                                                                                            content: Text("Please link a wallet using the Wallet page"),
                                                                                                          );
                                                                                                        }
                                                                                                        String dest = Config.config!["DHALI_PUBLIC_ADDRESS"]; // TODO : This should be Dhali's address
                                                                                                        var payment = wallet.getOpenPaymentChannels(destination_address: dest).then((channelDescriptors) async {
                                                                                                          double toClaim = 0;
                                                                                                          if (channelDescriptors.isEmpty) {
                                                                                                            channelDescriptors = [
                                                                                                              await wallet.openPaymentChannel(dest, deploymentCost.ceil().toString())
                                                                                                            ];
                                                                                                          }
                                                                                                          var docId = const Uuid().v5(Uuid.NAMESPACE_URL, channelDescriptors[0].channelId);
                                                                                                          var toClaimDoc = await widget.getFirestore()!.collection("public_claim_info").doc(docId).get();
                                                                                                          toClaim = toClaimDoc.exists ? toClaimDoc.data()!["to_claim"] as double : 0;
                                                                                                          String total = (toClaim + double.parse(deploymentCost.ceil().toString())).toString();
                                                                                                          double requiredInChannel = double.parse(total) - channelDescriptors[0].amount + 1;
                                                                                                          if (requiredInChannel > 0) {
                                                                                                            await wallet.fundPaymentChannel(channelDescriptors[0], requiredInChannel.toString());
                                                                                                          }
                                                                                                          var payment = wallet.preparePayment(destinationAddress: dest, authAmount: total, channelDescriptor: channelDescriptors[0]);
                                                                                                          return payment;
                                                                                                        });

                                                                                                        void onNFTOfferPoll(String nfTokenId) {
                                                                                                          // TODO: Maybe there's more validation we can do here.  This is just a PoC
                                                                                                          widget.getWallet()!.getNFTOffers(nfTokenId).then((offers) {
                                                                                                            for (var offer in offers) {
                                                                                                              int amount = offer.amount;
                                                                                                              // We are transferring ownership to the creator, so we want the
                                                                                                              // offer to be for free:
                                                                                                              if (amount != 0) {
                                                                                                                continue;
                                                                                                              }

                                                                                                              var offerIndex = offer.offerIndex;
                                                                                                              widget.getWallet()!.acceptOffer(offerIndex);
                                                                                                            }
                                                                                                          });
                                                                                                        }

                                                                                                        return Dialog(
                                                                                                            backgroundColor: Colors.transparent,
                                                                                                            child: FutureBuilder<Map<String, String>>(
                                                                                                              builder: (context, snapshot) {
                                                                                                                final exceptionString = "The NFTUploadingWidget must have access to ${Config.config!["DHALI_ID"]}";
                                                                                                                if (snapshot.hasData) {
                                                                                                                  var entryPointUrlRoot = const String.fromEnvironment('ENTRY_POINT_URL_ROOT', defaultValue: '');
                                                                                                                  if (entryPointUrlRoot == '') {
                                                                                                                    entryPointUrlRoot = Config.config!["ROOT_DEPLOY_URL"];
                                                                                                                  }
                                                                                                                  Map<String, String> payment = snapshot.data!;
                                                                                                                  return DataTransmissionWidget(
                                                                                                                    getUploader: ({required payment, required getRequest, required dynamic Function(double) progressStatus, required int maxChunkSize, required AssetModel model}) {
                                                                                                                      return DeployUploader(payment: payment, getRequest: getRequest, progressStatus: progressStatus, model: model, maxChunkSize: maxChunkSize, getWallet: widget.getWallet, assetEarningRate: assetEarnings);
                                                                                                                    },
                                                                                                                    payment: payment,
                                                                                                                    getRequest: widget.getRequest,
                                                                                                                    data: [
                                                                                                                      DataEndpointPair(data: asset, endPoint: "$entryPointUrlRoot/${Config.config!["POST_DEPLOY_ASSET_ROUTE"]}/"),
                                                                                                                      DataEndpointPair(data: readme, endPoint: "$entryPointUrlRoot/${Config.config!["POST_DEPLOY_README_ROUTE"]}/"),
                                                                                                                    ],
                                                                                                                    onNextClicked: (data) {},
                                                                                                                    getOnSuccessWidget: (BuildContext context, BaseResponse? response) {
                                                                                                                      if (response == null || !response.headers.containsKey(Config.config!["DHALI_ID"].toString().toLowerCase())) {
                                                                                                                        throw Exception(exceptionString);
                                                                                                                      }

                                                                                                                      return NFTUploadingWidget(context, widget.getFirestore, onNFTOfferPoll, () => response.headers[Config.config!["DHALI_ID"].toString().toLowerCase()]);
                                                                                                                    },
                                                                                                                  );
                                                                                                                }
                                                                                                                return Container();
                                                                                                              },
                                                                                                              future: payment,
                                                                                                            ));
                                                                                                      });
                                                                                                }),
                                                                                              ));
                                                                                        });
                                                                                  }));
                                                                        });
                                                                  }));
                                                    });
                                              },
                                            ));
                                      });
                                }),
                          );
                        });
                  },
                  backgroundColor: AppTheme.dhali_blue,
                  foregroundColor: AppTheme.white,
                  hoverColor: AppTheme.dhali_blue_highlight,
                  focusColor: AppTheme.dhali_blue_highlight,
                  label: const Text('Monetise my asset'),
                  icon: const Icon(Icons.add),
                )
              ],
            ));
        ;
        break;
      default:
        break;
    }
    return actionButton;
  }

  String getTitle(assetScreenType) {
    String title = "";
    switch (assetScreenType) {
      case AssetScreenType.Marketplace:
        title = "Marketplace";
        break;
      case AssetScreenType.MyAssets:
        title = "My Assets";
        break;
      default:
        break;
    }
    return title;
  }
}

class ContestTabHeader extends SliverPersistentHeaderDelegate {
  ContestTabHeader(
    this.searchUI,
  );
  final Widget searchUI;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return searchUI;
  }

  @override
  double get maxExtent => 52.0;

  @override
  double get minExtent => 52.0;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

enum AssetScreenType {
  MyAssets,
  Marketplace,
}
