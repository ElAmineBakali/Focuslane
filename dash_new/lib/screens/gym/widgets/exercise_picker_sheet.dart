import 'package:flutter/material.dart';
import '../models/gym_models.dart';
import '../models/exercise_library_data.dart';

class ExercisePickerSheet extends StatefulWidget {
  final int order;
  final int restDefault;
  const ExercisePickerSheet({
    super.key,
    required this.order,
    required this.restDefault,
  });

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  String _query = '';
  final _setsCtrl = TextEditingController(text: '3');
  final _repsCtrl = TextEditingController(text: '10');
  final _restCtrl = TextEditingController();
  final _tempoCtrl = TextEditingController();
  final _rpeCtrl = TextEditingController();
  final _p1rmCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _restCtrl.text = '${widget.restDefault}';
  }

  @override
  Widget build(BuildContext context) {
    final results =
        kExerciseLibrary.where((e) {
          if (_query.isEmpty) return true;
          return e.name.toLowerCase().contains(_query.toLowerCase()) ||
              e.muscleGroup.toLowerCase().contains(_query.toLowerCase());
        }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('Añadir ejercicio')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar ejercicio',
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final ex = results[i];
                    return ListTile(
                      title: Text(ex.name),
                      subtitle: Text('${ex.category} • ${ex.muscleGroup}'),
                      onTap: () => _configureAndReturn(ex),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _configureAndReturn(ExerciseLibraryItem ex) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(ex.name),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _setsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Series'),
                  ),
                  TextField(
                    controller: _repsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps'),
                  ),
                  TextField(
                    controller: _restCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Descanso (s)',
                    ),
                  ),
                  TextField(
                    controller: _tempoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tempo (p. ej. 3-1-1)',
                    ),
                  ),
                  TextField(
                    controller: _rpeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'RPE objetivo',
                    ),
                  ),
                  TextField(
                    controller: _p1rmCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '%1RM objetivo',
                    ),
                  ),
                  TextField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notas'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Añadir'),
              ),
            ],
          ),
    );
    if (ok == true) {
      final e = RoutineExercise(
        id: '',
        exerciseId: ex.id,
        name: ex.name,
        muscleGroup: ex.muscleGroup,
        category: ex.category,
        targetSets: int.tryParse(_setsCtrl.text) ?? 3,
        targetReps: int.tryParse(_repsCtrl.text) ?? 10,
        restSec: int.tryParse(_restCtrl.text),
        order: widget.order,
        tempo: _tempoCtrl.text.trim().isEmpty ? null : _tempoCtrl.text.trim(),
        targetRPE:
            _rpeCtrl.text.trim().isEmpty
                ? null
                : double.tryParse(_rpeCtrl.text),
        targetPercent1RM:
            _p1rmCtrl.text.trim().isEmpty
                ? null
                : double.tryParse(_p1rmCtrl.text),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      // ignore: use_build_context_synchronously
      Navigator.pop(context, e);
    }
  }
}
