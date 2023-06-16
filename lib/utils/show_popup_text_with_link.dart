import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher_string.dart';

void showPopupTextWithLink(
    {required String text,
    required String urlText,
    required String url,
    required BuildContext context}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: SelectableText.rich(
          TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(text: text),
              TextSpan(
                text: urlText,
                style: TextStyle(color: Colors.blue),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    if (await canLaunchUrlString(url)) {
                      await launchUrlString(url);
                    } else {
                      throw 'Could not launch $url';
                    }
                  },
              ),
            ],
          ),
        ),
      );
    },
  );
}
