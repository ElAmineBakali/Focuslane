import 'package:flutter/material.dart';

class FocusSecondaryButton extends StatelessWidget {
  const FocusSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.fullWidth = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    final button =
        icon == null
            ? OutlinedButton(
              onPressed: onPressed,
              style: style,
              child: Text(label),
            )
            : OutlinedButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon, size: 18),
              label: Text(label),
            );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
