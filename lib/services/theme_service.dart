import 'package:flutter/material.dart';
import 'persistence_service.dart';

class ThemeService with ChangeNotifier {
  static const String _colorKey = 'theme_seed_color';
  static const String _modeKey = 'theme_mode';

  Color _seedColor = const Color(0xFF2F2A86);
  ThemeMode _themeMode = ThemeMode.dark;

  Color get seedColor => _seedColor;
  ThemeMode get themeMode => _themeMode;

  ThemeService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final colorList = await PersistenceService.getList(_colorKey);
    if (colorList.isNotEmpty) {
      _seedColor = Color(int.parse(colorList.first));
    }

    final modeList = await PersistenceService.getList(_modeKey);
    if (modeList.isNotEmpty) {
      _themeMode = modeList.first == 'dark' ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    await PersistenceService.saveList(_colorKey, [color.toARGB32().toString()]);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await PersistenceService.saveList(_modeKey, [mode == ThemeMode.dark ? 'dark' : 'light']);
    notifyListeners();
  }
}
