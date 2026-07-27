import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class GoogleApiHeaders {
  static Map<String, String> _headers = {};

  static Future<Map<String, String>> getHeaders() async {
    if (_headers.isNotEmpty) return _headers;
    if (kIsWeb) return _headers;

    final packageInfo = await PackageInfo.fromPlatform();

    if (Platform.isIOS) {
      _headers = {
        'X-Ios-Bundle-Identifier': packageInfo.packageName,
      };
    } else if (Platform.isAndroid) {
      _headers = {
        'X-Android-Package': packageInfo.packageName,
      };
    }

    return _headers;
  }
}
