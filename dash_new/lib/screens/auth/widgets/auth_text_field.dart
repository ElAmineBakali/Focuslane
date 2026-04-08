import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/design/ui/components/focus_text_field.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.prefixIcon,
    this.obscureText = false,
    this.validator,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return FocusTextField(
      label: label,
      hint: hint,
      controller: controller,
      keyboardType: keyboardType,
      prefixIcon: prefixIcon,
      obscureText: obscureText,
      validator: validator,
    );
  }
}
