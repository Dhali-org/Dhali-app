import 'dart:convert';
import 'dart:io';
import 'package:dhali/wallet/xrpl_wallet.dart';
import 'package:http/http.dart';
import 'package:dhali/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dhali/navigation_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dhali/firebase_options.dart';
import 'package:dhali/config.dart' show Config;
import 'package:flutter/services.dart' show rootBundle;

import 'package:dhali/marketplace/asset_page.dart';
import 'package:dhali/marketplace/model/marketplace_list_data.dart';

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Config.loadConfig('assets/public.json');

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

MultipartRequest Function(String method, String path) getRequestFunction =
    (String method, String path) {
  return MultipartRequest(method, Uri.parse(path));
};

void main() async {
  await initializeApp();
  runApp(MyApp(getRequest: getRequestFunction));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.getRequest});

  final BaseRequest Function(String method, String path) getRequest;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  XRPLWallet? _wallet;

  @override
  Widget build(BuildContext context) {
    const title = "Dhali";
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness:
          !kIsWeb && Platform.isAndroid ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == null) {
          return null;
        }
        List<String> pathList = settings.name!.split("/");
        if (pathList.length == 3 && pathList[1] == "assets") {
          Widget asset;
          if (settings.arguments != null &&
              settings.arguments.runtimeType == AssetPage) {
            asset = settings.arguments as AssetPage;
          } else {
            Future<DocumentSnapshot<Map<String, dynamic>>> futureElement =
                FirebaseFirestore.instance
                    .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"])
                    .doc(pathList[2])
                    .get();
            asset = FutureBuilder(
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                      snapshot) {
                if (!snapshot.hasData) {
                  return const Text("Asset not found");
                }
                MarketplaceListData element = MarketplaceListData(
                    assetID: pathList[2],
                    assetName: snapshot.data![Config
                        .config!["MINTED_NFTS_DOCUMENT_KEYS"]["ASSET_NAME"]],
                    assetCategories: snapshot.data![Config
                        .config!["MINTED_NFTS_DOCUMENT_KEYS"]["CATEGORY"]],
                    averageRuntime: snapshot.data![
                        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
                            ["AVERAGE_INFERENCE_TIME_MS"]],
                    numberOfSuccessfullRequests: snapshot.data![
                        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
                            ["NUMBER_OF_SUCCESSFUL_REQUESTS"]],
                    pricePerRun: snapshot.data![Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EXPECTED_INFERENCE_COST_PER_MS"]]);
                return AssetPage(
                  asset: element,
                  getRequest: widget.getRequest,
                  getWallet: getWallet,
                );
              },
              future: futureElement,
            );
          }

          return MaterialPageRoute(
              builder: (context) => asset,
              settings: RouteSettings(name: settings.name));
        }
      },
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: AppTheme.textTheme,
        platform: TargetPlatform.iOS,
      ),
      home: NavigationHomeScreen(
        getWallet: getWallet,
        setWallet: setWallet,
        firestore: FirebaseFirestore.instance,
        getRequest: widget.getRequest,
      ),
    );
  }

  XRPLWallet? getWallet() {
    return _wallet;
  }

  void setWallet(XRPLWallet wallet) {
    setState(() {
      _wallet = wallet;
    });
  }
}

class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }
}
