import 'dart:io';
import 'package:dhali_wallet/dhali_wallet.dart';
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

import 'package:dhali/marketplace/asset_page.dart';
import 'package:dhali/marketplace/model/marketplace_list_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

BaseRequest getRequest<T extends BaseRequest>(String method, String path) {
  if (T == MultipartRequest) {
    return MultipartRequest(method, Uri.parse(path)) as T;
  } else if (T == Request) {
    return Request(method, Uri.parse(path)) as T;
  }
  throw ArgumentError('Unsupported request type: $T');
}

void main() async {
  await initializeApp();
  runApp(const MyApp(getRequest: getRequest));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.getRequest});

  final BaseRequest Function<T extends BaseRequest>(String method, String path)
      getRequest;

  @override
  State<MyApp> createState() => _MyAppState();
}

class HomeWithBanner extends StatelessWidget {
  final Widget child;

  const HomeWithBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          bottom: 0.0,
          left: 0.0,
          right: 0.0,
          child: Container(
            color: const Color.fromARGB(255, 248, 149, 36),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: Text(
                      "Warning!  This is a preview, and uses the XRPL testnet.  Please only use testnet wallets.  Created assets may not persist!",
                      style: TextStyle(),
                      textAlign: TextAlign.center)),
            ),
          ),
        ),
      ],
    );
  }
}

class _MyAppState extends State<MyApp> {
  _MyAppState();

  DhaliWallet? _wallet;

  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SharedPreferences.getInstance().then((value) {
        final themeString = value.getString('theme');
        if (themeString != null && themeString == "dark") {
          setDarkTheme(true);
        } else {
          setDarkTheme(false);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    const title = "Dhali Marketplace";
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness:
          !kIsWeb && Platform.isAndroid ? Brightness.dark : Brightness.light,
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
                    // Do not show "Asset not found" immediately. Instead, wait
                    // a couple of seconds to see if one actually is present
                    return FutureBuilder(
                      builder: (BuildContext context,
                          AsyncSnapshot<dynamic> snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return const Text("Asset not found");
                      },
                      future: Future.delayed(const Duration(seconds: 2)),
                    );
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
                      pricePerRun: snapshot.data![Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EXPECTED_INFERENCE_COST"]]);
                  return AssetPage(
                    asset: element,
                    getFirestore: () => FirebaseFirestore.instance,
                    getRequest: widget.getRequest,
                    getWallet: getWallet,
                  );
                },
                future: futureElement,
              );
            }

            return MaterialPageRoute(
                builder: (context) => asset, settings: settings);
          }

          final Uri uri = Uri.parse(settings.name!);
          final Map<String, String> queryParams = uri.queryParameters;
          return MaterialPageRoute(
              settings: settings,
              builder: (context) => getHomeScreen(queryParams: queryParams));
        },
        title: title,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          platform: TargetPlatform.iOS,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.dhali_blue,
            brightness: _isDark ? Brightness.dark : Brightness.light,
          ),
        ),
        home: getHomeScreen());
  }

  Widget getHomeScreen({Map<String, String>? queryParams}) {
    return HomeWithBanner(
      child: NavigationHomeScreen(
          setDarkTheme: setDarkTheme,
          isDarkTheme: isDarkTheme,
          getWallet: getWallet,
          setWallet: setWallet,
          firestore: FirebaseFirestore.instance,
          getRequest: widget.getRequest,
          queryParams: queryParams),
    );
  }

  DhaliWallet? getWallet() {
    return _wallet;
  }

  void setDarkTheme(bool value) {
    setState(() {
      _isDark = value;
    });
    SharedPreferences.getInstance().then((pref) async {
      await pref
          .setString('theme', _isDark ? "dark" : "light")
          .then((address) async {});
    });
  }

  bool isDarkTheme() {
    return _isDark;
  }

  void setWallet(DhaliWallet? wallet) {
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
      hexColor = 'FF$hexColor';
    }
    return int.parse(hexColor, radix: 16);
  }
}
