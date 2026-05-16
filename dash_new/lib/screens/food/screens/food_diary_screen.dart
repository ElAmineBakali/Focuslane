import 'package:flutter/material.dart';
import 'package:focuslane/design/ui/tokens/focuslane_tokens.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:focuslane/design/ui/components/focus_empty_state.dart';
import 'package:focuslane/design/ui/components/focus_badge.dart';
import 'package:focuslane/design/ui/components/focus_list_card.dart';
import 'package:focuslane/design/ui/components/focus_primary_button.dart';
import 'package:focuslane/design/ui/components/focus_progress_bar.dart';
import 'package:focuslane/design/ui/components/focus_card.dart';
import 'package:focuslane/design/ui/components/focus_icon_button.dart';
import 'package:focuslane/design/ui/components/focus_progress_ring.dart';
import 'package:focuslane/design/ui/components/focus_secondary_button.dart';
import 'package:focuslane/design/ui/components/focus_section_header.dart';
import 'package:focuslane/design/ui/layouts/page_container.dart';
import 'package:focuslane/design/ui/layouts/responsive_grid.dart';
import 'package:focuslane/screens/food/widgets/food_compact_widgets.dart';
import 'package:focuslane/screens/food/services/food_firestore_service.dart';
import 'package:focuslane/screens/food/models/food_models.dart';
import 'package:intl/intl.dart';

class FoodDiaryScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  final bool embedded;
  const FoodDiaryScreen({super.key, required this.svc, this.embedded = false});

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
      appBar:
          widget.embedded
              ? null
              : FoodCompactAppBar(
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
                              () => _date = _date.add(const Duration(days: 1)),
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

                  return SingleChildScrollView(
                    child: PageContainer(
                      child: Column(
                        children: [
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: mainContent),
                                const SizedBox(width: 16),
                                SizedBox(width: 340, child: sidePanel),
                              ],
                            )
                          else ...[
                            mainContent,
                            const SizedBox(height: 16),
                            sidePanel,
                          ],
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
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
      children:
          sections.map((section) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _MealSection(
                title: section.title,
                entries: section.entries,
                onDuplicate:
                    (entry) => widget.svc.addEntry(
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

    return FocusCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              FocusIconButton(
                onPressed: onPrev,
                icon: Icons.chevron_left_rounded,
                tooltip: 'Día anterior',
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
              FocusIconButton(
                onPressed: onNext,
                icon: Icons.chevron_right_rounded,
                tooltip: 'Día siguiente',
              ),
            ],
          ),
          if (!isToday) ...[
            const SizedBox(height: 10),
            FocusSecondaryButton(
              label: 'Ir a hoy',
              icon: Icons.today_rounded,
              onPressed: onToday,
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
    return ResponsiveGrid(
      minItemWidth: 210,
      spacing: 12,
      children: [
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
      ],
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

    final numericValue = double.tryParse(value) ?? 0;
    final progress =
        target == null || target == 0
            ? 0.0
            : (numericValue / target!).clamp(0.0, 1.0);

    return FocusCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FocuslaneUI.accentSurface(context, opacity: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: FocuslaneUI.accent(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$value $unit',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            targetText.isEmpty ? 'Sin objetivo' : 'Objetivo$targetText',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FocusProgressBar(
            value: progress,
            color: FocuslaneUI.accent(context),
            height: 7,
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

    return FocusCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.heading4(context)),
              Text(
                '${_kcalTotal().toStringAsFixed(0)} kcal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Text(
                'Sin entradas',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...entries.map((entry) {
              return _EntryCard(
                entry: entry,
                onDuplicate: () => onDuplicate(entry),
                onDelete: () => onDelete(entry),
              );
            }),
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
    final waterTarget = targets['water']?.toInt();
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
        FocusCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Objetivos del día',
                    style: AppTypography.heading4(context),
                  ),
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
                        style: AppTypography.bodySmall(
                          context,
                        ).copyWith(color: colorScheme.onSurfaceVariant),
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

  const _GoalRow({
    required this.label,
    required this.value,
    required this.unit,
  });
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
      children:
          options.map((option) {
            final selected = option.slot == value;
            return ChoiceChip(
              label: Text(option.label),
              selected: selected,
              onSelected: (_) => onChanged(option.slot),
              labelStyle: theme.textTheme.bodySmall?.copyWith(
                color:
                    selected
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

class _ModernWaterCard extends StatelessWidget {
  final int water;
  final int? waterTarget;
  final Function(int) onAdd;

  const _ModernWaterCard({
    required this.water,
    required this.waterTarget,
    required this.onAdd,
  });

  double _pct() {
    final target = waterTarget;
    if (target == null || target <= 0) return 0;
    return (water / target).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final target = waterTarget;
    final remaining = target == null ? null : target - water;
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FocusSectionHeader(
            title: 'Hidratación',
            subtitle: 'Agua registrada hoy',
            icon: Icons.water_drop_rounded,
          ),
          const SizedBox(height: 16),
          Center(
            child: FocusProgressRing(
              value: _pct(),
              size: 124,
              strokeWidth: 10,
              label: '${(water / 1000).toStringAsFixed(1)} L',
              subtitle: target == null ? 'sin objetivo' : 'agua',
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            target == null
                ? 'Sin objetivo de agua'
                : '$water / $target ml${remaining != null && remaining > 0 ? ' - faltan $remaining ml' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FocusSecondaryButton(
                label: '+250 ml',
                icon: Icons.add_rounded,
                onPressed: () => onAdd(250),
              ),
              FocusSecondaryButton(
                label: '+500 ml',
                icon: Icons.add_rounded,
                onPressed: () => onAdd(500),
              ),
              FocusSecondaryButton(
                label: 'Personalizar',
                icon: Icons.edit_rounded,
                onPressed: () => _showCustomWaterDialog(context),
              ),
            ],
          ),
        ],
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
    final title =
        entry.type == FavoriteType.photoAi
            ? (entry.nameSnapshot.trim().isEmpty
                ? 'Foto (IA)'
                : 'Foto (IA) · ${entry.nameSnapshot}')
            : entry.nameSnapshot;
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle =
        '${entry.qty.toStringAsFixed(0)} ${entry.unit.name} - ${kcal.toStringAsFixed(0)} kcal - P ${protein.toStringAsFixed(0)}g - C ${carbs.toStringAsFixed(0)}g - G ${fat.toStringAsFixed(0)}g';

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
                        Icon(Icons.delete, size: 20, color: colorScheme.error),
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
                        ? colorScheme.onSurface.withValues(alpha: 0.3)
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
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
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
                            ? colorScheme.onSurface.withValues(alpha: 0.3)
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
              title: f.alias ?? '${f.type.name} - ${f.refId}',
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
                    ? '${r.kcal!.toStringAsFixed(0)} kcal - ${r.servings} raciones'
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
