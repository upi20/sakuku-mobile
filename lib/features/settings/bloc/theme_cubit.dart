import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cubit untuk menyimpan & mengubah [ThemeMode] (light / dark / system).
/// State di-persist ke [SharedPreferences] sehingga bertahan antar session.
class ThemeCubit extends Cubit<ThemeMode> {
  static const _key = 'app_theme_mode';

  final SharedPreferences _prefs;

  ThemeCubit(this._prefs) : super(_loadSaved(_prefs));

  static ThemeMode _loadSaved(SharedPreferences prefs) {
    switch (prefs.getString(_key)) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  void setTheme(ThemeMode mode) {
    _prefs.setString(_key, mode.name);
    emit(mode);
  }

  void toggleDark() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setTheme(next);
  }
}
