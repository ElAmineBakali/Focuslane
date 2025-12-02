import 'package:flutter/material.dart';
import '../../../services/culture_firestore_service.dart';
import '../../../models/culture_models.dart';
import 'series_edit_screen.dart';
import '../../../widgets/ui_scaffold.dart';

class SeriesDetailScreen extends StatefulWidget {
  const SeriesDetailScreen({super.key});
  static const route = '/culture/series/detail';

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  Series? series;

  final _s = TextEditingController(text: '1');
  final _e = TextEditingController(text: '1');
  final _title = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Series && series == null) series = arg;
  }

  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;
    if (series == null)
      return const Scaffold(body: Center(child: Text('Sin serie')));

    final x = series!;
    return Scaffold(
      appBar: AppBar(
        title: Text(x.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed:
                () => Navigator.pushNamed(
                  context,
                  SeriesEditScreen.route,
                  arguments: x,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await svc.deleteSeries(x.id);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: PaddedListView(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.tv),
              title: Text(x.platform ?? '—'),
              subtitle: Text(
                'Estado: ${x.status.name} • Rating: ${x.rating?.toStringAsFixed(1) ?? "-"}',
              ),
            ),
          ),

          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Episodios',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _s,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Temporada',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _e,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Nº Episodio',
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: 'Título (opcional)',
                    ),
                  ),
                  const SizedBox(height: 6),
                  FilledButton(
                    onPressed: () async {
                      final ep = Episode(
                        id: '',
                        season: int.tryParse(_s.text) ?? 1,
                        number: int.tryParse(_e.text) ?? 1,
                        title:
                            _title.text.trim().isEmpty
                                ? null
                                : _title.text.trim(),
                      );
                      await svc.addEpisode(x.id, ep);
                      _title.clear();
                    },
                    child: const Text('Añadir episodio'),
                  ),
                  const Divider(),
                  StreamBuilder<List<Episode>>(
                    stream: svc.watchEpisodes(x.id),
                    builder: (_, s) {
                      final data = s.data ?? [];
                      if (s.connectionState == ConnectionState.waiting)
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      if (data.isEmpty) return const Text('Sin episodios aún');
                      return Column(
                        children:
                            data
                                .map(
                                  (ep) => CheckboxListTile(
                                    value: ep.watched,
                                    onChanged:
                                        (v) => svc.setEpisodeWatched(
                                          x.id,
                                          ep,
                                          v == true,
                                        ),
                                    title: Text(
                                      'T${ep.season}E${ep.number} ${ep.title ?? ""}',
                                    ),
                                    subtitle:
                                        ep.watchedAt != null
                                            ? Text(
                                              'Visto: ${ep.watchedAt!.toLocal().toString().split(" ").first}',
                                            )
                                            : null,
                                    secondary: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed:
                                          () => svc.deleteEpisode(x.id, ep.id),
                                    ),
                                  ),
                                )
                                .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
