import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/global_ui_theme.dart';
import '../services/food_firestore_service.dart';
import '../models/food_models.dart';
import 'package:intl/intl.dart';

class FoodDiaryScreenV2 extends StatefulWidget {
  final FoodFirestoreService svc;
  const FoodDiaryScreenV2({super.key, required this.svc});

  @override
  State<FoodDiaryScreenV2> createState() => _FoodDiaryScreenV2State();
}

class _FoodDiaryScreenV2State extends State<FoodDiaryScreenV2> {
  DateTime _date = DateTime.now();
  String _dayId(DateTime d) => d.toIso8601String().substring(0, 10);

  @override
  Widget build(BuildContext context) {
    final dayId = _dayId(_date);

    return Scaffold(
      appBar: ModernGradientAppBar(
        title: 'Diario de Alimentación',
        icon: Icons.restaurant_menu,
        useThemeColors: true,
        actions: [
          IconButton(
            tooltip: 'Objetivos Nutricionales',
            icon: Icon(
              Icons.flag_outlined,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => _showGoalsSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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

              Map<String, double?> mergedTargets = Map<String, double?>.from(
                d.targets,
              );
              for (final k in ['kcal', 'protein', 'carbs', 'fat', 'fiber']) {
                mergedTargets[k] ??= globalTargets[k];
              }
              mergedTargets['water'] ??= globalTargets['water'];

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _ModernDaySelector(
                      date: _date,
                      onPrev:
                          () => setState(
                            () =>
                                _date = _date.subtract(const Duration(days: 1)),
                          ),
                      onNext:
                          () => setState(
                            () => _date = _date.add(const Duration(days: 1)),
                          ),
                      onToday: () => setState(() => _date = DateTime.now()),
                    ).animate().slideY(begin: -0.2, duration: 300.ms),
                  ),

                  SliverToBoxAdapter(
                    child: _MacrosSummary(day: d, mergedTargets: mergedTargets)
                        .animate()
                        .fadeIn(delay: 100.ms)
                        .slideY(begin: 0.2, duration: 300.ms),
                  ),

                  SliverToBoxAdapter(
                    child: _ModernWaterCard(
                          water: d.waterMl,
                          waterTarget: (mergedTargets['water'] ?? 2000).toInt(),
                          onAdd: (ml) => widget.svc.incrementWater(dayId, ml),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.2, duration: 300.ms),
                  ),

                  if (d.entries.isEmpty)
                    SliverFillRemaining(
                      child: ModernEmptyState(
                        icon: Icons.restaurant_outlined,
                        message: 'No hay entradas para este día',
                        subtitle:
                            'Toca el botón + para añadir tu primera comida',
                        actionLabel: 'Añadir entrada',
                        onAction: () => _showAddEntrySheet(context, dayId),
                      ),
                    )
                  else
                    ..._buildMealSections(d.entries, dayId),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildMealSections(List<IntakeEntry> entries, String dayId) {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final entry = entries[index];
            return _EntryCard(
                  entry: entry,
                  onDuplicate:
                      () => widget.svc.addEntry(
                        dayId,
                        IntakeEntry(
                          id: '',
                          type: entry.type,
                          refId: entry.refId,
                          qty: entry.qty,
                          unit: entry.unit,
                          nameSnapshot: entry.nameSnapshot,
                          macrosSnapshot: entry.macrosSnapshot,
                        ),
                      ),
                  onDelete: () => widget.svc.deleteEntry(dayId, index),
                )
                .animate()
                .fadeIn(delay: (300 + index * 50).ms)
                .slideX(begin: -0.2, duration: 300.ms);
          }, childCount: entries.length),
        ),
      ),
    ];
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
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border:
            isDark
                ? Border.all(color: colorScheme.outline.withOpacity(0.2))
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
                        ModernBadge(label: 'HOY', color: colorScheme.primary),
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
            const SizedBox(height: AppSpacing.sm),
            ModernPrimaryButton(
              label: 'Ir a hoy',
              icon: Icons.today,
              onPressed: onToday,
              color: colorScheme.primary,
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

class _MacrosSummary extends StatelessWidget {
  final DailyIntakeDoc day;
  final Map<String, double?> mergedTargets;

  const _MacrosSummary({required this.day, required this.mergedTargets});

  @override
  Widget build(BuildContext context) {
    final t = day.totals;
    final g = mergedTargets;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nutrición del Día', style: AppTypography.heading3(context)),
          const SizedBox(height: AppSpacing.md),

          Card(
            elevation: AppSpacing.elevationMd,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.foodGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Calorías',
                        style: AppTypography.heading3(
                          context,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      Icon(
                        Icons.local_fire_department,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 32,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        (t['kcal'] ?? 0).toStringAsFixed(0),
                        style: AppTypography.heading1(
                          context,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ).copyWith(fontSize: 48),
                      ),
                      if (g['kcal'] != null) ...[
                        Text(
                          ' / ${g['kcal']!.toStringAsFixed(0)}',
                          style: AppTypography.heading3(
                            context,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withOpacity(0.7),
                          ),
                        ),
                      ],
                      Text(
                        ' kcal',
                        style: AppTypography.body(
                          context,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (g['kcal'] != null)
                    ModernProgressBar(
                      value: _pct(t['kcal'] ?? 0, g['kcal']),
                      color: Theme.of(context).colorScheme.onPrimary,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withOpacity(0.3),
                      height: 8,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.5,
            children: [
              _MacroCard(
                label: 'Proteínas',
                value: t['protein'] ?? 0,
                target: g['protein'],
                unit: 'g',
                color: AppColors.error,
                icon: Icons.fitness_center,
              ),
              _MacroCard(
                label: 'Carbohidratos',
                value: t['carbs'] ?? 0,
                target: g['carbs'],
                unit: 'g',
                color: AppColors.warning,
                icon: Icons.bakery_dining,
              ),
              _MacroCard(
                label: 'Grasas',
                value: t['fat'] ?? 0,
                target: g['fat'],
                unit: 'g',
                color: AppColors.gym,
                icon: Icons.water_drop,
              ),
              _MacroCard(
                label: 'Fibra',
                value: t['fiber'] ?? 0,
                target: g['fiber'],
                unit: 'g',
                color: AppColors.success,
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

    return Card(
      elevation: AppSpacing.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.caption(context),
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
                  style: AppTypography.heading2(context, color: color),
                ),
                if (target != null) ...[
                  Text(
                    '/${target!.toStringAsFixed(0)}',
                    style: AppTypography.body(context),
                  ),
                ],
                Text(unit, style: AppTypography.caption(context)),
              ],
            ),
            if (target != null)
              ModernProgressBar(value: pct, color: color, height: 4),
          ],
        ),
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
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Card(
        elevation: AppSpacing.elevationMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      color: AppColors.info,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hidratación',
                          style: AppTypography.heading4(context),
                        ),
                        Text(
                          '$water / $waterTarget ml',
                          style: AppTypography.body(context),
                        ),
                        if (remaining > 0)
                          Text(
                            'Faltan ${remaining}ml',
                            style: AppTypography.caption(
                              context,
                              color: AppColors.warning,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${(_pct() * 100).toStringAsFixed(0)}%',
                    style: AppTypography.heading3(
                      context,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ModernProgressBar(
                value: _pct(),
                color: AppColors.info,
                height: 8,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onAdd(250),
                      icon: const Icon(Icons.add),
                      label: const Text('250ml'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.info,
                        side: const BorderSide(color: AppColors.info),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onAdd(500),
                      icon: const Icon(Icons.add),
                      label: const Text('500ml'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.info,
                        side: const BorderSide(color: AppColors.info),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: () => _showCustomWaterDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Icon(Icons.edit),
                  ),
                ],
              ),
            ],
          ),
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
            content: ModernTextField(
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

    return Card(
      elevation: AppSpacing.elevationSm,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.food.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      entry.type == FavoriteType.food
                          ? Icons.restaurant
                          : Icons.menu_book,
                      color: AppColors.food,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.nameSnapshot,
                          style: AppTypography.heading4(context),
                        ),
                        Text(
                          '${entry.qty.toStringAsFixed(0)} ${entry.unit.name}',
                          style: AppTypography.caption(context),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
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
                                Icon(Icons.copy),
                                SizedBox(width: 8),
                                Text('Duplicar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'del',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: AppColors.error),
                                SizedBox(width: 8),
                                Text(
                                  'Eliminar',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroChip(
                    label: '${kcal.toStringAsFixed(0)} kcal',
                    icon: Icons.local_fire_department,
                    color: AppColors.food,
                  ),
                  _MacroChip(
                    label: '${protein.toStringAsFixed(0)}g P',
                    icon: Icons.fitness_center,
                    color: AppColors.error,
                  ),
                  _MacroChip(
                    label: '${carbs.toStringAsFixed(0)}g C',
                    icon: Icons.bakery_dining,
                    color: AppColors.warning,
                  ),
                  _MacroChip(
                    label: '${fat.toStringAsFixed(0)}g G',
                    icon: Icons.water_drop,
                    color: AppColors.info,
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

class _MacroChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.caption(context)),
      ],
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
                        : AppColors.grey300,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  Icon(Icons.add_circle, color: colorScheme.primary, size: 28),
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

            TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor:
                  isDark
                      ? colorScheme.onSurface.withOpacity(0.6)
                      : AppColors.grey600,
              indicatorColor: colorScheme.primary,
              tabs: const [
                Tab(icon: Icon(Icons.flash_on), text: 'Quick'),
                Tab(icon: Icon(Icons.star), text: 'Favoritos'),
                Tab(icon: Icon(Icons.restaurant), text: 'Alimentos'),
                Tab(icon: Icon(Icons.menu_book), text: 'Recetas'),
              ],
            ),

            SizedBox(
              height: 500,
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Añade calorías rápidamente',
            style: AppTypography.body(context),
          ),
          const SizedBox(height: AppSpacing.xl),

          ModernTextField(
            label: 'Nombre',
            hint: 'Ej: Snack casero',
            controller: _nameController,
            prefixIcon: Icons.edit,
          ),
          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              Expanded(
                child: ModernTextField(
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
                child: ModernTextField(
                  label: 'Proteínas (g)',
                  hint: '20',
                  controller: _proteinController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.fitness_center,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          ModernPrimaryButton(
            label: 'Añadir Quick Entry',
            icon: Icons.check,
            fullWidth: true,
            color: Theme.of(context).colorScheme.primary,
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ModernTextField(
            label: 'Buscar favoritos',
            hint: 'Busca por nombre...',
            controller: _searchController,
            prefixIcon: Icons.search,
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ModernTextField(
            label: 'Buscar alimentos',
            hint: 'Busca en tu catálogo...',
            controller: _searchController,
            prefixIcon: Icons.search,
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ModernTextField(
            label: 'Buscar recetas',
            hint: 'Busca tus recetas...',
            controller: _searchController,
            prefixIcon: Icons.search,
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
          child: ModernTextField(
            label: isRecipe ? 'Raciones' : 'Cantidad',
            controller: _qtyController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.numbers,
          ),
        ),
        if (!isRecipe) ...[
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.grey300),
            ),
            child: DropdownButton<UnitKind>(
              value: _unit,
              underline: const SizedBox(),
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
            ? 'Quick add'
            : _nameController.text.trim();
    final kcal = double.tryParse(_kcalController.text) ?? 0;
    final protein = double.tryParse(_proteinController.text) ?? 0;

    if (kcal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las calorías son requeridas')),
      );
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
                            : AppColors.grey300,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),

              Row(
                children: [
                  Icon(Icons.flag, color: colorScheme.primary, size: 28),
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

              const SizedBox(height: AppSpacing.xl),

              ModernTextField(
                label: 'Calorías objetivo (kcal)',
                hint: '2000',
                controller: _kcalController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.local_fire_department,
              ),

              const SizedBox(height: AppSpacing.lg),

              ModernTextField(
                label: 'Proteínas (g)',
                hint: '150',
                controller: _proteinController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.fitness_center,
              ),

              const SizedBox(height: AppSpacing.lg),

              ModernTextField(
                label: 'Carbohidratos (g)',
                hint: '250',
                controller: _carbsController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.bakery_dining,
              ),

              const SizedBox(height: AppSpacing.lg),

              ModernTextField(
                label: 'Grasas (g)',
                hint: '65',
                controller: _fatController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.water_drop,
              ),

              const SizedBox(height: AppSpacing.lg),

              ModernTextField(
                label: 'Fibra (g)',
                hint: '30',
                controller: _fiberController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.eco,
              ),

              const SizedBox(height: AppSpacing.lg),

              ModernTextField(
                label: 'Agua (ml)',
                hint: '2000',
                controller: _waterController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.water_drop,
              ),

              const SizedBox(height: AppSpacing.xxl),

              ModernPrimaryButton(
                label: 'Guardar Objetivos',
                icon: Icons.check,
                fullWidth: true,
                color: colorScheme.primary,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Objetivos guardados correctamente')),
      );
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
          return ModernEmptyState(
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
            return ModernListCard(
              title: f.alias ?? '${f.type.name} • ${f.refId}',
              subtitle:
                  'Por defecto: ${f.defaultQty.toStringAsFixed(0)} ${f.defaultUnit.name}',
              leadingIcon:
                  f.type == FavoriteType.food
                      ? Icons.restaurant
                      : Icons.menu_book,
              leadingColor: AppColors.food,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
          return ModernEmptyState(
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
            return ModernListCard(
              title: f.name,
              subtitle:
                  '${f.kcal.toStringAsFixed(0)} kcal por ${f.unitSize.toStringAsFixed(0)} ${f.perUnit.name}',
              leadingIcon: Icons.restaurant,
              leadingColor: f.color ?? AppColors.food,
              trailing: const Icon(Icons.add, color: AppColors.food),
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
          return ModernEmptyState(
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

            return ModernListCard(
              title: r.name,
              subtitle: macrosText,
              leadingIcon: Icons.menu_book,
              leadingColor: AppColors.gym,
              trailing: const Icon(Icons.add, color: AppColors.food),
              onTap: () => onPick(r),
            );
          },
        );
      },
    );
  }
}
