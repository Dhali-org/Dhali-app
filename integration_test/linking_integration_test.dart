import 'package:dhali/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';

var uuid = const Uuid();
String theInputAssetName = "integration-test-api";
const String theAPIURL = "https://api.xrpldata.com/api/v1";
const String theAPIKey = "integration-test-key";

enum FileType { readme, dockerImage }

Future<void> selectFile(
    WidgetTester tester, FileType fileType, int dialogNumber) async {
  await tester.pumpAndSettle();

  if (fileType == FileType.dockerImage) {
    await tester.tap(find.byKey(const Key("choose_docker_image_button")));
  } else if (fileType == FileType.readme) {
    await tester.tap(find.byKey(const Key("choose_readme_button")));
  }

  await tester.pumpAndSettle();
}

Future<void> setEarningsPerRequest(WidgetTester tester) async {
  await tester.enterText(
      find.byKey(const Key("percentage_earnings_input")), "0.012");
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('Per request')));
  await tester.pumpAndSettle();
}

Future<void> selectImage(WidgetTester tester) async {
  await selectFile(tester, FileType.dockerImage, 1);
  await tester.tap(find.byKey(const Key("DockerDropZoneDeployNext")));
  await tester.pumpAndSettle(const Duration(seconds: 4));
  await tester.tap(find.byKey(const Key("ImageScanningNext")));
  await tester.pumpAndSettle();
}

Future<void> selectAPICredentials(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key("api_base_url")), theAPIURL);
  await tester.enterText(find.byKey(const Key("api_key")), theAPIKey);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key("APICredentialsNext")));
  await tester.pumpAndSettle();
}

Future<void> deploymentDemo(WidgetTester tester, int responseCode,
    {bool isSelfHosted = false}) async {
  final ScaffoldState state = tester.firstState(find.byType(Scaffold));
  state.openDrawer();
  await tester.pumpAndSettle();
  await tester.tap(find.text("Wallet"));
  await tester.pumpAndSettle();
  await tester.tap(find.text(" Use free test wallet"));
  await tester.pumpAndSettle();
  await tester.tap(find.text("Generate new test wallet"));
  await tester.pumpAndSettle();
  state.openDrawer();
  await tester.pumpAndSettle();
  await tester.tap(find.text("My APIs"));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Monetise my API', skipOffstage: false));
  await tester.pumpAndSettle();
  // Go back and forth between the radio buttons
  await tester.tap(find.byKey(const Key("dhali_hosted-radio_button")));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key("self_hosted-radio_button")));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key("dhali_hosted-radio_button")));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key("self_hosted-radio_button")));
  await tester.pumpAndSettle();
  if (isSelfHosted) {
    await tester.tap(find.byKey(const Key("self_hosted-radio_button")));
  } else {
    await tester.tap(find.byKey(const Key("dhali_hosted-radio_button")));
  }
  await tester.pumpAndSettle();
  await tester.tap(find.text("API name"));
  await tester.enterText(
      find.byKey(const Key("asset_name_input_field")), theInputAssetName);
  await tester.pumpAndSettle(const Duration(seconds: 5));
  await tester.tap(find.byKey(const Key("AssetNameNext")));
  await tester.pumpAndSettle();
  await setEarningsPerRequest(tester);
  await tester.tap(find.byKey(const Key("ImageCostNext")));
  await tester.pumpAndSettle();

  if (isSelfHosted) {
    await selectAPICredentials(tester);
  } else {
    await selectImage(tester);
  }

  await selectFile(tester, FileType.readme, isSelfHosted ? 1 : 2);
  await tester.tap(find.byKey(const Key("ReadmeDropZoneDeployNext")));
  await tester.pumpAndSettle(const Duration(seconds: 4));

  await tester.tap(find.text("Yes"));

  await tester.pumpAndSettle(const Duration(seconds: 20));
  // Linking should take < 5 mins
  await Future.delayed(const Duration(seconds: 300));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Link an API', (tester) async {
    // Load app widget.
    await initializeApp();
    await tester.pumpWidget(const MyApp(getRequest: getRequest));

    await deploymentDemo(tester, 200, isSelfHosted: true);
  });
}
