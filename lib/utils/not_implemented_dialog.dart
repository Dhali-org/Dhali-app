
import 'package:flutter/material.dart';

void showNotImplentedWidget({required BuildContext context, String? feature}) {
  // TODO : Add logging of feature to Google Analytics
  showDialog(
      context: context,
      builder: (BuildContext _) {
        return const AlertDialog(
          title: Text("This feature has not been implemented yet"),
          content: Text("This is not your fault!"),
        );
      });
}
