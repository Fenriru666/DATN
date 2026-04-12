import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService extends ChangeNotifier {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal() {
    _loadLanguage();
  }

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language_code') ?? 'en';
    _locale = Locale(langCode);
    notifyListeners();
  }

  Future<void> changeLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', langCode);
    _locale = Locale(langCode);
    notifyListeners();
  }

  // Removed manual translate method and _vi map.
  // Use AppLocalizations.of(context) instead.
}
