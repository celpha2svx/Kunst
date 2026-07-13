import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  static const Map<String, String> _themeLabels = {
    'pure_black': 'Pure Black',
    'dark_grey': 'Dark Grey',
    'gunmetal': 'Gunmetal',
    'silver_dark': 'Silver Dark',
    'oled_saver': 'OLED Saver',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: _themeLabels.entries
              .map(
                (entry) => _ThemeChip(
                  label: entry.value,
                  value: entry.key,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final String value;

  const _ThemeChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final selected = settings.theme == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) async {
        await settings.setTheme(value);
      },
    );
  }
}
