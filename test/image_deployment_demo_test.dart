import 'dart:convert';

import 'package:dhali/marketplace/marketplace_home_screen.dart';
import 'package:dhali/marketplace/marketplace_dialogs.dart';
import 'package:dhali_wallet/wallet_types.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:dhali/app_theme.dart';
import 'package:dhali/navigation_home_screen.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'image_deployment_demo_test.mocks.dart';

import 'package:dhali/config.dart' show Config;
import 'utils.dart' as utils;

const String theInputAssetName = "a_badl3y_n@med-asset";
const String theAssetName = "abadl3ynmed-asset";
const String theDhaliAssetID = "a-session-id";

Future<void> selectAssets(
    WidgetTester tester,
    MockMultipartRequest mockRequester,
    FakeFirebaseFirestore mockFirebaseFirestore) async {
  expect(find.text("Choose .tar file"), findsOneWidget);
  expect(find.text("Choose .md file"), findsOneWidget);
  expect(find.byKey(const Key("DropZoneDeployNext")), findsOneWidget);
  expect(find.text("Drag or select your files"), findsOneWidget);
  expect(find.text("No .tar docker image asset selected"), findsOneWidget);
  expect(find.text("No .md asset description selected"), findsOneWidget);
  expect(find.byIcon(Icons.cloud_upload_rounded), findsOneWidget);
  expect(find.byIcon(Icons.help_outline_outlined), findsNWidgets(2));
  expect(find.byType(DropzoneView), findsOneWidget);

  await tester.tap(find.byType(DropzoneView));
  await tester.pumpAndSettle();

  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key("choose_docker_image_button")));

  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key("choose_readme_button")));

  await tester.pumpAndSettle();
}

Future<void> displayCosts(
    WidgetTester tester,
    MockMultipartRequest mockRequester,
    FakeFirebaseFirestore mockFirebaseFirestore) async {
  expect(
      find.text("Here is a break down of the asset's costs:"), findsOneWidget);
  expect(find.text("Paid by you:"), findsOneWidget);
  expect(find.text("Paid by the user of your asset:"), findsOneWidget);

  expect(find.text("What?"), findsNWidgets(2));
  expect(find.text("When?"), findsNWidgets(2));
  expect(find.text("Cost: XRP"), findsNWidgets(1));
  expect(find.text("Cost:"), findsNWidgets(1));
  expect(find.text("If you continue, the above costs will be applied."),
      findsOneWidget);
  expect(find.text("301%"), findsOneWidget);
  expect(find.text("20%"), findsOneWidget);
  expect(find.text("421%"), findsOneWidget); // 100 + 301 + 20
  expect(find.text("Are you sure you want to deploy?"), findsOneWidget);
  expect(find.text("Yes"), findsOneWidget);
  expect(find.byKey(const Key("DeploymentCostWidgetBack")), findsOneWidget);
}

Future<void> setEarnings(
    WidgetTester tester,
    MockMultipartRequest mockRequester,
    FakeFirebaseFirestore mockFirebaseFirestore) async {
  expect(find.text("Set your earning rate per inference."), findsOneWidget);
  expect(find.text("\nKeep this small to encourage usage.\n"), findsOneWidget);
  expect(
      find.text(
          "Example: If running your asset costs Dhali \$1 in compute costs per inference, by setting 20 below you will earn \$0.20 per inference."),
      findsOneWidget);

  await tester.enterText(find.byKey(const Key("percentage_earnings_input")),
      "a_badl3y_f0rmatted_Str1ng");
  await tester.pumpAndSettle();
  expect(find.text("301"), findsOneWidget);
}

void imageDeploymentDemo(
    WidgetTester tester,
    MockMultipartRequest mockRequester,
    FakeFirebaseFirestore mockFirebaseFirestore,
    int responseCode) async {
  await utils.dragOutDrawer(tester);

  await tester.tap(find.text("My APIs"));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Monetise my API', skipOffstage: false));
  await tester.pumpAndSettle();

  expect(find.text("What will your asset be called?"), findsOneWidget);
  expect(find.text("Step 1 of 4"), findsOneWidget);

  await tester.tap(find.text("Asset name"));
  expect(
      find.text("Enter the name you'd like for your asset "
          "(a-z, 0-9, -, .)"),
      findsOneWidget);
  await tester.enterText(
      find.byKey(const Key("asset_name_input_field")), theInputAssetName);
  await tester.pumpAndSettle(const Duration(seconds: 5));
  expect(find.text(theAssetName), findsOneWidget);
  await tester.tap(find.byKey(const Key("AssetNameNext")));
  await tester.pumpAndSettle();

  expect(find.text("Step 2 of 4"), findsOneWidget);
  await setEarnings(tester, mockRequester, mockFirebaseFirestore);

  await tester.tap(find.byKey(const Key("ImageCostNext")));
  await tester.pumpAndSettle();

  expect(find.text("Step 3 of 4"), findsOneWidget);
  await selectAssets(tester, mockRequester, mockFirebaseFirestore);

  await tester.tap(find.byKey(const Key("DropZoneDeployNext")));
  await tester.pumpAndSettle(const Duration(seconds: 4));

  expect(find.text("Step 3 of 4"), findsNWidgets(2));
  expect(find.text("Your image was successfully scanned."), findsOneWidget);

  await tester.tap(find.byKey(const Key("ImageScanningNext")));
  await tester.pumpAndSettle();

  expect(find.text("Step 4 of 4"), findsOneWidget);
  await displayCosts(tester, mockRequester, mockFirebaseFirestore);

  await tester.tap(find.text("Yes"));

  await tester
      .pump(); // First pump releases the Future from `mockWallet.getOpenPaymentChannels`
  await tester.pump(); // Second pump releases the Future.value to FutureBuilder
  expect(find.byKey(const Key("deploying_in_progress_dialog")), findsOneWidget);
  expect(find.text("Cancel"), findsOneWidget);

  if (responseCode == 200) {
    await tester.pump();
    expect(find.byKey(const Key("minting_nft_spinner")), findsOneWidget);
    await mockFirebaseFirestore
        .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"])
        .doc(theDhaliAssetID)
        .set({
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
          ["NUMBER_OF_SUCCESSFUL_REQUESTS"]: 0,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
          ["EXPECTED_INFERENCE_COST_PER_MS"]: 20,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["AVERAGE_INFERENCE_TIME_MS"]:
          20,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ASSET_CREATOR_ACCOUNT"]:
          "some_test_address",
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["CATEGORY"]: [
        "some_category"
      ],
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ASSET_NAME"]: theAssetName,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ENDPOINT_URL"]:
          "some_asset_url",
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["NFTOKEN_ID"]:
          "some_NFToken_id",
    });
    await tester.pump();

    expect(find.byKey(const Key("minting_nft_spinner")), findsNothing);
    expect(find.byKey(const Key("upload_success_info")), findsOneWidget);
    expect(find.byKey(const Key("upload_failed_warning")), findsNothing);
  } else {
    await tester.pump();
    expect(find.byKey(const Key("deploying_in_progress_dialog")), findsNothing);
    expect(find.byKey(const Key("upload_success_info")), findsNothing);
    expect(find.byKey(const Key("upload_failed_warning")), findsOneWidget);
  }
  await tester.tap(find.byKey(const Key("exit_deployment_dialogs")));
  await tester.pump();
  expect(find.byType(DataTransmissionWidget), findsNothing);
  expect(find.byType(MarketplaceHomeScreen), findsOneWidget);
}

@GenerateMocks([MultipartRequest, XRPLWallet])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Config.config = jsonDecode(utils.publicConfig);

  late FakeFirebaseFirestore firebaseMockInstance;
  late MockXRPLWallet mockWallet;
  late MockMultipartRequest mockRequester;

  setUpAll(() {
    mockWallet = MockXRPLWallet();
    mockRequester = MockMultipartRequest();
    firebaseMockInstance = FakeFirebaseFirestore();

    const String theAssetName = "abadl3ynmed-asset";
    when(mockWallet.balance).thenReturn(ValueNotifier("1000000"));
    when(mockWallet.address).thenReturn("a-random-address");
    when(mockWallet.mnemonic).thenReturn("memorable words");
    when(mockWallet.sendDrops("9000000", "CHANNEL_ID_STRING"))
        .thenReturn("a-random-signature");
    when(mockWallet.acceptOffer("0")).thenAnswer((_) async {
      return Future.value(true);
    });
    when(mockWallet.getNFTOffers("some_NFToken_id")).thenAnswer((_) async {
      return Future.value(
          // TODO: Make a more realistic offer, inject XRPL client and confirm it fails
          //      for a nonzero amount, and passes for zero amount
          [NFTOffer(0, "an_owner_account", "a_destination_account", "0")]);
    });
    when(mockWallet.getOpenPaymentChannels(
            destination_address: "rstbSTpPcyxMsiXwkBxS9tFTrg2JsDNxWk"))
        .thenAnswer((_) async {
      return Future.value(
          [PaymentChannelDescriptor("CHANNEL_ID_STRING", 10000000)]);
    });
    when(mockWallet.getAvailableNFTs()).thenAnswer((_) async {
      return Future.value({
        "id": 0,
        "result": {
          "account": "a-random-address",
          "account_nfts": [],
          "ledger_current_index": 36554056,
          "validated": false
        },
        "type": "response"
      });
    });
    when(mockWallet.preparePayment(
            destinationAddress: "rstbSTpPcyxMsiXwkBxS9tFTrg2JsDNxWk",
            authAmount: "12000",
            channelDescriptor: anyNamed("channelDescriptor")))
        .thenAnswer((_) {
      return Future.value({"key": "value"});
    });
  });

  group('Image deployment journeys', () {
    testWidgets('Bad payment in header', (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      int responseCode = 402;

      when(mockRequester.send()).thenAnswer((_) async => StreamedResponse(
              const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockRequester.headers).thenAnswer((_) => {});
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

      imageDeploymentDemo(
          tester, mockRequester, FakeFirebaseFirestore(), responseCode);
    });
    testWidgets('Successful image deployment', (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      var mockRequester = MockMultipartRequest();
      int responseCode = 200;

      when(mockRequester.send()).thenAnswer((_) async => StreamedResponse(
              const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockRequester.headers).thenAnswer((_) => {});
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

      imageDeploymentDemo(
          tester, mockRequester, firebaseMockInstance, responseCode);
    });

    testWidgets('Select self hosted journey deployment',
        (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      var mockRequester = MockMultipartRequest();
      int responseCode = 200;

      when(mockRequester.send()).thenAnswer((_) async => StreamedResponse(
              const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockRequester.headers).thenAnswer((_) => {});
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

      await tester.tap(find.text("My APIs"));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Monetise my API', skipOffstage: false));
      await tester.pumpAndSettle();

      expect(find.text("What will your asset be called?"), findsOneWidget);
      expect(find.text("Step 1 of 4"), findsOneWidget);

      await tester.tap(find.text("Asset name"));
      expect(
          find.text("Enter the name you'd like for your asset "
              "(a-z, 0-9, -, .)"),
          findsOneWidget);
      await tester.enterText(
          find.byKey(const Key("asset_name_input_field")), theInputAssetName);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text(theAssetName), findsOneWidget);
      await tester.tap(find.byKey(const Key("self_hosted-radio_button")));
      await tester.tap(find.byKey(const Key("AssetNameNext")));
      await tester.pumpAndSettle();

      expect(find.text("Self hosting is unavailable."), findsOneWidget);
    });

    testWidgets('Cancel image deployment', (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      var mockRequester = MockMultipartRequest();
      int responseCode = 200;

      when(mockRequester.send()).thenAnswer((_) async => StreamedResponse(
              const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockRequester.headers).thenAnswer((_) => {});
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

      await utils.dragOutDrawer(tester);

      await tester.tap(find.text("My APIs"));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Monetise my API', skipOffstage: false));
      await tester.pumpAndSettle();

      expect(find.text("What will your asset be called?"), findsOneWidget);

      await tester.tap(find.text("Asset name"));
      expect(
          find.text("Enter the name you'd like for your asset "
              "(a-z, 0-9, -, .)"),
          findsOneWidget);
      await tester.enterText(
          find.byKey(const Key("asset_name_input_field")), theInputAssetName);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text(theAssetName), findsOneWidget);
      await tester.tap(find.byKey(const Key("AssetNameNext")));
      await tester.pumpAndSettle();
      await setEarnings(tester, mockRequester, firebaseMockInstance);

      await tester.tap(find.byKey(const Key("ImageCostNext")));
      await tester.pumpAndSettle();

      await selectAssets(tester, mockRequester, firebaseMockInstance);

      await tester.tap(find.byKey(const Key("DropZoneDeployNext")));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(find.text("Your image was successfully scanned."), findsOneWidget);

      await tester.tap(find.byKey(const Key("ImageScanningNext")));
      await tester.pumpAndSettle();

      await displayCosts(tester, mockRequester, firebaseMockInstance);

      await tester.tap(find.text("Yes"));

      await tester
          .pump(); // First pump releases the Future from `mockWallet.getOpenPaymentChannels`
      await tester
          .pump(); // Second pump releases the Future.value to FutureBuilder
      expect(find.byKey(const Key("deploying_in_progress_dialog")),
          findsOneWidget);
      expect(find.text("Cancel"), findsOneWidget);
      await tester.tap(find.text("Cancel"));
      await tester.pump();
      expect(find.byKey(const Key("minting_nft_spinner")), findsNothing);
    });
  });
}
