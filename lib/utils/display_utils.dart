import 'package:flutter/material.dart';

bool isDesktopResolution(BuildContext context) {
  return MediaQuery.of(context).size.width > 1200;
}
