import 'package:flutter/material.dart';
import 'package:focuslane/screens/calendar/models/calendar_models.dart';

Future<void> showCalendarEventEditor({
  required BuildContext context,
  required CalendarEvent? event,
  DateTime? defaultDay,
  required String Function(DateTime value, bool allDay) humanDateTime,
  required Future<void> Function(CalendarEvent draft, bool isNew, DateTime when)
  onSave,
  required Future<void> Function(CalendarEvent event) onDelete,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return _CalendarEventEditorSheet(
        event: event,
        defaultDay: defaultDay,
        humanDateTime: humanDateTime,
        onSave: onSave,
        onDelete: onDelete,
      );
    },
  );
}

class _CalendarEventEditorSheet extends StatefulWidget {
  const _CalendarEventEditorSheet({
    required this.event,
    required this.defaultDay,
    required this.humanDateTime,
    required this.onSave,
    required this.onDelete,
  });

  final CalendarEvent? event;
  final DateTime? defaultDay;
  final String Function(DateTime value, bool allDay) humanDateTime;
  final Future<void> Function(CalendarEvent draft, bool isNew, DateTime when)
  onSave;
  final Future<void> Function(CalendarEvent event) onDelete;

  @override
  State<_CalendarEventEditorSheet> createState() =>
      _CalendarEventEditorSheetState();
}

class _CalendarEventEditorSheetState extends State<_CalendarEventEditorSheet> {
  late String _titleText;
  late String _notesText;

  late CalendarType _type;
  late CalendarPriority _priority;
  late bool _allDay;
  late DateTime _when;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleText = widget.event?.title ?? '';
    _notesText = widget.event?.notes ?? '';
    _type = widget.event?.type ?? CalendarType.other;
    _priority = widget.event?.priority ?? CalendarPriority.normal;
    _allDay = widget.event?.allDay ?? false;
    _when = widget.event?.start ?? (widget.defaultDay ?? DateTime.now());
  }

  Future<void> _pickDateTime() async {
    final day = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || day == null) return;

    if (!_allDay) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_when),
      );
      if (!mounted) return;
      setState(() {
        _when = DateTime(
          day.year,
          day.month,
          day.day,
          time?.hour ?? 9,
          time?.minute ?? 0,
        );
      });
      return;
    }

    setState(() {
      _when = DateTime(day.year, day.month, day.day);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final draft = CalendarEvent(
      id: widget.event?.id ?? '',
      title: _titleText.trim().isEmpty ? 'Evento' : _titleText.trim(),
      type: _type,
      priority: _priority,
      start: _when,
      allDay: _allDay,
      end: _allDay
          ? DateTime(_when.year, _when.month, _when.day, 23, 59)
          : widget.event?.end,
      notes: _notesText.trim().isNotEmpty ? _notesText.trim() : null,
      relatedActionId: widget.event?.relatedActionId,
      relatedTxId: widget.event?.relatedTxId,
      dedupeKey: widget.event?.dedupeKey,
    );

    try {
      await widget.onSave(draft, widget.event == null, _when);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo guardar el evento: $e')));
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final event = widget.event;
    if (event == null || _saving) return;
    setState(() => _saving = true);

    try {
      await widget.onDelete(event);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo eliminar el evento: $e')));
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final editing = widget.event != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    editing ? 'Editar evento' : 'Nuevo evento',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                initialValue: _titleText,
                onChanged: (value) => _titleText = value,
                decoration: const InputDecoration(labelText: 'Titulo del evento'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<CalendarType>(
                      initialValue: _type,
                      items: CalendarType.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.name),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _type = value ?? _type),
                      decoration: const InputDecoration(labelText: 'Tipo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<CalendarPriority>(
                      initialValue: _priority,
                      items: CalendarPriority.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.name),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _priority = value ?? _priority),
                      decoration: const InputDecoration(labelText: 'Prioridad'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                value: _allDay,
                onChanged: _saving ? null : (value) => setState(() => _allDay = value),
                title: const Text('Todo el dia'),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(widget.humanDateTime(_when, _allDay)),
                onTap: _saving ? null : _pickDateTime,
              ),
              TextFormField(
                initialValue: _notesText,
                onChanged: (value) => _notesText = value,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notas / detalles'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (editing)
                    TextButton(
                      onPressed: _saving ? null : _delete,
                      child: const Text('Eliminar'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Guardando...' : 'Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

