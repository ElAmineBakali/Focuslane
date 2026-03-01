import 'package:flutter/material.dart';

class FocusLaneTitle extends StatelessWidget {
  const FocusLaneTitle({super.key, this.fontSize = 40});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final c1 = _tune(
      cs.primary,
      lightness: isDark ? 0.10 : 0.00,
      saturation: 0.10,
    );
    final c2 = _tune(
      cs.tertiary,
      lightness: isDark ? 0.00 : -0.05,
      saturation: 0.05,
    );
    final c3 = _tune(
      cs.secondary,
      lightness: isDark ? 0.12 : 0.02,
      saturation: 0.10,
    );

    final keyStr = '${c1.value}-${c2.value}-${c3.value}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          child: _GradientMask(
            key: ValueKey('text-$keyStr'),
            colors: [c1, c2, c3],
            child: Text(
              'FocusLane',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Color _tune(
    Color base, {
    double lightness = 0,
    double saturation = 0,
  }) {
    final hsl = HSLColor.fromColor(base);
    final l = (hsl.lightness + lightness).clamp(0.0, 1.0);
    final s = (hsl.saturation + saturation).clamp(0.0, 1.0);
    return hsl.withLightness(l).withSaturation(s).toColor();
  }
}

class _GradientMask extends StatelessWidget {
  const _GradientMask({super.key, required this.child, required this.colors});
  final Widget child;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback:
          (Rect rect) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ).createShader(rect),
      child: child,
    );
  }
}
