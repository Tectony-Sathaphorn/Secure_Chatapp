import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleStorageKey = '__locale_key__';

class FFLocalizations {
  FFLocalizations(this.locale);

  final Locale locale;

  static FFLocalizations of(BuildContext context) =>
      Localizations.of<FFLocalizations>(context, FFLocalizations)!;

  static List<String> languages() => ['en', 'th'];

  static late SharedPreferences _prefs;
  static Future initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _prefs.getString(_kLocaleStorageKey) ?? '';
    return true;
  }

  static Future storeLocale(String locale) =>
      _prefs.setString(_kLocaleStorageKey, locale);

  static Locale? getStoredLocale() {
    final locale = _prefs.getString(_kLocaleStorageKey);
    return locale != null && locale.isNotEmpty
        ? createLocale(locale)
        : null;
  }

  String get languageCode => locale.toString();
  String? get languageShortCode =>
      _languagesWithShortCode.contains(locale.toString())
          ? '${locale.toString()}_short'
          : null;

  static const Set<String> _languagesWithShortCode = {
    'en',
    'th',
  };

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'Home': 'Home',
      'Chat': 'Chat',
      'Profile': 'Profile',
      'Send': 'Send',
      'Call': 'Call',
      'Settings': 'Settings',
      'Logout': 'Logout',
    },
    'th': {
      'Home': 'หน้าหลัก',
      'Chat': 'แชท',
      'Profile': 'โปรไฟล์',
      'Send': 'ส่ง',
      'Call': 'โทร',
      'Settings': 'ตั้งค่า',
      'Logout': 'ออกจากระบบ',
    },
  };

  String getText(String key) =>
      (_localizedValues[locale.toString()] ?? {})[key] ?? key;

  String getVariableText({
    String? enText = '',
    String? thText = '',
  }) =>
      [
        if (locale.toString() == 'en') enText,
        if (locale.toString() == 'th') thText,
      ].first ?? '';
}

Locale createLocale(String language) => language.contains('_')
    ? Locale.fromSubtags(
        languageCode: language.split('_').first,
        countryCode: language.split('_').last,
      )
    : Locale(language);

String getTranslated(BuildContext context, String key) {
  return FFLocalizations.of(context).getText(key);
}

class FFLocalizationsDelegate extends LocalizationsDelegate<FFLocalizations> {
  const FFLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    final language = locale.toString();
    return FFLocalizations.languages().contains(
      language.endsWith('_')
          ? language.substring(0, language.length - 1)
          : language,
    );
  }

  @override
  Future<FFLocalizations> load(Locale locale) =>
      SynchronousFuture<FFLocalizations>(FFLocalizations(locale));

  @override
  bool shouldReload(FFLocalizationsDelegate old) => false;
} 