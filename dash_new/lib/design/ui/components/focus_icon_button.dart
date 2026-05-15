import 'package:flutter/material.dart';

import '../tokens/focuslane_tokens.dart';

class FocusIconButton extends StatelessWidget {
  const FocusIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.isActive = false,
    this.badge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isActive;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = isActive ? scheme.primary : scheme.onSurfaceVariant;
    final bg =
        isActive
            ? scheme.primaryContainer.withValues(alpha: 0.24)
            : scheme.surfaceContainerLow;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(FocuslaneTokens.radius8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(FocuslaneTokens.radius8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Icon(icon, color: tone, size: 20),
              ),
              if (badge)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: scheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: bg, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
