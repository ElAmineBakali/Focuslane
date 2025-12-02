import 'package:flutter/material.dart';

class ThemeToggle extends StatelessWidget {
  final Function(bool) toggleTheme;
  final ThemeMode themeMode;

  const ThemeToggle({
    super.key,
    required this.toggleTheme,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Tema oscuro'),
        Switch(
          value: themeMode == ThemeMode.dark,
          onChanged: toggleTheme,
        ),
      ],
    );
  }
}
