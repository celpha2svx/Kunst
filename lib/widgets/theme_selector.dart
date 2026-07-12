import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Theme'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            _ThemeChip(label: 'Pure Black', value: 'pure_black'),
            _ThemeChip(label: 'Dark Grey', value: 'dark_grey'),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () async {
            await settings.setTheme(settings.theme == 'dark_grey' ? 'pure_black' : 'dark_grey');
            themeProvider.setTheme(settings.theme);
          },
          child: const Text('Toggle theme'),
        ),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final String value;

  const _ThemeChip({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final selected = settings.theme == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) async {
        await settings.setTheme(value);
        themeProvider.setTheme(value);
      },
    );
  }
}
