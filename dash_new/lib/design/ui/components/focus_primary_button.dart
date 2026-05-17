import 'package:flutter/material.dart';

import '../tokens/focuslane_tokens.dart';

class FocusPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final Color? color;

  const FocusPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = color ?? cs.primary;
    final compact = FocuslaneTokens.isCompact(context);

    final style = FilledButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: cs.onPrimary,
      minimumSize: Size(0, FocuslaneTokens.buttonHeightFor(context)),
      padding: EdgeInsets.symmetric(
        horizontal: FocuslaneTokens.buttonHPaddingFor(context),
        vertical: FocuslaneTokens.buttonVPaddingFor(context),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    final loadingIcon = SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
    );

    final button =
        (icon != null || isLoading)
            ? FilledButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon:
                  isLoading ? loadingIcon : Icon(icon, size: compact ? 17 : 18),
              label: Text(label),
              style: style,
            )
            : FilledButton(
              onPressed: onPressed,
              style: style,
              child: Text(label),
            );

    if (!fullWidth) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}
