import 'dart:async';
import 'dart:convert';
import 'package:dhali/marketplace/marketplace_dialogs.dart';
import 'package:dhali/utils/api_administration_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'authentication_client_test.mocks.dart';

class MockDisplayQrAuth extends Mock {
  void call(String qrUrl, String deepLink);
}

class MockPrefillHeaders extends Mock {
  void call(List<dynamic> headers);
}

class MockPrefillBaseUrl extends Mock {
  void call(String baseUrl);
}

class MockOnUpdated extends Mock {
  void call(List<dynamic> successfulUpdateKeys, List<dynamic> failedUpdateKeys);
}

@GenerateMocks([WebSocketChannel, Stream, StreamSubscription, WebSocketSink])
void main() {
  group('APIAdminGatewayClient Tests - Web', () {
    late MockWebSocketChannel mockChannel;
    late MockStream mockStream;
    late APIAdminGatewayClient client;
    late StreamController<dynamic> streamController;

    late MockDisplayQrAuth mockDisplayQrAuth;
    late MockPrefillHeaders mockPrefillHeaders;
    late MockPrefillBaseUrl mockPrefillBaseUrl;
    late MockOnUpdated mockOnUpdated;

    setUp(() {
      mockChannel = MockWebSocketChannel();
      mockStream = MockStream();
      streamController = StreamController<dynamic>();

      when(mockChannel.stream).thenAnswer((_) => streamController.stream);
      when(mockChannel.ready).thenAnswer((_) => Future.delayed(Duration.zero));

      // Initialize your mock callbacks
      mockDisplayQrAuth = MockDisplayQrAuth();
      mockPrefillHeaders = MockPrefillHeaders();
      mockPrefillBaseUrl = MockPrefillBaseUrl();
      mockOnUpdated = MockOnUpdated();

      client = APIAdminGatewayClient(
        uuid: "test-uuid",
        getWebSocketChannel: (uuid) => mockChannel,
        displayQrAuth: (qrCodeUrl, deepLink) =>
            mockDisplayQrAuth(qrCodeUrl, deepLink),
        onAuthFailure: () => {},
        prefillHeaders: (headers) => mockPrefillHeaders(headers),
        prefillBaseUrl: (baseUrl) => mockPrefillBaseUrl(baseUrl),
        onUpdated: (successList, failedList) =>
            mockOnUpdated(successList, failedList),
      );
    });

    test('connectAndPrefillPrivateMetadata listens to stream', () async {
      final mockSubscription = MockStreamSubscription<dynamic>();
      when(mockChannel.stream).thenAnswer((_) => mockStream);
      when(mockStream.listen(any,
              onDone: anyNamed('onDone'),
              onError: anyNamed('onError'),
              cancelOnError: true))
          .thenAnswer((_) => mockSubscription);

      verifyNever(mockStream.listen(any,
          onDone: anyNamed('onDone'), onError: anyNamed('onError')));
      client.connectAndPrefillPrivateMetadata();

      await Future.delayed(const Duration(milliseconds: 100));

      verify(mockStream.listen(any,
              onDone: anyNamed('onDone'),
              onError: anyNamed('onError'),
              cancelOnError: true))
          .called(1);
    });

    test('api_admin_gateway_qr_code callback', () async {
      client.connectAndPrefillPrivateMetadata();
      // Assume this message triggers the displayQrAuth callback
      streamController.add({
        "schema": "api_admin_gateway_qr_code",
        "qr_code_url": "https://example.com/qr",
        "deep_link": "https://example.com/deep_link"
      });

      await Future.delayed(const Duration(milliseconds: 100));

      // Verify that displayQrAuth was called exactly once
      verify(mockDisplayQrAuth.call(
              "https://example.com/qr", "https://example.com/deep_link"))
          .called(1);
    });

    test('api_admin_gateway_authentication_successful', () async {
      final webSocketSink = MockWebSocketSink();

      when(mockChannel.sink).thenReturn(webSocketSink);
      client.connectAndPrefillPrivateMetadata();
      // Assume this message triggers the displayQrAuth callback
      streamController.add({
        "schema": "api_admin_gateway_authentication_successful",
      });

      final message = {
        "schema": "api_admin_gateway_prefill_request",
        "schema_version": "1.0",
      };

      await Future.delayed(const Duration(milliseconds: 100));

      verify(webSocketSink.add(jsonEncode(message))).called(1);
    });

    test('api_admin_gateway_prefill_response callback', () async {
      var future = client.connectAndPrefillPrivateMetadata();
      String baseUrl = "example.com";
      final headers = [
        {"header_1": "1"},
        {"header_2": "2"}
      ];
      streamController.add({
        "schema": "api_admin_gateway_prefill_response",
        "pre_fill_data": {"base_url": baseUrl, "headers": headers}
      });

      await Future.delayed(const Duration(milliseconds: 100));

      verify(mockPrefillBaseUrl.call(baseUrl)).called(1);
      verify(mockPrefillHeaders.call(headers)).called(1);
      await future; // This future should resolve after the prefill response
    });
    test('api_admin_gateway_update_response callbacks', () async {
      client.connectAndPrefillPrivateMetadata();

      streamController.add({
        "schema": "api_admin_gateway_update_response",
        "successful_updates": ["A", "B", "C"],
        "failed_updates": ["D", "E", "F"]
      });

      await Future.delayed(const Duration(milliseconds: 100));

      verify(mockOnUpdated.call(["A", "B", "C"], ["D", "E", "F"])).called(1);
    });

    test("Validate submitUpdates", () async {
      client.connectAndPrefillPrivateMetadata();
      String baseUrl = "example.com";
      final headers = {"header_1": "1", "header_2": "2"};
      final webSocketSink = MockWebSocketSink();

      void triggerFuture() {
        streamController.add({
          "schema": "api_admin_gateway_update_response",
          "successful_updates": [],
          "failed_updates": []
        });
      }

      when(mockChannel.sink).thenReturn(webSocketSink);
      // Update everything
      var future = client.submitUpdates(
          apiHeaders: headers,
          baseUrl: baseUrl,
          apiName: "a-random-name",
          earningRate: 9,
          earningType: ChargingChoice.perRequest,
          docs: "some documentation");
      triggerFuture();
      await future;
      Map<String, dynamic> message = {
        "schema": "api_admin_gateway_update_request",
        "schema_version": "1.0",
        "updates": {
          "api_credentials": {
            "url": "example.com",
            "header_1": "1",
            "header_2": "2"
          },
          "name": "a-random-name",
          "asset_earning_rate": 9,
          "asset_earning_type": "per_request",
          "docs": "some documentation"
        }
      };
      verify(webSocketSink.add(jsonEncode(message))).called(1);

      // don't update headers
      future = client.submitUpdates(
          baseUrl: baseUrl,
          apiName: "a-random-name",
          earningRate: 9,
          earningType: ChargingChoice.perRequest,
          docs: "some documentation");
      triggerFuture();
      await future;
      message = {
        "schema": "api_admin_gateway_update_request",
        "schema_version": "1.0",
        "updates": {
          "api_credentials": {
            "url": "example.com",
          },
          "name": "a-random-name",
          "asset_earning_rate": 9,
          "asset_earning_type": "per_request",
          "docs": "some documentation"
        }
      };
      verify(webSocketSink.add(jsonEncode(message))).called(1);

      // don't update name or headers
      future = client.submitUpdates(
          baseUrl: baseUrl,
          earningRate: 9,
          earningType: ChargingChoice.perRequest,
          docs: "some documentation");
      triggerFuture();
      await future;
      message = {
        "schema": "api_admin_gateway_update_request",
        "schema_version": "1.0",
        "updates": {
          "api_credentials": {
            "url": "example.com",
          },
          "asset_earning_rate": 9,
          "asset_earning_type": "per_request",
          "docs": "some documentation"
        }
      };
      verify(webSocketSink.add(jsonEncode(message))).called(1);

      // per_second update instead
      future = client.submitUpdates(
          baseUrl: baseUrl,
          earningRate: 9,
          earningType: ChargingChoice.perSecond,
          docs: "some documentation");
      triggerFuture();
      await future;
      message = {
        "schema": "api_admin_gateway_update_request",
        "schema_version": "1.0",
        "updates": {
          "api_credentials": {
            "url": "example.com",
          },
          "asset_earning_rate": 9,
          "asset_earning_type": "per_second",
          "docs": "some documentation"
        }
      };
      verify(webSocketSink.add(jsonEncode(message))).called(1);

      // don't update docs
      future = client.submitUpdates(
        baseUrl: baseUrl,
        earningRate: 9,
        earningType: ChargingChoice.perSecond,
      );
      triggerFuture();
      await future;
      message = {
        "schema": "api_admin_gateway_update_request",
        "schema_version": "1.0",
        "updates": {
          "api_credentials": {
            "url": "example.com",
          },
          "asset_earning_rate": 9,
          "asset_earning_type": "per_second",
        }
      };
      verify(webSocketSink.add(jsonEncode(message))).called(1);

      // don't update any credentials
      future = client.submitUpdates(
        earningRate: 9,
        earningType: ChargingChoice.perSecond,
      );
      triggerFuture();
      await future;
      message = {
        "schema": "api_admin_gateway_update_request",
        "schema_version": "1.0",
        "updates": {
          "asset_earning_rate": 9,
          "asset_earning_type": "per_second",
        }
      };
      verify(webSocketSink.add(jsonEncode(message))).called(1);

      // don't update asset_earning_rate
      future = client.submitUpdates(
        earningType: ChargingChoice.perSecond,
      );
      triggerFuture();
      await future;
      message = {
        "schema": "api_admin_gateway_update_request",
        "schema_version": "1.0",
        "updates": {
          "asset_earning_type": "per_second",
        }
      };
      verify(webSocketSink.add(jsonEncode(message))).called(1);

      // don't update anything
      future = client.submitUpdates();
      triggerFuture();
      await future;
      verifyNever(webSocketSink.add(any));
    });
  });
}
