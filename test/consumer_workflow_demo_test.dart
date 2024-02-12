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
const double earnings = 10102;
const double paidOut = 10101;
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
    when(mockWallet.amount).thenReturn(ValueNotifier("10000000"));
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

      T getMockMultipartRequest<T extends BaseRequest>(String _, String path) {
        var mockRunRequester = MockMultipartRequest();
        when(mockRunRequester.send()).thenAnswer(
            (_) async => StreamedResponse(const Stream.empty(), responseCode));
        when(mockRunRequester.headers).thenAnswer((_) => {});

        return mockRunRequester as T;
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
          asset: MarketplaceListData(
              earnings: earnings,
              paidOut: paidOut,
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
    });
  });
}
