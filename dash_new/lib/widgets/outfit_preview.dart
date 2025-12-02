import 'package:flutter/material.dart';
import '../models/outfit_model.dart';

class OutfitPreview extends StatelessWidget {
  final Outfit outfit;
  const OutfitPreview({super.key, required this.outfit});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(outfit.nombre,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(outfit.notas, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text("Veces usado: ${outfit.vecesUsado}"),
          ],
        ),
      ),
    );
  }
}
