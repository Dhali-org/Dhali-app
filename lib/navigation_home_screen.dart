import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali/wallet/xrpl_wallet.dart';
import 'package:http/http.dart';
import 'package:dhali/app_theme.dart';
import 'package:dhali/marketplace/marketplace_home_screen.dart';
import 'package:flutter/material.dart';

import 'wallet/home_screen.dart';

enum DrawerIndex {
  Wallet,
  Assets,
  Marketplace,
  Licenses,
}

class NavigationHomeScreen extends StatefulWidget {
  const NavigationHomeScreen(
      {this.drawerIndex,
      this.wallet,
      required this.getRequest,
      required this.firestore});

  final BaseRequest Function(String method, String path) getRequest;
  final FirebaseFirestore firestore;

  final DrawerIndex? drawerIndex;
  final XRPLWallet? wallet;

  @override
  _NavigationHomeScreenState createState() =>
      _NavigationHomeScreenState(drawerIndex, wallet);
}

class _NavigationHomeScreenState extends State<NavigationHomeScreen> {
  _NavigationHomeScreenState(this.drawerIndex, this._wallet);
  Widget? screenView;
  DrawerIndex? drawerIndex;
  XRPLWallet? _wallet;

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
                const DrawerHeader(
                  decoration: BoxDecoration(
                    color: AppTheme.dark_grey,
                  ),
                  child: Text(
                    'Dhali',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.wallet),
                  title: const Text('Wallet'),
                  onTap: () {
                    getScreenView(DrawerIndex.Wallet);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.token),
                  title: const Text('My assets'),
                  onTap: () {
                    getScreenView(DrawerIndex.Assets);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shop),
                  title: const Text('Marketplace'),
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
                  leading: const Icon(Icons.book),
                  title: const Text('Licenses'),
                  onTap: () {
                    getScreenView(DrawerIndex.Licenses);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          //backgroundColor: AppTheme.nearlyWhite,
          backgroundColor: AppTheme.nearlyBlack,
          drawerEdgeDragWidth: 0,
          body: screenView,
        ),
      ),
    );
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
        getWallet: getWallet,
        setWallet: setWallet,
        getFirestore: getFirestore);
    switch (drawerIndex) {
      case DrawerIndex.Wallet:
        setState(() {
          screenView = WalletHomeScreen(
            title: "wallet",
            getWallet: getWallet,
            setWallet: setWallet,
          );
        });
        break;
      case DrawerIndex.Assets:
        setState(() {
          screenView = MarketplaceHomeScreen(
            key: const Key("My Assets"), // Key used to force State rebuild
            getRequest: widget.getRequest,
            assetScreenType: AssetScreenType.MyAssets,
            getWallet: getWallet,
            setWallet: setWallet,
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
              getWallet: getWallet,
              setWallet: setWallet,
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

  XRPLWallet? getWallet() {
    return this._wallet;
  }

  void setWallet(XRPLWallet wallet) {
    setState(() {
      this._wallet = wallet;
    });
  }
}
