import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  String _currentTheme = 'dark_grey';

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
  };

  ThemeData get currentTheme => themes[_currentTheme] ?? themes['dark_grey']!;

  void setTheme(String themeName) {
    if (themes.containsKey(themeName)) {
      _currentTheme = themeName;
      notifyListeners();
    }
  }
}
