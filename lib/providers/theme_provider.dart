import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  String _currentTheme = 'dark_grey';

  String get currentThemeName => _currentTheme;

  final Map<String, ThemeData> themes = {
    'dark_grey': ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1e1e1e),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFe0e0e0),
        secondary: Color(0xFFa0a0a0),
        surface: Color(0xFF1e1e1e),
        background: Color(0xFF121212),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFe0e0e0)),
        bodyMedium: TextStyle(color: Color(0xFF888888)),
      ),
    ),
    'pure_black': ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF000000),
      cardColor: const Color(0xFF0a0a0a),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFffffff),
        secondary: Color(0xFF888888),
        surface: Color(0xFF0a0a0a),
        background: Color(0xFF000000),
      ),
    ),
    'gunmetal': ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF1a1a2e),
      cardColor: const Color(0xFF16213e),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFc0c0c0),
        secondary: Color(0xFF667eea),
        surface: Color(0xFF16213e),
        background: Color(0xFF1a1a2e),
      ),
    ),
    'silver_dark': ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF1c1c1c),
      cardColor: const Color(0xFF2a2a2a),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFd4d4d4),
        secondary: Color(0xFFc0c0c0),
        surface: Color(0xFF2a2a2a),
        background: Color(0xFF1c1c1c),
      ),
    ),
    'oled_saver': ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF050505),
      cardColor: const Color(0xFF0d0d0d),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFb0b0b0),
        secondary: Color(0xFF666666),
        surface: Color(0xFF0d0d0d),
        background: Color(0xFF050505),
      ),
    ),
  };

  ThemeData get currentTheme => themes[_currentTheme] ?? themes['dark_grey']!;

  void setTheme(String themeName) {
    if (themes.containsKey(themeName)) {
      if (_currentTheme == themeName) {
        return;
      }
      _currentTheme = themeName;
      notifyListeners();
    }
  }
}
