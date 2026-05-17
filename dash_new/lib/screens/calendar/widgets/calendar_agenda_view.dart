import 'package:flutter/material.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/screens/calendar/controllers/calendar_controller.dart';
import 'package:focuslane/screens/calendar/models/calendar_models.dart';
import 'package:focuslane/screens/calendar/widgets/calendar_item_widget.dart';

class CalendarAgendaView extends StatelessWidget {
  const CalendarAgendaView({
    super.key,
    required this.rows,
    required this.searchController,
    required this.humanDateLong,
    required this.onTapItem,
    required this.onDeletePlanner,
    required this.prefs,
    required this.onTypeToggle,
    required this.onHighOnlyToggle,
    this.usePageScroll = false,
  });

  final List<CalendarAgendaRow> rows;
  final TextEditingController searchController;
  final String Function(DateTime day) humanDateLong;
  final ValueChanged<CalendarItem> onTapItem;
  final ValueChanged<String> onDeletePlanner;
  final PlannerPrefs? prefs;
  final Future<void> Function(CalendarType type, bool value) onTypeToggle;
  final Future<void> Function(bool value) onHighOnlyToggle;
  final bool usePageScroll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filters = CalendarFilterChips(
      prefs: prefs,
      onTypeToggle: onTypeToggle,
      onHighOnlyToggle: onHighOnlyToggle,
    );
    final search = FocusCard(
      padding: const EdgeInsets.all(14),
      elevated: false,
      backgroundColor: scheme.surfaceContainerLow,
      child: TextField(
        controller: searchController,
        decoration: const InputDecoration(
          hintText: 'Buscar en agenda',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
    );
    final list = FocusCard(
      padding: EdgeInsets.zero,
      backgroundColor: scheme.surfaceContainerLowest,
      child: _buildAgendaList(context, scrollable: !usePageScroll),
    );

    if (usePageScroll) {
      return Column(
        children: [
          filters,
          const SizedBox(height: 12),
          search,
          const SizedBox(height: 12),
          list,
        ],
      );
    }

    return Column(
      children: [
        filters,
        const SizedBox(height: 12),
        search,
        const SizedBox(height: 12),
        Expanded(child: list),
      ],
    );
  }

  Widget _buildAgendaList(BuildContext context, {required bool scrollable}) {
    if (rows.isEmpty) {
      return const FocusEmptyState(
        icon: Icons.event_busy_rounded,
        message: 'No hay elementos para este rango',
        subtitle: 'Prueba otra búsqueda o cambia de periodo.',
      );
    }

    if (!scrollable) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (final row in rows) _buildAgendaRow(context, row),
            const SizedBox(height: 2),
          ],
        ),
      );
    }

    return ScrollConfiguration(
      behavior: const CalendarScrollBehavior(),
      child: Scrollbar(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildAgendaRow(ctx, rows[i]),
                  childCount: rows.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaRow(BuildContext context, CalendarAgendaRow row) {
    if (row.headerDay != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: FocusSectionHeader(
          title: humanDateLong(row.headerDay!),
          subtitle: 'Agenda del día',
          icon: Icons.event_rounded,
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final item = row.item!;
    final color = CalendarItemVisuals.colorForItem(context, item);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onLongPress: item.isEditable ? () => onDeletePlanner(item.id) : null,
        child: FocusCard(
          padding: const EdgeInsets.all(12),
          elevated: false,
          backgroundColor: scheme.surfaceContainerLow,
          onTap: () => onTapItem(item),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.22)),
                ),
                child: Icon(
                  CalendarItemVisuals.iconFor(item.type),
                  color: color,
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        decoration:
                            (item.type == CalendarType.task &&
                                    item.completed == true)
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FocusChip(
                          label: CalendarItemVisuals.timeLabel(item),
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
                      ],
                    ),
                    if ((item.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.description!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
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
  }
}
