import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/calendar/models/calendar_models.dart';

Future<void> showCalendarEventEditor({
  required BuildContext context,
  required CalendarEvent? event,
  DateTime? defaultDay,
  required String Function(DateTime value, bool allDay) humanDateTime,
  required Future<void> Function(CalendarEvent draft, bool isNew, DateTime when)
  onSave,
  required Future<void> Function(CalendarEvent event) onDelete,
}) async {
  final title = TextEditingController(text: event?.title ?? '');
  CalendarType type = event?.type ?? CalendarType.other;
  CalendarPriority priority = event?.priority ?? CalendarPriority.normal;
  bool allDay = event?.allDay ?? false;
  final notes = TextEditingController(text: event?.notes ?? '');
  DateTime when = event?.start ?? (defaultDay ?? DateTime.now());

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder:
        (ctx) => StatefulBuilder(
          builder: (ctx, setS) {
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
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
                            event == null ? 'Nuevo evento' : 'Editar evento',
                            style: Theme.of(ctx).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Cerrar',
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: title,
                        decoration: const InputDecoration(
                          labelText: 'Titulo del evento',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<CalendarType>(
                              initialValue: type,
                              items:
                                  CalendarType.values
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value.name),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) => setS(() => type = value ?? type),
                              decoration: const InputDecoration(
                                labelText: 'Tipo',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<CalendarPriority>(
                              initialValue: priority,
                              items:
                                  CalendarPriority.values
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value.name),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) =>
                                      setS(() => priority = value ?? priority),
                              decoration: const InputDecoration(
                                labelText: 'Prioridad',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SwitchListTile(
                        value: allDay,
                        onChanged: (value) => setS(() => allDay = value),
                        title: const Text('Todo el dia'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event),
                        title: Text(humanDateTime(when, allDay)),
                        onTap: () async {
                          final day = await showDatePicker(
                            context: ctx,
                            initialDate: when,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (!ctx.mounted) return;
                          if (day == null) return;

                          if (!allDay) {
                            final time = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay.fromDateTime(when),
                            );
                            if (!ctx.mounted) return;
                            setS(() {
                              when = DateTime(
                                day.year,
                                day.month,
                                day.day,
                                time?.hour ?? 9,
                                time?.minute ?? 0,
                              );
                            });
                          } else {
                            setS(
                              () =>
                                  when = DateTime(day.year, day.month, day.day),
                            );
                          }
                        },
                      ),
                      TextField(
                        controller: notes,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notas / detalles',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (event != null)
                            TextButton(
                              onPressed: () async {
                                await onDelete(event);
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              child: const Text('Eliminar'),
                            ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () async {
                              final draft = CalendarEvent(
                                id: event?.id ?? '',
                                title:
                                    title.text.trim().isEmpty
                                        ? 'Evento'
                                        : title.text.trim(),
                                type: type,
                                priority: priority,
                                start: when,
                                allDay: allDay,
                                end:
                                    allDay
                                        ? DateTime(
                                          when.year,
                                          when.month,
                                          when.day,
                                          23,
                                          59,
                                        )
                                        : event?.end,
                                notes:
                                    notes.text.trim().isNotEmpty
                                        ? notes.text.trim()
                                        : null,
                                relatedActionId: event?.relatedActionId,
                                relatedTxId: event?.relatedTxId,
                                dedupeKey: event?.dedupeKey,
                              );

                              await onSave(draft, event == null, when);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: const Text('Guardar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
  );
}
