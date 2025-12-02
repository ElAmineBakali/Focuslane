import 'package:flutter/material.dart';

class AppDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isDense: true,
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: color.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          hint: hint != null ? Text(hint!, style: TextStyle(color: color.onSurfaceVariant)) : null,
        ),
      ),
    );
  }
}
