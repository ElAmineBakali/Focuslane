import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/navigation/app_routes.dart';
import '../services/study_firestore_service.dart';
import '../models/study_models.dart';
import '../../../design/ui/components/focus_module_header.dart';

class GradesScreen extends StatelessWidget {
  final StudyFirestoreService svc;
  final String? courseId;
  const GradesScreen({super.key, required this.svc, this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificaciones'),
        leading: FocusModuleHeader.buildLeading(
          context,
          mode: FocusModuleLeadingMode.backToModuleDashboard,
          backRouteName: AppRoutes.studyDashboard,
        ),
        leadingWidth: 96,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => _AddGradeDialog(svc: svc, courseId: courseId),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<GradeEntry>>(
        stream: svc.streamGrades(courseId: courseId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final grades = snap.data!;
          final avg =
              grades.isEmpty
                  ? 0.0
                  : (grades.map((g) => g.grade).reduce((a, b) => a + b) /
                      grades.length);
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.star_rate_rounded,
                    color: Colors.amber,
                  ),
                  title: const Text('Promedio'),
                  subtitle: Text(avg.toStringAsFixed(2)),
                ),
              ),
              const SizedBox(height: 8),
              ...grades.map(
                (g) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.assignment_turned_in),
                    title: Text('Tarea: ${g.taskId}'),
                    subtitle: Text(
                      'Nota: ${g.grade.toStringAsFixed(2)} • ${g.date.toLocal()}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (_) => _EditGradeDialog(svc: svc, grade: g),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddGradeDialog extends StatefulWidget {
  final StudyFirestoreService svc;
  final String? courseId;
  const _AddGradeDialog({required this.svc, this.courseId});
  @override
  State<_AddGradeDialog> createState() => _AddGradeDialogState();
}

class _AddGradeDialogState extends State<_AddGradeDialog> {
  String? _taskId;
  final _gradeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar calificación'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'ID de tarea'),
            onChanged: (v) => _taskId = v,
          ),
          TextField(
            decoration: const InputDecoration(labelText: 'Nota'),
            keyboardType: TextInputType.number,
            controller: _gradeCtrl,
          ),
          TextField(
            decoration: const InputDecoration(labelText: 'Notas (opcional)'),
            controller: _notesCtrl,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            final grade = double.tryParse(_gradeCtrl.text.trim());
            final taskId = _taskId;
            if (grade == null || taskId == null || taskId.isEmpty) return;
            final entry = GradeEntry(
              id: '',
              taskId: taskId,
              courseId: widget.courseId ?? '',
              grade: grade,
              date: DateTime.now(),
              notes:
                  _notesCtrl.text.trim().isEmpty
                      ? null
                      : _notesCtrl.text.trim(),
            );
            await widget.svc.addGrade(entry);
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _EditGradeDialog extends StatefulWidget {
  final StudyFirestoreService svc;
  final GradeEntry grade;
  const _EditGradeDialog({required this.svc, required this.grade});
  @override
  State<_EditGradeDialog> createState() => _EditGradeDialogState();
}

class _EditGradeDialogState extends State<_EditGradeDialog> {
  late final TextEditingController _gradeCtrl = TextEditingController(
    text: widget.grade.grade.toString(),
  );
  late final TextEditingController _notesCtrl = TextEditingController(
    text: widget.grade.notes ?? '',
  );
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar calificación'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Nota'),
            keyboardType: TextInputType.number,
            controller: _gradeCtrl,
          ),
          TextField(
            decoration: const InputDecoration(labelText: 'Notas (opcional)'),
            controller: _notesCtrl,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            final grade = double.tryParse(_gradeCtrl.text.trim());
            if (grade == null) return;
            await widget.svc.updateGrade(widget.grade.id, {
              'grade': grade,
              'notes':
                  _notesCtrl.text.trim().isEmpty
                      ? null
                      : _notesCtrl.text.trim(),
            });
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

