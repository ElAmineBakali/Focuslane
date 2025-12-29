import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CircularTimerWidget extends StatefulWidget {
  final int timeLeft;
  final int totalTime;
  final String phase;
  final Color color;
  final bool isRunning;

  const CircularTimerWidget({
    super.key,
    required this.timeLeft,
    required this.totalTime,
    required this.phase,
    required this.color,
    this.isRunning = false,
  });

  @override
  State<CircularTimerWidget> createState() => _CircularTimerWidgetState();
}

class _CircularTimerWidgetState extends State<CircularTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final s = seconds.abs();
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final r = s % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        widget.totalTime > 0 ? 1.0 - (widget.timeLeft / widget.totalTime) : 0.0;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue =
            widget.isRunning ? 1.0 + (_pulseController.value * 0.05) : 1.0;

        return Transform.scale(
          scale: pulseValue,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow:
                  widget.isRunning
                      ? [
                        BoxShadow(
                          color: widget.color.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ]
                      : [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
                ),
                CustomPaint(
                  size: const Size(280, 280),
                  painter: _CircularProgressPainter(
                    progress: progress,
                    color: widget.color,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(widget.timeLeft),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                        height: 1.0,
                      ),
                    ).animate(key: ValueKey(widget.timeLeft)).fadeIn(),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.phase.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;

    final backgroundPaint =
        Paint()
          ..color = backgroundColor.withOpacity(0.3)
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [color, color.withOpacity(0.6)],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    if (progress > 0 && progress < 1) {
      final glowPaint =
          Paint()
            ..color = color.withOpacity(0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final angle = -math.pi / 2 + sweepAngle;
      final glowX = center.dx + radius * math.cos(angle);
      final glowY = center.dy + radius * math.sin(angle);

      canvas.drawCircle(Offset(glowX, glowY), 8, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
