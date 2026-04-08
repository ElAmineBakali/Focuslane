import 'package:flutter/material.dart';

class AuthSecondaryLink extends StatelessWidget {
  const AuthSecondaryLink({
    super.key,
    required this.label,
    required this.actionLabel,
    required this.onTap,
  });

  final String label;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: textTheme.bodySmall),
        TextButton(onPressed: onTap, child: Text(actionLabel)),
      ],
    );
  }
}
