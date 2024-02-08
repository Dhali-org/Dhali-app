import 'dart:convert';
import 'dart:math';

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
const String theAPIURL = "a_random url with-spaces_n@med-asset";

// TODO : This length variable is designed to validate that input headers cannot
// be longer that maxLength. Annoyingly, it can't be taken beyond its current
// value for some unknown reason. The implication is that this test is not
// asserting that inputs beyond maxLength are not allowed
const length = 219;
const maxLength = 4096;
String theUnsanitisedString =
    "ThisIsAHeaderKey:ButItIncludesAColonA spaceAnd,Comma;Semicolon@AtSymbol\"DoubleQuote/Slash?QuestionMark=EqualsSign{CurlyBrace}AndExcessiveLength${"." * length}";
String theSanitsedPartialString =
    "ThisIsAHeaderKeyButItIncludesAColonA spaceAndCommaSemicolonAtSymbolDoubleQuoteSlashQuestionMarkEqualsSignCurlyBraceAndExcessiveLength";
String theSanitsedString =
    "$theSanitsedPartialString${"." * min(length, maxLength - theSanitsedPartialString.length)}";

String theUnsantisatedAPIKeyKey = theUnsanitisedString;
String theUnsantisatedAPIKeyValue = theUnsanitisedString.replaceFirst("T", "t");

String theAPIKeyKey =
    theSanitsedString.replaceAll(" ", ""); // No whitespace allowed in keys
String theAPIKeyValue = theSanitsedString.replaceFirst("T",
    "t"); // Whitespace allowed, but also replace the character to make sure expected key/value gststrings are different

const String theAssetName = "abadl3ynmed-asset";
const String theDhaliAssetID = "a-session-id";

enum FileType { readme, dockerImage }

Future<void> selectFile(
    WidgetTester tester,
    FakeFirebaseFirestore mockFirebaseFirestore,
    FileType fileType,
    int dialogNumber) async {
  expect(find.text("Select"), findsNWidgets(dialogNumber));
  if (fileType == FileType.dockerImage) {
    expect(find.byKey(const Key("DockerDropZoneDeployNext")), findsOneWidget);
  } else if (fileType == FileType.readme) {
    expect(find.byKey(const Key("ReadmeDropZoneDeployNext")), findsOneWidget);
  }

  expect(find.text("Drag or select your file"), findsNWidgets(dialogNumber));
  if (fileType == FileType.dockerImage) {
    expect(find.text("No .tar docker image asset selected"), findsOneWidget);
  } else if (fileType == FileType.readme) {
    expect(find.text("No README/OpenAPI json selected"), findsOneWidget);
  }
  expect(find.byIcon(Icons.cloud_upload_rounded), findsNWidgets(dialogNumber));
  expect(find.byIcon(Icons.help_outline_outlined), findsNWidgets(dialogNumber));
  expect(find.byType(DropzoneView), findsNWidgets(dialogNumber));

  await tester.pumpAndSettle();

  if (fileType == FileType.dockerImage) {
    await tester.tap(find.byKey(const Key("choose_docker_image_button")));
  } else if (fileType == FileType.readme) {
    await tester.tap(find.byKey(const Key("choose_readme_button")));
  }

  await tester.pumpAndSettle();
}

Future<void> displayCosts(
    WidgetTester tester, FakeFirebaseFirestore mockFirebaseFirestore) async {
  expect(find.text("Here is a break down of the charges:"), findsOneWidget);
  expect(find.text("Paid by you:"), findsOneWidget);
  expect(find.text("Paid by the user of your asset:"), findsOneWidget);

  expect(find.text("What?"), findsNWidgets(2));
  expect(find.text("When?"), findsNWidgets(2));
  expect(find.text("Cost (XRP):"), findsNWidgets(2));
  expect(find.text("15.10000 per second"), findsOneWidget);
  expect(find.text("302.00000 per second"), findsOneWidget);
  expect(find.text("317.10000 per second"), findsOneWidget);
  expect(find.text("Are you sure you want to deploy?"), findsOneWidget);
  expect(find.text("Yes"), findsOneWidget);
  expect(find.byKey(const Key("DeploymentCostWidgetBack")), findsOneWidget);
}

Future<void> setEarningsPerRequest(
    WidgetTester tester, FakeFirebaseFirestore mockFirebaseFirestore) async {
  expect(find.text("How much would you like to earn?"), findsOneWidget);
  expect(find.text("\nKeep this small to encourage usage.\n"), findsOneWidget);
  expect(find.text("Per second"), findsOneWidget);
  expect(find.text("Per request"), findsOneWidget);
  expect(find.text("0.001"), findsOneWidget);
  expect(find.text("   XRP  "), findsOneWidget);
  expect(find.text("Your API earns you 0.001 XRP per second"), findsOneWidget);

  await tester.enterText(
      find.byKey(const Key("percentage_earnings_input")), "302");
  await tester.pumpAndSettle();

  expect(find.text("302"), findsOneWidget);
  expect(find.text("Your API earns you 302 XRP per second"), findsOneWidget);

  await tester.tap(find.byKey(const Key('Per request')));
  await tester.pumpAndSettle();
  expect(find.text("Your API earns you 302 XRP per request"), findsOneWidget);

  await tester.tap(find.byKey(const Key('Per second')));
  await tester.pumpAndSettle();
  expect(find.text("Your API earns you 302 XRP per second"), findsOneWidget);
}

Future<void> selectImage(
  WidgetTester tester,
  FakeFirebaseFirestore mockFirebaseFirestore,
) async {
  await selectFile(tester, mockFirebaseFirestore, FileType.dockerImage, 1);
  await tester.tap(find.byKey(const Key("DockerDropZoneDeployNext")));
  await tester.pumpAndSettle(const Duration(seconds: 4));

  expect(find.text("Step 3 of 5"), findsNWidgets(2));
  expect(find.text("Your image was successfully scanned."), findsOneWidget);

  await tester.tap(find.byKey(const Key("ImageScanningNext")));
  await tester.pumpAndSettle();
}

Future<void> selectAPICredentials(
  WidgetTester tester,
  FakeFirebaseFirestore mockFirebaseFirestore,
) async {
  expect(find.text("Step 3 of 5"), findsNWidgets(1));
  expect(find.text("What are your APIs details?"), findsOneWidget);
  expect(find.text("API base URL:"), findsOneWidget);
  expect(find.text("URL"), findsOneWidget);
  expect(find.text("API header:"), findsOneWidget);
  expect(find.text("These must not expire.\n"), findsOneWidget);
  expect(find.byKey(const Key("add_header")), findsOneWidget);
  expect(find.byIcon(Icons.remove), findsOneWidget);
  expect(find.text("You must complete all headers"), findsOneWidget);

  expect(find.text(theAPIURL.replaceAll(" ", "")), findsNothing);
  await tester.enterText(find.byKey(const Key("api_base_url")), theAPIURL);
  await tester.pumpAndSettle();
  // No spaces should be present
  expect(find.text(theAPIURL.replaceAll(" ", "")), findsOneWidget);

  // Should not progress to next dialog
  await tester.tap(find.byKey(const Key("APICredentialsNext")));
  await tester.pumpAndSettle();
  expect(find.text("Step 4 of 5"), findsNothing);

  // Remove all header inputs. Should not progress to next dialog
  await tester.tap(find.byIcon(Icons.remove));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key("APICredentialsNext")));
  await tester.pumpAndSettle();
  expect(find.text("Step 4 of 5"), findsNothing);
  await tester.tap(find.byKey(const Key("add_header")));
  await tester.pumpAndSettle();

  // Should be one key-value input available
  expect(find.text("Key 1"), findsOneWidget);
  expect(find.text("Value 1"), findsOneWidget);
  expect(find.text("You must complete all headers"), findsOneWidget);
  // Should be one key-value input available
  expect(find.text("Key 2"), findsNothing);
  expect(find.text("Value 2"), findsNothing);

  await tester.tap(find.byKey(const Key("add_header")));
  await tester.pumpAndSettle();

  // Pressing should reveal another input for headers
  expect(find.text("Key 1"), findsOneWidget);
  expect(find.text("Value 1"), findsOneWidget);
  expect(find.text("You must complete all headers"), findsOneWidget);
  expect(find.text("Key 2"), findsOneWidget);
  expect(find.text("Value 2"), findsOneWidget);

  await tester.tap(find.byIcon(Icons.remove));
  await tester.pumpAndSettle();

  expect(find.text("Key 2"), findsNothing);
  expect(find.text("Value 2"), findsNothing);
  expect(find.text("You must complete all headers"), findsOneWidget);
  expect(find.text("Key 1"), findsOneWidget);
  expect(find.text("Value 1"), findsOneWidget);

  expect(find.text(theAPIKeyKey), findsNothing);
  await tester.enterText(
      find.byKey(const Key('Key 1')), theUnsantisatedAPIKeyKey);
  await tester.pumpAndSettle();
  // Typing only a key shouldn't reveal the hinted value that headers will take
  expect(find.text("You must complete all headers"), findsOneWidget);
  await tester.enterText(
      find.byKey(const Key('Value 1')), theUnsantisatedAPIKeyValue);
  await tester.pumpAndSettle();
  expect(find.text("You must complete all headers"), findsNothing);

  expect(find.text(theAPIKeyKey), findsOneWidget);

  // Spaces can be present
  expect(find.text(theAPIKeyValue), findsOneWidget);

  expect(
      find.text("Requests will have headers\n\n"
          "'$theAPIKeyKey: ${theAPIKeyValue.substring(0, 10)}...'"),
      findsOneWidget);

  // Adding a header should cause the "Requests will have ..." box to vanish
  await tester.tap(find.byKey(const Key("add_header")));
  await tester.pumpAndSettle();
  expect(find.text("You must complete all headers"), findsOneWidget);
  expect(
      find.text("Requests will have headers\n\n"
          "'${theAPIKeyKey.replaceAll(" ", "")}: ${theAPIKeyValue.substring(0, 10)}...'"),
      findsNothing);
  expect(find.text("Key 2"), findsOneWidget);
  expect(find.text("Value 2"), findsOneWidget);

  // Should not progress to next dialog until unfilled headers are filled
  await tester.tap(find.byKey(const Key("APICredentialsNext")));
  await tester.pumpAndSettle();
  expect(find.text("Step 4 of 5"), findsNothing);

  // Should now be possible to progress
  await tester.tap(find.byIcon(Icons.remove));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key("APICredentialsNext"), skipOffstage: false),
      findsOneWidget);
  expect(find.byKey(const Key("APICredentialsBack"), skipOffstage: false),
      findsOneWidget);
  await tester.tap(find.byKey(const Key("APICredentialsNext")));
  await tester.pumpAndSettle();
}

Future<void> deploymentDemo(WidgetTester tester,
    FakeFirebaseFirestore mockFirebaseFirestore, int responseCode,
    {bool isSelfHosted = false}) async {
  await utils.dragOutDrawer(tester);

  await tester.tap(find.text("My APIs"));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Monetise my API', skipOffstage: false));
  await tester.pumpAndSettle();

  expect(find.text("What will your API be called?"), findsOneWidget);
  expect(find.text("Step 1 of 5"), findsOneWidget);
  expect(find.text("You will need:"), findsOneWidget);
  expect(find.text("To know what you'll charge"), findsOneWidget);
  expect(find.text("API base URL"), findsOneWidget);
  expect(find.text("API key"), findsOneWidget);
  expect(
      find.text("A README or an OpenAPI json specification"), findsOneWidget);

  await tester.pumpAndSettle();

  await tester.tap(find.text("API name"));
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

  expect(find.text("Step 2 of 5"), findsOneWidget);
  await setEarningsPerRequest(tester, mockFirebaseFirestore);

  await tester.tap(find.byKey(const Key("ImageCostNext")));
  await tester.pumpAndSettle();

  expect(find.text("Step 3 of 5"), findsOneWidget);

  if (isSelfHosted) {
    await selectAPICredentials(tester, mockFirebaseFirestore);
  } else {
    await selectImage(tester, mockFirebaseFirestore);
  }

  expect(find.text("Step 4 of 5"), findsOneWidget);
  await selectFile(
      tester, mockFirebaseFirestore, FileType.readme, isSelfHosted ? 1 : 2);
  await tester.tap(find.byKey(const Key("ReadmeDropZoneDeployNext")));
  await tester.pumpAndSettle(const Duration(seconds: 4));

  await displayCosts(tester, mockFirebaseFirestore);

  await tester.tap(find.text("Yes"));

  await tester
      .pump(); // First pump releases the Future from `mockWallet.getOpenPaymentChannels`
  await tester.pump(); // Second pump releases the Future.value to FutureBuilder
  expect(find.byKey(const Key("deploying_in_progress_dialog")), findsOneWidget);
  expect(find.text("Cancel"), findsOneWidget);

  if (responseCode == 200) {
    await tester.pump();
    if (isSelfHosted) {
      expect(find.byKey(const Key("linking_api_spinner")), findsOneWidget);
      await tester.pump();
    }
    expect(find.byKey(const Key("minting_nft_spinner")), findsOneWidget);
    await mockFirebaseFirestore
        .collection(Config.config!["MINTED_NFTS_COLLECTION_NAME"])
        .doc(theDhaliAssetID)
        .set({
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]
          ["NUMBER_OF_SUCCESSFUL_REQUESTS"]: 0,
      Config.config!["MINTED_NFTS_DOCUMENT_KEYS"]["EXPECTED_INFERENCE_COST"]:
          20,
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
  await tester.pumpAndSettle();
  expect(find.byType(DataTransmissionWidget), findsNothing);
  expect(find.byType(MarketplaceHomeScreen), findsOneWidget);

  expect(find.byKey(const Key("APICredentialsBack")), findsNothing);
  expect(find.byKey(const Key("APICredentialsNext")), findsNothing);
  expect(find.byKey(const Key("AssetNameBack")), findsNothing);
  expect(find.byKey(const Key("AssetNameNext")), findsNothing);
  expect(find.byKey(const Key("DeploymentCostWidgetBack")), findsNothing);
  expect(find.byKey(const Key("DockerDropZoneDeployNext")), findsNothing);
  expect(find.byKey(const Key("DropZoneDeployBack")), findsNothing);
  expect(find.byKey(const Key("DropZoneDeployNext")), findsNothing);
  expect(find.byKey(const Key("DropZoneRunNext")), findsNothing);
  expect(find.byKey(const Key("ImageCostBack")), findsNothing);
  expect(find.byKey(const Key("ImageCostNext")), findsNothing);
  expect(find.byKey(const Key("ImageScanningBack")), findsNothing);
  expect(find.byKey(const Key("ImageScanningNext")), findsNothing);
  expect(find.byKey(const Key("Per request")), findsNothing);
  expect(find.byKey(const Key("Per second")), findsNothing);
  expect(find.byKey(const Key("ReadmeDropZoneDeployNext")), findsNothing);
  expect(find.byKey(const Key("api_base_url")), findsNothing);
  expect(find.byKey(const Key("api_key")), findsNothing);
  expect(find.byKey(const Key("asset_name_input_field")), findsNothing);
  expect(find.byKey(const Key("choose_docker_image_button")), findsNothing);
  expect(find.byKey(const Key("choose_readme_button")), findsNothing);
  expect(find.byKey(const Key("choose_run_input")), findsNothing);
  expect(find.byKey(const Key("deploying_in_progress_dialog")), findsNothing);
  expect(find.byKey(const Key("dhali_hosted-radio_button")), findsNothing);
  expect(find.byKey(const Key("exit_deployment_dialogs")), findsNothing);
  expect(find.byKey(const Key("minting_nft_spinner")), findsNothing);
  expect(find.byKey(const Key("percentage_earnings_input")), findsNothing);
  expect(find.byKey(const Key("self_hosted-radio_button")), findsNothing);
  expect(find.byKey(const Key("upload_failed_warning")), findsNothing);
  expect(find.byKey(const Key("upload_failed_warning")), findsNothing);
  expect(find.byKey(const Key("upload_success_info")), findsNothing);
  expect(find.byKey(const Key("upload_success_info")), findsNothing);
  expect(find.byKey(const Key("use_docker_image_button")), findsNothing);
  expect(find.byKey(const Key("use_docker_image_button")), findsNothing);
}

@GenerateMocks([Request, MultipartRequest, XRPLWallet])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Config.config = jsonDecode(utils.publicConfig);

  late FakeFirebaseFirestore firebaseMockInstance;
  late MockXRPLWallet mockWallet;
  late MockRequest mockRequester;
  late MockMultipartRequest mockMultipartRequester;

  BaseRequest getRequest<T extends BaseRequest>(String method, String path) {
    if (T == MultipartRequest) {
      return mockMultipartRequester;
    } else if (T == Request) {
      return mockRequester;
    }
    throw ArgumentError('Unsupported request type: $T');
  }

  setUpAll(() {
    mockWallet = MockXRPLWallet();
    mockRequester = MockRequest();
    mockMultipartRequester = MockMultipartRequest();
    firebaseMockInstance = FakeFirebaseFirestore();

    const String theAssetName = "abadl3ynmed-asset";
    when(mockWallet.balance).thenReturn(ValueNotifier("1000000"));
    when(mockWallet.address).thenReturn("a-random-address");
    when(mockWallet.mnemonic).thenReturn("memorable words");
    when(mockWallet.sendDrops("9000000", "CHANNEL_ID_STRING"))
        .thenReturn("a-random-signature");
    when(mockWallet.acceptOffer(any, context: anyNamed("context")))
        .thenAnswer((_) async {
      return Future.value(true);
    });
    when(mockWallet.getNFTOffers("some_NFToken_id")).thenAnswer((_) async {
      return Future.value([
        NFTOffer(0, Config.config!["DHALI_MINTER_PUBLIC_ADDRESS"],
            mockWallet.address, "0")
      ]);
    });
    when(mockWallet.getOpenPaymentChannels(
            destination_address: "rhtfMhppuk5siMi8jvkencnCTyjciArCh7"))
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
            context: anyNamed("context"),
            destinationAddress: "rhtfMhppuk5siMi8jvkencnCTyjciArCh7",
            authAmount: anyNamed("authAmount"),
            channelDescriptor: anyNamed("channelDescriptor")))
        .thenAnswer((_) {
      return Future.value({"key": "value"});
    });
  });

  group('Deployment journeys', () {
    testWidgets('Bad payment in header', (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      int responseCode = 402;

      when(mockRequester.send()).thenAnswer((_) async => StreamedResponse(
              const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockRequester.headers).thenAnswer((_) => {});
      when(mockMultipartRequester.send()).thenAnswer((_) async =>
          StreamedResponse(const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockMultipartRequester.headers).thenAnswer((_) => {});
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
            setDarkTheme: (value) {},
            isDarkTheme: () => true,
            firestore: firebaseMockInstance,
            getWallet: () => mockWallet,
            setWallet: (wallet) => {},
            getRequest: getRequest),
      ));

      await tester.pumpAndSettle();

      await deploymentDemo(tester, FakeFirebaseFirestore(), responseCode,
          isSelfHosted: true);
    });
    testWidgets('Successful image deployment', (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      int responseCode = 200;

      when(mockRequester.send()).thenAnswer((_) async => StreamedResponse(
              const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockRequester.headers).thenAnswer((_) => {});
      when(mockMultipartRequester.send()).thenAnswer((_) async =>
          StreamedResponse(const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockMultipartRequester.headers).thenAnswer((_) => {});
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
            setDarkTheme: (value) {},
            isDarkTheme: () => true,
            firestore: firebaseMockInstance,
            getWallet: () => mockWallet,
            setWallet: (wallet) => {},
            getRequest: getRequest),
      ));

      await tester.pumpAndSettle();

      await deploymentDemo(tester, firebaseMockInstance, responseCode,
          isSelfHosted: true);

      verify(mockWallet.acceptOffer(any, context: anyNamed("context")))
          .called(1);
    });

    testWidgets('Successful self hosted journey deployment',
        (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      int responseCode = 200;

      when(mockRequester.send()).thenAnswer((_) async => StreamedResponse(
              const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockRequester.headers).thenAnswer((_) => {});
      when(mockMultipartRequester.send()).thenAnswer((_) async =>
          StreamedResponse(const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockMultipartRequester.headers).thenAnswer((_) => {});
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
            setDarkTheme: (value) {},
            isDarkTheme: () => true,
            firestore: firebaseMockInstance,
            getWallet: () => mockWallet,
            setWallet: (wallet) => {},
            getRequest: getRequest),
      ));

      await tester.pumpAndSettle();
      await deploymentDemo(tester, firebaseMockInstance, responseCode,
          isSelfHosted: true);

      verify(mockWallet.acceptOffer(any, context: anyNamed("context")))
          .called(1);
    });

    testWidgets('Image deployment, incorrect offer amount',
        (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      int responseCode = 200;

      when(mockWallet.getNFTOffers("some_NFToken_id")).thenAnswer((_) async {
        return Future.value([
          NFTOffer(1, Config.config!["DHALI_MINTER_PUBLIC_ADDRESS"],
              mockWallet.address, "0")
        ]);
      });
      when(mockRequester.send()).thenAnswer((_) async => StreamedResponse(
              const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockRequester.headers).thenAnswer((_) => {});
      when(mockMultipartRequester.send()).thenAnswer((_) async =>
          StreamedResponse(const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockMultipartRequester.headers).thenAnswer((_) => {});
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
            setDarkTheme: (value) {},
            isDarkTheme: () => true,
            firestore: firebaseMockInstance,
            getWallet: () => mockWallet,
            setWallet: (wallet) => {},
            getRequest: getRequest),
      ));

      await tester.pumpAndSettle();
      await deploymentDemo(tester, firebaseMockInstance, responseCode,
          isSelfHosted: true);
      verifyNever(mockWallet.acceptOffer(any, context: anyNamed("context")));
    });

    testWidgets('Image deployment, incorrect source address',
        (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      int responseCode = 200;

      when(mockWallet.getNFTOffers("some_NFToken_id")).thenAnswer((_) async {
        return Future.value(
            [NFTOffer(0, "some_incorrect_address", mockWallet.address, "0")]);
      });
      when(mockRequester.send()).thenAnswer((_) async => StreamedResponse(
              const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockRequester.headers).thenAnswer((_) => {});
      when(mockMultipartRequester.send()).thenAnswer((_) async =>
          StreamedResponse(const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockMultipartRequester.headers).thenAnswer((_) => {});
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
            setDarkTheme: (value) {},
            isDarkTheme: () => true,
            firestore: firebaseMockInstance,
            getWallet: () => mockWallet,
            setWallet: (wallet) => {},
            getRequest: getRequest),
      ));

      await tester.pumpAndSettle();
      await deploymentDemo(tester, firebaseMockInstance, responseCode,
          isSelfHosted: true);
      verifyNever(mockWallet.acceptOffer(any, context: anyNamed("context")));
    });

    testWidgets('Image deployment, incorrect destination address',
        (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      int responseCode = 200;

      when(mockWallet.getNFTOffers("some_NFToken_id")).thenAnswer((_) async {
        return Future.value([
          NFTOffer(0, Config.config!["DHALI_MINTER_PUBLIC_ADDRESS"],
              "some_incorrect_address", "0")
        ]);
      });
      when(mockRequester.send()).thenAnswer((_) async => StreamedResponse(
              const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockRequester.headers).thenAnswer((_) => {});
      when(mockMultipartRequester.send()).thenAnswer((_) async =>
          StreamedResponse(const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockMultipartRequester.headers).thenAnswer((_) => {});
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
            setDarkTheme: (value) {},
            isDarkTheme: () => true,
            firestore: firebaseMockInstance,
            getWallet: () => mockWallet,
            setWallet: (wallet) => {},
            getRequest: getRequest),
      ));

      await tester.pumpAndSettle();
      await deploymentDemo(tester, firebaseMockInstance, responseCode,
          isSelfHosted: true);
      verifyNever(mockWallet.acceptOffer(any, context: anyNamed("context")));
    });

    testWidgets(
        'Successful image deployment, mixed incorrect offers with correct',
        (WidgetTester tester) async {
      const w = 1920;
      const h = 1080;
      int responseCode = 200;

      when(mockWallet.getNFTOffers("some_NFToken_id")).thenAnswer((_) async {
        return Future.value([
          NFTOffer(0, Config.config!["DHALI_MINTER_PUBLIC_ADDRESS"],
              "some_incorrect_address", "0"),
          NFTOffer(0, Config.config!["DHALI_MINTER_PUBLIC_ADDRESS"],
              mockWallet.address, "1"),
          NFTOffer(0, "some_incorrect_address", mockWallet.address, "2")
        ]);
      });
      when(mockRequester.send()).thenAnswer((_) async => StreamedResponse(
              const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockRequester.headers).thenAnswer((_) => {});
      when(mockMultipartRequester.send()).thenAnswer((_) async =>
          StreamedResponse(const Stream.empty(), responseCode, headers: {
            Config.config!["DHALI_ID"].toString().toLowerCase(): theDhaliAssetID
          }));
      when(mockMultipartRequester.headers).thenAnswer((_) => {});
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
            setDarkTheme: (value) {},
            isDarkTheme: () => true,
            firestore: firebaseMockInstance,
            getWallet: () => mockWallet,
            setWallet: (wallet) => {},
            getRequest: getRequest),
      ));

      await tester.pumpAndSettle();
      await deploymentDemo(tester, firebaseMockInstance, responseCode,
          isSelfHosted: true);
      verify(mockWallet.acceptOffer(any, context: anyNamed("context")))
          .called(1);
    });
  });
}
