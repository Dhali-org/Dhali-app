import 'dart:js' as js;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali_wallet/dhali_wallet_widget.dart';
import 'package:http/http.dart';
import 'package:dhali/app_theme.dart';
import 'package:dhali/marketplace/marketplace_home_screen.dart';
import 'package:flutter/material.dart';

import 'package:dhali_wallet/dhali_wallet.dart';

import 'package:url_launcher/url_launcher.dart';

enum DrawerIndex {
  Wallet,
  Assets,
  Marketplace,
  Licenses,
}

class NavigationHomeScreen extends StatefulWidget {
  const NavigationHomeScreen(
      {super.key, this.drawerIndex,
      required this.getWallet,
      required this.setWallet,
      required this.getRequest,
      required this.firestore});

  final BaseRequest Function(String method, String path) getRequest;
  final FirebaseFirestore firestore;

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

  @override
  void initState() {
    drawerIndex == Null ? DrawerIndex.Marketplace : drawerIndex;
    screenView = getScreenView(drawerIndex);
    super.initState();
  }

  void activateWallet() {
    setState(() {
      _showContinueButton = true;
      screenView = getScreenView(DrawerIndex.Wallet);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.white,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppTheme.white,
            foregroundColor: AppTheme.nearlyBlack,
          ),
          drawer: Drawer(
            backgroundColor: AppTheme.white,
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: AppTheme.white,
                  ),
                  child: SizedBox(
                    height: 100, // Or any other height that suits your design
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Image.asset('assets/images/dhali-logo.png'),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.wallet, color: AppTheme.dhali_blue),
                  title: const Text('Wallet',
                      style: TextStyle(color: AppTheme.nearlyBlack)),
                  onTap: () {
                    getScreenView(DrawerIndex.Wallet);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.token, color: AppTheme.dhali_blue),
                  title: const Text('My assets',
                      style: TextStyle(color: AppTheme.nearlyBlack)),
                  onTap: () {
                    getScreenView(DrawerIndex.Assets);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shop, color: AppTheme.dhali_blue),
                  title: const Text('Marketplace',
                      style: TextStyle(color: AppTheme.nearlyBlack)),
                  onTap: () {
                    getScreenView(DrawerIndex.Marketplace);
                    Navigator.pop(context);
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
                  onTap: _launchUrl,
                ),
                ListTile(
                  leading: const Icon(Icons.badge, color: AppTheme.dhali_blue),
                  title: const Text('Licenses',
                      style: TextStyle(color: AppTheme.nearlyBlack)),
                  onTap: () {
                    getScreenView(DrawerIndex.Licenses);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                    leading:
                        const Icon(Icons.cookie, color: AppTheme.dhali_blue),
                    title: const Text('Cookie Consent Preferences',
                        style: TextStyle(color: AppTheme.nearlyBlack)),
                    onTap: () {
                      js.context.callMethod('displayPreferenceModal');
                    }),
              ],
            ),
          ),
          backgroundColor: AppTheme.nearlyBlack,
          drawerEdgeDragWidth: 0,
          body: screenView,
        ),
      ),
    );
  }

  Future<void> _launchUrl() async {
    if (!await launchUrl(Uri.parse("https://dhali.io/docs/#/"))) {
      throw Exception('Could not launch https://dhali.io/docs/#/');
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
    switch (drawerIndex) {
      case DrawerIndex.Wallet:
        setState(() {
          SnackBar snackbar;
          snackbar = const SnackBar(
            backgroundColor: Colors.red,
            content:
                Text("Dhali is currently in alpha and uses test XRP only!"),
            duration: Duration(days: 1),
          );

          Future(() => ScaffoldMessenger.of(context).showSnackBar(snackbar));
          if (_showContinueButton) {}
          screenView = Scaffold(
              body: Stack(children: [
            WalletHomeScreen(
              title: "wallet",
              getWallet: widget.getWallet,
              setWallet: widget.setWallet,
              appBarColor: AppTheme.dhali_blue,
              bodyTextColor: Colors.black,
              buttonsColor: AppTheme.dhali_blue,
              onActivation: activateWallet,
            ),
            if (_showContinueButton)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton.extended(
                    label: const Text('Continue to assets page'),
                    onPressed: (() {
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
          ]));
        });
        break;
      case DrawerIndex.Assets:
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
