import 'package:flutter/material.dart';
import '../models/prenda_model.dart';

class PrendaCard extends StatelessWidget {
  final Prenda prenda;
  const PrendaCard({super.key, required this.prenda});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child:
                prenda.imagenes['thumb'] != null
                    ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        prenda.imagenes['thumb']!,
                        fit: BoxFit.cover,
                      ),
                    )
                    : Container(
                      decoration: BoxDecoration(
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: const Icon(Icons.checkroom, size: 48),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prenda.nombre,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _iconoEstado(prenda.estado),
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(prenda.estado.name),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconoEstado(EstadoPrenda estado) {
    switch (estado) {
      case EstadoPrenda.lavada:
        return Icons.check_circle;
      case EstadoPrenda.usada:
        return Icons.check;
      case EstadoPrenda.sucia:
        return Icons.cancel;
      case EstadoPrenda.lavandose:
        return Icons.refresh;
    }
  }
}

