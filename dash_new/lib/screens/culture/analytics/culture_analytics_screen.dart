import 'package:flutter/material.dart';
import '../../../services/culture_firestore_service.dart';

class CultureAnalyticsScreen extends StatelessWidget {
  const CultureAnalyticsScreen({super.key});
  static const route = '/culture/analytics';

  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;
    return Scaffold(
      appBar: AppBar(title: const Text('Analíticas de Cultura')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: svc.quickKpis(),
        builder: (_, s) {
          final m = s.data ?? const {'booksDone': 0, 'moviesDone': 0, 'seriesDone': 0, 'gameHours': 0.0};
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _tile('Libros terminados', '${m['booksDone']}'),
              _tile('Películas vistas', '${m['moviesDone']}'),
              _tile('Series completadas', '${m['seriesDone']}'),
              _tile('Horas totales de juegos', (m['gameHours'] as double).toStringAsFixed(1)),
              const Divider(height: 24),
              const ListTile(
                title: Text('Siguientes ideas'),
                subtitle: Text('• Racha de lectura diaria\n• % de backlog completado\n• Tiempo medio por libro / serie / juego'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(String t, String s) => Card(child: ListTile(leading: const Icon(Icons.show_chart), title: Text(t), subtitle: Text(s)));
}
