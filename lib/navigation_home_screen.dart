import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali/wallet/xrpl_wallet.dart';
import 'package:http/http.dart';
import 'package:dhali/app_theme.dart';
import 'package:dhali/marketplace/marketplace_home_screen.dart';
import 'package:flutter/material.dart';

import 'package:dhali/wallet/home_screen.dart';
import 'package:url_launcher/url_launcher.dart';

enum DrawerIndex {
  Wallet,
  Assets,
  Marketplace,
  Licenses,
}

class NavigationHomeScreen extends StatefulWidget {
  const NavigationHomeScreen(
      {this.drawerIndex,
      required this.getWallet,
      required this.setWallet,
      required this.getRequest,
      required this.firestore});

  final BaseRequest Function(String method, String path) getRequest;
  final FirebaseFirestore firestore;

  final DrawerIndex? drawerIndex;
  final XRPLWallet? Function() getWallet;
  final void Function(XRPLWallet) setWallet;

  @override
  _NavigationHomeScreenState createState() =>
      _NavigationHomeScreenState(drawerIndex);
}

class _NavigationHomeScreenState extends State<NavigationHomeScreen> {
  _NavigationHomeScreenState(this.drawerIndex);
  Widget? screenView;
  DrawerIndex? drawerIndex;

  @override
  void initState() {
    drawerIndex == Null ? DrawerIndex.Marketplace : drawerIndex;
    screenView = getScreenView(drawerIndex);
    super.initState();
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
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                  ),
                  child: Container(
                    height: 100, // Or any other height that suits your design
                    child: FittedBox(
                      child: Image.asset('assets/images/dhali-logo.png'),
                      fit: BoxFit.contain,
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
          screenView = WalletHomeScreen(
            title: "wallet",
            getWallet: widget.getWallet,
            setWallet: widget.setWallet,
          );
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
          screenView = LicensePage();
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
