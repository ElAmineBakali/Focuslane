import 'package:flutter/material.dart';
import '../models/plan_outfit_model.dart';

class CalendarDayTile extends StatelessWidget {
  final DateTime fecha;
  final List<PlanOutfit> planes;
  final VoidCallback onTap;

  const CalendarDayTile({
    super.key,
    required this.fecha,
    required this.planes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final planesDia =
        planes
            .where(
              (p) =>
                  p.fecha.year == fecha.year &&
                  p.fecha.month == fecha.month &&
                  p.fecha.day == fecha.day,
            )
            .toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          children: [
            Text(
              "${fecha.day}/${fecha.month}",
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            if (planesDia.isEmpty)
              const Text(
                "Sin outfit",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              )
            else
              ...planesDia.map(
                (p) =>
                    Text(p.estado.name, style: const TextStyle(fontSize: 10)),
              ),
          ],
        ),
      ),
    );
  }
}


