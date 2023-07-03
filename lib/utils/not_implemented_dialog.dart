import 'package:flutter/material.dart';

import 'package:dhali/analytics/analytics.dart';

void showNotImplentedWidget(
    {required BuildContext context, String? feature, String? message}) {
  showDialog(
      context: context,
      builder: (BuildContext _) {
        gtag(
            command: "event",
            target: "NotImplementedShown",
            parameters: {"feature": feature});
        const String contentStart = "This is not your fault!";
        return AlertDialog(
            title: const Text(
              "This feature has not been implemented yet.",
              textAlign: TextAlign.center,
            ),
            content: Text(
                message == null ? contentStart : "$contentStart\n$message",
                textAlign: TextAlign.center));
      });
}
