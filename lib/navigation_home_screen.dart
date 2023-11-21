import 'dart:js' as js;

import 'package:dhali/config.dart';
import 'package:dhali/utils/display_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:split_view/split_view.dart';
import 'package:http/http.dart';

import 'package:dhali/analytics/analytics.dart';
import 'package:dhali/marketplace/marketplace_home_screen.dart';
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
      required this.setDarkTheme,
      required this.isDarkTheme,
      this.queryParams});

  final BaseRequest Function<T extends BaseRequest>(String method, String path)
      getRequest;
  final FirebaseFirestore firestore;
  final Map<String, String>? queryParams;

  final DrawerIndex? drawerIndex;
  final DhaliWallet? Function() getWallet;
  final Function(DhaliWallet?) setWallet;
  final void Function(bool) setDarkTheme;
  final bool Function() isDarkTheme;

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
  final bool _is_dark = false;

  @override
  void initState() {
    drawerIndex = drawerIndex ?? DrawerIndex.Wallet;
    screenView = getScreenView(drawerIndex);

    // Hit the README server as soon as the app is opened to spin it up
    var uri = Uri.parse(
        "${Config.config!["ROOT_CONSUMER_URL"]}/dummy-asset/${Config.config!['GET_READMES_ROUTE']}");

    if (widget.firestore.runtimeType == FirebaseFirestore) {
      // Only hit the README server if `firestore` is not a mocked type
      var logger = Logger();
      logger.d("Spinning up README server");
      get(uri);
    }

    super.initState();
  }

  void linkWallet() {
    final String walletType = widget.getWallet() is XRPLWallet
        ? "XRPL"
        : widget.getWallet() is XummWallet
            ? "Xumm"
            : "Unknown";

    gtag(command: "event", target: "walletLinked", parameters: {
      "type": walletType,
    });

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
      child: SafeArea(
        top: false,
        bottom: false,
        child: Scaffold(
          appBar: !_tray_open
              ? AppBar(
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
                  child: getTrayElements(),
                )
              : null,
          drawerEdgeDragWidth: 0,
          body: !_tray_open ? screenView : getSplitScreen(),
        ),
      ),
    );
  }

  Widget getSplitScreen() {
    return SplitView(
      viewMode: SplitViewMode.Horizontal,
      gripSize: 5.0,
      controller: SplitViewController(weights: [0.15, 0.85]),
      children: [getTrayElements(), screenView!],
    );
  }

  Widget getTrayElements() {
    return Container(
        child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          child: SizedBox(
            height: 30, // Or any other height that suits your design
            child: FittedBox(
              fit: BoxFit.contain,
              child: Image.asset('assets/images/dhali.png'),
            ),
          ),
        ),
        Material(
            type: MaterialType.transparency,
            child: ListTile(
              leading: const Icon(Icons.home_filled),
              title: const Text('Home', style: TextStyle()),
              onTap: () {
                gtag(command: "event", target: "HomeSelected", parameters: {});
                _launchUrl("https://dhali.io");
              },
            )),
        const Divider(
          height: 20,
          thickness: 1,
          color: Colors.grey,
        ),
        Stack(
          children: <Widget>[
            ListTile(
              selected: DrawerIndex.Wallet == drawerIndex,
              selectedTileColor: Theme.of(context).colorScheme.secondary,
              leading: Icon(Icons.wallet,
                  color: DrawerIndex.Wallet == drawerIndex
                      ? Theme.of(context).colorScheme.onSecondary
                      : Theme.of(context).colorScheme.onBackground),
              title: Text(
                'Wallet',
                style: TextStyle(
                    color: DrawerIndex.Wallet == drawerIndex
                        ? Theme.of(context).colorScheme.onSecondary
                        : Theme.of(context).colorScheme.onBackground),
              ),
              onTap: () {
                drawerIndex = DrawerIndex.Wallet;
                getScreenView(DrawerIndex.Wallet);
                if (!_tray_open) {
                  Navigator.pop(context);
                }
              },
            ),
            Positioned(
              left: 30,
              top: 5,
              child: Container(
                padding: const EdgeInsets.all(1),
                child: Icon(
                  CupertinoIcons.circle_filled, // Your notification icon
                  color: _walletIsLinked ? Colors.green : Colors.red,
                  size: 18, // Adjust this to make your icon bigger or smaller
                ),
              ),
            ),
          ],
        ),
        ListTile(
          selected: DrawerIndex.Assets == drawerIndex,
          selectedTileColor: Theme.of(context).colorScheme.secondary,
          leading: Icon(Icons.token,
              color: DrawerIndex.Assets == drawerIndex
                  ? Theme.of(context).colorScheme.onSecondary
                  : Theme.of(context).colorScheme.onBackground),
          title: Text('My APIs',
              style: TextStyle(
                  color: DrawerIndex.Assets == drawerIndex
                      ? Theme.of(context).colorScheme.onSecondary
                      : Theme.of(context).colorScheme.onBackground)),
          onTap: () {
            drawerIndex = DrawerIndex.Assets;
            getScreenView(DrawerIndex.Assets);
            if (!_tray_open) {
              Navigator.pop(context);
            }
          },
        ),
        ListTile(
          selected: DrawerIndex.Marketplace == drawerIndex,
          selectedTileColor: Theme.of(context).colorScheme.secondary,
          leading: Icon(Icons.shop,
              color: DrawerIndex.Marketplace == drawerIndex
                  ? Theme.of(context).colorScheme.onSecondary
                  : Theme.of(context).colorScheme.onBackground),
          title: Text('Marketplace',
              style: TextStyle(
                  color: DrawerIndex.Marketplace == drawerIndex
                      ? Theme.of(context).colorScheme.onSecondary
                      : Theme.of(context).colorScheme.onBackground)),
          onTap: () {
            drawerIndex = DrawerIndex.Marketplace;
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
          leading: const Icon(Icons.book),
          title: const Text(
            'Docs',
          ),
          onTap: () {
            gtag(command: "event", target: "DocsSelected", parameters: {});
            _launchUrl("https://dhali.io/docs");
          },
        ),
        ListTile(
          selected: DrawerIndex.Licenses == drawerIndex,
          selectedTileColor: Theme.of(context).colorScheme.secondary,
          leading: Icon(Icons.badge,
              color: DrawerIndex.Licenses == drawerIndex
                  ? Theme.of(context).colorScheme.onSecondary
                  : Theme.of(context).colorScheme.onBackground),
          title: Text(
            'Licenses',
            style: TextStyle(
                color: DrawerIndex.Licenses == drawerIndex
                    ? Theme.of(context).colorScheme.onSecondary
                    : Theme.of(context).colorScheme.onBackground),
          ),
          onTap: () {
            drawerIndex = DrawerIndex.Licenses;
            getScreenView(drawerIndex);
            if (!_tray_open) {
              Navigator.pop(context);
            }
          },
        ),
        ListTile(
            leading: const Icon(Icons.cookie),
            title: const Text(
              'Cookie Consent Preferences',
            ),
            onTap: () {
              js.context.callMethod('displayPreferenceModal');
            }),
        const Divider(
          height: 20,
          thickness: 1,
          color: Colors.grey,
        ),
        ListTile(
          leading: Switch(
              value: widget.isDarkTheme(),
              onChanged: (value) {
                widget.setDarkTheme(value);
              }),
        ),
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
          screenView = Scaffold(
              body: Stack(children: [
            WalletHomeScreen(
              title: "Wallet",
              getWallet: widget.getWallet,
              setWallet: widget.setWallet,
              onActivation: linkWallet,
            ),
            if (_showContinueButton)
              Positioned(
                bottom: isDesktopResolution(context) ? 100 : 50,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton.extended(
                    label: const Text('Continue to "My APIs"'),
                    onPressed: (() {
                      gtag(
                          command: "event",
                          target: "AssetsScreenShownFromWalletContinue",
                          parameters: {"walletIsLinked": _walletIsLinked});
                      setState(() {
                        this.drawerIndex = DrawerIndex.Assets;
                        screenView = getScreenView(DrawerIndex.Assets);
                        _showContinueButton = false;
                      });
                    }),
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
            key: const Key("My APIs"), // Key used to force State rebuild
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
