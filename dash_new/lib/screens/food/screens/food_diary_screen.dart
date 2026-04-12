import 'package:flutter/material.dart';
import '../../../design/ui/tokens/focuslane_tokens.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design/ui/components/focus_empty_state.dart';
import '../../../design/ui/components/focus_badge.dart';
import '../../../design/ui/components/focus_list_card.dart';
import '../../../design/ui/components/focus_primary_button.dart';
import '../../../design/ui/components/focus_progress_bar.dart';
import '../widgets/food_compact_widgets.dart';
import '../services/food_firestore_service.dart';
import '../models/food_models.dart';
import 'package:intl/intl.dart';

class FoodDiaryScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  const FoodDiaryScreen({super.key, required this.svc});

  @override
  State<FoodDiaryScreen> createState() => _FoodDiaryScreenState();
}

class _FoodDiaryScreenState extends State<FoodDiaryScreen> {
  DateTime _date = DateTime.now();
  String _dayId(DateTime d) => d.toIso8601String().substring(0, 10);

  @override
  Widget build(BuildContext context) {
    final dayId = _dayId(_date);

    return Scaffold(
      appBar: FoodCompactAppBar(
        title: 'Diario',
        subtitle: 'Registro diario',
        actions: [
          IconButton(
            tooltip: 'Objetivos nutricionales',
            icon: const Icon(Icons.flag_outlined, size: 18),
            onPressed: () => _showGoalsSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'foodDiaryFab',
        onPressed: () => _showAddEntrySheet(context, dayId),
        icon: const Icon(Icons.add),
        label: const Text('Añadir'),
      ).animate().scale(delay: 300.ms, duration: 200.ms),
      body: StreamBuilder<Map<String, double?>>(
        stream: widget.svc.streamGlobalTargets(),
        builder: (context, globalSnap) {
          final globalTargets = globalSnap.data ?? const {};

          return StreamBuilder<DailyIntakeDoc>(
            stream: widget.svc.streamDay(dayId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final d = snap.data!;
              final mergedTargets = Map<String, double?>.from(d.targets);
              for (final k in ['kcal', 'protein', 'carbs', 'fat', 'fiber']) {
                mergedTargets[k] ??= globalTargets[k];
              }
              mergedTargets['water'] ??= globalTargets['water'];

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1100;

                  final mainContent = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ModernDaySelector(
                        date: _date,
                        onPrev:
                            () => setState(
                              () =>
                                  _date = _date.subtract(
                                    const Duration(days: 1),
                                  ),
                            ),
                        onNext:
                            () => setState(
                              () =>
                                  _date = _date.add(const Duration(days: 1)),
                            ),
                        onToday: () => setState(() => _date = DateTime.now()),
                      ).animate().slideY(begin: -0.2, duration: 300.ms),
                      const SizedBox(height: AppSpacing.md),
                      _KpiRow(day: d, targets: mergedTargets),
                      const SizedBox(height: AppSpacing.md),
                      _buildMealSections(d.entries, dayId),
                    ],
                  );

                  final sidePanel = _SidePanel(
                    day: d,
                    targets: mergedTargets,
                    onAddWater: (ml) => widget.svc.incrementWater(dayId, ml),
                    onEditGoals: () => _showGoalsSheet(context),
                  );

                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: mainContent),
                            const SizedBox(width: AppSpacing.md),
                            SizedBox(width: 320, child: sidePanel),
                          ],
                        )
                      else ...[
                        mainContent,
                        const SizedBox(height: AppSpacing.md),
                        sidePanel,
                      ],
                      const SizedBox(height: 100),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMealSections(List<IntakeEntry> entries, String dayId) {
    if (entries.isEmpty) {
      return FocusEmptyState(
        icon: Icons.restaurant_outlined,
        message: 'No hay entradas para este día',
        subtitle: 'Toca el botón + para añadir tu primera comida',
        actionLabel: 'Añadir entrada',
        onAction: () => _showAddEntrySheet(context, dayId),
      );
    }

    final grouped = _groupByMeal(entries);
    final sections = [
      _MealSectionData(
        title: 'Desayuno',
        entries: grouped[MealSlot.breakfast] ?? const [],
      ),
      _MealSectionData(
        title: 'Comida',
        entries: grouped[MealSlot.lunch] ?? const [],
      ),
      _MealSectionData(
        title: 'Cena',
        entries: grouped[MealSlot.dinner] ?? const [],
      ),
      _MealSectionData(
        title: 'Aperitivos',
        entries: [
          ...(grouped[MealSlot.snack] ?? const []),
          ...(grouped[MealSlot.merienda] ?? const []),
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _MealSection(
            title: section.title,
            entries: section.entries,
            onDuplicate: (entry) => widget.svc.addEntry(
              dayId,
              IntakeEntry(
                id: '',
                type: entry.type,
                refId: entry.refId,
                qty: entry.qty,
                unit: entry.unit,
                nameSnapshot: entry.nameSnapshot,
                macrosSnapshot: entry.macrosSnapshot,
                meal: entry.meal,
              ),
            ),
            onDelete: (entry) {
              final index = entries.indexOf(entry);
              if (index >= 0) widget.svc.deleteEntry(dayId, index);
            },
          ),
        );
      }).toList(),
    );
  }

  Map<MealSlot, List<IntakeEntry>> _groupByMeal(List<IntakeEntry> entries) {
    final grouped = <MealSlot, List<IntakeEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.meal, () => []).add(entry);
    }
    return grouped;
  }

  void _showGoalsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModernGoalsSheet(svc: widget.svc),
    );
  }

  void _showAddEntrySheet(BuildContext context, String dayId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModernAddEntrySheet(svc: widget.svc, dayId: dayId),
    );
  }
}

class _ModernDaySelector extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  const _ModernDaySelector({
    required this.date,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(date);
    final dateStr = DateFormat('EEEE, d MMMM', 'es').format(date);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border:
            isDark
                ? Border.all(
                    color: FocuslaneUI.borderColor(context),
                    width: FocuslaneUI.borderW,
                  )
                : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        dateStr,
                        style: AppTypography.heading4(context),
                        textAlign: TextAlign.center,
                      ),
                      if (isToday)
                        FocusBadge(
                          label: 'HOY',
                          color: FocuslaneUI.accent(context),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
          if (!isToday) ...[
            const SizedBox(height: AppSpacing.xs),
            FocusPrimaryButton(
              label: 'Ir a hoy',
              icon: Icons.today,
              onPressed: onToday,
              color: FocuslaneUI.accent(context),
            ),
          ],
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _KpiRow extends StatelessWidget {
  final DailyIntakeDoc day;
  final Map<String, double?> targets;

  const _KpiRow({required this.day, required this.targets});

  @override
  Widget build(BuildContext context) {
    final t = day.totals;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final cards = [
          _KpiCard(
            label: 'Calorías',
            value: (t['kcal'] ?? 0).toStringAsFixed(0),
            unit: 'kcal',
            target: targets['kcal'],
            icon: Icons.local_fire_department,
          ),
          _KpiCard(
            label: 'Proteína',
            value: (t['protein'] ?? 0).toStringAsFixed(0),
            unit: 'g',
            target: targets['protein'],
            icon: Icons.fitness_center,
          ),
          _KpiCard(
            label: 'Carbohidratos',
            value: (t['carbs'] ?? 0).toStringAsFixed(0),
            unit: 'g',
            target: targets['carbs'],
            icon: Icons.bakery_dining,
          ),
          _KpiCard(
            label: 'Grasas',
            value: (t['fat'] ?? 0).toStringAsFixed(0),
            unit: 'g',
            target: targets['fat'],
            icon: Icons.water_drop,
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1)
                  const SizedBox(width: AppSpacing.sm),
              ],
            ],
          );
        }

        return Column(
          children: cards
              .map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double? target;
  final IconData icon;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.target,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final targetText =
        target != null ? ' / ${target!.toStringAsFixed(0)} $unit' : '';

    return FoodCompactCard(
      maxHeight: 72,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: FocuslaneUI.accentSurface(context, opacity: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: FocuslaneUI.accent(context)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '$value $unit$targetText',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealSectionData {
  final String title;
  final List<IntakeEntry> entries;

  const _MealSectionData({required this.title, required this.entries});
}

class _MealSection extends StatelessWidget {
  final String title;
  final List<IntakeEntry> entries;
  final ValueChanged<IntakeEntry> onDuplicate;
  final ValueChanged<IntakeEntry> onDelete;

  const _MealSection({
    required this.title,
    required this.entries,
    required this.onDuplicate,
    required this.onDelete,
  });

  double _kcalTotal() {
    return entries.fold<double>(
      0,
      (sum, e) => sum + (e.macrosSnapshot['kcal'] ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FoodCompactCard(
      maxHeight: 240,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.heading4(context),
              ),
              Text(
                '${_kcalTotal().toStringAsFixed(0)} kcal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (entries.isEmpty)
            Text(
              'Sin entradas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...entries.take(4).map((entry) {
              return _EntryCard(
                entry: entry,
                onDuplicate: () => onDuplicate(entry),
                onDelete: () => onDelete(entry),
              );
            }),
          if (entries.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${entries.length - 4} más',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  final DailyIntakeDoc day;
  final Map<String, double?> targets;
  final ValueChanged<int> onAddWater;
  final VoidCallback onEditGoals;

  const _SidePanel({
    required this.day,
    required this.targets,
    required this.onAddWater,
    required this.onEditGoals,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final waterTarget = (targets['water'] ?? 2000).toInt();
    final summary = [
      _GoalRow(label: 'Calorías', value: targets['kcal'], unit: 'kcal'),
      _GoalRow(label: 'Proteína', value: targets['protein'], unit: 'g'),
      _GoalRow(label: 'Carbohidratos', value: targets['carbs'], unit: 'g'),
      _GoalRow(label: 'Grasas', value: targets['fat'], unit: 'g'),
      _GoalRow(label: 'Fibra', value: targets['fiber'], unit: 'g'),
    ];

    return Column(
      children: [
        _ModernWaterCard(
          water: day.waterMl,
          waterTarget: waterTarget,
          onAdd: onAddWater,
        ),
        const SizedBox(height: AppSpacing.md),
        FoodCompactCard(
          maxHeight: 220,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Objetivos del día', style: AppTypography.heading4(context)),
                  TextButton(
                    onPressed: onEditGoals,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Editar'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...summary.map((row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(row.label, style: AppTypography.bodySmall(context)),
                      Text(
                        row.value != null
                            ? '${row.value!.toStringAsFixed(0)} ${row.unit}'
                            : 'Sin objetivo',
                        style: AppTypography.bodySmall(context).copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalRow {
  final String label;
  final double? value;
  final String unit;

  const _GoalRow({required this.label, required this.value, required this.unit});
}

class _MealSelector extends StatelessWidget {
  final MealSlot value;
  final ValueChanged<MealSlot> onChanged;

  const _MealSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final options = const [
      _MealOption(MealSlot.breakfast, 'Desayuno'),
      _MealOption(MealSlot.lunch, 'Comida'),
      _MealOption(MealSlot.dinner, 'Cena'),
      _MealOption(MealSlot.snack, 'Aperitivo'),
    ];

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: options.map((option) {
        final selected = option.slot == value;
        return ChoiceChip(
          label: Text(option.label),
          selected: selected,
          onSelected: (_) => onChanged(option.slot),
          labelStyle: theme.textTheme.bodySmall?.copyWith(
            color: selected
                ? FocuslaneUI.accent(context)
                : colorScheme.onSurfaceVariant,
          ),
          selectedColor: FocuslaneUI.accentSurface(context, opacity: 0.16),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}

class _MealOption {
  final MealSlot slot;
  final String label;

  const _MealOption(this.slot, this.label);
}

// ignore: unused_element
class _MacrosSummary extends StatelessWidget {
  final DailyIntakeDoc day;
  final Map<String, double?> mergedTargets;

  const _MacrosSummary({required this.day, required this.mergedTargets});

  @override
  Widget build(BuildContext context) {
    final t = day.totals;
    final g = mergedTargets;

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nutrición del Día', style: AppTypography.heading3(context)),
          const SizedBox(height: AppSpacing.md),

          FoodCompactCard(
            maxHeight: 120,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Calorías', style: AppTypography.heading4(context)),
                    Icon(
                      Icons.local_fire_department,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (t['kcal'] ?? 0).toStringAsFixed(0),
                      style: AppTypography.heading2(context),
                    ),
                    if (g['kcal'] != null) ...[
                      Text(
                        ' / ${g['kcal']!.toStringAsFixed(0)}',
                        style: AppTypography.bodySmall(context),
                      ),
                    ],
                    Text(
                      ' kcal',
                      style: AppTypography.bodySmall(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (g['kcal'] != null)
                  FocusProgressBar(
                    value: _pct(t['kcal'] ?? 0, g['kcal']),
                    color: colorScheme.primary,
                    backgroundColor: colorScheme.outlineVariant,
                    height: 6,
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.2,
            children: [
              _MacroCard(
                label: 'Proteínas',
                value: t['protein'] ?? 0,
                target: g['protein'],
                unit: 'g',
                color: colorScheme.primary,
                icon: Icons.fitness_center,
              ),
              _MacroCard(
                label: 'Carbohidratos',
                value: t['carbs'] ?? 0,
                target: g['carbs'],
                unit: 'g',
                color: colorScheme.secondary,
                icon: Icons.bakery_dining,
              ),
              _MacroCard(
                label: 'Grasas',
                value: t['fat'] ?? 0,
                target: g['fat'],
                unit: 'g',
                color: colorScheme.tertiary,
                icon: Icons.water_drop,
              ),
              _MacroCard(
                label: 'Fibra',
                value: t['fiber'] ?? 0,
                target: g['fiber'],
                unit: 'g',
                color: colorScheme.primary,
                icon: Icons.eco,
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _pct(double v, double? t) {
    if (t == null || t <= 0) return 0;
    return (v / t).clamp(0, 1);
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final double value;
  final double? target;
  final String unit;
  final Color color;
  final IconData icon;

  const _MacroCard({
    required this.label,
    required this.value,
    this.target,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pct =
        target != null && target! > 0
            ? (value / target!).clamp(0.0, 1.0).toDouble()
            : 0.0;

    return FoodCompactCard(
      maxHeight: 96,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: AppSpacing.xs),
              SizedBox(
                width: 90,
                child: Text(
                  label,
                  style: AppTypography.caption(context).copyWith(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toStringAsFixed(0),
                style: AppTypography.heading4(context, color: color),
              ),
              if (target != null) ...[
                Text(
                  '/${target!.toStringAsFixed(0)}',
                  style: AppTypography.bodySmall(context),
                ),
              ],
              const SizedBox(width: 2),
              Text(unit, style: AppTypography.caption(context)),
            ],
          ),
          if (target != null)
            FocusProgressBar(value: pct, color: color, height: 3),
        ],
      ),
    );
  }
}

class _ModernWaterCard extends StatelessWidget {
  final int water;
  final int waterTarget;
  final Function(int) onAdd;

  const _ModernWaterCard({
    required this.water,
    required this.waterTarget,
    required this.onAdd,
  });

  double _pct() {
    if (waterTarget <= 0) return 0;
    return (water / waterTarget).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = waterTarget - water;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: FoodCompactCard(
        maxHeight: 160,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.water_drop,
                    color:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hidratación', style: AppTypography.heading4(context)),
                    Text(
                      '$water / $waterTarget ml',
                      style: AppTypography.bodySmall(context),
                    ),
                    if (remaining > 0)
                      Text(
                        'Faltan ${remaining}ml',
                        style: AppTypography.caption(context),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${(_pct() * 100).toStringAsFixed(0)}%',
                  style: AppTypography.heading4(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
                FocusProgressBar(
              value: _pct(),
              color: Theme.of(context).colorScheme.primary,
              height: 6,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => onAdd(250),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('250ml'),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => onAdd(500),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('500ml'),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: () => _showCustomWaterDialog(context),
                    child: const Icon(Icons.edit, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomWaterDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              'Añadir agua personalizada',
              style: AppTypography.heading3(ctx),
            ),
            content: FoodCompactTextField(
              label: 'Cantidad (ml)',
              hint: 'Ej: 750',
              controller: controller,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.water_drop,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final ml = int.tryParse(controller.text);
                  if (ml != null && ml > 0) {
                    onAdd(ml);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Añadir'),
              ),
            ],
          ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final IntakeEntry entry;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _EntryCard({
    required this.entry,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final kcal = entry.macrosSnapshot['kcal'] ?? 0;
    final protein = entry.macrosSnapshot['protein'] ?? 0;
    final carbs = entry.macrosSnapshot['carbs'] ?? 0;
    final fat = entry.macrosSnapshot['fat'] ?? 0;
    final title = entry.type == FavoriteType.photoAi
      ? (entry.nameSnapshot.trim().isEmpty
        ? 'Foto (IA)'
        : 'Foto (IA) · ${entry.nameSnapshot}')
      : entry.nameSnapshot;
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle =
        '${entry.qty.toStringAsFixed(0)} ${entry.unit.name} • ${kcal.toStringAsFixed(0)} kcal • P ${protein.toStringAsFixed(0)}g • C ${carbs.toStringAsFixed(0)}g • G ${fat.toStringAsFixed(0)}g';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        container: true,
        label: '$title. $subtitle',
        child: FoodCompactTile(
          height: 52,
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              entry.type == FavoriteType.food
                  ? Icons.restaurant
                  : (entry.type == FavoriteType.photoAi
                      ? Icons.add_a_photo_outlined
                      : Icons.menu_book),
              color: colorScheme.onPrimaryContainer,
              size: 18,
            ),
          ),
          title: title,
          subtitle: subtitle,
          trailing: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            onSelected: (v) {
              if (v == 'dup') onDuplicate();
              if (v == 'del') onDelete();
            },
            itemBuilder:
                (_) => [
                  const PopupMenuItem(
                    value: 'dup',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Text('Duplicar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'del',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          size: 20,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Eliminar',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ),
      ),
    );
  }
}

class _ModernAddEntrySheet extends StatefulWidget {
  final FoodFirestoreService svc;
  final String dayId;

  const _ModernAddEntrySheet({required this.svc, required this.dayId});

  @override
  State<_ModernAddEntrySheet> createState() => _ModernAddEntrySheetState();
}

class _ModernAddEntrySheetState extends State<_ModernAddEntrySheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _kcalController = TextEditingController();
  final _proteinController = TextEditingController();
  final _qtyController = TextEditingController(text: '100');
  final _searchController = TextEditingController();
  String _searchQuery = '';
  UnitKind _unit = UnitKind.g;
  MealSlot _meal = MealSlot.lunch;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? colorScheme.onSurface.withOpacity(0.3)
                        : colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle,
                    color: FocuslaneUI.accent(context),
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Añadir al Diario',
                      style: AppTypography.heading2(context),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _MealSelector(
                value: _meal,
                onChanged: (m) => setState(() => _meal = m),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            TabBar(
              controller: _tabController,
              labelColor: FocuslaneUI.accent(context),
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: FocuslaneUI.accent(context),
              tabs: const [
                Tab(icon: Icon(Icons.flash_on), text: 'Rápido'),
                Tab(icon: Icon(Icons.star), text: 'Favoritos'),
                Tab(icon: Icon(Icons.restaurant), text: 'Alimentos'),
                Tab(icon: Icon(Icons.menu_book), text: 'Recetas'),
              ],
            ),

            SizedBox(
              height: 420,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQuickAddTab(),
                  _buildFavoritesTab(),
                  _buildFoodsTab(),
                  _buildRecipesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Añade calorías rápidamente',
            style: AppTypography.body(context),
          ),
          const SizedBox(height: AppSpacing.md),

          FoodCompactTextField(
            label: 'Nombre',
            hint: 'Ej: Snack casero',
            controller: _nameController,
            prefixIcon: Icons.edit,
          ),
          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              Expanded(
                child: FoodCompactTextField(
                  label: 'Calorías*',
                  hint: '250',
                  controller: _kcalController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.local_fire_department,
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FoodCompactTextField(
                  label: 'Proteínas (g)',
                  hint: '20',
                  controller: _proteinController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.fitness_center,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          FocusPrimaryButton(
            label: 'Añadir entrada rápida',
            icon: Icons.check,
            fullWidth: true,
            color: FocuslaneUI.accent(context),
            onPressed: _addQuickEntry,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FoodCompactTextField(
            label: 'Buscar favoritos',
            hint: 'Busca por nombre...',
            controller: _searchController,
            prefixIcon: Icons.search,
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _buildQuantityRow(),
        ),
        Expanded(
          child: _FavList(
            svc: widget.svc,
            query: _searchQuery,
            onPick: (f) => _addFavorite(f),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FoodCompactTextField(
            label: 'Buscar alimentos',
            hint: 'Busca en tu catálogo...',
            controller: _searchController,
            prefixIcon: Icons.search,
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _buildQuantityRow(),
        ),
        Expanded(
          child: _FoodList(
            svc: widget.svc,
            query: _searchQuery,
            onPick: (f) => _addFood(f),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FoodCompactTextField(
            label: 'Buscar recetas',
            hint: 'Busca tus recetas...',
            controller: _searchController,
            prefixIcon: Icons.search,
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _buildQuantityRow(isRecipe: true),
        ),
        Expanded(
          child: _RecipeList(
            svc: widget.svc,
            query: _searchQuery,
            onPick: (r) => _addRecipe(r),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityRow({bool isRecipe = false}) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: FoodCompactTextField(
            label: isRecipe ? 'Raciones' : 'Cantidad',
            controller: _qtyController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.numbers,
          ),
        ),
        if (!isRecipe) ...[
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            height: 44,
            child: DropdownButtonFormField<UnitKind>(
              initialValue: _unit,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FocuslaneUI.radius),
                  borderSide: BorderSide(
                    color: FocuslaneUI.borderColor(context),
                    width: FocuslaneUI.borderW,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FocuslaneUI.radius),
                  borderSide: BorderSide(
                    color: FocuslaneUI.borderColor(context),
                    width: FocuslaneUI.borderW,
                  ),
                ),
              ),
              items: const [
                DropdownMenuItem(value: UnitKind.g, child: Text('g')),
                DropdownMenuItem(value: UnitKind.ml, child: Text('ml')),
                DropdownMenuItem(value: UnitKind.unit, child: Text('unidad')),
              ],
              onChanged: (v) => setState(() => _unit = v ?? UnitKind.g),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _addQuickEntry() async {
    final name =
      _nameController.text.trim().isEmpty
        ? 'Entrada rápida'
        : _nameController.text.trim();
    final kcal = double.tryParse(_kcalController.text) ?? 0;
    final protein = double.tryParse(_proteinController.text) ?? 0;

    if (kcal <= 0) {
      FoodFeedback.showError(context, 'Las calorías son requeridas');
      return;
    }

    await widget.svc.addEntry(
      widget.dayId,
      IntakeEntry(
        id: '',
        type: FavoriteType.food,
        refId: 'quickadd',
        qty: 1,
        unit: UnitKind.unit,
        nameSnapshot: name,
        macrosSnapshot: {
          'kcal': kcal,
          'protein': protein,
          'carbs': 0.0,
          'fat': 0.0,
          'fiber': 0.0,
          'sodium': 0.0,
        },
        meal: _meal,
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  Future<void> _addFavorite(Favorite f) async {
    final qty = double.tryParse(_qtyController.text) ?? f.defaultQty;
    final unit = _unit;

    if (f.type == FavoriteType.food) {
      final foods = await widget.svc.streamFoods().first;
      final food = foods.firstWhere(
        (x) => x.id == f.refId,
        orElse:
            () => Food(
              id: f.refId,
              name: f.alias ?? 'Alimento',
              perUnit: unit,
              unitSize: 100,
              kcal: 0,
              protein: 0,
              carbs: 0,
              fat: 0,
              fiber: 0,
              sodium: 0,
              isSupplement: false,
            ),
      );
      final mac = food.macrosFor(qty);
      await widget.svc.addEntry(
        widget.dayId,
        IntakeEntry(
          id: '',
          type: FavoriteType.food,
          refId: food.id,
          qty: qty,
          unit: unit,
          nameSnapshot: f.alias ?? food.name,
          macrosSnapshot: mac,
          meal: _meal,
        ),
      );
    } else {
      final recs = await widget.svc.streamRecipes().first;
      final r = recs.firstWhere(
        (x) => x.id == f.refId,
        orElse:
            () => Recipe(
              id: f.refId,
              name: 'Receta',
              servings: 1,
              ingredients: const [],
            ),
      );
      final perServing = _calculatePerServing(r);
      final mac = perServing.map((k, v) => MapEntry(k, v * qty));
      await widget.svc.addEntry(
        widget.dayId,
        IntakeEntry(
          id: '',
          type: FavoriteType.recipe,
          refId: r.id,
          qty: qty,
          unit: UnitKind.unit,
          nameSnapshot: r.name,
          macrosSnapshot: mac,
          meal: _meal,
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _addFood(Food f) async {
    final qty = double.tryParse(_qtyController.text) ?? f.unitSize;
    final unit = _unit;
    final mac = f.macrosFor(qty);

    await widget.svc.addEntry(
      widget.dayId,
      IntakeEntry(
        id: '',
        type: FavoriteType.food,
        refId: f.id,
        qty: qty,
        unit: unit,
        nameSnapshot: f.name,
        macrosSnapshot: mac,
        meal: _meal,
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  Future<void> _addRecipe(Recipe r) async {
    final servings = double.tryParse(_qtyController.text) ?? 1;
    final perServing = _calculatePerServing(r);
    final mac = perServing.map((k, v) => MapEntry(k, v * servings));

    await widget.svc.addEntry(
      widget.dayId,
      IntakeEntry(
        id: '',
        type: FavoriteType.recipe,
        refId: r.id,
        qty: servings,
        unit: UnitKind.unit,
        nameSnapshot: r.name,
        macrosSnapshot: mac,
        meal: _meal,
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  Map<String, double> _calculatePerServing(Recipe r) {
    final div = r.servings == 0 ? 1 : r.servings;
    return {
      'kcal': (r.kcal ?? 0) / div,
      'protein': (r.protein ?? 0) / div,
      'carbs': (r.carbs ?? 0) / div,
      'fat': (r.fat ?? 0) / div,
      'fiber': (r.fiber ?? 0) / div,
      'sodium': (r.sodium ?? 0) / div,
    };
  }
}

class _ModernGoalsSheet extends StatefulWidget {
  final FoodFirestoreService svc;

  const _ModernGoalsSheet({required this.svc});

  @override
  State<_ModernGoalsSheet> createState() => _ModernGoalsSheetState();
}

class _ModernGoalsSheetState extends State<_ModernGoalsSheet> {
  final _kcalController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();
  final _waterController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? colorScheme.onSurface.withOpacity(0.3)
                            : colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),

              Row(
                children: [
                  Icon(
                    Icons.flag,
                    color: FocuslaneUI.accent(context),
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Objetivos Nutricionales',
                      style: AppTypography.heading2(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),
              Text(
                'Configura tus objetivos diarios de nutrición',
                style: AppTypography.body(context),
              ),

              const SizedBox(height: AppSpacing.md),

              FoodCompactTextField(
                label: 'Calorías objetivo (kcal)',
                hint: '2000',
                controller: _kcalController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.local_fire_department,
              ),

              const SizedBox(height: AppSpacing.lg),

              FoodCompactTextField(
                label: 'Proteínas (g)',
                hint: '150',
                controller: _proteinController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.fitness_center,
              ),

              const SizedBox(height: AppSpacing.lg),

              FoodCompactTextField(
                label: 'Carbohidratos (g)',
                hint: '250',
                controller: _carbsController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.bakery_dining,
              ),

              const SizedBox(height: AppSpacing.lg),

              FoodCompactTextField(
                label: 'Grasas (g)',
                hint: '65',
                controller: _fatController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.water_drop,
              ),

              const SizedBox(height: AppSpacing.lg),

              FoodCompactTextField(
                label: 'Fibra (g)',
                hint: '30',
                controller: _fiberController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.eco,
              ),

              const SizedBox(height: AppSpacing.lg),

              FoodCompactTextField(
                label: 'Agua (ml)',
                hint: '2000',
                controller: _waterController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.water_drop,
              ),

              const SizedBox(height: AppSpacing.xxl),

              FocusPrimaryButton(
                label: 'Guardar Objetivos',
                icon: Icons.check,
                fullWidth: true,
                color: FocuslaneUI.accent(context),
                onPressed: _saveGoals,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveGoals() async {
    await widget.svc.setGlobalTargets(
      kcal:
          _kcalController.text.isNotEmpty
              ? double.tryParse(_kcalController.text)
              : null,
      protein:
          _proteinController.text.isNotEmpty
              ? double.tryParse(_proteinController.text)
              : null,
      carbs:
          _carbsController.text.isNotEmpty
              ? double.tryParse(_carbsController.text)
              : null,
      fat:
          _fatController.text.isNotEmpty
              ? double.tryParse(_fatController.text)
              : null,
      fiber:
          _fiberController.text.isNotEmpty
              ? double.tryParse(_fiberController.text)
              : null,
      waterMl:
          _waterController.text.isNotEmpty
              ? int.tryParse(_waterController.text)
              : null,
    );

    if (mounted) {
      Navigator.pop(context);
      FoodFeedback.showSuccess(context, 'Objetivos guardados');
    }
  }
}

class _FavList extends StatelessWidget {
  final FoodFirestoreService svc;
  final String query;
  final ValueChanged<Favorite> onPick;

  const _FavList({
    required this.svc,
    required this.query,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Favorite>>(
      stream: svc.streamFavorites(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var list = snap.data!;
        if (query.trim().isNotEmpty) {
          final ql = query.toLowerCase();
          list =
              list
                  .where((f) => (f.alias ?? '').toLowerCase().contains(ql))
                  .toList();
        }

        if (list.isEmpty) {
          return FocusEmptyState(
            icon: Icons.star_border,
            message: 'No hay favoritos',
            subtitle:
                'Marca alimentos o recetas como favoritos para verlos aquí',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final f = list[i];
            final colorScheme = Theme.of(context).colorScheme;
            return FocusListCard(
              title: f.alias ?? '${f.type.name} • ${f.refId}',
              subtitle:
                  'Por defecto: ${f.defaultQty.toStringAsFixed(0)} ${f.defaultUnit.name}',
              leadingIcon:
                  f.type == FavoriteType.food
                      ? Icons.restaurant
                      : Icons.menu_book,
              leadingColor: FocuslaneUI.accent(context),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () => onPick(f),
            );
          },
        );
      },
    );
  }
}

class _FoodList extends StatelessWidget {
  final FoodFirestoreService svc;
  final String query;
  final ValueChanged<Food> onPick;

  const _FoodList({
    required this.svc,
    required this.query,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Food>>(
      stream: svc.streamFoods(query: query),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final list = snap.data!;

        if (list.isEmpty) {
          return FocusEmptyState(
            icon: Icons.restaurant_outlined,
            message: 'No se encontraron alimentos',
            subtitle:
                query.isNotEmpty
                    ? 'Intenta con otro término de búsqueda'
                    : 'Añade alimentos a tu catálogo',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final f = list[i];
            return FocusListCard(
              title: f.name,
              subtitle:
                  '${f.kcal.toStringAsFixed(0)} kcal por ${f.unitSize.toStringAsFixed(0)} ${f.perUnit.name}',
              leadingIcon: Icons.restaurant,
              leadingColor: FocuslaneUI.accent(context),
              trailing: Icon(Icons.add, color: FocuslaneUI.accent(context)),
              onTap: () => onPick(f),
            );
          },
        );
      },
    );
  }
}

class _RecipeList extends StatelessWidget {
  final FoodFirestoreService svc;
  final String query;
  final ValueChanged<Recipe> onPick;

  const _RecipeList({
    required this.svc,
    required this.query,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Recipe>>(
      stream: svc.streamRecipes(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var list = snap.data!;
        if (query.trim().isNotEmpty) {
          final ql = query.toLowerCase();
          list = list.where((r) => r.name.toLowerCase().contains(ql)).toList();
        }

        if (list.isEmpty) {
          return FocusEmptyState(
            icon: Icons.menu_book_outlined,
            message: 'No se encontraron recetas',
            subtitle:
                query.isNotEmpty
                    ? 'Intenta con otro término de búsqueda'
                    : 'Crea recetas para verlas aquí',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final r = list[i];
            final macrosText =
                r.kcal != null
                    ? '${r.kcal!.toStringAsFixed(0)} kcal • ${r.servings} raciones'
                    : '${r.servings} raciones';

            return FocusListCard(
              title: r.name,
              subtitle: macrosText,
              leadingIcon: Icons.menu_book,
              leadingColor: FocuslaneUI.accent(context),
              trailing: Icon(Icons.add, color: FocuslaneUI.accent(context)),
              onTap: () => onPick(r),
            );
          },
        );
      },
    );
  }
}

