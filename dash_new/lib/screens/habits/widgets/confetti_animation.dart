import 'dart:math';
import 'package:flutter/material.dart';

/// Widget de animación confeti al completar un hábito
class ConfettiAnimation extends StatefulWidget {
  final VoidCallback? onComplete;

  const ConfettiAnimation({super.key, this.onComplete});

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Generar partículas
    for (int i = 0; i < 50; i++) {
      _particles.add(_Particle(
        random: _random,
        colorScheme: Theme.of(context).colorScheme,
      ));
    }

    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ConfettiPainter(
        particles: _particles,
        progress: _controller.value,
      ),
      size: Size.infinite,
    );
  }
}

class _Particle {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late double rotation;
  late double rotationSpeed;
  late Color color;
  late double size;
  late ParticleShape shape;

  _Particle({required Random random, required ColorScheme colorScheme}) {
    // Posición inicial (centro-arriba)
    x = 0.3 + random.nextDouble() * 0.4;
    y = 0.3;

    // Velocidad
    vx = (random.nextDouble() - 0.5) * 0.8;
    vy = -0.3 - random.nextDouble() * 0.5;

    // Rotación
    rotation = random.nextDouble() * 2 * pi;
    rotationSpeed = (random.nextDouble() - 0.5) * 12;

    // Color (usa colores del theme)
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
    ];
    color = colors[random.nextInt(colors.length)];

    // Tamaño
    size = 6 + random.nextDouble() * 8;

    // Forma
    shape = ParticleShape.values[random.nextInt(ParticleShape.values.length)];
  }

  void update(double progress) {
    // Movimiento parabólico con gravedad
    x += vx * 0.016;
    y += vy * 0.016;
    vy += 1.5 * 0.016; // Gravedad

    // Rotación
    rotation += rotationSpeed * 0.016;

    // Desaceleración horizontal leve
    vx *= 0.99;
  }
}

enum ParticleShape { circle, square, triangle, star }

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      particle.update(progress);

      final paint = Paint()
        ..color = particle.color.withOpacity(1.0 - progress * 0.5)
        ..style = PaintingStyle.fill;

      final center = Offset(
        particle.x * size.width,
        particle.y * size.height,
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(particle.rotation);

      switch (particle.shape) {
        case ParticleShape.circle:
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
          break;

        case ParticleShape.square:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size,
            ),
            paint,
          );
          break;

        case ParticleShape.triangle:
          final path = Path()
            ..moveTo(0, -particle.size / 2)
            ..lineTo(particle.size / 2, particle.size / 2)
            ..lineTo(-particle.size / 2, particle.size / 2)
            ..close();
          canvas.drawPath(path, paint);
          break;

        case ParticleShape.star:
          final path = _createStarPath(particle.size);
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();
    }
  }

  Path _createStarPath(double size) {
    final path = Path();
    final double radius = size / 2;
    final double innerRadius = radius * 0.4;

    for (int i = 0; i < 10; i++) {
      final double angle = (i * pi / 5) - pi / 2;
      final double r = i.isEven ? radius : innerRadius;
      final double x = r * cos(angle);
      final double y = r * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}

/// Dialog para celebrar completar un hábito
class HabitCompletedDialog extends StatefulWidget {
  final String habitName;
  final String? emoji;
  final bool isPerfectDay;

  const HabitCompletedDialog({
    super.key,
    required this.habitName,
    this.emoji,
    this.isPerfectDay = false,
  });

  @override
  State<HabitCompletedDialog> createState() => _HabitCompletedDialogState();
}

class _HabitCompletedDialogState extends State<HabitCompletedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _showConfetti = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Ocultar confeti después de 2 segundos
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => _showConfetti = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Stack(
      children: [
        // Confeti
        if (_showConfetti)
          Positioned.fill(
            child: IgnorePointer(
              child: ConfettiAnimation(onComplete: () {}),
            ),
          ),

        // Dialog
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: EdgeInsets.all(isMobile ? 24 : 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primaryContainer,
                    cs.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono grande
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: isMobile ? 80 : 100,
                      height: isMobile ? 80 : 100,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: widget.emoji != null
                            ? Text(
                                widget.emoji!,
                                style: TextStyle(fontSize: isMobile ? 40 : 50),
                              )
                            : Icon(
                                Icons.check_circle_rounded,
                                color: cs.primary,
                                size: isMobile ? 50 : 60,
                              ),
                      ),
                    ),
                  ),

                  SizedBox(height: isMobile ? 16 : 20),

                  // Mensaje
                  Text(
                    widget.isPerfectDay ? '¡Día perfecto!' : '¡Bien hecho!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                      fontSize: isMobile ? 22 : 24,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: isMobile ? 8 : 12),

                  Text(
                    widget.isPerfectDay
                        ? 'Has completado todos tus hábitos 💯'
                        : 'Hábito "${widget.habitName}" completado ✨',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontSize: isMobile ? 14 : 15,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: isMobile ? 20 : 24),

                  // Botón
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24 : 32,
                        vertical: isMobile ? 12 : 14,
                      ),
                    ),
                    child: const Text('Continuar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
