import 'dart:io';
import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:dhali_wallet/xumm_wallet.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

WebSocketChannel getWebSocketChannel(String uuid) {
  String url = Config.config!["ROOT_API_ADMIN_URL"];
  return WebSocketChannel.connect(Uri.parse("$url/$uuid/update"));
}

BaseRequest getRequest<T extends BaseRequest>(String method, String path) {
  if (T == MultipartRequest) {
    return MultipartRequest(method, Uri.parse(path)) as T;
  } else if (T == Request) {
    return Request(method, Uri.parse(path)) as T;
  }
  throw ArgumentError('Unsupported request type: $T');
}

Function(String, String) getQRCodeToBeScanned(
    BuildContext context, DhaliWallet wallet) {
  void qRCodeToBeScanned(String qrUrl, String deepLink) {
    displayQRCodeFrom("Verify your identity", context, {
      "refs": {"qr_png": qrUrl},
      "next": {"always": deepLink}
    });
  }

  return qRCodeToBeScanned;
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

class HomeWithBanner extends StatefulWidget {
  const HomeWithBanner({super.key, required this.childBuilder});
  final Widget Function() childBuilder;

  @override
  State<HomeWithBanner> createState() => _HomeWithBannerState();
}

class _HomeWithBannerState extends State<HomeWithBanner> {
  bool displayBanner = true;
  late final Widget child; // Declare a final variable for the child widget

  @override
  void initState() {
    super.initState();
    child =
        widget.childBuilder(); // Initialize the child widget once in initState
  }

  @override
  Widget build(BuildContext context) {
    // Use the already initialized child widget in the build method
    return Stack(
      children: [
        child,
        if (displayBanner) // Use the 'if' inside the children list for conditionally displaying the banner
          MaterialBanner(
            padding: const EdgeInsets.all(20),
            content: const Text(
              "This is a preview. Please only use testnet wallets.",
              style: TextStyle(fontSize: 18),
            ),
            leading: const Icon(Icons.warning),
            backgroundColor: const Color.fromARGB(255, 255, 146, 22),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  setState(() {
                    displayBanner = false;
                  });
                },
                child: const Text('DISMISS'),
              ),
            ],
          ),
      ],
    );
  }
}

class _MyAppState extends State<MyApp> {
  _MyAppState();

  DhaliWallet? _wallet;

  bool _isDark = false;

  Widget? _child;

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

                  return AssetPage(
                    getFirestore: () => FirebaseFirestore.instance,
                    uuid: snapshot.data!.id,
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

  Widget getChild() {
    return _child!;
  }

  Widget getHomeScreen({Map<String, String>? queryParams}) {
    _child = NavigationHomeScreen(
        getDisplayQRCodeFrom: getQRCodeToBeScanned,
        getWebSocketChannel: getWebSocketChannel,
        setDarkTheme: setDarkTheme,
        isDarkTheme: isDarkTheme,
        getWallet: getWallet,
        setWallet: setWallet,
        firestore: FirebaseFirestore.instance,
        getRequest: widget.getRequest,
        queryParams: queryParams);

    return HomeWithBanner(
      childBuilder: getChild,
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
