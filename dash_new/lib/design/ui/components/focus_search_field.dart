import 'package:flutter/material.dart';

import '../tokens/focuslane_tokens.dart';

class FocusSearchField extends StatelessWidget {
  const FocusSearchField({
    super.key,
    this.controller,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = FocuslaneTokens.isCompact(context);

    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(Icons.search_rounded, size: compact ? 18 : 20),
        prefixIconConstraints: BoxConstraints(minWidth: compact ? 34 : 40),
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 8 : 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocuslaneTokens.radius8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocuslaneTokens.radius8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocuslaneTokens.radius8),
          borderSide: BorderSide(color: scheme.primary),
        ),
      ),
    );
  }
}
