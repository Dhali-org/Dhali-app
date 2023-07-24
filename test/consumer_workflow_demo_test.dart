import 'dart:convert';

import 'package:dhali/marketplace/asset_page.dart';
import 'package:dhali/marketplace/model/marketplace_list_data.dart';
import 'package:dhali_wallet/wallet_types.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:dhali/app_theme.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'image_deployment_demo_test.mocks.dart';

import 'package:dhali/config.dart' show Config;
import 'utils.dart' as utils;

const String theAssetName = "my name";
const String theOtherAssetName = "${theAssetName}diff";
const String theAssetID = "An asset ID";
const String theOtherAssetID = "${theAssetID}diff";
const String NFTokenID = "An asset NFT ID";
const String anotherNFTokenID = "${NFTokenID}diff";
const String creatorAccount = "A random classic address";
const String dhaliAccount = "${creatorAccount}diff";
const double inferenceTime = 1.0;
const List<String> categories = ["A category"];
const double cost = 1000000;
const numSuccessfulRequests = 10.0;
const endpointUrl = "a random url";

void expectedInputUploadDialog() {
  expect(find.text("Choose input file"), findsOneWidget);
  expect(find.text("Next"), findsOneWidget);
  expect(find.text("Drag or select your input file"), findsOneWidget);
  expect(find.byIcon(Icons.cloud_upload_rounded), findsOneWidget);
  expect(find.byIcon(Icons.help_outline_outlined), findsNWidgets(2));
  expect(find.byType(DropzoneView), findsOneWidget);
}

Future<void> imageConsumptionDemo(WidgetTester tester) async {
  expect(find.text(theAssetName), findsOneWidget);
  expect(find.text(theOtherAssetName), findsNothing);
  expect(find.byKey(const Key("asset_circular_spinner")), findsOneWidget);
  expect(find.byKey(const Key("categories_in_asset_page")), findsOneWidget);
  expect(find.text("Run"), findsOneWidget);
  await tester.pump();
  expect(find.byKey(const Key("asset_page_readme")), findsOneWidget);
  expect(find.byKey(const Key("asset_circular_spinner")), findsNothing);
  await tester.tap(find.text("Run"));
  await tester.pump();
  expect(find.text("Unable to proceed"), findsNothing);
  expect(find.text("Please link a wallet using the Wallet page"), findsNothing);

  expectedInputUploadDialog();
  await tester.tap(find.text("Next"));
  await tester.pump();
  expectedInputUploadDialog(); // Ensure that Next is not active until file selected

  await tester.tap(find.text("Choose input file"));
  await tester.pumpAndSettle();
  expect(find.text("Selected input file: test.tar"), findsOneWidget);
  await tester.tap(find.text("Next"));
  await tester.pumpAndSettle();
  expect(find.text("Running this asset typically costs 1.0000 XRP"),
      findsOneWidget);
  expect(find.text("Are you sure you want to continue?"), findsOneWidget);
  expect(find.text("Yes"), findsOneWidget);
  expect(find.text("No"), findsOneWidget);
}

@GenerateMocks([MultipartRequest, XRPLWallet])
void main() async {
  late FakeFirebaseFirestore firebaseMockInstance;
  TestWidgetsFlutterBinding.ensureInitialized();
  Config.config = jsonDecode(utils.publicConfig);

  late MockXRPLWallet mockWallet;

  setUpAll(() {
    mockWallet = MockXRPLWallet();
    firebaseMockInstance = FakeFirebaseFirestore();

    when(mockWallet.balance).thenReturn(ValueNotifier("1000000"));
    when(mockWallet.address).thenReturn("a-random-address");
    when(mockWallet.sendDrops("9000000", "CHANNEL_ID_STRING"))
        .thenReturn("a-random-signature");
    when(mockWallet.acceptOffer("0")).thenAnswer((_) async {
      return Future.value(true);
    });
    when(mockWallet.mnemonic).thenReturn("memorable words");
    when(mockWallet.getOpenPaymentChannels(
            destination_address: "rstbSTpPcyxMsiXwkBxS9tFTrg2JsDNxWk"))
        .thenAnswer((_) async {
      return Future.value(
          [PaymentChannelDescriptor("CHANNEL_ID_STRING", 10000000)]);
    });
    when(mockWallet.preparePayment(
            destinationAddress: "rstbSTpPcyxMsiXwkBxS9tFTrg2JsDNxWk",
            authAmount: anyNamed("authAmount"),
            channelDescriptor: anyNamed("channelDescriptor")))
        .thenAnswer((_) {
      return Future.value({"key": "value"});
    });
  });

  group('Asset consumption journeys', () {
    testWidgets('Successful run', (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      int responseCode = 200;

      await firebaseMockInstance
          .collection("public_minted_nfts")
          .doc(theAssetID)
          .set({"average_inference_time_ms": 1000});
      var docId = const Uuid().v5(Uuid.NAMESPACE_URL, "CHANNEL_ID_STRING");
      await firebaseMockInstance
          .collection("public_claim_info")
          .doc(docId)
          .set({"to_claim": 0});

      MockMultipartRequest getMockMultipartRequest(String _, String path) {
        var mockRunRequester = MockMultipartRequest();
        when(mockRunRequester.send()).thenAnswer(
            (_) async => StreamedResponse(const Stream.empty(), responseCode));
        when(mockRunRequester.headers).thenAnswer((_) => {});

        return mockRunRequester;
      }

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
        home: AssetPage(
          getReadme: (path) => Future.value(Response("# A markdown", 200)),
          getFirestore: () => firebaseMockInstance,
          asset: MarketplaceListData(
              assetID: theAssetID,
              assetName: theAssetName,
              assetCategories: categories,
              averageRuntime: inferenceTime,
              numberOfSuccessfullRequests: numSuccessfulRequests,
              pricePerRun: cost),
          getRequest: getMockMultipartRequest,
          getWallet: () => mockWallet,
        ),
      ));

      await imageConsumptionDemo(tester);

      await tester.tap(find.text("Yes"));
      await tester.pump();
      expect(find.byKey(const Key("download_file")), findsNothing);

      await tester.pump();

      expect(
          find.text("Uploading 'test.tar: "
              "file 1 of 1'."
              "\nPlease wait."),
          findsOneWidget);
      await tester.pump();
      expect(find.byKey(const Key("download_file")), findsOneWidget);
      expect(find.text("Download result"), findsOneWidget);
      expect(find.text("Exit"), findsOneWidget);
      await tester.tap(find.text("Exit"));
      await tester.pumpAndSettle();
      expect(find.byType(AssetPage), findsOneWidget);
    });

    testWidgets('Unsuccessful run', (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      int responseCode = 723948239;

      await firebaseMockInstance
          .collection("public_minted_nfts")
          .doc(theAssetID)
          .set({"average_inference_time_ms": 1000});
      var docId = const Uuid().v5(Uuid.NAMESPACE_URL, "CHANNEL_ID_STRING");
      await firebaseMockInstance
          .collection("public_claim_info")
          .doc(docId)
          .set({"to_claim": 0});

      String reasonPhrase = "you are useless";

      MockMultipartRequest getMockMultipartRequest(String _, String path) {
        var mockRunRequester = MockMultipartRequest();
        when(mockRunRequester.send()).thenAnswer((_) async => StreamedResponse(
              Stream.value(utf8.encode('{"detail": "$reasonPhrase"}')),
              responseCode,
            ));
        when(mockRunRequester.headers).thenAnswer((_) => {});

        return mockRunRequester;
      }

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
        home: AssetPage(
          getReadme: (path) => Future.value(Response("# A markdown", 200)),
          getFirestore: () => firebaseMockInstance,
          asset: MarketplaceListData(
              assetID: theAssetID,
              assetName: theAssetName,
              assetCategories: categories,
              averageRuntime: inferenceTime,
              numberOfSuccessfullRequests: numSuccessfulRequests,
              pricePerRun: cost),
          getRequest: getMockMultipartRequest,
          getWallet: () => mockWallet,
        ),
      ));

      await imageConsumptionDemo(tester);

      await tester.tap(find.text("Yes"));
      await tester.pump();
      expect(find.byKey(const Key("download_file")), findsNothing);

      await tester.pump();

      expect(
          find.text("Uploading 'test.tar: "
              "file 1 of 1'."
              "\nPlease wait."),
          findsOneWidget);
      await tester.pump();
      expect(
          find.text("Upload failed"
              "\nStatus code: ${responseCode.toString()}"
              "\nReason: $reasonPhrase"),
          findsOneWidget);
    });

    testWidgets('Wallet unavailable', (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      int responseCode = 200;
      MockMultipartRequest getMockMultipartRequest(String _, String path) {
        var mockRunRequester = MockMultipartRequest();
        when(mockRunRequester.send()).thenAnswer(
            (_) async => StreamedResponse(const Stream.empty(), responseCode));
        when(mockRunRequester.headers).thenAnswer((_) => {});

        return mockRunRequester;
      }

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
        home: AssetPage(
          getReadme: (path) => Future.value(Response("# A markdown", 200)),
          getFirestore: () => firebaseMockInstance,
          asset: MarketplaceListData(
              assetID: theAssetID,
              assetName: theAssetName,
              assetCategories: categories,
              averageRuntime: inferenceTime,
              numberOfSuccessfullRequests: numSuccessfulRequests,
              pricePerRun: cost),
          getRequest: getMockMultipartRequest,
          getWallet: () => null,
        ),
      ));

      await tester.tap(find.text("Run"));
      await tester.pump();
      expect(find.text("Unable to proceed"), findsOneWidget);
      expect(find.text("Please link a wallet using the Wallet page"),
          findsOneWidget);
    });
  });
}
