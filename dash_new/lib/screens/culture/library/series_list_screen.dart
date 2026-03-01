import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/shared/app_links.dart';
import '../../../screens/culture/services/culture_firestore_service.dart';
import '../models/culture_models.dart';

class SeriesListScreen extends StatefulWidget {
  const SeriesListScreen({super.key});
  static const route = '/culture/series';

  @override
  State<SeriesListScreen> createState() => _SeriesListScreenState();
}

class _SeriesListScreenState extends State<SeriesListScreen> {
  ItemStatus? _status;

  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anime'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Atajos',
            icon: const Icon(Icons.link_rounded),
            onSelected: (v) {
              if (v == 'crunchyroll') AppLinks.openCrunchyroll();
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(
                    value: 'crunchyroll',
                    child: Text('Crunchyroll'),
                  ),
                ],
          ),
          PopupMenuButton<ItemStatus?>(
            onSelected: (v) => setState(() => _status = v),
            itemBuilder:
                (_) => [
                  const PopupMenuItem(value: null, child: Text('Todas')),
                  ...ItemStatus.values.map(
                    (e) => PopupMenuItem(value: e, child: Text(e.name)),
                  ),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                () => Navigator.pushNamed(context, '/culture/series/edit'),
          ),
        ],
      ),
      body: StreamBuilder<List<Series>>(
        stream: svc.watchSeries(status: _status),
        builder: (_, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) return const Center(child: Text('Sin anime'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final x = data[i];
              return ListTile(
                leading: const Icon(Icons.tv),
                title: Text(x.title),
                subtitle: Text('${x.platform ?? "â€”"} â€¢ ${x.status.name}'),
                trailing: Text(x.rating?.toStringAsFixed(1) ?? '-'),
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      '/culture/series/detail',
                      arguments: x,
                    ),
              );
            },
          );
        },
      ),
    );
  }
}



