import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final languageProvider = NotifierProvider<LanguageNotifier, Locale>(
  LanguageNotifier.new,
);

class LanguageNotifier extends Notifier<Locale> {
  static const _kLanguageKey = 'selected_language';

  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final languageCode = prefs.getString(_kLanguageKey);
    if (languageCode != null) {
      return Locale(languageCode);
    }
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kLanguageKey, locale.languageCode);
  }
}
