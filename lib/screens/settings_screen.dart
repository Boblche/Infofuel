import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Apparence',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          RadioGroup<ThemeMode>(
            groupValue: themeProvider.mode,
            onChanged: (mode) => themeProvider.setMode(mode!),
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('Clair'),
                  secondary: Icon(Icons.light_mode_outlined),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Sombre'),
                  secondary: Icon(Icons.dark_mode_outlined),
                  value: ThemeMode.dark,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Système'),
                  secondary: Icon(Icons.brightness_auto_outlined),
                  value: ThemeMode.system,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
