import 'package:flutter/material.dart';
import '../tokens/focuslane_tokens.dart';

class FocusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const FocusChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tone = color ?? FocuslaneTokens.accent(context);

    final chip = InputChip(
      label: Text(label),
      avatar: icon != null ? Icon(icon, size: 16, color: tone) : null,
      onPressed: onTap,
      onDeleted: onDelete,
      backgroundColor: tone.withOpacity(0.1),
      side: BorderSide(color: tone.withOpacity(0.18)),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: tone,
            fontWeight: FontWeight.w600,
          ),
      deleteIconColor: tone,
    );

    return chip;
  }
}
