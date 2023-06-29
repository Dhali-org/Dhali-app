import 'dart:html' as html;

import 'package:js/js.dart';
import 'package:js/js_util.dart';

import 'package:logger/logger.dart';

final Logger _logger = Logger();

// Docs used: https://developers.google.com/analytics/devguides/collection/ga4/event-parameters?client_type=gtag#about-event-parameters
@JS('gtag')
external void _gtag(String command, String target, [dynamic parameters]);

void gtag(
    {required String command,
    required String target,
    Map<String, dynamic>? parameters}) async {
  if (!hasProperty(html.window, 'gtag')) {
    _logger.w(
        "gtag function not found in the JavaScript global context. The requested analytic will not be emitted.");
    return;
  }
  if (parameters == null) {
    _gtag(command, target);
  } else {
    _gtag(command, target, jsify(parameters));
  }
}
