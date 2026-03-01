import 'package:flutter/material.dart';
import '../tokens/focuslane_tokens.dart';

class FocusSearchBar extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final VoidCallback? onClear;
  final IconData? prefixIcon;

  const FocusSearchBar({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.onClear,
    this.prefixIcon = Icons.search,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FocuslaneTokens.spacing12,
          vertical: 10,
        ),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        suffixIcon: onClear != null
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocuslaneTokens.radius16),
          borderSide: BorderSide(
            color: FocuslaneTokens.borderColor(context),
            width: FocuslaneTokens.borderW,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocuslaneTokens.radius16),
          borderSide: BorderSide(
            color: FocuslaneTokens.borderColor(context),
            width: FocuslaneTokens.borderW,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocuslaneTokens.radius16),
          borderSide: BorderSide(
            color: FocuslaneTokens.accent(context),
            width: FocuslaneTokens.borderW,
          ),
        ),
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
      ),
    );
  }
}
