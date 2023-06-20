import 'package:flutter/material.dart';

import 'package:dhali/analytics/analytics.dart';

void showNotImplentedWidget({required BuildContext context, String? feature}) {
  showDialog(
      context: context,
      builder: (BuildContext _) {
        gtag(
            command: "event",
            target: "NotImplementedShown",
            parameters: {"feature": feature});
        return const AlertDialog(
          title: Text("This feature has not been implemented yet"),
          content: Text("This is not your fault!"),
        );
      });
}
