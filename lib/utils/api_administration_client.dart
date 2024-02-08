import 'dart:async';
import 'dart:convert';

import 'package:dhali/marketplace/marketplace_dialogs.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class APIAdminGatewayClient {
  final Logger _logger = Logger();
  final Completer<void> _prefillCompleter;
  Completer<Map<String, List<dynamic>>> _updatedCompleter;
  final WebSocketChannel _channel;
  final void Function(String qrUrl, String deepLink) _displayQrAuth;
  final void Function() _onAuthFailure;
  final void Function(List<dynamic> headers) _prefillHeaders;
  final void Function(String baseUrl) _prefillBaseUrl;
  final void Function(
          List<dynamic> successfulUpdateKeys, List<dynamic> failedUpdateKeys)
      _onUpdated;

  APIAdminGatewayClient(
      {required String uuid,
      required WebSocketChannel Function(String) getWebSocketChannel,
      required void Function(String qrUrl, String deepLink) displayQrAuth,
      required void Function() onAuthFailure,
      required void Function(List<dynamic>) prefillHeaders,
      required void Function(String baseUrl) prefillBaseUrl,
      required void Function(List<dynamic> successfulUpdateKeys,
              List<dynamic> failedUpdateKeys)
          onUpdated})
      : _channel = getWebSocketChannel(uuid),
        _prefillCompleter = Completer<void>(),
        _updatedCompleter = Completer<Map<String, List<dynamic>>>(),
        _displayQrAuth = displayQrAuth,
        _prefillHeaders = prefillHeaders,
        _prefillBaseUrl = prefillBaseUrl,
        _onUpdated = onUpdated,
        _onAuthFailure = onAuthFailure;

  Future<void> connectAndPrefillPrivateMetadata() async {
    // Resolves once all prefill callbacks have been called
    await _channel.ready;
    _channel.stream.listen((message) {
      _onMessageReceived(message);
    }, onDone: () {
      onDone();
    }, onError: (error) {
      onError(error);
    }, cancelOnError: true);
    return _prefillCompleter.future;
  }

  Future<Map<String, List<dynamic>>?> submitUpdates(
      {Map<String, String>? apiHeaders,
      String? baseUrl,
      String? apiName,
      double? earningRate,
      ChargingChoice? earningType,
      String? docs}) async {
    if (_updatedCompleter.isCompleted) {
      _updatedCompleter = Completer<Map<String, List<dynamic>>>();
    }
    var args = [apiHeaders, baseUrl, apiName, earningRate, earningType, docs];

    bool allNull = args.every((arg) => arg == null);
    if (allNull) {
      return null;
    }

    Map<String, dynamic> message = {
      "schema": "api_admin_gateway_update_request",
      "schema_version": "1.0",
      "updates": {}
    };

    if (baseUrl != null || apiHeaders != null) {
      Map<String, dynamic> apiCredentials;
      apiCredentials = {"api_credentials": {}};

      if (baseUrl != null) {
        apiCredentials["api_credentials"]["url"] = baseUrl;
      }

      if (apiHeaders != null) {
        apiCredentials["api_credentials"].addAll(apiHeaders);
      }
      message["updates"].addAll(apiCredentials);
    }

    if (apiName != null) {
      message["updates"]["name"] = apiName;
    }
    if (earningRate != null) {
      message["updates"]["asset_earning_rate"] = earningRate;
    }
    if (earningType == ChargingChoice.perSecond) {
      message["updates"]["asset_earning_type"] = "per_second";
    } else if (earningType == ChargingChoice.perRequest) {
      message["updates"]["asset_earning_type"] = "per_request";
    }

    if (docs != null) {
      message["updates"]["docs"] = docs;
    }

    _channel.sink.add(json.encode(message));
    return _updatedCompleter.future;
  }

  void _send(Map<String, String> message) {
    _channel.sink.add(json.encode(message));
  }

  void close() {
    _channel.sink.close();
  }

  void _onMessageReceived(dynamic message) {
    try {
      if (message.runtimeType == String) {
        message = jsonDecode(message) as Map<String, dynamic>;
      }
      final castedMessage = (message as Map<String, dynamic>);
      var schema = castedMessage["schema"];
      if (schema == "api_admin_gateway_qr_code") {
        _displayQrAuth(
            castedMessage["qr_code_url"]!, castedMessage["deep_link"]!);
      } else if (schema == "api_admin_gateway_authentication_successful") {
        _send({
          "schema": "api_admin_gateway_prefill_request",
          "schema_version": "1.0",
        });
      } else if (schema == "api_admin_gateway_authentication_failed") {
        _onAuthFailure();
      } else if (schema == "api_admin_gateway_prefill_response") {
        final preFillData = castedMessage["pre_fill_data"];
        _prefillBaseUrl(preFillData!["base_url"]!);
        _prefillHeaders(preFillData["headers"]!);
        _prefillCompleter.complete();
      } else if (schema == "api_admin_gateway_update_response") {
        final succussfulUpdates = message["successful_updates"]!;
        final failedUpdates = message["failed_updates"]!;
        _updatedCompleter.complete({
          "failed_updates": failedUpdates,
          "successful_updates": succussfulUpdates
        });
        _onUpdated(succussfulUpdates, failedUpdates);
      }
    } catch (e) {
      _logger.e("ERROR: _onMessageReceived raised the following exception: $e");
    }
  }

  void onDone() {
    // Implement based on your application needs
    print('WebSocket connection closed');
  }

  void onError(dynamic) {
    print("An error occured");
  }
}
