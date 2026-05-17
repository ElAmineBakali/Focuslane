import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/focuslane_tokens.dart';

class FocusTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? suffix;
  final bool obscureText;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const FocusTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.obscureText = false,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final compact = FocuslaneTokens.isCompact(context);

    final field = TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      obscureText: obscureText,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          vertical: compact ? 8 : 10,
          horizontal: 12,
        ),
        prefixIcon:
            prefixIcon != null
                ? Icon(prefixIcon, size: compact ? 17 : 18)
                : null,
        prefixIconConstraints: BoxConstraints(
          minWidth: compact ? 32 : 34,
          minHeight: compact ? 32 : 34,
        ),
        suffixIcon: suffixIcon,
        suffixText: suffix,
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
        hintStyle: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        ),
        labelStyle: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        ),
      ),
    );

    if (maxLines == 1) {
      return SizedBox(height: compact ? 38 : 40, child: field);
    }

    return field;
  }
}
