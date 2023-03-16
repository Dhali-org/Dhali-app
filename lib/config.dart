library dhali.globals;

import 'dart:convert';

import 'package:flutter/services.dart';

// TODO
//
// At the moment, we have:
//
// some_firestore_value[private_config["SOME_KEY"]] = "TEST"
//
// class PrivateConfig()
//   def get_some_key():
//     return __private_config["SOME_KEY"]
//
// TODO Also, we should consider versioning configs:
//
// Config: {
//   "v1.0": {
//     "SOME_KEY": "SOME_KEY_VALUE"
//   }
//   "v1.4": {
//     "SOME_KEY": "SOME_KEY_VALUE"
//     "SOME_OTHER_KEY": "SOME_OTHER_KEY_VALUE"
//   }
// }

class Config {
  static Map<String, dynamic>? config;
  static Future<void> loadConfig() async {
    final jsonString = await rootBundle.loadString('assets/public.json');
    config = jsonDecode(jsonString);
  }
}
