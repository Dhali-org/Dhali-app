import 'dart:async';
import 'dart:convert';

import 'package:dhali/marketplace/api_admin_journey.dart';
import 'package:dhali/marketplace/marketplace_dialogs.dart';
import 'package:dhali/marketplace/model/asset_model.dart';
import 'package:dhali_wallet/wallet_types.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:dhali/app_theme.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_administration_demo_test.mocks.dart';

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
const double earnings = 10102;
const double paidOut = 10101;
const numSuccessfulRequests = 10.0;
const endpointUrl = "a random url";

class MockDisplayQrAuth extends Mock {
  void call(String qrUrl, String deepLink);
}

@GenerateMocks([MultipartRequest, XRPLWallet, WebSocketChannel, Stream])
void main() async {
  late FakeFirebaseFirestore firebaseMockInstance;
  TestWidgetsFlutterBinding.ensureInitialized();
  Config.config = jsonDecode(utils.publicConfig);

  late MockXRPLWallet mockWallet;
  late MockWebSocketChannel mockChannel;
  late MockStream mockStream;
  late StreamController<dynamic> streamController;
  late MockDisplayQrAuth mockDisplayQrAuth;
  late MockWebSocketSink webSocketSink;
  late GlobalKey<ScaffoldState> scaffoldKey;

  setUp(() {
    scaffoldKey = GlobalKey<ScaffoldState>();
    mockDisplayQrAuth = MockDisplayQrAuth();
    mockChannel = MockWebSocketChannel();
    mockStream = MockStream();
    streamController = StreamController<dynamic>();

    webSocketSink = MockWebSocketSink();
    when(mockChannel.sink).thenReturn(webSocketSink);
    when(mockChannel.stream).thenAnswer((_) => streamController.stream);
    when(mockChannel.ready).thenAnswer((_) => Future.delayed(Duration.zero));

    mockWallet = MockXRPLWallet();
    firebaseMockInstance = FakeFirebaseFirestore();

    when(mockWallet.balance).thenReturn(ValueNotifier("1000000"));
    when(mockWallet.address).thenReturn("a-random-address");
    when(mockWallet.sendDrops("9000000", "CHANNEL_ID_STRING"))
        .thenReturn("a-random-signature");
    when(mockWallet.acceptOffer("0", context: null)).thenAnswer((_) async {
      return Future.value(true);
    });
    when(mockWallet.mnemonic).thenReturn("memorable words");
    when(mockWallet.getOpenPaymentChannels(
            destination_address: "rhtfMhppuk5siMi8jvkencnCTyjciArCh7"))
        .thenAnswer((_) async {
      return Future.value(
          [PaymentChannelDescriptor("CHANNEL_ID_STRING", 10000000)]);
    });
    when(mockWallet.preparePayment(
            context: null,
            destinationAddress: "rhtfMhppuk5siMi8jvkencnCTyjciArCh7",
            authAmount: anyNamed("authAmount"),
            channelDescriptor: anyNamed("channelDescriptor")))
        .thenAnswer((_) {
      return Future.value({"key": "value"});
    });
  });

  group('Successful asset administration', () {
    testWidgets('Docs not selected', (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      int responseCode = 200;

      firebaseMockInstance
          .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"])
          .doc(theAssetID)
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
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EXPECTED_INFERENCE_COST"]:
            cost,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ASSET_NAME"]: theAssetName,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["NFTOKEN_ID"]: NFTokenID,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EARNING_RATE"]: 31415926,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EARNING_TYPE"]:
            "per_request"
      });

      T getMockMultipartRequest<T extends BaseRequest>(String _, String path) {
        var mockRunRequester = MockMultipartRequest();
        when(mockRunRequester.send()).thenAnswer(
            (_) async => StreamedResponse(const Stream.empty(), responseCode));
        when(mockRunRequester.headers).thenAnswer((_) => {});

        return mockRunRequester as T;
      }

      final dpi = tester.binding.window.devicePixelRatio;
      tester.binding.window.physicalSizeTestValue = Size(w * dpi, h * dpi);

      String apiUuid = theAssetID;
      String? apiName;
      double? currentEarningRate;
      ChargingChoice? chargingChoice;
      String? baseUrl;
      Map<String, String>? currentHeaders;
      AssetModel? readme;

      await tester.pumpWidget(MaterialApp(
          title: "Dhali",
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: AppTheme.textTheme,
            platform: TargetPlatform.iOS,
          ),
          home: Scaffold(
            key: scaffoldKey,
            body: Builder(builder: (context) {
              return Center(
                child: TextButton(
                  child: const Text("BUTTON"),
                  onPressed: () async {
                    administrateEntireAPI(
                        context: context,
                        displayQrAuth: (qrUrl, deepLink) =>
                            {mockDisplayQrAuth(qrUrl, deepLink)},
                        getWebSocketChannel: (_) => mockChannel,
                        getApiUuid: () => apiUuid,
                        getDb: () => firebaseMockInstance,
                        getApiHeaders: () => currentHeaders,
                        getBaseUrl: () => baseUrl,
                        getApiName: () => apiName,
                        getEarningRate: () => currentEarningRate,
                        getEarningType: () => chargingChoice,
                        getDocs: () => readme,
                        setApiHeaders: (headers) => {currentHeaders = headers},
                        setBaseUrl: (url) => {baseUrl = url},
                        setApiName: (name) => {apiName = name},
                        setEarningRate: (earningRate) =>
                            {currentEarningRate = earningRate},
                        setEarningType: (earningType) =>
                            {chargingChoice = earningType},
                        setDocs: (doc) => {readme = doc});
                  },
                ),
              );
            }),
          )));

      expect(find.text("BUTTON"), findsOneWidget);
      await tester.tap(find.text("BUTTON"));

      // Trigger the API Admin Client
      streamController.add({
        "schema": "api_admin_gateway_prefill_response",
        "pre_fill_data": {
          "base_url": "a-cool-url",
          "headers": [
            {"some-random-key-1": "its-value-1"},
            {"another-ace-key": "super-val"},
          ]
        }
      });

      await tester.pumpAndSettle();

      // Verify all of the api properties are prefilled correctly
      expect(apiName, theAssetName);
      expect(currentEarningRate, 31.415926);
      expect(chargingChoice, ChargingChoice.perRequest);
      expect(currentHeaders,
          {"some-random-key-1": "its-value-1", "another-ace-key": "super-val"});
      expect(baseUrl, "a-cool-url");

      // Dialog 1
      expect(find.text("Step 1 of 5"), findsOneWidget);
      await tester.enterText(find.byKey(const Key("asset_name_input_field")),
          "a-weird-new-and-cool-name");
      await tester.pumpAndSettle();
      expect(find.text("a-weird-new-and-cool-name"), findsOneWidget);
      await tester.tap(find.byKey(const Key("AssetNameNext")));
      await tester.pumpAndSettle();

      expect(apiName,
          "a-weird-new-and-cool-name"); // The apiName variable should have changed

      // Dialog 2
      expect(find.text("Step 2 of 5"), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key("percentage_earnings_input")), "302");
      await tester.tap(find.byKey(const Key('Per second')));
      await tester.tap(find.byKey(const Key("ImageCostNext")));
      await tester.pumpAndSettle();

      expect(currentEarningRate,
          302); // The currentEarningRate should have changed
      expect(
          chargingChoice,
          ChargingChoice
              .perSecond); // The currentEarningRate should have changed

      // Dialog 3
      expect(find.text("Step 3 of 5"), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key("api_base_url")), "some-strange-new-url");
      await tester.enterText(
          find.byKey(const Key('Key 1')), "a-header-that-will-be-used");
      await tester.enterText(
          find.byKey(const Key('Value 1')), "a-value-that-will-be-used");
      await tester.tap(find.byIcon(Icons.remove));
      await tester.tap(find.byKey(const Key("APICredentialsNext")));
      await tester.pumpAndSettle();

      expect(currentHeaders,
          {"a-header-that-will-be-used": "a-value-that-will-be-used"});
      expect(baseUrl, "some-strange-new-url");

      // Dialog 4
      expect(find.text("Step 4 of 5"), findsOneWidget);
      await tester.tap(find.byKey(const Key("ReadmeDocsSkip")));
      await tester.pumpAndSettle();
      expect(readme, null);

      // Dialog 5
      expect(find.text("Step 5 of 5"), findsOneWidget);
      expect(find.text("Would you like to continue?"), findsOneWidget);
      expect(
          find.text("You are about to update the following:"), findsOneWidget);
      expect(find.text("API name: a-weird-new-and-cool-name"), findsOneWidget);
      expect(find.text("Base URL: some-strange-new-url"), findsOneWidget);
      expect(find.text("Headers: $currentHeaders"), findsOneWidget);
      expect(find.text("Earnings: 302 XRP perSecond"), findsOneWidget);
      expect(find.text("Docs: test.tar"), findsNothing);

      await tester.tap(find.byKey(const Key("AreYouSureYes")));

      await tester.pump();
      expect(find.byKey(const Key("showWaitingOnFutureDialogSpinner")),
          findsOneWidget);
      Map<String, dynamic> message = {
        "schema": "api_admin_gateway_update_request",
        "schema_version": "1.0",
        "updates": {
          "api_credentials": {
            "url": "some-strange-new-url",
            "a-header-that-will-be-used": "a-value-that-will-be-used"
          },
          "name": "a-weird-new-and-cool-name",
          "asset_earning_rate": 302000000,
          "asset_earning_type": "per_second",
        }
      };
      await tester.pump();
      verify(webSocketSink.add(jsonEncode(message))).called(1);
      streamController.add({
        "schema": "api_admin_gateway_update_response",
        "successful_updates": [],
        "failed_updates": []
      });
      await tester.pump();
      expect(find.byKey(const Key("showWaitingOnFutureDialogSpinner")),
          findsNothing);
      expect(find.text("Your updates were successful"), findsOneWidget);
      expect(find.text("The following updates were successful:"), findsNothing);
      expect(find.text("The following updates failed:"), findsNothing);
      await tester.tap(find.text("OK"));
      await tester.pump();
      expect(find.text("Your updates were successful"), findsNothing);
    });

    testWidgets('Docs selected', (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      int responseCode = 200;

      firebaseMockInstance
          .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"])
          .doc(theAssetID)
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
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EXPECTED_INFERENCE_COST"]:
            cost,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ASSET_NAME"]: theAssetName,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["NFTOKEN_ID"]: NFTokenID,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EARNING_RATE"]: 31415926,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EARNING_TYPE"]:
            "per_request"
      });

      T getMockMultipartRequest<T extends BaseRequest>(String _, String path) {
        var mockRunRequester = MockMultipartRequest();
        when(mockRunRequester.send()).thenAnswer(
            (_) async => StreamedResponse(const Stream.empty(), responseCode));
        when(mockRunRequester.headers).thenAnswer((_) => {});

        return mockRunRequester as T;
      }

      final dpi = tester.binding.window.devicePixelRatio;
      tester.binding.window.physicalSizeTestValue = Size(w * dpi, h * dpi);

      String apiUuid = theAssetID;
      String? apiName;
      double? currentEarningRate;
      ChargingChoice? chargingChoice;
      String? baseUrl;
      Map<String, String>? currentHeaders;
      AssetModel? readme;

      await tester.pumpWidget(MaterialApp(
          title: "Dhali",
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: AppTheme.textTheme,
            platform: TargetPlatform.iOS,
          ),
          home: Scaffold(
            key: scaffoldKey,
            body: Builder(builder: (context) {
              return Center(
                child: TextButton(
                  child: const Text("BUTTON"),
                  onPressed: () async {
                    administrateEntireAPI(
                        context: context,
                        displayQrAuth: (qrUrl, deepLink) =>
                            {mockDisplayQrAuth(qrUrl, deepLink)},
                        getWebSocketChannel: (_) => mockChannel,
                        getApiUuid: () => apiUuid,
                        getDb: () => firebaseMockInstance,
                        getApiHeaders: () => currentHeaders,
                        getBaseUrl: () => baseUrl,
                        getApiName: () => apiName,
                        getEarningRate: () => currentEarningRate,
                        getEarningType: () => chargingChoice,
                        getDocs: () => readme,
                        setApiHeaders: (headers) => {currentHeaders = headers},
                        setBaseUrl: (url) => {baseUrl = url},
                        setApiName: (name) => {apiName = name},
                        setEarningRate: (earningRate) =>
                            {currentEarningRate = earningRate},
                        setEarningType: (earningType) =>
                            {chargingChoice = earningType},
                        setDocs: (doc) => {readme = doc});
                  },
                ),
              );
            }),
          )));

      expect(find.text("BUTTON"), findsOneWidget);
      await tester.tap(find.text("BUTTON"));

      // Trigger the API Admin Client
      streamController.add({
        "schema": "api_admin_gateway_prefill_response",
        "pre_fill_data": {
          "base_url": "a-cool-url",
          "headers": [
            {"some-random-key-1": "its-value-1"},
            {"another-ace-key": "super-val"},
          ]
        }
      });

      await tester.pumpAndSettle();

      // Verify all of the api properties are prefilled correctly
      expect(apiName, theAssetName);
      expect(currentEarningRate, 31.415926);
      expect(chargingChoice, ChargingChoice.perRequest);
      expect(currentHeaders,
          {"some-random-key-1": "its-value-1", "another-ace-key": "super-val"});
      expect(baseUrl, "a-cool-url");

      // Dialog 1
      expect(find.text("Step 1 of 5"), findsOneWidget);
      await tester.enterText(find.byKey(const Key("asset_name_input_field")),
          "a-weird-new-and-cool-name");
      await tester.pumpAndSettle();
      expect(find.text("a-weird-new-and-cool-name"), findsOneWidget);
      await tester.tap(find.byKey(const Key("AssetNameNext")));
      await tester.pumpAndSettle();

      expect(apiName,
          "a-weird-new-and-cool-name"); // The apiName variable should have changed

      // Dialog 2
      expect(find.text("Step 2 of 5"), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key("percentage_earnings_input")), "302");
      await tester.tap(find.byKey(const Key('Per second')));
      await tester.tap(find.byKey(const Key("ImageCostNext")));
      await tester.pumpAndSettle();

      expect(currentEarningRate,
          302); // The currentEarningRate should have changed
      expect(
          chargingChoice,
          ChargingChoice
              .perSecond); // The currentEarningRate should have changed

      // Dialog 3
      expect(find.text("Step 3 of 5"), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key("api_base_url")), "some-strange-new-url");
      await tester.enterText(
          find.byKey(const Key('Key 1')), "a-header-that-will-be-used");
      await tester.enterText(
          find.byKey(const Key('Value 1')), "a-value-that-will-be-used");
      await tester.tap(find.byIcon(Icons.remove));
      await tester.tap(find.byKey(const Key("APICredentialsNext")));
      await tester.pumpAndSettle();

      expect(currentHeaders,
          {"a-header-that-will-be-used": "a-value-that-will-be-used"});
      expect(baseUrl, "some-strange-new-url");

      // Dialog 4
      expect(find.text("Step 4 of 5"), findsOneWidget);
      await tester.tap(find.text("Select"));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("ReadmeDocsNext")));
      await tester.pumpAndSettle();

      // expect(readme!.fileName, "test.tar");

      // Dialog 5
      expect(find.text("Step 5 of 5"), findsOneWidget);
      expect(find.text("Would you like to continue?"), findsOneWidget);
      expect(
          find.text("You are about to update the following:"), findsOneWidget);
      expect(find.text("API name: a-weird-new-and-cool-name"), findsOneWidget);
      expect(find.text("Base URL: some-strange-new-url"), findsOneWidget);
      expect(find.text("Headers: $currentHeaders"), findsOneWidget);
      expect(find.text("Earnings: 302 XRP perSecond"), findsOneWidget);
      expect(find.text("Docs: test.tar"), findsOneWidget);

      expect(find.byKey(const Key("AreYouSureYes")), findsOneWidget);
    });
  });

  tearDown(() {
    reset(mockDisplayQrAuth);
    reset(mockChannel);
    reset(mockStream);
    reset(mockWallet);
    resetMockitoState(); // Resets all mocks if you're using multiple
  });

  group('Failed asset administration', () {
    testWidgets('Some updates fail', (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      int responseCode = 200;

      firebaseMockInstance
          .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"])
          .doc(theAssetID)
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
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EXPECTED_INFERENCE_COST"]:
            cost,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ASSET_NAME"]: theAssetName,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["NFTOKEN_ID"]: NFTokenID,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EARNING_RATE"]: 31415926,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EARNING_TYPE"]:
            "per_request"
      });

      T getMockMultipartRequest<T extends BaseRequest>(String _, String path) {
        var mockRunRequester = MockMultipartRequest();
        when(mockRunRequester.send()).thenAnswer(
            (_) async => StreamedResponse(const Stream.empty(), responseCode));
        when(mockRunRequester.headers).thenAnswer((_) => {});

        return mockRunRequester as T;
      }

      final dpi = tester.binding.window.devicePixelRatio;
      tester.binding.window.physicalSizeTestValue = Size(w * dpi, h * dpi);

      String apiUuid = theAssetID;
      String? apiName;
      double? currentEarningRate;
      ChargingChoice? chargingChoice;
      String? baseUrl;
      Map<String, String>? currentHeaders;
      AssetModel? readme;

      await tester.pumpWidget(MaterialApp(
          title: "Dhali",
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: AppTheme.textTheme,
            platform: TargetPlatform.iOS,
          ),
          home: Scaffold(
            key: scaffoldKey,
            body: Builder(builder: (context) {
              return Center(
                child: TextButton(
                  child: const Text("BUTTON"),
                  onPressed: () async {
                    administrateEntireAPI(
                        context: context,
                        displayQrAuth: (qrUrl, deepLink) =>
                            {mockDisplayQrAuth(qrUrl, deepLink)},
                        getWebSocketChannel: (_) => mockChannel,
                        getApiUuid: () => apiUuid,
                        getDb: () => firebaseMockInstance,
                        getApiHeaders: () => currentHeaders,
                        getBaseUrl: () => baseUrl,
                        getApiName: () => apiName,
                        getEarningRate: () => currentEarningRate,
                        getEarningType: () => chargingChoice,
                        getDocs: () => readme,
                        setApiHeaders: (headers) => {currentHeaders = headers},
                        setBaseUrl: (url) => {baseUrl = url},
                        setApiName: (name) => {apiName = name},
                        setEarningRate: (earningRate) =>
                            {currentEarningRate = earningRate},
                        setEarningType: (earningType) =>
                            {chargingChoice = earningType},
                        setDocs: (doc) => {readme = doc});
                  },
                ),
              );
            }),
          )));

      expect(find.text("BUTTON"), findsOneWidget);
      await tester.tap(find.text("BUTTON"));

      // Trigger the API Admin Client
      streamController.add({
        "schema": "api_admin_gateway_prefill_response",
        "pre_fill_data": {
          "base_url": "a-cool-url",
          "headers": [
            {"some-random-key-1": "its-value-1"},
            {"another-ace-key": "super-val"},
          ]
        }
      });

      await tester.pumpAndSettle();

      // Verify all of the api properties are prefilled correctly
      expect(apiName, theAssetName);
      expect(currentEarningRate, 31.415926);
      expect(chargingChoice, ChargingChoice.perRequest);
      expect(currentHeaders,
          {"some-random-key-1": "its-value-1", "another-ace-key": "super-val"});
      expect(baseUrl, "a-cool-url");

      // Dialog 1
      expect(find.text("Step 1 of 5"), findsOneWidget);
      await tester.enterText(find.byKey(const Key("asset_name_input_field")),
          "a-weird-new-and-cool-name");
      await tester.pumpAndSettle();
      expect(find.text("a-weird-new-and-cool-name"), findsOneWidget);
      await tester.tap(find.byKey(const Key("AssetNameNext")));
      await tester.pumpAndSettle();

      expect(apiName,
          "a-weird-new-and-cool-name"); // The apiName variable should have changed

      // Dialog 2
      expect(find.text("Step 2 of 5"), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key("percentage_earnings_input")), "302");
      await tester.tap(find.byKey(const Key('Per second')));
      await tester.tap(find.byKey(const Key("ImageCostNext")));
      await tester.pumpAndSettle();

      expect(currentEarningRate,
          302); // The currentEarningRate should have changed
      expect(
          chargingChoice,
          ChargingChoice
              .perSecond); // The currentEarningRate should have changed

      // Dialog 3
      expect(find.text("Step 3 of 5"), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key("api_base_url")), "some-strange-new-url");
      await tester.enterText(
          find.byKey(const Key('Key 1')), "a-header-that-will-be-used");
      await tester.enterText(
          find.byKey(const Key('Value 1')), "a-value-that-will-be-used");
      await tester.tap(find.byIcon(Icons.remove));
      await tester.tap(find.byKey(const Key("APICredentialsNext")));
      await tester.pumpAndSettle();

      expect(currentHeaders,
          {"a-header-that-will-be-used": "a-value-that-will-be-used"});
      expect(baseUrl, "some-strange-new-url");

      // Dialog 4
      expect(find.text("Step 4 of 5"), findsOneWidget);
      await tester.tap(find.byKey(const Key("ReadmeDocsSkip")));
      await tester.pumpAndSettle();
      expect(readme, null);

      // Dialog 5
      expect(find.text("Step 5 of 5"), findsOneWidget);
      expect(find.text("Would you like to continue?"), findsOneWidget);
      expect(
          find.text("You are about to update the following:"), findsOneWidget);
      expect(find.text("API name: a-weird-new-and-cool-name"), findsOneWidget);
      expect(find.text("Base URL: some-strange-new-url"), findsOneWidget);
      expect(find.text("Headers: $currentHeaders"), findsOneWidget);
      expect(find.text("Earnings: 302 XRP perSecond"), findsOneWidget);
      expect(find.text("Docs: test.tar"), findsNothing);

      await tester.tap(find.byKey(const Key("AreYouSureYes")));

      await tester.pump();
      expect(find.byKey(const Key("showWaitingOnFutureDialogSpinner")),
          findsOneWidget);
      Map<String, dynamic> message = {
        "schema": "api_admin_gateway_update_request",
        "schema_version": "1.0",
        "updates": {
          "api_credentials": {
            "url": "some-strange-new-url",
            "a-header-that-will-be-used": "a-value-that-will-be-used"
          },
          "name": "a-weird-new-and-cool-name",
          "asset_earning_rate": 302000000,
          "asset_earning_type": "per_second",
        }
      };
      await tester.pump();
      verify(webSocketSink.add(jsonEncode(message))).called(1);
      streamController.add({
        "schema": "api_admin_gateway_update_response",
        "successful_updates": ["success-1", "success-2"],
        "failed_updates": ["failed-1", "failed-2"]
      });
      await tester.pump();
      expect(find.byKey(const Key("showWaitingOnFutureDialogSpinner")),
          findsNothing);
      expect(find.text("Your updates were successful"), findsNothing);
      expect(
          find.text("The following updates were successful:"), findsOneWidget);
      expect(find.text("The following updates failed:"), findsOneWidget);
      expect(find.text(jsonEncode(["success-1", "success-2"])), findsOneWidget);
      expect(find.text(jsonEncode(["failed-1", "failed-2"])), findsOneWidget);
      await tester.tap(find.text("OK"));
      await tester.pump();
      expect(find.text("Your updates were successful"), findsNothing);
    });

    testWidgets('Cancelled half way', (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      int responseCode = 200;

      firebaseMockInstance
          .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"])
          .doc(theAssetID)
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
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EXPECTED_INFERENCE_COST"]:
            cost,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ASSET_NAME"]: theAssetName,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["NFTOKEN_ID"]: NFTokenID,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EARNING_RATE"]: 31415926,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EARNING_TYPE"]:
            "per_request"
      });

      T getMockMultipartRequest<T extends BaseRequest>(String _, String path) {
        var mockRunRequester = MockMultipartRequest();
        when(mockRunRequester.send()).thenAnswer(
            (_) async => StreamedResponse(const Stream.empty(), responseCode));
        when(mockRunRequester.headers).thenAnswer((_) => {});

        return mockRunRequester as T;
      }

      final dpi = tester.binding.window.devicePixelRatio;
      tester.binding.window.physicalSizeTestValue = Size(w * dpi, h * dpi);

      String apiUuid = theAssetID;
      String? apiName;
      double? currentEarningRate;
      ChargingChoice? chargingChoice;
      String? baseUrl;
      Map<String, String>? currentHeaders;
      AssetModel? readme;

      await tester.pumpWidget(MaterialApp(
          title: "Dhali",
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: AppTheme.textTheme,
            platform: TargetPlatform.iOS,
          ),
          home: Scaffold(
            key: scaffoldKey,
            body: Builder(builder: (context) {
              return Center(
                child: TextButton(
                  child: const Text("BUTTON"),
                  onPressed: () async {
                    administrateEntireAPI(
                        context: context,
                        displayQrAuth: (qrUrl, deepLink) =>
                            {mockDisplayQrAuth(qrUrl, deepLink)},
                        getWebSocketChannel: (_) => mockChannel,
                        getApiUuid: () => apiUuid,
                        getDb: () => firebaseMockInstance,
                        getApiHeaders: () => currentHeaders,
                        getBaseUrl: () => baseUrl,
                        getApiName: () => apiName,
                        getEarningRate: () => currentEarningRate,
                        getEarningType: () => chargingChoice,
                        getDocs: () => readme,
                        setApiHeaders: (headers) => {currentHeaders = headers},
                        setBaseUrl: (url) => {baseUrl = url},
                        setApiName: (name) => {apiName = name},
                        setEarningRate: (earningRate) =>
                            {currentEarningRate = earningRate},
                        setEarningType: (earningType) =>
                            {chargingChoice = earningType},
                        setDocs: (doc) => {readme = doc});
                  },
                ),
              );
            }),
          )));

      expect(find.text("BUTTON"), findsOneWidget);
      await tester.tap(find.text("BUTTON"));

      // Trigger the API Admin Client
      streamController.add({
        "schema": "api_admin_gateway_prefill_response",
        "pre_fill_data": {
          "base_url": "a-cool-url",
          "headers": [
            {"some-random-key-1": "its-value-1"},
            {"another-ace-key": "super-val"},
          ]
        }
      });

      await tester.pumpAndSettle();

      // Verify all of the api properties are prefilled correctly
      expect(apiName, theAssetName);
      expect(currentEarningRate, 31.415926);
      expect(chargingChoice, ChargingChoice.perRequest);
      expect(currentHeaders,
          {"some-random-key-1": "its-value-1", "another-ace-key": "super-val"});
      expect(baseUrl, "a-cool-url");

      // Dialog 1
      expect(find.text("Step 1 of 5"), findsOneWidget);
      await tester.enterText(find.byKey(const Key("asset_name_input_field")),
          "a-weird-new-and-cool-name");
      await tester.pumpAndSettle();
      expect(find.text("a-weird-new-and-cool-name"), findsOneWidget);
      await tester.tap(find.byKey(const Key("AssetNameNext")));
      await tester.pumpAndSettle();

      expect(apiName,
          "a-weird-new-and-cool-name"); // The apiName variable should have changed

      // Dialog 2
      expect(find.text("Step 2 of 5"), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key("percentage_earnings_input")), "302");
      await tester.tap(find.byKey(const Key('Per second')));
      await tester.tap(find.byKey(const Key("ImageCostNext")));
      await tester.pumpAndSettle();

      expect(currentEarningRate,
          302); // The currentEarningRate should have changed
      expect(
          chargingChoice,
          ChargingChoice
              .perSecond); // The currentEarningRate should have changed

      // Dialog 3
      expect(find.text("Step 3 of 5"), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text("Step 3 of 5"), findsNothing);

      await tester.pumpAndSettle();
      verifyNever(webSocketSink.add(any));
    });

    testWidgets('Rejected at the end', (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      int responseCode = 200;

      firebaseMockInstance
          .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"])
          .doc(theAssetID)
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
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EXPECTED_INFERENCE_COST"]:
            cost,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["ASSET_NAME"]: theAssetName,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["NFTOKEN_ID"]: NFTokenID,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EARNING_RATE"]: 31415926,
        Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EARNING_TYPE"]:
            "per_request"
      });

      T getMockMultipartRequest<T extends BaseRequest>(String _, String path) {
        var mockRunRequester = MockMultipartRequest();
        when(mockRunRequester.send()).thenAnswer(
            (_) async => StreamedResponse(const Stream.empty(), responseCode));
        when(mockRunRequester.headers).thenAnswer((_) => {});

        return mockRunRequester as T;
      }

      final dpi = tester.binding.window.devicePixelRatio;
      tester.binding.window.physicalSizeTestValue = Size(w * dpi, h * dpi);

      String apiUuid = theAssetID;
      String? apiName;
      double? currentEarningRate;
      ChargingChoice? chargingChoice;
      String? baseUrl;
      Map<String, String>? currentHeaders;
      AssetModel? readme;

      await tester.pumpWidget(MaterialApp(
          title: "Dhali",
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: AppTheme.textTheme,
            platform: TargetPlatform.iOS,
          ),
          home: Scaffold(
            key: scaffoldKey,
            body: Builder(builder: (context) {
              return Center(
                child: TextButton(
                  child: const Text("BUTTON"),
                  onPressed: () async {
                    administrateEntireAPI(
                        context: context,
                        displayQrAuth: (qrUrl, deepLink) =>
                            {mockDisplayQrAuth(qrUrl, deepLink)},
                        getWebSocketChannel: (_) => mockChannel,
                        getApiUuid: () => apiUuid,
                        getDb: () => firebaseMockInstance,
                        getApiHeaders: () => currentHeaders,
                        getBaseUrl: () => baseUrl,
                        getApiName: () => apiName,
                        getEarningRate: () => currentEarningRate,
                        getEarningType: () => chargingChoice,
                        getDocs: () => readme,
                        setApiHeaders: (headers) => {currentHeaders = headers},
                        setBaseUrl: (url) => {baseUrl = url},
                        setApiName: (name) => {apiName = name},
                        setEarningRate: (earningRate) =>
                            {currentEarningRate = earningRate},
                        setEarningType: (earningType) =>
                            {chargingChoice = earningType},
                        setDocs: (doc) => {readme = doc});
                  },
                ),
              );
            }),
          )));

      expect(find.text("BUTTON"), findsOneWidget);
      await tester.tap(find.text("BUTTON"));

      // Trigger the API Admin Client
      streamController.add({
        "schema": "api_admin_gateway_prefill_response",
        "pre_fill_data": {
          "base_url": "a-cool-url",
          "headers": [
            {"some-random-key-1": "its-value-1"},
            {"another-ace-key": "super-val"},
          ]
        }
      });

      await tester.pumpAndSettle();

      // Verify all of the api properties are prefilled correctly
      expect(apiName, theAssetName);
      expect(currentEarningRate, 31.415926);
      expect(chargingChoice, ChargingChoice.perRequest);
      expect(currentHeaders,
          {"some-random-key-1": "its-value-1", "another-ace-key": "super-val"});
      expect(baseUrl, "a-cool-url");

      // Dialog 1
      expect(find.text("Step 1 of 5"), findsOneWidget);
      await tester.enterText(find.byKey(const Key("asset_name_input_field")),
          "a-weird-new-and-cool-name");
      await tester.pumpAndSettle();
      expect(find.text("a-weird-new-and-cool-name"), findsOneWidget);
      await tester.tap(find.byKey(const Key("AssetNameNext")));
      await tester.pumpAndSettle();

      expect(apiName,
          "a-weird-new-and-cool-name"); // The apiName variable should have changed

      // Dialog 2
      expect(find.text("Step 2 of 5"), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key("percentage_earnings_input")), "302");
      await tester.tap(find.byKey(const Key('Per second')));
      await tester.tap(find.byKey(const Key("ImageCostNext")));
      await tester.pumpAndSettle();

      expect(currentEarningRate,
          302); // The currentEarningRate should have changed
      expect(
          chargingChoice,
          ChargingChoice
              .perSecond); // The currentEarningRate should have changed

      // Dialog 3
      expect(find.text("Step 3 of 5"), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key("api_base_url")), "some-strange-new-url");
      await tester.enterText(
          find.byKey(const Key('Key 1')), "a-header-that-will-be-used");
      await tester.enterText(
          find.byKey(const Key('Value 1')), "a-value-that-will-be-used");
      await tester.tap(find.byIcon(Icons.remove));
      await tester.tap(find.byKey(const Key("APICredentialsNext")));
      await tester.pumpAndSettle();

      expect(currentHeaders,
          {"a-header-that-will-be-used": "a-value-that-will-be-used"});
      expect(baseUrl, "some-strange-new-url");

      // Dialog 4
      expect(find.text("Step 4 of 5"), findsOneWidget);
      await tester.tap(find.byKey(const Key("ReadmeDocsSkip")));
      await tester.pumpAndSettle();
      expect(readme, null);

      // Dialog 5
      expect(find.text("Step 5 of 5"), findsOneWidget);
      expect(find.text("Would you like to continue?"), findsOneWidget);
      expect(
          find.text("You are about to update the following:"), findsOneWidget);
      expect(find.text("API name: a-weird-new-and-cool-name"), findsOneWidget);
      expect(find.text("Base URL: some-strange-new-url"), findsOneWidget);
      expect(find.text("Headers: $currentHeaders"), findsOneWidget);
      expect(find.text("Earnings: 302 XRP perSecond"), findsOneWidget);
      expect(find.text("Docs: test.tar"), findsNothing);

      await tester.tap(find.byKey(const Key("AreYouSureNo")));

      await tester.pumpAndSettle();
      verifyNever(webSocketSink.add(any));
      expect(find.text("Step 5 of 5"), findsNothing);
    });
  });
  tearDown(() {
    reset(mockDisplayQrAuth);
    reset(mockChannel);
    reset(mockStream);
    reset(mockWallet);
    resetMockitoState(); // Resets all mocks if you're using multiple
  });
}
