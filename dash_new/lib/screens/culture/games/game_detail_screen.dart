import 'package:flutter/material.dart';
import '../../../services/culture_firestore_service.dart';
import '../../../models/culture_models.dart';
import 'game_edit_screen.dart';
import '../../../widgets/ui_scaffold.dart';

class GameDetailScreen extends StatefulWidget {
  const GameDetailScreen({super.key});
  static const route = '/culture/game';

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  Game? game;
  final _min = TextEditingController();
  final _note = TextEditingController();
  final _prog = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Game && game == null) game = arg;
  }

  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;
    if (game == null) return const Scaffold(body: Center(child: Text('Sin juego')));
    final g = game!;

    return Scaffold(
      appBar: AppBar(
        title: Text(g.title),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: ()=>Navigator.pushNamed(context, GameEditScreen.route, arguments: g)),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { await svc.deleteGame(g.id); if (mounted) Navigator.pop(context); }),
        ],
      ),
      body: PaddedListView(
        children: [
          Card(child: ListTile(
            leading: const Icon(Icons.sports_esports),
            title: Text('${g.platform} • ${g.hours.toStringAsFixed(1)} h'),
            subtitle: Text('Estado: ${g.status.name} • ${g.progressPct}% • Dificultad: ${g.difficulty ?? "-"} • Rating: ${g.rating?.toStringAsFixed(1) ?? "-"}'),
          )),
          if (g.notes != null && g.notes!.isNotEmpty) Card(child: ListTile(leading: const Icon(Icons.notes), title: const Text('Notas'), subtitle: Text(g.notes!))),

          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Sesiones de juego', style: Theme.of(context).textTheme.titleMedium),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _min, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minutos'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _prog, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Progreso % (después)'))),
                    ],
                  ),
                  TextField(controller: _note, decoration: const InputDecoration(labelText: 'Notas (opcional)')),
                  const SizedBox(height: 6),
                  FilledButton(
                    onPressed: () async {
                      final s = GameSession(
                        id: '', date: DateTime.now(),
                        minutes: int.tryParse(_min.text) ?? 0,
                        progressAfter: int.tryParse(_prog.text),
                        notes: _note.text.trim().isEmpty ? null : _note.text.trim(),
                      );
                      await svc.addGameSession(g.id, s);
                      _min.clear(); _prog.clear(); _note.clear();
                    },
                    child: const Text('Añadir sesión'),
                  ),
                  const Divider(),
                  StreamBuilder<List<GameSession>>(
                    stream: svc.watchGameSessions(g.id),
                    builder: (_, s) {
                      final data = s.data ?? [];
                      if (data.isEmpty) return const Text('Sin sesiones registradas');
                      return Column(
                        children: data.map((x) => ListTile(
                          leading: const Icon(Icons.timer),
                          title: Text('${x.minutes} min'),
                          subtitle: Text(
                            x.date.toLocal().toString().split('.').first +
                            (x.progressAfter!=null?' • ${x.progressAfter}%':'') +
                            (x.notes!=null?' • ${x.notes}':'')
                          ),
                        )).toList(),
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
