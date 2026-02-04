import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/components/focus_text_field.dart';

class AppTextField extends StatelessWidget {
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

  const AppTextField({
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
    return FocusTextField(
      label: label,
      hint: hint,
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffix: suffix,
      obscureText: obscureText,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
    );
  }
}
