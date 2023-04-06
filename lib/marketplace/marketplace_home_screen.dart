import 'dart:async';

import 'package:dhali/marketplace/model/asset_model.dart';
import 'package:dhali/utils/Uploaders.dart';
import 'package:dhali/wallet/home_screen.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart';
import 'package:dhali/app_theme.dart';
import 'package:dhali/marketplace/marketplace_dialogs.dart';
import 'package:dhali/marketplace/marketplace_list_view.dart';
import 'package:dhali/marketplace/model/marketplace_list_data.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../wallet/xrpl_wallet.dart';
import 'asset_page.dart';
import 'filters_screen.dart';
import 'marketplace_app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali/config.dart' show Config;
import 'package:http/http.dart' as http;

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
  final XRPLWallet? Function() getWallet;
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
          // TODO .where("FILTERRED_BY_NFT", isEqualTo: "classic address")
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
          floatingActionButtonLocation: this.widget.getWallet() != null
              ? FloatingActionButtonLocation.centerFloat
              : null,
          floatingActionButton: this.widget.getWallet() != null
              ? getFloatingActionButton(widget.assetScreenType)
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
                    widget.assetScreenType == AssetScreenType.MyAssets
                        ? widget.getWallet() == null
                            ? const Text(
                                "Please activate your wallet using the Wallet page",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 25),
                              )
                            : getGeneratedWidget(widget.getWallet()!)
                        : Container(),
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
                                .backgroundColor,
                            child: widget.assetScreenType ==
                                    AssetScreenType.MyAssets
                                ? getFilteredAssetStreamBuilder()
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
                return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          key: Key("loading_asset_key"),
                          "Loading assets: ",
                          style: TextStyle(fontSize: 25)),
                      CircularProgressIndicator()
                    ]);
              } else {
                print(snapshot.data);
                var nfTokenIDs =
                    (snapshot.data["result"]["account_nfts"] as List<dynamic>)
                        .map((x) => x["NFTokenID"])
                        .toList();

                if (nfTokenIDs.isNotEmpty) {
                  return getAssetStreamBuilder(
                      assetStream: widget
                          .getFirestore()!
                          .collection(
                              Config.config!["MINTED_NFTS_COLLECTION_NAME"])
                          .where(
                              Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
                                  ["NFTOKEN_ID"],
                              whereIn: nfTokenIDs)
                          .limit(20)
                          .snapshots());
                } else {
                  return const Text(
                    key: Key("my_asset_not_found"),
                    "Your wallet has no assets",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                  );
                }
              }
            },
            future: widget.getWallet()!.getAvailableNFTs(),
          )
        : Container();
  }

  Widget getAssetStreamBuilder(
      {Stream<QuerySnapshot<Map<String, dynamic>>>? assetStream}) {
    return StreamBuilder(
        stream: assetStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            return GridView.builder(
              itemCount: snapshot.data!.size,
              padding: const EdgeInsets.only(top: 8),
              scrollDirection: Axis.vertical,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 600, childAspectRatio: 3),
              itemBuilder: (BuildContext context, int index) {
                final int count =
                    snapshot.data!.size > 10 ? 10 : snapshot.data!.size;
                final Animation<double> animation =
                    Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                        parent: animationController!,
                        curve: Interval((1 / count) * index, 1.0,
                            curve: Curves.fastOutSlowIn)));
                animationController?.forward();
                Map<String, dynamic> elementData =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                MarketplaceListData element = MarketplaceListData(
                    assetID: snapshot.data!.docs[index].id,
                    assetName: elementData[Config
                        .config!["MINTED_NFTS_DOCUMENT_KEYS"]["ASSET_NAME"]],
                    assetCategories: elementData[Config
                        .config!["MINTED_NFTS_DOCUMENT_KEYS"]["CATEGORY"]],
                    averageRuntime: elementData[
                        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
                            ["AVERAGE_INFERENCE_TIME_MS"]],
                    rating: elementData[
                        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
                            ["NUMBER_OF_SUCCESSFUL_REQUESTS"]],
                    pricePerRun: elementData[
                        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
                            ["EXPECTED_INFERENCE_COST_PER_MS"]]);
                return MarketplaceListView(
                  callback: displayAsset,
                  marketplaceData: element,
                  animation: animation,
                  animationController: animationController!,
                );
              },
            );
          } else {
            return const SizedBox();
          }
        });
  }

  Widget getListUI() {
    return Container(
      decoration: BoxDecoration(
        color: MarketplaceAppTheme.buildLightTheme().backgroundColor,
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              offset: const Offset(0, -2),
              blurRadius: 8.0),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
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
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AssetPage(
                  asset: asset,
                  getRequest: widget.getRequest,
                  getWallet: widget.getWallet,
                )));
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
                  color: MarketplaceAppTheme.buildLightTheme().backgroundColor,
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
                      hintText: 'Model name, model type, solution space, etc',
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
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Icon(FontAwesomeIcons.magnifyingGlass,
                      size: 20,
                      color: MarketplaceAppTheme.buildLightTheme()
                          .backgroundColor),
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
              color: MarketplaceAppTheme.buildLightTheme().backgroundColor,
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
          color: MarketplaceAppTheme.buildLightTheme().backgroundColor,
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
                      FocusScope.of(context).requestFocus(FocusNode());
                      Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                            builder: (BuildContext context) => FiltersScreen(),
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
        color: MarketplaceAppTheme.buildLightTheme().backgroundColor,
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
            Container(
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

  FloatingActionButton? getFloatingActionButton(assetScreenType) {
    FloatingActionButton? actionButton = null;
    switch (assetScreenType) {
      case AssetScreenType.Marketplace:
        actionButton = null;
        break;
      case AssetScreenType.MyAssets:
        actionButton = FloatingActionButton.extended(
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext _) {
                  if (widget.getWallet() == null) {
                    return AlertDialog(
                      title: Text("Unable to proceed"),
                      content: Text("Your wallet has not been activated"),
                    );
                  }

                  return Dialog(
                    backgroundColor: Colors.transparent,
                    child: DropzoneDeployWidget(
                      onDroppedFile: ((file) {}),
                      onNextClicked: (asset, readme) {
                        Navigator.of(context).pop();
                        showDialog(
                            context: context,
                            builder: (BuildContext _) {
                              return Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: ImageScanningWidget(
                                      file: asset,
                                      onNextClicked: (asset) {
                                        Navigator.of(context).pop();
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext _) {
                                              return Dialog(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  child: ImageCostWidget(
                                                      defaultEarningsPerInference:
                                                          100,
                                                      file: asset,
                                                      onNextClicked: (asset,
                                                          earningsInferenceCost) {
                                                        showDialog(
                                                            context: context,
                                                            builder:
                                                                (BuildContext
                                                                    _) {
                                                              return Dialog(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .transparent,
                                                                  child:
                                                                      DeploymentCostWidget(
                                                                    file: asset,
                                                                    earningsInferenceCost:
                                                                        earningsInferenceCost,
                                                                    yesClicked:
                                                                        ((asset,
                                                                            earningsInferenceCost) {
                                                                      XRPLWallet?
                                                                          wallet =
                                                                          widget
                                                                              .getWallet();

                                                                      showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (BuildContext _) {
                                                                            if (wallet ==
                                                                                null) {
                                                                              // Should never make it here!
                                                                              return AlertDialog(
                                                                                title: Text("Unable to proceed"),
                                                                                content: Text("Your wallet has not been activated"),
                                                                              );
                                                                            }
                                                                            String
                                                                                dest =
                                                                                Config.config!["DHALI_PUBLIC_ADDRESS"]; // TODO : This should be Dhali's address
                                                                            var openChannelsFut =
                                                                                wallet.getOpenPaymentChannels(destination_address: dest);
                                                                            String
                                                                                amount =
                                                                                "10000000"; // TODO : Make sure that these are appropriate 10 XRP
                                                                            String
                                                                                authAmount =
                                                                                "3000000"; // TODO : Make sure that these are appropriate 3 XRP

                                                                            void
                                                                                onNFTOfferPoll(String nfTokenId) {
                                                                              // TODO: Maybe there's more validation we can do here.  This is just a PoC
                                                                              widget.getWallet()!.getNFTOffers(nfTokenId).then((offers) {
                                                                                offers.forEach((offer) {
                                                                                  int amount = offer.amount;
                                                                                  // We are transferring ownership to the creator, so we want the
                                                                                  // offer to be for free:
                                                                                  if (amount != 0) {
                                                                                    return;
                                                                                  }

                                                                                  var offerIndex = offer.offerIndex;
                                                                                  widget.getWallet()!.acceptOffer(offerIndex);
                                                                                });
                                                                              });
                                                                            }

                                                                            var nfTokenIdStream =
                                                                                widget.getFirestore()!.collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"]).doc(asset.modelName).snapshots();

                                                                            return Dialog(
                                                                                backgroundColor: Colors.transparent,
                                                                                child: FutureBuilder<List<PaymentChannelDescriptor>>(
                                                                                  builder: (context, snapshot) {
                                                                                    final exceptionString = "The NFTUploadingWidget must have access to ${Config.config!["DHALI_ID"]}";
                                                                                    if (snapshot.hasData) {
                                                                                      dynamic channel = null;

                                                                                      snapshot.data!.forEach((returnedChannel) {
                                                                                        if (returnedChannel.amount >= int.parse(authAmount)) {
                                                                                          channel = returnedChannel;
                                                                                        }
                                                                                      });
                                                                                      var entryPointUrlRoot = const String.fromEnvironment('ENTRY_POINT_URL_ROOT', defaultValue: '');
                                                                                      if (entryPointUrlRoot == '') {
                                                                                        entryPointUrlRoot = Config.config!["ROOT_DEPLOY_URL"];
                                                                                      }
                                                                                      if (channel != null) {
                                                                                        print(Config.config);
                                                                                        Map<String, String> payment = {
                                                                                          Config.config!["PAYMENT_CLAIM_KEYS"]["ACCOUNT"]: wallet.address,
                                                                                          Config.config!["PAYMENT_CLAIM_KEYS"]["DESTINATION_ACCOUNT"]: dest,
                                                                                          Config.config!["PAYMENT_CLAIM_KEYS"]["AUTHORIZED_AMOUNT"]: authAmount,
                                                                                          Config.config!["PAYMENT_CLAIM_KEYS"]["SIGNATURE"]: wallet.sendDrops(authAmount, channel.channelId),
                                                                                          Config.config!["PAYMENT_CLAIM_KEYS"]["CHANNEL_ID"]: channel.channelId
                                                                                        };
                                                                                        return DataTransmissionWidget(
                                                                                          getUploader: ({required payment, required getRequest, required dynamic Function(double) progressStatus, required int maxChunkSize, required AssetModel model}) {
                                                                                            return DeployUploader(payment: payment, getRequest: getRequest, progressStatus: progressStatus, model: model, maxChunkSize: maxChunkSize, getWallet: widget.getWallet);
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
                                                                                      var newChannelsFut = wallet.openPaymentChannel(dest, amount);
                                                                                      return FutureBuilder<PaymentChannelDescriptor>(
                                                                                        builder: (context, snapshot) {
                                                                                          if (snapshot.hasData) {
                                                                                            print(Config.config);
                                                                                            Map<String, String> payment = {
                                                                                              Config.config!["PAYMENT_CLAIM_KEYS"]["ACCOUNT"]: wallet.address,
                                                                                              Config.config!["PAYMENT_CLAIM_KEYS"]["DESTINATION_ACCOUNT"]: dest,
                                                                                              Config.config!["PAYMENT_CLAIM_KEYS"]["AUTHORIZED_AMOUNT"]: authAmount,
                                                                                              Config.config!["PAYMENT_CLAIM_KEYS"]["SIGNATURE"]: wallet.sendDrops(authAmount, snapshot.data!.channelId),
                                                                                              Config.config!["PAYMENT_CLAIM_KEYS"]["CHANNEL_ID"]: snapshot.data!.channelId
                                                                                            };

                                                                                            return DataTransmissionWidget(
                                                                                                getUploader: ({required payment, required getRequest, required dynamic Function(double) progressStatus, required int maxChunkSize, required AssetModel model}) {
                                                                                                  return DeployUploader(payment: payment, getRequest: getRequest, progressStatus: progressStatus, model: model, maxChunkSize: maxChunkSize, getWallet: widget.getWallet);
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
                                                                                                });
                                                                                          }
                                                                                          return Container();
                                                                                        },
                                                                                        future: newChannelsFut,
                                                                                      );
                                                                                    }
                                                                                    return Container();
                                                                                  },
                                                                                  future: openChannelsFut,
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
                    ),
                  );
                });
          },
          label: const Text('Add new asset'),
          icon: const Icon(Icons.add),
        );
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
