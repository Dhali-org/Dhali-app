import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:dhali/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dhali/navigation_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:dhali/config.dart' show Config;
import 'package:flutter/services.dart' show rootBundle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Config.loadConfig();
  var entryPointUrlRoot =
      const String.fromEnvironment('ENTRY_POINT_URL_ROOT', defaultValue: '');
  if (entryPointUrlRoot == '') {
    entryPointUrlRoot = Config.config!["ROOT_DEPLOY_URL"];
  }
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]).then((_) => runApp(MyApp(getMintingRequest: (String path) {
        String url = "$entryPointUrlRoot/$path/";
        return MultipartRequest("POST", Uri.parse(url));
      })));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.getMintingRequest});

  final BaseRequest Function(String path) getMintingRequest;

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
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: AppTheme.textTheme,
        platform: TargetPlatform.iOS,
      ),
      home: NavigationHomeScreen(
        firestore: FirebaseFirestore.instance,
        getMintingRequest: getMintingRequest,
      ),
    );
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
