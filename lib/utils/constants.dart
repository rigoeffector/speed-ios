import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

const String ENGLISH = 'en';
const String FRENCH = 'en';
const String LANGUAGE_CODE = 'languageCode';

class Strings {
  static const String appName = 'SPEED';
  static const String user = 'client';
}

Future<Locale> setLocale(String languageCode) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(LANGUAGE_CODE, languageCode);
  return _locale(languageCode);
}

Locale _locale(String languageCode) {
  Locale temp;
  switch (languageCode) {
    case ENGLISH:
      temp = Locale(languageCode, 'US');
      break;
    case FRENCH:
      temp = Locale(languageCode, 'FR');
      break;
    default:
      temp = Locale(languageCode, 'US');
  }
  return temp;
}

Future<Locale> getLocale() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? languageCode = prefs.getString(LANGUAGE_CODE) ?? ENGLISH;
  return _locale(languageCode);
}
