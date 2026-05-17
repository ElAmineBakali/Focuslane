import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/focuslane_tokens.dart';

class FocusProgressRing extends StatelessWidget {
  const FocusProgressRing({
    super.key,
    required this.value,
    this.size = 132,
    this.strokeWidth = 10,
    this.label,
    this.subtitle,
    this.color,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final String? label;
  final String? subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = value.clamp(0.0, 1.0);
    final tone = color ?? scheme.primary;
    final textLabel = label ?? '${(progress * 100).round()}%';
    final compact = FocuslaneTokens.isCompact(context);
    final resolvedSize = compact && size == 132 ? 108.0 : size;
    final resolvedStroke = compact && strokeWidth == 10 ? 8.0 : strokeWidth;

    return SizedBox(
      width: resolvedSize,
      height: resolvedSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(resolvedSize),
            painter: _RingPainter(
              value: progress,
              color: tone,
              trackColor: scheme.surfaceContainerHigh,
              strokeWidth: resolvedStroke,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                textLabel,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final center = rect.center;
    final trackPaint =
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    final valuePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
