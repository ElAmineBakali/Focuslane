import 'package:flutter/material.dart';

import '../tokens/focuslane_tokens.dart';

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
    final compact = FocuslaneTokens.isCompact(context);
    final style = OutlinedButton.styleFrom(
      minimumSize: Size(0, FocuslaneTokens.buttonHeightFor(context)),
      padding: EdgeInsets.symmetric(
        horizontal: FocuslaneTokens.buttonHPaddingFor(context),
        vertical: FocuslaneTokens.buttonVPaddingFor(context),
      ),
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
              icon: Icon(icon, size: compact ? 17 : 18),
              label: Text(label),
            );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
