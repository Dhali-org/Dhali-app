import 'dart:js' as js;

import 'package:dhali/utils/display_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:split_view/split_view.dart';
import 'package:http/http.dart';

import 'package:dhali/analytics/analytics.dart';
import 'package:dhali/app_theme.dart';
import 'package:dhali/marketplace/marketplace_home_screen.dart';
import 'package:dhali/utils/not_implemented_dialog.dart';
import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:dhali_wallet/dhali_wallet_widget.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:dhali_wallet/xumm_wallet.dart';

import 'package:url_launcher/url_launcher.dart';

enum DrawerIndex {
  Wallet,
  Assets,
  Marketplace,
  Licenses,
}

class NavigationHomeScreen extends StatefulWidget {
  const NavigationHomeScreen(
      {super.key,
      this.drawerIndex,
      required this.getWallet,
      required this.setWallet,
      required this.getRequest,
      required this.firestore,
      this.queryParams});

  final BaseRequest Function(String method, String path) getRequest;
  final FirebaseFirestore firestore;
  final Map<String, String>? queryParams;

  final DrawerIndex? drawerIndex;
  final DhaliWallet? Function() getWallet;
  final Function(DhaliWallet?) setWallet;

  @override
  _NavigationHomeScreenState createState() =>
      _NavigationHomeScreenState(drawerIndex);
}

class _NavigationHomeScreenState extends State<NavigationHomeScreen> {
  _NavigationHomeScreenState(this.drawerIndex);
  Widget? screenView;
  DrawerIndex? drawerIndex;
  bool _showContinueButton = false;
  bool _walletIsLinked = false;
  bool _showWalletPrompt = true;
  bool _tray_open = false;

  @override
  void initState() {
    drawerIndex == Null ? DrawerIndex.Marketplace : drawerIndex;
    screenView = getScreenView(drawerIndex);
    super.initState();
  }

  void linkWallet() {
    setState(() {
      _walletIsLinked = true;
      _showWalletPrompt = false;
      _showContinueButton = true;
      screenView = getScreenView(DrawerIndex.Wallet);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktopResolution(context)) {
      _tray_open = true;
    }

    return Container(
      color: AppTheme.white,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Scaffold(
          appBar: !_tray_open
              ? AppBar(
                  backgroundColor: AppTheme.white,
                  foregroundColor: AppTheme.nearlyBlack,
                  leading: Builder(
                    builder: (BuildContext context) {
                      return Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu),
                            iconSize: 35,
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                          ),
                          if (_showWalletPrompt)
                            Positioned(
                              right: 5,
                              top: 5,
                              child: Container(
                                padding: const EdgeInsets.all(1),
                                child: const Icon(
                                  CupertinoIcons
                                      .exclamationmark_circle_fill, // Your notification icon
                                  color: Colors.red,
                                  size:
                                      18, // Adjust this to make your icon bigger or smaller
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                )
              : null,
          drawer: !_tray_open
              ? Drawer(
                  backgroundColor: AppTheme.white,
                  child: getTrayElements(),
                )
              : null,
          backgroundColor: AppTheme.nearlyBlack,
          drawerEdgeDragWidth: 0,
          body: !_tray_open ? screenView : getSplitScreen(),
        ),
      ),
    );
  }

  Widget getSplitScreen() {
    return SplitView(
      viewMode: SplitViewMode.Horizontal,
      gripColor: Colors.grey,
      gripSize: 5.0,
      controller: SplitViewController(weights: [0.15, 0.85]),
      children: [getTrayElements(), screenView!],
    );
  }

  Widget getTrayElements() {
    return Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.white,
              ),
              child: SizedBox(
                height: 30, // Or any other height that suits your design
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Image.asset('assets/images/dhali.png'),
                ),
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.home_filled, color: AppTheme.dhali_blue),
              title: const Text('Home',
                  style: TextStyle(color: AppTheme.nearlyBlack)),
              onTap: () {
                gtag(command: "event", target: "HomeSelected", parameters: {});
                _launchUrl("https://dhali.io");
              },
            ),
            const Divider(
              height: 20,
              thickness: 1,
              color: Colors.grey,
            ),
            Stack(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.wallet, color: AppTheme.dhali_blue),
                  title: const Text('Wallet',
                      style: TextStyle(color: AppTheme.nearlyBlack)),
                  onTap: () {
                    getScreenView(DrawerIndex.Wallet);
                    if (!_tray_open) {
                      Navigator.pop(context);
                    }
                  },
                ),
                if (_showWalletPrompt)
                  Positioned(
                    left: 30,
                    top: 5,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      child: const Icon(
                        CupertinoIcons
                            .exclamationmark_circle_fill, // Your notification icon
                        color: Colors.red,
                        size:
                            18, // Adjust this to make your icon bigger or smaller
                      ),
                    ),
                  ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.token, color: AppTheme.dhali_blue),
              title: const Text('My assets',
                  style: TextStyle(color: AppTheme.nearlyBlack)),
              onTap: isDesktopResolution(context)
                  ? () {
                      getScreenView(DrawerIndex.Assets);
                      if (!_tray_open) {
                        Navigator.pop(context);
                      }
                    }
                  : () {
                      showNotImplentedWidget(
                          context: context,
                          feature: "Mobile asset administration",
                          message: "This tab is available on desktops.");
                    },
            ),
            ListTile(
              leading: const Icon(Icons.shop, color: AppTheme.dhali_blue),
              title: const Text('Marketplace',
                  style: TextStyle(color: AppTheme.nearlyBlack)),
              onTap: () {
                getScreenView(DrawerIndex.Marketplace);
                if (!_tray_open) {
                  Navigator.pop(context);
                }
              },
            ),
            const Divider(
              height: 20,
              thickness: 1,
              color: Colors.grey,
            ),
            ListTile(
              leading: const Icon(Icons.book, color: AppTheme.dhali_blue),
              title: const Text('Docs',
                  style: TextStyle(color: AppTheme.nearlyBlack)),
              onTap: () {
                gtag(command: "event", target: "DocsSelected", parameters: {});
                _launchUrl("https://dhali.io/docs");
              },
            ),
            ListTile(
              leading: const Icon(Icons.badge, color: AppTheme.dhali_blue),
              title: const Text('Licenses',
                  style: TextStyle(color: AppTheme.nearlyBlack)),
              onTap: () {
                getScreenView(DrawerIndex.Licenses);
                if (!_tray_open) {
                  Navigator.pop(context);
                }
              },
            ),
            ListTile(
                leading: const Icon(Icons.cookie, color: AppTheme.dhali_blue),
                title: const Text('Cookie Consent Preferences',
                    style: TextStyle(color: AppTheme.nearlyBlack)),
                onTap: () {
                  js.context.callMethod('displayPreferenceModal');
                }),
          ],
        ));
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  void changeIndex(DrawerIndex drawerIndexdata) {
    if (drawerIndex != drawerIndexdata) {
      drawerIndex = drawerIndexdata;
      setState(() {
        screenView = getScreenView(drawerIndex);
      });
    }
  }

  Widget? getScreenView(drawerIndex) {
    Future(() => ScaffoldMessenger.of(context).hideCurrentSnackBar());
    screenView = MarketplaceHomeScreen(
        key: const Key("Marketplace"), // Key used to force State rebuild
        getRequest: widget.getRequest,
        assetScreenType: AssetScreenType.Marketplace,
        getWallet: widget.getWallet,
        setWallet: widget.setWallet,
        getFirestore: getFirestore);
    _showWalletPrompt = !_walletIsLinked;
    switch (drawerIndex) {
      case DrawerIndex.Wallet:
        _showWalletPrompt = false;
        setState(() {
          SnackBar snackbar;
          snackbar = const SnackBar(
            backgroundColor: Colors.red,
            content:
                Text("Dhali is currently in alpha and uses test XRP only!"),
            duration: Duration(days: 1),
          );

          final String walletType = widget.getWallet() is XRPLWallet
              ? "XRPL"
              : widget.getWallet() is XummWallet
                  ? "Xumm"
                  : "Not selected yet";

          gtag(command: "event", target: "WalletScreenShown", parameters: {
            "type": walletType,
            "walletIsLinked": _walletIsLinked
          });

          Future(() => ScaffoldMessenger.of(context).showSnackBar(snackbar));
          if (_showContinueButton) {}
          screenView = Scaffold(
              body: Stack(children: [
            WalletHomeScreen(
              title: "Wallet",
              getWallet: widget.getWallet,
              setWallet: widget.setWallet,
              appBarColor: AppTheme.dhali_blue,
              bodyTextColor: Colors.black,
              buttonsColor: AppTheme.dhali_blue,
              onActivation: linkWallet,
            ),
            if (_showContinueButton)
              if (isDesktopResolution(context))
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton.extended(
                      label: const Text('Continue to assets page'),
                      onPressed: (() {
                        gtag(
                            command: "event",
                            target: "AssetsScreenShownFromWalletContinue",
                            parameters: {"walletIsLinked": _walletIsLinked});
                        setState(() {
                          screenView = getScreenView(DrawerIndex.Assets);
                          _showContinueButton = false;
                        });
                      }),
                      backgroundColor: AppTheme.dhali_blue,
                      foregroundColor: AppTheme.white,
                      hoverColor: AppTheme.dhali_blue_highlight,
                      focusColor: AppTheme.dhali_blue_highlight,
                    ),
                  ),
                )
              else
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton.extended(
                      label: const Text('Continue to marketplace'),
                      onPressed: (() {
                        gtag(
                            command: "event",
                            target: "MarketplaceScreenShownFromWalletContinue",
                            parameters: {"walletIsLinked": _walletIsLinked});
                        setState(() {
                          screenView = getScreenView(DrawerIndex.Marketplace);
                          _showContinueButton = false;
                        });
                      }),
                      backgroundColor: AppTheme.dhali_blue,
                      foregroundColor: AppTheme.white,
                      hoverColor: AppTheme.dhali_blue_highlight,
                      focusColor: AppTheme.dhali_blue_highlight,
                    ),
                  ),
                )
          ]));
        });
        break;
      case DrawerIndex.Assets:
        gtag(
            command: "event",
            target: "AssetsScreenShown",
            parameters: {"walletIsLinked": _walletIsLinked});

        setState(() {
          screenView = MarketplaceHomeScreen(
            key: const Key("My Assets"), // Key used to force State rebuild
            getRequest: widget.getRequest,
            assetScreenType: AssetScreenType.MyAssets,
            getWallet: widget.getWallet,
            setWallet: widget.setWallet,
            getFirestore: getFirestore,
          );
        });
        break;
      case DrawerIndex.Marketplace:
        gtag(
            command: "event",
            target: "MarketplaceScreenShown",
            parameters: {"walletIsLinked": _walletIsLinked});
        setState(() {
          screenView = MarketplaceHomeScreen(
              key: const Key("Marketplace"), // Key used to force State rebuild
              getRequest: widget.getRequest,
              assetScreenType: AssetScreenType.Marketplace,
              getWallet: widget.getWallet,
              setWallet: widget.setWallet,
              getFirestore: getFirestore);
        });
        break;
      case DrawerIndex.Licenses:
        setState(() {
          screenView = const LicensePage();
        });
        break;
      default:
        break;
    }
    return screenView;
  }

  FirebaseFirestore? getFirestore() {
    return widget.firestore;
  }
}
