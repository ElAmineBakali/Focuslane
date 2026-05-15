import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/screens/calendar/models/calendar_models.dart';

class CalendarItemVisuals {
  static Color colorForItem(BuildContext context, CalendarItem item) {
    final scheme = Theme.of(context).colorScheme;
    if (item.priority == CalendarPriority.high) return Colors.redAccent;
    switch (item.type) {
      case CalendarType.task:
        return scheme.primary;
      case CalendarType.study:
        return scheme.secondary;
      case CalendarType.gym:
        return scheme.tertiary;
      case CalendarType.finance:
        return scheme.error;
      case CalendarType.food:
        return scheme.secondary;
      case CalendarType.other:
        return scheme.outline;
    }
  }

  static IconData iconFor(CalendarType type) {
    switch (type) {
      case CalendarType.task:
        return Icons.checklist;
      case CalendarType.study:
        return Icons.school;
      case CalendarType.gym:
        return Icons.fitness_center;
      case CalendarType.finance:
        return Icons.payments;
      case CalendarType.food:
        return Icons.restaurant;
      case CalendarType.other:
        return Icons.event_note;
    }
  }

  static String sourceLabel(CalendarSourceModule source) {
    switch (source) {
      case CalendarSourceModule.planner:
        return 'Calendario';
      case CalendarSourceModule.task:
        return 'Tareas';
      case CalendarSourceModule.study:
        return 'Estudio';
      case CalendarSourceModule.gym:
        return 'Gimnasio';
      case CalendarSourceModule.food:
        return 'Alimentación';
      case CalendarSourceModule.finance:
        return 'Finanzas';
      case CalendarSourceModule.habit:
        return 'Hábitos';
    }
  }

  static String timeLabel(CalendarItem item) {
    if (item.isAllDay) return 'Todo el día';
    final h = item.startAt.hour.toString().padLeft(2, '0');
    final m = item.startAt.minute.toString().padLeft(2, '0');
    if (item.endAt == null) return '$h:$m';
    final eh = item.endAt!.hour.toString().padLeft(2, '0');
    final em = item.endAt!.minute.toString().padLeft(2, '0');
    return '$h:$m-$eh:$em';
  }

  static String agendaSubtitle(CalendarItem item) {
    final parts = <String>[
      timeLabel(item),
      sourceLabel(item.sourceModule),
      if ((item.description ?? '').trim().isNotEmpty) item.description!.trim(),
    ];
    return parts.join(' · ');
  }
}

class CalendarFilterChips extends StatelessWidget {
  const CalendarFilterChips({
    super.key,
    required this.prefs,
    required this.onTypeToggle,
    required this.onHighOnlyToggle,
  });

  final PlannerPrefs? prefs;
  final Future<void> Function(CalendarType type, bool value) onTypeToggle;
  final Future<void> Function(bool value) onHighOnlyToggle;

  @override
  Widget build(BuildContext context) {
    final p = prefs;
    if (p == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    FilterChip chip(CalendarType t, String label, IconData icon) {
      final selected = p.enabled.contains(t);
      return FilterChip(
        label: Text(label),
        selected: selected,
        avatar: Icon(icon, size: 18),
        onSelected: (v) => onTypeToggle(t, v),
        selectedColor: scheme.primaryContainer.withValues(alpha: 0.55),
        backgroundColor: scheme.surfaceContainerLowest,
        side: BorderSide(
          color:
              selected
                  ? scheme.primary.withValues(alpha: 0.36)
                  : scheme.outlineVariant,
        ),
      );
    }

    return FocusCard(
      padding: const EdgeInsets.all(14),
      elevated: false,
      backgroundColor: scheme.surfaceContainerLow,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          chip(CalendarType.task, 'Tareas', Icons.checklist_rounded),
          chip(CalendarType.study, 'Estudio', Icons.school_rounded),
          chip(CalendarType.gym, 'Gimnasio', Icons.fitness_center_rounded),
          chip(CalendarType.finance, 'Pagos', Icons.payments_rounded),
          chip(CalendarType.food, 'Comidas', Icons.restaurant_rounded),
          chip(CalendarType.other, 'Otros', Icons.event_note_rounded),
          FilterChip(
            label: const Text('Prioridad alta'),
            selected: p.highOnly,
            avatar: const Icon(Icons.priority_high_rounded, size: 18),
            onSelected: onHighOnlyToggle,
            selectedColor: scheme.errorContainer.withValues(alpha: 0.62),
            backgroundColor: scheme.surfaceContainerLowest,
            side: BorderSide(
              color:
                  p.highOnly
                      ? scheme.error.withValues(alpha: 0.36)
                      : scheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarDayNumberCell extends StatelessWidget {
  const CalendarDayNumberCell({super.key, required this.day, this.bg, this.fg});

  final int day;
  final Color? bg;
  final Color? fg;

  @override
  Widget build(BuildContext context) {
    final child = Center(child: Text('$day', style: TextStyle(color: fg)));
    if (bg == null) return child;
    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: child,
      ),
    );
  }
}

class CalendarDayNumberRing extends StatelessWidget {
  const CalendarDayNumberRing({
    super.key,
    required this.day,
    required this.border,
    this.textColor,
  });

  final int day;
  final Color border;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: border, width: 2),
        ),
        alignment: Alignment.center,
        child: Text('$day', style: TextStyle(color: textColor)),
      ),
    );
  }
}

class CalendarMiniActionIcon extends StatelessWidget {
  const CalendarMiniActionIcon({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: .55),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 11),
      ),
    );
  }
}

class CalendarScrollBehavior extends MaterialScrollBehavior {
  const CalendarScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class CalendarDayItemList extends StatelessWidget {
  const CalendarDayItemList({
    super.key,
    required this.items,
    required this.onTap,
    required this.onDelete,
    this.scrollable = false,
  });

  final List<CalendarItem> items;
  final ValueChanged<CalendarItem> onTap;
  final ValueChanged<String> onDelete;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const FocusEmptyState(
        icon: Icons.event_available_rounded,
        message: 'No hay eventos para este día',
        subtitle: 'Puedes crear uno desde el botón de nuevo evento.',
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      shrinkWrap: !scrollable,
      physics:
          scrollable
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final item = items[i];
        final icon = CalendarItemVisuals.iconFor(item.type);
        final color = CalendarItemVisuals.colorForItem(context, item);

        final timeLabel = CalendarItemVisuals.timeLabel(item);

        final isCompleted =
            item.type == CalendarType.task && item.completed == true;
        final titleStyle = TextStyle(
          decoration:
              isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
          color: isCompleted ? scheme.onSurface.withValues(alpha: .65) : null,
        );

        return Material(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => onTap(item),
            onLongPress: item.isEditable ? () => onDelete(item.id) : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                          isCompleted
                              ? scheme.surfaceContainerHigh
                              : color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.22)),
                    ),
                    child: Icon(
                      icon,
                      color: isCompleted ? scheme.onSurfaceVariant : color,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FocusChip(
                              label: timeLabel,
                              icon: Icons.schedule_rounded,
                              color: color,
                            ),
                            FocusChip(
                              label: CalendarItemVisuals.sourceLabel(
                                item.sourceModule,
                              ),
                              icon: Icons.hub_outlined,
                              color: scheme.secondary,
                            ),
                            if (item.priority == CalendarPriority.high)
                              FocusChip(
                                label: 'Alta prioridad',
                                icon: Icons.priority_high_rounded,
                                color: scheme.error,
                              ),
                          ],
                        ),
                        if ((item.description ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            item.description!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    item.isEditable
                        ? Icons.edit_outlined
                        : Icons.open_in_new_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CalendarAllDayItemChip extends StatelessWidget {
  const CalendarAllDayItemChip({
    super.key,
    required this.item,
    required this.onTap,
    required this.canMove,
  });

  final CalendarItem item;
  final VoidCallback onTap;
  final bool canMove;

  @override
  Widget build(BuildContext context) {
    final color = CalendarItemVisuals.colorForItem(context, item);

    final chip = InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 96, maxWidth: 230),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: .14),
          border: Border.all(color: color.withValues(alpha: .40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CalendarItemVisuals.iconFor(item.type),
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                item.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );

    if (!canMove) return chip;

    return LongPressDraggable<CalendarItem>(
      data: item,
      maxSimultaneousDrags: 1,
      feedback: Material(color: Colors.transparent, child: chip),
      childWhenDragging: Opacity(opacity: .35, child: chip),
      child: chip,
    );
  }
}

class CalendarTimedItemCard extends StatelessWidget {
  const CalendarTimedItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.canMove,
    required this.canResize,
    required this.onResize,
  });

  final CalendarItem item;
  final VoidCallback onTap;
  final bool canMove;
  final bool canResize;
  final ValueChanged<int> onResize;

  @override
  Widget build(BuildContext context) {
    final color = CalendarItemVisuals.colorForItem(context, item);

    final card = LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 74;
        return Material(
          borderRadius: BorderRadius.circular(10),
          color: color.withValues(alpha: .14),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CalendarItemVisuals.timeLabel(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                  if (canResize && !isCompact) ...[
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CalendarMiniActionIcon(
                          icon: Icons.remove,
                          onTap: () => onResize(-30),
                        ),
                        const SizedBox(width: 4),
                        CalendarMiniActionIcon(
                          icon: Icons.add,
                          onTap: () => onResize(30),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!canMove) return card;

    return LongPressDraggable<CalendarItem>(
      data: item,
      maxSimultaneousDrags: 1,
      feedback: SizedBox(width: 160, child: card),
      childWhenDragging: Opacity(opacity: .35, child: card),
      child: card,
    );
  }
}
