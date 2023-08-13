import 'package:flutter/material.dart';

import 'package:universal_html/html.dart';

bool isDesktopResolution(BuildContext context) {
  final userAgent = window.navigator.userAgent.toString().toLowerCase();
  final isMobile =
      (userAgent.contains('mobi') || userAgent.contains('android'));
  return !isMobile || MediaQuery.of(context).size.width > 720;
}
