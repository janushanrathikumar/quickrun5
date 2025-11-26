import 'package:flutter/material.dart';

// 1. Translation Data Structure
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Define supported languages (English and German)
  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('de', ''), // German
  ];

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // 2. Map of translations for all keys
  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'login': 'Login',
      'signup': 'Sign up',
      'goToAdminLogin': 'Go to Admin Login',
      'adminLogin': 'Admin Login',
      'activeDrivers': 'Active Drivers Map',
      'goTo': 'Go to ',
    },
    'de': {
      'login': 'Anmelden',
      'signup': 'Registrieren',
      'goToAdminLogin': 'Gehe zu Admin-Anmeldung',
      'adminLogin': 'Admin-Anmeldung',
      'activeDrivers': 'Aktive Fahrer Karte',
      'goTo': 'Gehe zu ',
    },
  };

  // 3. Getter for a translated key
  String translate(String key) {
    return _localizedStrings[locale.languageCode]![key] ?? key;
  }
}

// 4. Delegate to load the translations
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .map((l) => l.languageCode)
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// 5. Locale State Management (Requires package:provider setup at application root)
class LocaleNotifier extends ChangeNotifier {
  Locale _locale = const Locale('de', '');

  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    if (AppLocalizations.supportedLocales.contains(newLocale)) {
      _locale = newLocale;
      notifyListeners();
    }
  }
}

// NOTE: You must wrap your MaterialApp with a ChangeNotifierProvider<LocaleNotifier>
// and configure the MaterialApp's localizationsDelegates and supportedLocales
// in your main.dart file for localization to work fully.
