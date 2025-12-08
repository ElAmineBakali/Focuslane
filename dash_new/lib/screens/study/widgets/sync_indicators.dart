import 'package:flutter/material.dart';

/// Widgets y utilidades para sincronización entre Study y Tasks
class SyncIndicators {
  /// Badge que muestra que la tarea está sincronizada
  static Widget syncBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sync_rounded,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'Sincronizado',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Ícono pequeño que indica sincronización
  static Widget syncIcon(BuildContext context, {double size = 16}) {
    return Icon(
      Icons.sync_rounded,
      size: size,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  /// Indicador de que la tarea no está sincronizada (sin sincronizar)
  static Widget unsyncBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 14,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 4),
          Text(
            'Sin sincronizar',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  /// Animación de sincronización (spinner)
  static Widget syncingSpinner(BuildContext context, {double size = 14}) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
