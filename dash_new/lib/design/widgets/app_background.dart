import 'package:flutter/material.dart';
import '../theme/prefs.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, required this.style});

  final Widget child;
  final BackgroundStyle style;

  @override
  Widget build(BuildContext context) {
    try {
      final scheme = Theme.of(context).colorScheme;
      final surface = scheme.surface;
      final primary = scheme.primary;
      final primaryContainer = scheme.primaryContainer;

      final BoxDecoration decoration = switch (style) {
        BackgroundStyle.none => BoxDecoration(color: surface),
        BackgroundStyle.gradientSunrise => const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFEDD5), Color(0xFFFDE68A), Color(0xFFFECACA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        BackgroundStyle.gradientOcean => BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryContainer.withOpacity(0.35),
              primary.withOpacity(0.15),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        BackgroundStyle.gradientForest => const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        BackgroundStyle.gradientOrchid => const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3E8FF), Color(0xFFE9D5FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      };

      return Container(decoration: decoration, child: child);
    } catch (_) {
      return child;
    }
  }
}


