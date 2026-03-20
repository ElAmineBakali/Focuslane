import 'package:flutter/material.dart';
import '../tokens/focuslane_tokens.dart';

/// Widget reutilizable para grids de KPIs responsive
/// - Móvil: 2x2 grid (2 columnas)
/// - Tablet: 2 columnas
/// - Desktop: 4 columnas
/// Mantiene tamaños y espacios consistentes en TODOS los módulos
class ResponsiveKpiGrid extends StatelessWidget {
  final List<Widget> children;
  final int? crossAxisCount;
  final double spacing;
  final double childAspectRatio;

  const ResponsiveKpiGrid({
    super.key,
    required this.children,
    this.crossAxisCount,
    this.spacing = FocuslaneTokens.spacing12,
    this.childAspectRatio = 2.8,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determinar número de columnas según el ancho
        final int cols = crossAxisCount ??
            (constraints.maxWidth >= 1200
                ? 4
                : constraints.maxWidth >= 600
                    ? 2
                    : 2); // Mobile siempre 2x2

        // Ajustar aspect ratio para desktop
        final double aspectRatio =
            constraints.maxWidth >= 600 ? 3.2 : childAspectRatio;

        // Si estamos en móvil y tenemos menos de 2 columnas, hacer una sola fila
        if (constraints.maxWidth < 600 && children.length == 1) {
          return SizedBox(
            child: children.first,
          );
        }

        return GridView.count(
          crossAxisCount: cols,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: aspectRatio,
          children: children,
        );
      },
    );
  }
}
