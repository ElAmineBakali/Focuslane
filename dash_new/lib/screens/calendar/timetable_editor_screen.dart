import 'package:flutter/material.dart';
import 'models/calendar_models.dart';
import '../../screens/calendar/services/calendar_service.dart';

class TimetableEditorScreen extends StatefulWidget {
  final Timetable? timetable;
  const TimetableEditorScreen({super.key, this.timetable});

  @override
  State<TimetableEditorScreen> createState() => _TimetableEditorScreenState();
}

class _TimetableEditorScreenState extends State<TimetableEditorScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _isDefault = false;
  final _days = <String>{"Mon", "Tue", "Wed", "Thu", "Fri"};
  String _start = '07:00';
  String _end = '22:00';
  int _slot = 60;

  @override
  void initState() {
    super.initState();
    final t = widget.timetable;
    if (t != null) {
      _name.text = t.name;
      _isDefault = t.isDefault;
      _days
        ..clear()
        ..addAll(t.days);
      _start = t.startHour;
      _end = t.endHour;
      _slot = t.slotMinutes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = CalendarService.I;
    final t = widget.timetable;

    return Scaffold(
      appBar: AppBar(
        title: Text(t == null ? 'Nuevo horario' : 'Editar horario'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Requerido'
                                : null,
                  ),
                  SwitchListTile(
                    value: _isDefault,
                    onChanged: (v) => setState(() => _isDefault = v),
                    title: const Text('Predeterminado'),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final d in const [
                        "Mon",
                        "Tue",
                        "Wed",
                        "Thu",
                        "Fri",
                        "Sat",
                        "Sun",
                      ])
                        FilterChip(
                          label: Text(d),
                          selected: _days.contains(d),
                          onSelected:
                              (v) => setState(() {
                                if (v) {
                                  _days.add(d);
                                } else {
                                  _days.remove(d);
                                }
                              }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _start,
                          decoration: const InputDecoration(
                            labelText: 'Inicio (HH:mm)',
                          ),
                          onChanged: (v) => _start = v,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: _end,
                          decoration: const InputDecoration(
                            labelText: 'Fin (HH:mm)',
                          ),
                          onChanged: (v) => _end = v,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: '$_slot',
                          decoration: const InputDecoration(
                            labelText: 'Slot (min)',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _slot = int.tryParse(v) ?? 60,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                    onPressed: () async {
                      if (!_form.currentState!.validate()) return;
                      final obj = Timetable(
                        id: t?.id ?? '',
                        name: _name.text.trim(),
                        isDefault: _isDefault,
                        days: _days.toList()..sort((a, b) => a.compareTo(b)),
                        startHour: _start,
                        endHour: _end,
                        slotMinutes: _slot,
                      );
                      if (t == null) {
                        await svc.addTimetable(obj);
                      } else {
                        await svc.updateTimetable(obj);
                      }
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          if (widget.timetable != null)
            Expanded(child: _SlotsEditor(timetable: widget.timetable!)),
        ],
      ),
    );
  }
}

class _SlotsEditor extends StatelessWidget {
  final Timetable timetable;
  const _SlotsEditor({required this.timetable});

  @override
  Widget build(BuildContext context) {
    final svc = CalendarService.I;
    return StreamBuilder<List<TimetableSlot>>(
      stream: svc.watchSlots(timetable.id),
      builder: (context, s) {
        final list = s.data ?? const <TimetableSlot>[];
        return Column(
          children: [
            ListTile(
              title: const Text('Bloques'),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _editSlot(context, svc, timetable.id, null),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final x = list[i];
                  return ListTile(
                    leading: const Icon(Icons.event),
                    title: Text(x.title),
                    subtitle: Text(
                      '${x.day} • ${x.start}—${x.end} • ${x.type.name}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editSlot(context, svc, timetable.id, x),
                    ),
                    onLongPress: () => svc.deleteSlot(timetable.id, x.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editSlot(
    BuildContext context,
    CalendarService svc,
    String timetableId,
    TimetableSlot? s,
  ) async {
    final title = TextEditingController(text: s?.title ?? '');
    String day = s?.day ?? 'Mon';
    String start = s?.start ?? '09:00';
    String end = s?.end ?? '10:00';
    CalendarType type = s?.type ?? CalendarType.other;
    final note = TextEditingController(text: s?.note ?? '');

    await showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (ctx, setS) => AlertDialog(
                  title: Text(s == null ? 'Nuevo bloque' : 'Editar bloque'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: day,
                        items:
                            const [
                                  "Mon",
                                  "Tue",
                                  "Wed",
                                  "Thu",
                                  "Fri",
                                  "Sat",
                                  "Sun",
                                ]
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setS(() => day = v ?? day),
                        decoration: const InputDecoration(labelText: 'Día'),
                      ),
                      TextField(
                        controller: title,
                        decoration: const InputDecoration(labelText: 'Título'),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Inicio (HH:mm)',
                              ),
                              controller: TextEditingController(text: start),
                              onChanged: (v) => start = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Fin (HH:mm)',
                              ),
                              controller: TextEditingController(text: end),
                              onChanged: (v) => end = v,
                            ),
                          ),
                        ],
                      ),
                      DropdownButtonFormField<CalendarType>(
                        initialValue: type,
                        items:
                            CalendarType.values
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setS(() => type = v ?? type),
                        decoration: const InputDecoration(labelText: 'Tipo'),
                      ),
                      TextField(
                        controller: note,
                        decoration: const InputDecoration(
                          labelText: 'Nota (opcional)',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    if (s != null)
                      TextButton(
                        child: const Text('Eliminar'),
                        onPressed: () async {
                          await svc.deleteSlot(timetableId, s.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    TextButton(
                      child: const Text('Cancelar'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    FilledButton(
                      child: const Text('Guardar'),
                      onPressed: () async {
                        final obj = TimetableSlot(
                          id: s?.id ?? '',
                          day: day,
                          start: start,
                          end: end,
                          title:
                              title.text.trim().isEmpty
                                  ? 'Bloque'
                                  : title.text.trim(),
                          type: type,
                          note:
                              note.text.trim().isEmpty
                                  ? null
                                  : note.text.trim(),
                        );
                        if (s == null) {
                          await svc.addSlot(timetableId, obj);
                        } else {
                          await svc.updateSlot(timetableId, obj);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
          ),
    );
  }
}


