import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/onboarding_screen.dart';

class KunstApp extends StatelessWidget {
  const KunstApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'KUNST Launcher',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            home: const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
