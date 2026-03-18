import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/calendar/controllers/calendar_controller.dart';
import 'package:mi_dashboard_personal/screens/calendar/models/calendar_models.dart';
import 'package:mi_dashboard_personal/screens/calendar/widgets/calendar_item_widget.dart';

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
  });

  final List<CalendarAgendaRow> rows;
  final TextEditingController searchController;
  final String Function(DateTime day) humanDateLong;
  final ValueChanged<CalendarItem> onTapItem;
  final ValueChanged<String> onDeletePlanner;
  final PlannerPrefs? prefs;
  final Future<void> Function(CalendarType type, bool value) onTypeToggle;
  final Future<void> Function(bool value) onHighOnlyToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CalendarFilterChips(
          prefs: prefs,
          onTypeToggle: onTypeToggle,
          onHighOnlyToggle: onHighOnlyToggle,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Buscar en agenda...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: ScrollConfiguration(
            behavior: const CalendarScrollBehavior(),
            child: Scrollbar(
              thumbVisibility: true,
              child: CustomScrollView(
                slivers: [
                  if (rows.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text('No hay elementos para el rango actual'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((ctx, i) {
                          final row = rows[i];
                          if (row.headerDay != null) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: 12,
                                bottom: 6,
                              ),
                              child: Text(
                                humanDateLong(row.headerDay!),
                                style: Theme.of(ctx).textTheme.titleSmall,
                              ),
                            );
                          }

                          final item = row.item!;
                          final color = CalendarItemVisuals.colorForItem(
                            ctx,
                            item,
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: .16),
                                child: Icon(
                                  CalendarItemVisuals.iconFor(item.type),
                                  color: color,
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  decoration:
                                      (item.type == CalendarType.task &&
                                              item.completed == true)
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                ),
                              ),
                              subtitle: Text(
                                CalendarItemVisuals.agendaSubtitle(item),
                              ),
                              trailing:
                                  item.isEditable
                                      ? const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                      )
                                      : const Icon(Icons.open_in_new, size: 18),
                              onTap: () => onTapItem(item),
                              onLongPress:
                                  item.isEditable
                                      ? () => onDeletePlanner(item.id)
                                      : null,
                            ),
                          );
                        }, childCount: rows.length),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 92)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
