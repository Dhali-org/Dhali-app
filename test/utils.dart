// TODO : Work out how to load assets into unit tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const publicConfig = '''
{
    "MINTED_NFTS_DOCUMENT_KEYS": {
        "NUMBER_OF_SUCCESSFUL_REQUESTS": "num_successful_requests", 
        "ASSET_CREATOR_ACCOUNT": "asset_creator_account", 
        "AVERAGE_INFERENCE_TIME_MS": "average_inference_time_ms", 
        "CATEGORY": "category", 
        "ENDPOINT_URL": "endpoint_url",
        "EXPECTED_INFERENCE_COST_PER_MS": "expected_inference_cost",
        "ASSET_NAME": "name",
        "NFTOKEN_ID": "NFTokenId"
    },
    "MINTED_NFTS_COLLECTION_NAME": "public_minted_nfts",
    "PAYMENT_CLAIM_KEYS": {
        "ACCOUNT": "account",
        "DESTINATION_ACCOUNT": "destination_account",
        "AUTHORIZED_AMOUNT": "authorized_to_claim",
        "SIGNATURE": "signature",
        "CHANNEL_ID": "channel_id"
    },
    "CURRENCY_KEYS": {
        "CODE": "code", 
        "SCALE": "scale"
    },
    "GET_READMES_ROUTE": "readme",
    "POST_DEPLOY_README_ROUTE": "readme",
    "POST_RUN_INFERENCE_ROUTE": "run",
    "POST_DEPLOY_ASSET_ROUTE": "asset",
    "ROOT_DEPLOY_URL": "https://kernml-3mmgxhct.uc.gateway.dev",
    "ROOT_CONSUMER_URL": "https://kernml-consumer-3mmgxhct.uc.gateway.dev",
    "DHALI_PUBLIC_ADDRESS": "rstbSTpPcyxMsiXwkBxS9tFTrg2JsDNxWk"
}
''';

Future<void> dragOutDrawer(WidgetTester tester) async {
  final ScaffoldState state = tester.firstState(find.byType(Scaffold));
  state.openDrawer();
  await tester.pumpAndSettle();

  expect(find.text("Marketplace"), findsOneWidget);
  expect(find.text("My assets"), findsOneWidget);
  expect(find.text("Wallet"), findsOneWidget);
}
