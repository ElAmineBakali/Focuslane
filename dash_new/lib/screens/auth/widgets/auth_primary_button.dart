import 'package:flutter/material.dart';
import 'package:focuslane/design/ui/components/focus_primary_button.dart';

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FocusPrimaryButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      fullWidth: true,
    );
  }
}

