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
        "EXPECTED_INFERENCE_COST": "average_cost",
        "ASSET_NAME": "name",
        "NFTOKEN_ID": "NFTokenId",
        "EARNING_RATE": "asset_earning_rate",
        "EARNING_TYPE": "asset_earning_type",
        "CANONICAL_API": "canonical_api"
    },
    "MINTED_NFTS_COLLECTION_NAME": "public_minted_nfts",
    "PAYMENT_CLAIM_KEYS": {
        "ACCOUNT": "account",
        "DESTINATION_ACCOUNT": "destination_account",
        "AUTHORIZED_AMOUNT": "authorized_to_claim",
        "SIGNATURE": "signature",
        "CHANNEL_ID": "channel_id"
    },
    "DHALI_ID": "Dhali-ID",
    "PAYMENT_CLAIM_HEADER_KEY": "Payment-Claim",
    "CURRENCY_KEYS": {
        "CODE": "code", 
        "SCALE": "scale"
    },
    "GET_READMES_ROUTE": "readme",
    "GET_WARMUP_ROUTE": "warmup",
    "POST_DEPLOY_README_ROUTE": "readme",
    "POST_RUN_INFERENCE_ROUTE": "run",
    "POST_DEPLOY_ASSET_ROUTE": "asset",
    "ROOT_DEPLOY_URL": "https://kernml-3mmgxhct.uc.gateway.dev",
    "ROOT_CONSUMER_URL": "https://kernml-consumer-3mmgxhct.uc.gateway.dev",
    "ROOT_RUN_URL": "https://kernml-run-3mmgxhct.uc.gateway.dev",
    "DHALI_PUBLIC_ADDRESS": "rstbSTpPcyxMsiXwkBxS9tFTrg2JsDNxWk",
    "DHALI_DEPLOYMENT_COST_PER_CHUNK_DROPS": 2000,
    "DHALI_CPU_INFERENCE_COST_PER_MS": 0.1,
    "DHALI_EARNINGS_PERCENTAGE_PER_INFERENCE": 5,
    "MAX_NUMBER_OF_BYTES_PER_DEPLOY_CHUNK": 10485760,
    "PAYMENT_CLAIM_BUFFER": 30
}
''';

Future<void> dragOutDrawer(WidgetTester tester) async {
  final ScaffoldState state = tester.firstState(find.byType(Scaffold));
  state.openDrawer();
  await tester.pumpAndSettle();

  expect(find.text("Marketplace"), findsOneWidget);
  expect(find.text("My APIs"), findsOneWidget);
  expect(find.text("Wallet"), findsOneWidget);
}
