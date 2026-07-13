import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/focus_home_screen.dart';
import 'screens/onboarding_screen.dart';

class KunstApp extends StatelessWidget {
  const KunstApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProxyProvider<SettingsProvider, ThemeProvider>(
          create: (_) => ThemeProvider(),
          update: (_, settingsProvider, themeProvider) {
            final provider = themeProvider ?? ThemeProvider();
            if (provider.currentThemeName != settingsProvider.theme) {
              provider.setTheme(settingsProvider.theme);
            }
            return provider;
          },
        ),
      ],
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settingsProvider, _) {
          if (!settingsProvider.loaded) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          final selectedTheme = settingsProvider.theme;
          if (themeProvider.currentThemeName != selectedTheme) {
            themeProvider.setTheme(selectedTheme);
          }

          return MaterialApp(
            title: 'KUNST Launcher',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            home: settingsProvider.firstLaunchComplete
                ? const FocusHomeScreen()
                : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
