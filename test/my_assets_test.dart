import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dhali/app_theme.dart';
import 'package:dhali/navigation_home_screen.dart';
import 'package:mockito/mockito.dart';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import './image_deployment_demo_test.mocks.dart';

import 'package:dhali/config.dart' show Config;
import 'utils.dart' as utils;

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Config.config = jsonDecode(utils.publicConfig);

  late FakeFirebaseFirestore firebaseMockInstance;
  late MockXRPLWallet mockWallet;
  late MockMultipartRequest mockRequester;

  const String theAssetName = "my name";
  const String theOtherAssetName = "${theAssetName}diff";
  const String theAssetID = "An asset ID";
  const String theOtherAssetID = "${theAssetID}diff";
  const String NFTokenID = "An asset NFT ID";
  const String anotherNFTokenID = "${NFTokenID}diff";
  const String creatorAccount = "A random classic address";
  const String dhaliAccount = "${creatorAccount}diff";
  const int inferenceTime = 1;
  const List<String> categories = ["A category"];
  const int cost = 1;
  const numSuccessfulRequests = 10;
  const endpointUrl = "a random url";

  setUpAll(() {
    mockWallet = MockXRPLWallet();
    mockRequester = MockMultipartRequest();
    firebaseMockInstance = FakeFirebaseFirestore();

    firebaseMockInstance
        .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"])
        .doc(theAssetID)
        .set({
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
          ["NUMBER_OF_SUCCESSFUL_REQUESTS"]: numSuccessfulRequests,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ASSET_CREATOR_ACCOUNT"]:
          creatorAccount,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["AVERAGE_INFERENCE_TIME_MS"]:
          inferenceTime,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["CATEGORY"]: categories,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ENDPOINT_URL"]: endpointUrl,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
          ["EXPECTED_INFERENCE_COST_PER_MS"]: cost,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ASSET_NAME"]: theAssetName,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["NFTOKEN_ID"]: NFTokenID
    });

    firebaseMockInstance
        .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"])
        .doc(theOtherAssetID)
        .set({
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
          ["NUMBER_OF_SUCCESSFUL_REQUESTS"]: numSuccessfulRequests,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ASSET_CREATOR_ACCOUNT"]:
          creatorAccount,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["AVERAGE_INFERENCE_TIME_MS"]:
          inferenceTime,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["CATEGORY"]: categories,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ENDPOINT_URL"]: endpointUrl,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
          ["EXPECTED_INFERENCE_COST_PER_MS"]: cost,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ASSET_NAME"]:
          theOtherAssetName,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["NFTOKEN_ID"]:
          anotherNFTokenID
    });

    when(mockWallet.balance).thenReturn(ValueNotifier("1000000"));
    when(mockWallet.mnemonic).thenReturn("memorable words");
    when(mockWallet.getAvailableNFTs()).thenAnswer((_) async {
      return Future.value({
        "id": 0,
        "result": {
          "account": creatorAccount,
          "account_nfts": [
            {
              "Flags": 8,
              "Issuer": dhaliAccount,
              "NFTokenID": NFTokenID,
              "NFTokenTaxon": 0,
              "TransferFee": 500,
              "URI": "A random uri string",
              "nft_serial": 93
            }
          ],
          "ledger_current_index": 36554056,
          "validated": false
        },
        "type": "response"
      });
    });
  });

  group('My assets', () {
    testWidgets('Only my asset visible', (WidgetTester tester) async {
      const w = 1480;
      const h = 1080;

      when(mockWallet.address).thenReturn(creatorAccount);

      final dpi = tester.binding.window.devicePixelRatio;
      tester.binding.window.physicalSizeTestValue = Size(w * dpi, h * dpi);

      await tester.pumpWidget(MaterialApp(
        title: "Dhali",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: AppTheme.textTheme,
          platform: TargetPlatform.iOS,
        ),
        home: NavigationHomeScreen(
            firestore: firebaseMockInstance,
            getWallet: () => mockWallet,
            setWallet: (wallet) => {},
            getRequest: (String method, String path) => mockRequester),
      ));

      await tester.pumpAndSettle();

      await utils.dragOutDrawer(tester);
      await tester.tap(find.text("My assets"));
      await tester.pump();
      expect(find.byKey(const Key("loading_asset_key")), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("loading_asset_key")), findsNothing);
      expect(find.byKey(const Key("my_asset_not_found")), findsNothing);
      expect(find.text(theOtherAssetName), findsNothing);
      expect(find.text(theAssetName), findsOneWidget);
    });

    testWidgets('10 or more assets visible', (WidgetTester tester) async {
      const w = 1480;
      const h = 1080;

      when(mockWallet.address).thenReturn(creatorAccount);

      var accountNFTs = [];
      const int numAssets = 35;
      for (int i = 0; i < numAssets; ++i) {
        final currentNFTokenID = "$NFTokenID-$i";
        accountNFTs.add({
          "Flags": 8,
          "Issuer": dhaliAccount,
          "NFTokenID": currentNFTokenID,
          "NFTokenTaxon": 0,
          "TransferFee": 500,
          "URI": "A random uri string",
          "nft_serial": 93
        });

        firebaseMockInstance
            .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"])
            .doc(currentNFTokenID)
            .set({
          Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
              ["NUMBER_OF_SUCCESSFUL_REQUESTS"]: numSuccessfulRequests,
          Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ASSET_CREATOR_ACCOUNT"]:
              creatorAccount,
          Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
              ["AVERAGE_INFERENCE_TIME_MS"]: inferenceTime,
          Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["CATEGORY"]: categories,
          Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ENDPOINT_URL"]:
              endpointUrl,
          Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
              ["EXPECTED_INFERENCE_COST_PER_MS"]: cost,
          Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ASSET_NAME"]:
              "$theAssetName-$i",
          Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["NFTOKEN_ID"]:
              currentNFTokenID
        });
      }

      when(mockWallet.getAvailableNFTs()).thenAnswer((_) async {
        return Future.value({
          "id": 0,
          "result": {
            "account": creatorAccount,
            "account_nfts": accountNFTs,
            "ledger_current_index": 36554056,
            "validated": false
          },
          "type": "response"
        });
      });

      final dpi = tester.binding.window.devicePixelRatio;
      tester.binding.window.physicalSizeTestValue = Size(w * dpi, h * dpi);

      await tester.pumpWidget(MaterialApp(
        title: "Dhali",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: AppTheme.textTheme,
          platform: TargetPlatform.iOS,
        ),
        home: NavigationHomeScreen(
            firestore: firebaseMockInstance,
            getWallet: () => mockWallet,
            setWallet: (wallet) => {},
            getRequest: (String method, String path) => mockRequester),
      ));

      await tester.pumpAndSettle();

      await utils.dragOutDrawer(tester);
      await tester.tap(find.text("My assets"));
      await tester.pump();
      expect(find.byKey(const Key("loading_asset_key")), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("loading_asset_key")), findsNothing);
      expect(find.byKey(const Key("my_asset_not_found")), findsNothing);

      for (int i = 0; i < 15; ++i) {
        expect(find.text("$theAssetName-$i"), findsOneWidget);
      }
      await tester.drag(
          find.byKey(const Key('asset_grid_view')), const Offset(0.0, -1000));
      await tester.pump();
      for (int i = 15; i < 32; ++i) {
        expect(
          find.text("$theAssetName-$i"),
          findsOneWidget,
        );
      }
      await tester.drag(
          find.byKey(const Key('asset_grid_view')), const Offset(0.0, -200));
      await tester.pump();
      for (int i = 32; i < numAssets; ++i) {
        expect(
          find.text("$theAssetName-$i"),
          findsOneWidget,
        );
      }
    });

    testWidgets('No assets visible', (WidgetTester tester) async {
      const w = 1480;
      const h = 1080;

      when(mockWallet.getAvailableNFTs()).thenAnswer((_) async {
        return Future.value({
          "id": 0,
          "result": {
            "account": creatorAccount,
            "account_nfts": [],
            "ledger_current_index": 36554056,
            "validated": false
          },
          "type": "response"
        });
      });

      final dpi = tester.binding.window.devicePixelRatio;
      tester.binding.window.physicalSizeTestValue = Size(w * dpi, h * dpi);

      await tester.pumpWidget(MaterialApp(
        title: "Dhali",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: AppTheme.textTheme,
          platform: TargetPlatform.iOS,
        ),
        home: NavigationHomeScreen(
            firestore: firebaseMockInstance,
            getWallet: () => mockWallet,
            setWallet: (wallet) => {},
            getRequest: (String method, String path) => mockRequester),
      ));

      await tester.pumpAndSettle();

      await utils.dragOutDrawer(tester);
      await tester.tap(find.text("My assets"));
      await tester.pump();
      expect(find.byKey(const Key("loading_asset_key")), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("loading_asset_key")), findsNothing);
      expect(find.text(theOtherAssetName), findsNothing);
      expect(find.text(theAssetName), findsNothing);
      expect(find.byKey(const Key("my_asset_not_found")), findsOneWidget);
    });

    testWidgets('Assets in ledger, but not firebase',
        (WidgetTester tester) async {
      const w = 1480;
      const h = 1080;

      const someOtherNFTkokenID = "this_is_not_in_firebase";

      when(mockWallet.address).thenReturn(creatorAccount);
      when(mockWallet.getAvailableNFTs()).thenAnswer((_) async {
        return Future.value({
          "id": 0,
          "result": {
            "account": creatorAccount,
            "account_nfts": [
              {
                "Flags": 8,
                "Issuer": dhaliAccount,
                "NFTokenID": someOtherNFTkokenID,
                "NFTokenTaxon": 0,
                "TransferFee": 500,
                "URI": "A random uri string",
                "nft_serial": 93
              }
            ],
            "ledger_current_index": 36554056,
            "validated": false
          },
          "type": "response"
        });
      });

      final dpi = tester.binding.window.devicePixelRatio;
      tester.binding.window.physicalSizeTestValue = Size(w * dpi, h * dpi);

      await tester.pumpWidget(MaterialApp(
        title: "Dhali",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: AppTheme.textTheme,
          platform: TargetPlatform.iOS,
        ),
        home: NavigationHomeScreen(
            firestore: firebaseMockInstance,
            getWallet: () => mockWallet,
            setWallet: (wallet) => {},
            getRequest: (String method, String path) => mockRequester),
      ));

      await tester.pumpAndSettle();

      await utils.dragOutDrawer(tester);
      await tester.tap(find.text("My assets"));
      await tester.pump();
      expect(find.byKey(const Key("loading_asset_key")), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("loading_asset_key")), findsNothing);
      expect(find.text(theOtherAssetName), findsNothing);
      expect(find.text(theAssetName), findsNothing);
      // Do not test for 'my_asset_not_found' key here, since we can't determine
      // this from the stream in the implementation.
    });
  });
}
