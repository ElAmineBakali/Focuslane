import 'package:flutter/material.dart';
import '../services/study_firestore_service.dart';
import '../models/study_models.dart';

class CourseEditSheet extends StatefulWidget {
  final StudyFirestoreService svc;
  final Course? initial;
  const CourseEditSheet({super.key, required this.svc, this.initial});

  @override
  State<CourseEditSheet> createState() => _CourseEditSheetState();
}

class _CourseEditSheetState extends State<CourseEditSheet> {
  final _name = TextEditingController();
  final _teacher = TextEditingController();
  final _credits = TextEditingController();
  final _goalHours = TextEditingController();
  final _colorHex = TextEditingController();

  /// ✅ NUEVO: % asistencia requerida (0–100)
  final _attendancePct = TextEditingController();

  static const _swatches = <int>[
    0xFF2962FF,
    0xFF00BFA5,
    0xFF43A047,
    0xFFF9A825,
    0xFFEF6C00,
    0xFFE53935,
    0xFF8E24AA,
    0xFF546E7A,
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    if (c != null) {
      _name.text = c.name;
      _teacher.text = c.teacher ?? '';
      _credits.text = c.credits?.toString() ?? '';
      _goalHours.text = c.goalHours?.toString() ?? '';
      _colorHex.text = c.colorHex ?? '';
      _attendancePct.text = c.attendanceRequired?.toString() ?? ''; // ✅
    }
  }

  Color? _selectedColorOrNull() {
    final raw = _colorHex.text.trim();
    if (raw.isEmpty) return null;
    try {
      return Color(int.parse(raw));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final previewColor = _selectedColorOrNull();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? 'Editar curso' : 'Nuevo curso',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: _teacher,
                decoration: const InputDecoration(
                  labelText: 'Profesor (opcional)',
                ),
              ),
              TextField(
                controller: _credits,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Créditos (opcional)',
                ),
              ),
              TextField(
                controller: _goalHours,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Objetivo de horas (opcional)',
                ),
              ),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Color',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Sin color'),
                    selected: _colorHex.text.trim().isEmpty,
                    onSelected: (_) => setState(() => _colorHex.text = ''),
                  ),
                  ..._swatches.map((hex) {
                    final c = Color(hex);
                    final sel = (previewColor?.toARGB32()) == c.toARGB32();
                    return ChoiceChip(
                      selected: sel,
                      label: const SizedBox(width: 0, height: 0),
                      avatar: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.black12),
                        ),
                      ),
                      onSelected:
                          (_) => setState(
                            () =>
                                _colorHex.text =
                                    '0x${hex.toRadixString(16).toUpperCase()}',
                          ),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 12),
              TextField(
                controller: _attendancePct,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Asistencia requerida (%)',
                  helperText: 'Ejemplo: 50 = 50% (opcional)',
                ),
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Vista previa:'),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor:
                        previewColor ?? Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final name = _name.text.trim();
                      if (name.isEmpty) return;

                      final attendance = double.tryParse(
                        _attendancePct.text.trim(),
                      );

                      final payload = Course(
                        id: widget.initial?.id ?? '',
                        name: name,
                        teacher:
                            _teacher.text.trim().isEmpty
                                ? null
                                : _teacher.text.trim(),
                        credits: double.tryParse(_credits.text),
                        goalHours: double.tryParse(_goalHours.text),
                        colorHex:
                            _colorHex.text.trim().isEmpty
                                ? null
                                : _colorHex.text.trim(),
                        attendanceRequired: attendance,
                      );

                      if (widget.initial == null) {
                        final id = await widget.svc.createCourse(payload);
                        final created = Course(
                          id: id,
                          name: payload.name,
                          teacher: payload.teacher,
                          credits: payload.credits,
                          goalHours: payload.goalHours,
                          colorHex: payload.colorHex,
                          attendanceRequired: payload.attendanceRequired,
                        );
                        Navigator.pop(context, created);
                      } else {
                        await widget.svc.updateCourse(widget.initial!.id, {
                          'name': payload.name,
                          'teacher': payload.teacher,
                          'credits': payload.credits,
                          'goalHours': payload.goalHours,
                          'colorHex': payload.colorHex,
                          'attendanceRequired': payload.attendanceRequired,
                        });
                        if (mounted) Navigator.pop(context, null);
                      }
                    },
                    child: Text(isEdit ? 'Guardar' : 'Crear'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
