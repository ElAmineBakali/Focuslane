import 'package:flutter/material.dart';

import '../services/skills_firestore_service.dart';
import '../models/skills_models.dart';
import 'package:mi_dashboard_personal/widgets/ui_scaffold.dart';

class SkillEditScreen extends StatefulWidget {
  const SkillEditScreen({super.key});
  static const route = '/skills/edit';

  @override
  State<SkillEditScreen> createState() => _SkillEditScreenState();
}

class _SkillEditScreenState extends State<SkillEditScreen> {
  final _form = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _motivation = TextEditingController();
  final _outcome = TextEditingController();
  final _contextCtl = TextEditingController();

  SkillLevel _current = SkillLevel.novice;
  SkillLevel _target = SkillLevel.intermediate;
  DateTime? _targetDate;

  final _tags = TextEditingController();
  final Map<String, String> _metrics = {}; // nombre->unidad

  Skill? editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Skill && editing == null) {
      editing = arg;
      _name.text = arg.name;
      _desc.text = arg.description;
      _motivation.text = arg.motivation;
      _outcome.text = arg.desiredOutcome;
      _contextCtl.text = arg.context;
      _current = arg.currentLevel;
      _target = arg.targetLevel;
      _targetDate = arg.targetDate;
      _tags.text = arg.tags.join(',');
      _metrics.addAll(arg.metricsConfig);
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = SkillsFirestoreService.I;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    InputDecoration deco(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(editing == null ? 'Nueva habilidad' : 'Editar habilidad'),
      ),
      body: TaskFormTheme(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, screenPad(context)),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre
                TextFormField(
                  controller: _name,
                  decoration: deco('Nombre (Guitarra, Ilustración, Cocina...)'),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _desc,
                  decoration: deco('Descripción / ¿qué es?'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Motivación
                TextFormField(
                  controller: _motivation,
                  decoration: deco('Motivación (¿por qué?)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Resultado deseado
                TextFormField(
                  controller: _outcome,
                  decoration: deco('Resultado deseado'),
                ),
                const SizedBox(height: 16),

                // Contexto
                TextFormField(
                  controller: _contextCtl,
                  decoration: deco(
                    'Contexto (herramientas, recursos, bloqueos)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Niveles y meta
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<SkillLevel>(
                        initialValue: _current,
                        decoration: deco('Nivel actual'),
                        items:
                            SkillLevel.values
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(skillLevelLabel(e)),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (v) => setState(() => _current = v ?? _current),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<SkillLevel>(
                        initialValue: _target,
                        decoration: deco('Objetivo'),
                        items:
                            SkillLevel.values
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(skillLevelLabel(e)),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (v) => setState(() => _target = v ?? _target),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Fecha meta (estilo tareas)
                Text('Fecha objetivo', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _targetDate == null
                            ? 'Sin fecha seleccionada'
                            : _targetDate!
                                .toLocal()
                                .toString()
                                .split(' ')
                                .first,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _targetDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setState(() => _targetDate = d);
                      },
                      icon: const Icon(Icons.event),
                      label: const Text('Elegir fecha'),
                    ),
                  ],
                ),

                const Divider(height: 32),

                // Métricas
                Text(
                  'Métricas específicas (nombre y unidad, p.ej. "BPM" - "bpm", "Precisión" - "%")',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                ..._metrics.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: e.key,
                            readOnly: true,
                            decoration: deco('Métrica'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: e.value,
                            onChanged: (v) => _metrics[e.key] = v,
                            decoration: deco('Unidad'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed:
                              () => setState(() => _metrics.remove(e.key)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Tags + añadir métrica
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tags,
                        decoration: deco('Tags (coma)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir métrica'),
                      onPressed: () async {
                        final name = await _promptStr('Nombre de la métrica');
                        if (name == null || name.trim().isEmpty) return;
                        final unit = await _promptStr(
                          'Unidad/ayuda (p.ej. %, bpm, min)',
                        );
                        setState(
                          () => _metrics[name.trim()] = unit?.trim() ?? '',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Guardar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                    onPressed: () async {
                      if (!_form.currentState!.validate()) return;
                      final obj = Skill(
                        id: editing?.id ?? '',
                        name: _name.text.trim(),
                        description: _desc.text.trim(),
                        motivation: _motivation.text.trim(),
                        desiredOutcome: _outcome.text.trim(),
                        context: _contextCtl.text.trim(),
                        currentLevel: _current,
                        targetLevel: _target,
                        targetDate: _targetDate,
                        tags:
                            _tags.text
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList(),
                        metricsConfig: _metrics,
                        totalHours: editing?.totalHours ?? 0,
                        streakDays: editing?.streakDays ?? 0,
                      );
                      if (editing == null) {
                        await svc.addSkill(obj);
                      } else {
                        await svc.updateSkill(obj);
                      }
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                if (editing != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar'),
                      onPressed: () async {
                        await svc.deleteSkill(editing!.id);
                        if (mounted) Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _promptStr(String title) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: TextField(controller: c, autofocus: true),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, c.text),
                child: const Text('Aceptar'),
              ),
            ],
          ),
    );
  }
}
