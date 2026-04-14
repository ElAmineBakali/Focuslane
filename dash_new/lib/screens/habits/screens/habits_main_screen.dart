import 'package:flutter/material.dart';
import 'package:focuslane/screens/habits/models/habit_model.dart';
import 'package:focuslane/screens/habits/services/habit_firestore_service.dart';
import 'package:focuslane/screens/habits/utils/habit_constants.dart';

class HabitsMainScreen extends StatefulWidget {
  const HabitsMainScreen({super.key});

  @override
  State<HabitsMainScreen> createState() => _HabitsMainScreenState();
}

class _HabitsMainScreenState extends State<HabitsMainScreen> {
  List<Habit> _habits = [];
  String? _selectedTagFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Hábitos'),
        actions: [
          if (_selectedTagFilter != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _selectedTagFilter = null),
              tooltip: 'Limpiar filtro',
            ),
        ],
      ),
      body: StreamBuilder<List<Habit>>(
        stream: HabitFirestoreService.getHabits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          _habits = snapshot.data ?? [];

          final filteredHabits =
              _selectedTagFilter == null
                  ? _habits
                  : _habits
                      .where((h) => h.tags.contains(_selectedTagFilter))
                      .toList();

          final allTags = <String>{};
          for (final habit in _habits) {
            allTags.addAll(habit.tags);
          }

          if (_habits.isEmpty) {
            return const Center(child: Text('No tienes hábitos aún.'));
          }

          return Column(
            children: [
              if (allTags.isNotEmpty)
                Container(
                  height: isMobile ? 50 : 56,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterChip(
                        label: const Text('Todas'),
                        selected: _selectedTagFilter == null,
                        onSelected:
                            (_) => setState(() => _selectedTagFilter = null),
                        selectedColor: cs.primaryContainer,
                        showCheckmark: true,
                      ),
                      const SizedBox(width: 8),
                      ...allTags.map((tag) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(tag),
                            selected: _selectedTagFilter == tag,
                            onSelected:
                                (_) => setState(() => _selectedTagFilter = tag),
                            selectedColor: cs.primaryContainer,
                            showCheckmark: true,
                          ),
                        );
                      }),
                    ],
                  ),
                ),

              Expanded(
                child:
                    filteredHabits.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_alt_off_rounded,
                                size: 64,
                                color: cs.onSurfaceVariant.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay hábitos con esta etiqueta',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ReorderableListView(
                          padding: const EdgeInsets.all(16),
                          onReorder: (oldIndex, newIndex) async {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final habit = filteredHabits.removeAt(oldIndex);
                            filteredHabits.insert(newIndex, habit);

                            for (int i = 0; i < filteredHabits.length; i++) {
                              filteredHabits[i] = filteredHabits[i].copyWith(
                                order: i,
                                isActive: true,
                              );
                            }

                            await HabitFirestoreService().updateHabitOrder(
                              filteredHabits,
                            );
                            setState(() {});
                          },
                          children: [
                            for (final habit in filteredHabits)
                              Card(
                                key: ValueKey(habit.id),
                                elevation: 0,
                                color: cs.surfaceContainerHigh,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 14 : 16,
                                  ),
                                ),
                                child: InkWell(
                                  onTap:
                                      () => Navigator.pushNamed(
                                        context,
                                        '/habits/detail',
                                        arguments: habit,
                                      ),
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 14 : 16,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(isMobile ? 14 : 16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: isMobile ? 50 : 56,
                                          height: isMobile ? 50 : 56,
                                          decoration: BoxDecoration(
                                            color: habit.color.withOpacity(
                                              0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: habit.color.withOpacity(
                                                0.3,
                                              ),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Center(
                                            child:
                                                habit.emoji != null
                                                    ? Text(
                                                      habit.emoji!,
                                                      style: TextStyle(
                                                        fontSize:
                                                            isMobile ? 24 : 28,
                                                      ),
                                                    )
                                                    : habit.iconCode != null
                                                    ? Icon(
                                                      HabitIcons.getIcon(
                                                        habit.iconCode,
                                                      ),
                                                      color: habit.color,
                                                      size: isMobile ? 26 : 30,
                                                    )
                                                    : Icon(
                                                      Icons
                                                          .check_circle_outline,
                                                      color: habit.color,
                                                      size: isMobile ? 26 : 30,
                                                    ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                habit.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          isMobile ? 15 : 16,
                                                    ),
                                              ),
                                              if (habit
                                                  .description
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  habit.description,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color:
                                                            cs.onSurfaceVariant,
                                                        fontSize:
                                                            isMobile ? 12 : 13,
                                                      ),
                                                ),
                                              ],

                                              if (habit.tags.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  children:
                                                      habit.tags.take(3).map((
                                                        tag,
                                                      ) {
                                                        return Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 3,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: habit.color
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            border: Border.all(
                                                              color: habit.color
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            tag,
                                                            style: TextStyle(
                                                              fontSize:
                                                                  isMobile
                                                                      ? 10
                                                                      : 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  habit.color,
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                ),
                                              ],

                                              if (habit.currentStreak > 0) ...[
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .local_fire_department_rounded,
                                                      size: isMobile ? 14 : 16,
                                                      color: Colors.orange,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${habit.currentStreak} ${habit.currentStreak == 1 ? 'día' : 'días'}',
                                                      style: TextStyle(
                                                        fontSize:
                                                            isMobile ? 11 : 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.orange,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/habits/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}


