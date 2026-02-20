import 'package:flutter/material.dart';
import '../../../theme/focuslane_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../theme/global_ui_theme.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';
import '../widgets/food_compact_widgets.dart';

class FoodPlannerScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  const FoodPlannerScreen({super.key, required this.svc});

  @override
  State<FoodPlannerScreen> createState() => _FoodPlannerScreenState();
}

class _FoodPlannerScreenState extends State<FoodPlannerScreen> {
  String _currentPlannerId = 'menu';
  ShoppingScope _scope = ShoppingScope.weekly;
  bool _showPlannersList = false;
  String _selectedMobileDay = 'lunes';

  List<Map<String, dynamic>> _enabledSlots = [];
  bool _slotsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSlotsConfig();
  }

  Future<void> _loadSlotsConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final slotsJson = prefs.getString('meal_slots_config');

    if (slotsJson != null) {
      final List<dynamic> decoded = jsonDecode(slotsJson);
      setState(() {
        _enabledSlots =
            decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        _slotsLoaded = true;
      });
    } else {
      setState(() {
        _enabledSlots = [
          {
            'slot': 'breakfast',
            'name': 'Desayuno',
            'icon': Icons.wb_sunny.codePoint,
            'enabled': true,
          },
          {
            'slot': 'snack',
            'name': 'Media Mañana',
            'icon': Icons.cookie.codePoint,
            'enabled': true,
          },
          {
            'slot': 'lunch',
            'name': 'Almuerzo',
            'icon': Icons.restaurant.codePoint,
            'enabled': true,
          },
          {
            'slot': 'merienda',
            'name': 'Merienda',
            'icon': Icons.icecream.codePoint,
            'enabled': true,
          },
          {
            'slot': 'dinner',
            'name': 'Cena',
            'icon': Icons.dinner_dining.codePoint,
            'enabled': true,
          },
        ];
        _slotsLoaded = true;
      });
    }
  }

  List<MealSlot> _getActiveSlots() {
    final slotMap = {
      'breakfast': MealSlot.breakfast,
      'snack': MealSlot.snack,
      'lunch': MealSlot.lunch,
      'merienda': MealSlot.merienda,
      'dinner': MealSlot.dinner,
    };

    return _enabledSlots
        .where((s) => s['enabled'] == true)
        .map((s) => slotMap[s['slot']])
        .whereType<MealSlot>()
        .toList();
  }

  String _getConfiguredSlotName(MealSlot slot) {
    final slotKey = slot.toString().split('.').last;
    final config = _enabledSlots.firstWhere(
      (s) => s['slot'] == slotKey,
      orElse: () => {'name': _getSlotName(slot)},
    );
    return config['name'] ?? _getSlotName(slot);
  }

  IconData _getConfiguredSlotIcon(MealSlot slot) {
    final slotKey = slot.toString().split('.').last;
    final config = _enabledSlots.firstWhere(
      (s) => s['slot'] == slotKey,
      orElse: () => {'icon': _getSlotIcon(slot).codePoint},
    );
    return IconData(
      config['icon'] ?? _getSlotIcon(slot).codePoint,
      fontFamily: 'MaterialIcons',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FoodCompactAppBar(
        title: 'Planificador',
        subtitle: _getPlannerName(),
        actions: [
          IconButton(
            onPressed:
                () => setState(() => _showPlannersList = !_showPlannersList),
            icon: const Icon(Icons.restaurant_menu, size: 18),
            tooltip: 'Cambiar planner',
          ),
          PopupMenuButton<ShoppingScope>(
            icon: const Icon(Icons.calendar_today, size: 18),
            tooltip: 'Alcance del planner',
            onSelected: (scope) => setState(() => _scope = scope),
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: ShoppingScope.weekly,
                    child: Row(
                      children: [
                        Icon(
                          _scope == ShoppingScope.weekly
                              ? Icons.check
                              : Icons.calendar_view_week,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('Semanal'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ShoppingScope.biweekly,
                    child: Row(
                      children: [
                        Icon(
                          _scope == ShoppingScope.biweekly
                              ? Icons.check
                              : Icons.calendar_view_week,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('Quincenal (x2)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ShoppingScope.monthly,
                    child: Row(
                      children: [
                        Icon(
                          _scope == ShoppingScope.monthly
                              ? Icons.check
                              : Icons.calendar_view_month,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('Mensual (x4)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ShoppingScope.custom,
                    child: Row(
                      children: [
                        Icon(
                          _scope == ShoppingScope.custom
                              ? Icons.check
                              : Icons.settings,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('Personalizado'),
                      ],
                    ),
                  ),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.edit_calendar, size: 18),
            tooltip: 'Configurar comidas',
            onPressed: _configureMealSlots,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_checkout, size: 18),
            tooltip: 'Generar lista',
            onPressed: _generateShoppingList,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;
          return Column(
            children: [
              _buildRealtimeStatusBar(),
              if (_showPlannersList) _buildPlannersList(),
              if (isMobile) _buildMobileDaySelector(),
              Expanded(
                child:
                    isMobile
                        ? _buildMobileDayView(_selectedMobileDay)
                        : _buildWeekPlannerTable(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewPlanner,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  Widget _buildRealtimeStatusBar() {
    return StreamBuilder<Map<String, double?>>(
      stream: widget.svc.streamGlobalTargets(),
      builder: (context, targetsSnap) {
        final targetKcal = targetsSnap.data?['kcal'] ?? 2000;
        final targetProtein = targetsSnap.data?['protein'] ?? 120;
        return StreamBuilder<Map<String, dynamic>>(
          stream: widget.svc.streamAlerts(),
          builder: (context, alertsSnap) {
            final alerts = alertsSnap.data ?? const {};
            final overBudget = alerts['foodOverBudget'] == true;
            final proteinLow = alerts['foodProteinLowAfterWorkout'] == true;
            final extremeDeficit = alerts['foodExtremeDeficitWorkout'] == true;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    label: Text('Objetivo kcal ${targetKcal.toStringAsFixed(0)}'),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text('Objetivo proteína ${targetProtein.toStringAsFixed(0)}g'),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (proteinLow)
                    Chip(
                      label: const Text('Proteína baja tras entreno'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (extremeDeficit)
                    Chip(
                      label: const Text('Déficit extremo con entreno fuerte'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (overBudget)
                    Chip(
                      label: const Text('Presupuesto food superado'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlannersList() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('weekPlanners')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }

          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final planners = snapshot.data!.docs;

          return SizedBox(
            height: 88,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              itemCount: planners.length,
              itemBuilder: (context, index) {
                final planner = planners[index];
                final isSelected = planner.id == _currentPlannerId;

                return GestureDetector(
                  onTap: () {
                    widget.svc.setActiveWeekPlanner(planner.id);
                    setState(() {
                      _currentPlannerId = planner.id;
                      _showPlannersList = false;
                    });
                  },
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? colorScheme.surface
                              : colorScheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color:
                            isSelected
                                ? FocuslaneUI.accent(context)
                                : Colors.transparent,
                        width: FocuslaneUI.borderW,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).dividerColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              color:
                                  isSelected
                                      ? FocuslaneUI.accent(context)
                                      : AppColors.textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                planner.id,
                                style: AppTypography.label(context).copyWith(
                                  color:
                                      isSelected
                                      ? FocuslaneUI.accent(context)
                                          : AppColors.textSecondary,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Última edición',
                          style: AppTypography.caption(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                        Text(
                          _formatDate(planner.get('updatedAt')),
                          style: AppTypography.caption(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().scale(
                  delay: Duration(milliseconds: index * 50),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekPlannerTable() {
    return StreamBuilder<WeekPlanner>(
      stream: widget.svc.streamWeek(_currentPlannerId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final planner = snap.data!;
        final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
        final dayKeys = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final slots = _slotsLoaded ? _getActiveSlots() : MealSlot.values;

        return StreamBuilder<List<Food>>(
          stream: widget.svc.streamFoods(),
          builder: (context, foodsSnap) {
            if (!foodsSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final foods = foodsSnap.data!;
            final foodsMap = {for (final f in foods) f.id: f};

            return LayoutBuilder(
              builder: (context, constraints) {
                final viewW = constraints.maxWidth;
                final contentW = viewW < 1400 ? 1400.0 : viewW;

                return InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 0.7,
                  maxScale: 2.0,
                  boundaryMargin: const EdgeInsets.all(32),
                  child: Center(
                    child: SizedBox(
                      width: contentW,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                        size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                      const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'Toca para añadir • Mantén pulsado para eliminar',
                                      style: AppTypography.caption(
                                        context,
                                      ).copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                ModernBadge(
                                  label: _getScopeLabel(_scope),
                                  color: FocuslaneUI.accent(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).dividerColor.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Table(
                                columnWidths: const {0: FixedColumnWidth(90)},
                                defaultColumnWidth: const FixedColumnWidth(170),
                                border: TableBorder.all(
                                  color: FocuslaneUI.borderColor(context),
                                  width: FocuslaneUI.borderW,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusLg,
                                  ),
                                ),
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondaryContainer,
                                        ],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(
                                          AppSpacing.radiusLg,
                                        ),
                                        topRight: Radius.circular(
                                          AppSpacing.radiusLg,
                                        ),
                                      ),
                                    ),
                                    children: [
                                      _buildHeaderCell(''),
                                      ...days.map((d) => _buildHeaderCell(d)),
                                    ],
                                  ),
                                  ...slots.asMap().entries.map((entry) {
                                    final slotIndex = entry.key;
                                    final slot = entry.value;
                                    final cs = Theme.of(context).colorScheme;

                                    return TableRow(
                                      decoration: BoxDecoration(
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? cs.surface
                                                : (slotIndex.isEven
                                                    ? cs.surfaceContainerHighest
                                                    : cs.surface),
                                      ),
                                      children: [
                                        _buildSlotHeaderCell(
                                          _getConfiguredSlotName(slot),
                                          _getConfiguredSlotIcon(slot),
                                        ),
                                        ...dayKeys.asMap().entries.map((
                                          dayEntry,
                                        ) {
                                          final dayIndex = dayEntry.key;
                                          final dayKey = dayEntry.value;
                                          final entries =
                                              planner.days[dayKey] ?? const [];
                                          final slotEntries =
                                              entries
                                                  .where((e) => e.slot == slot)
                                                  .toList();

                                          return _buildMealCell(
                                            planner: planner,
                                            dayKey: dayKey,
                                            slot: slot,
                                            entries: slotEntries,
                                            foodsMap: foodsMap,
                                            delay:
                                                (slotIndex * 7 + dayIndex) * 30,
                                          );
                                        }),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTypography.caption(context).copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildSlotHeaderCell(String text, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(icon, size: 16, color: FocuslaneUI.accent(context)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption(context).copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCell({
    required WeekPlanner planner,
    required String dayKey,
    required MealSlot slot,
    required List<PlannerDayEntry> entries,
    required Map<String, Food> foodsMap,
    required int delay,
  }) {
    return GestureDetector(
      onTap: () => _openFoodSelector(planner, dayKey, slot, foodsMap),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.all(6),
        child:
            entries.isEmpty
                ? Center(
                  child: Icon(
                    Icons.add_circle_outline,
                    color: AppColors.textSecondary.withOpacity(0.5),
                    size: 24,
                  ),
                )
                : Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children:
                      entries.asMap().entries.map((entry) {
                        final index = entry.key;
                        final plannerEntry = entry.value;
                        final food = foodsMap[plannerEntry.refId];

                        return GestureDetector(
                          onLongPress:
                              () => _deleteEntry(planner, dayKey, slot, index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: FocuslaneUI.accentSurface(
                                context,
                                opacity: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: FocuslaneUI.borderColor(context),
                                width: FocuslaneUI.borderW,
                              ),
                            ),
                            child: Text(
                              food?.name ?? plannerEntry.refId,
                              style: AppTypography.caption(context).copyWith(
                                color: FocuslaneUI.accent(context),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay));
  }

  String _getPlannerName() {
    if (_currentPlannerId == 'menu') return 'Principal';
    return _currentPlannerId.length > 12
        ? '${_currentPlannerId.substring(0, 12)}...'
        : _currentPlannerId;
  }

  String _getScopeLabel(ShoppingScope scope) {
    switch (scope) {
      case ShoppingScope.weekly:
        return 'Semanal';
      case ShoppingScope.biweekly:
        return 'Quincenal';
      case ShoppingScope.monthly:
        return 'Mensual';
      case ShoppingScope.custom:
        return 'Personalizado';
    }
  }

  String _getSlotName(MealSlot slot) {
    switch (slot) {
      case MealSlot.breakfast:
        return 'Desayuno';
      case MealSlot.snack:
        return 'Aperitivo';
      case MealSlot.lunch:
        return 'Comida';
      case MealSlot.merienda:
        return 'Merienda';
      case MealSlot.dinner:
        return 'Cena';
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Reciente';
    try {
      final date = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) return 'Hoy';
      if (diff.inDays == 1) return 'Ayer';
      if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Reciente';
    }
  }

  Future<void> _generateShoppingList() async {
    try {
      await widget.svc.generateShoppingFromWeek(
        _currentPlannerId,
        scopeOverride: _scope,
      );

      if (mounted) {
        FoodFeedback.showSuccess(
          context,
          'Lista generada (${_getScopeLabel(_scope)})',
        );
      }
    } catch (e) {
      if (mounted) {
        FoodFeedback.showError(context, 'Error al generar: $e');
      }
    }
  }

  Future<void> _configureMealSlots() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _MealSlotsConfigSheet(
            onConfigSaved: () {
              _loadSlotsConfig();
            },
          ),
    );
  }

  Future<void> _createNewPlanner() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Nuevo planificador'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Nombre del planificador',
                hintText: 'Ej: Definición, Volumen, Familiar',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Crear'),
              ),
            ],
          ),
    );

    if (name != null && name.isNotEmpty) {
      final newPlanner = WeekPlanner(id: name, scope: _scope, days: {});
      await widget.svc.saveWeek(newPlanner);
      await widget.svc.setActiveWeekPlanner(name);

      setState(() {
        _currentPlannerId = name;
        _showPlannersList = false;
      });

      if (mounted) {
        FoodFeedback.showSuccess(context, 'Planificador "$name" creado');
      }
    }
  }

  Future<void> _openFoodSelector(
    WeekPlanner planner,
    String dayKey,
    MealSlot slot,
    Map<String, Food> foodsMap,
  ) async {
    final foods = foodsMap.values.toList();

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusXl),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: AppSpacing.sm),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? colorScheme.onSurface.withOpacity(0.3)
                                  : FocuslaneUI.borderColor(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Selecciona alimentos',
                                style: AppTypography.heading3(context),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: FocuslaneUI.dividerW,
                        thickness: FocuslaneUI.dividerW,
                        color: FocuslaneUI.dividerColor(context),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: foods.length,
                          itemBuilder: (context, index) {
                            final food = foods[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    FocuslaneUI.accentSurface(
                                      context,
                                      opacity: 0.18,
                                    ),
                                child: const Icon(Icons.restaurant, size: 20),
                              ),
                              title: Text(
                                food.name,
                                style: AppTypography.body(context),
                              ),
                              subtitle:
                                  food.brand != null
                                      ? Text(
                                        food.brand!,
                                        style: AppTypography.caption(context),
                                      )
                                      : null,
                              trailing: Text(
                                '${food.kcal.toStringAsFixed(0)} kcal',
                                style: AppTypography.label(
                                  context,
                                ).copyWith(color: FocuslaneUI.accent(context)),
                              ),
                              onTap: () async {
                                await _addFoodToSlot(
                                  planner,
                                  dayKey,
                                  slot,
                                  food.id,
                                );
                                if (context.mounted) Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Future<void> _addFoodToSlot(
    WeekPlanner planner,
    String dayKey,
    MealSlot slot,
    String foodId,
  ) async {
    final dayList = List<PlannerDayEntry>.from(
      planner.days[dayKey] ?? const [],
    );
    dayList.add(
      PlannerDayEntry(
        slot: slot,
        type: FavoriteType.food,
        refId: foodId,
        servings: 1.0,
      ),
    );

    final newDays = Map<String, List<PlannerDayEntry>>.from(planner.days);
    newDays[dayKey] = dayList;

    await widget.svc.saveWeek(
      WeekPlanner(id: _currentPlannerId, scope: _scope, days: newDays),
    );
  }

  Future<void> _deleteEntry(
    WeekPlanner planner,
    String dayKey,
    MealSlot slot,
    int index,
  ) async {
    final dayList = List<PlannerDayEntry>.from(
      planner.days[dayKey] ?? const [],
    );
    final filtered = dayList.where((e) => e.slot == slot).toList();

    if (index >= filtered.length) return;

    final target = filtered[index];
    dayList.remove(target);

    final newDays = Map<String, List<PlannerDayEntry>>.from(planner.days);
    newDays[dayKey] = dayList;

    await widget.svc.saveWeek(
      WeekPlanner(id: _currentPlannerId, scope: _scope, days: newDays),
    );

    if (mounted) {
      FoodFeedback.showSuccess(context, 'Elemento eliminado');
    }
  }

  Widget _buildMobileDaySelector() {
    final days = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day == _selectedMobileDay;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(
                day[0].toUpperCase() + day.substring(1, 3),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : colorScheme.onSurface,
                ),
              ),
              selected: isSelected,
              selectedColor: FocuslaneUI.accent(context),
              backgroundColor: colorScheme.surface,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedMobileDay = day);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileDayView(String dayKey) {
    return StreamBuilder<WeekPlanner?>(
      stream: widget.svc.streamWeek(_currentPlannerId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final planner =
            snap.data ??
            WeekPlanner(id: _currentPlannerId, scope: _scope, days: const {});
        final slots = _slotsLoaded ? _getActiveSlots() : MealSlot.values;

        return StreamBuilder<List<Food>>(
          stream: widget.svc.streamFoods(),
          builder: (context, foodsSnap) {
            if (!foodsSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final foods = foodsSnap.data!;
            final foodsMap = {for (final f in foods) f.id: f};
            final colorScheme = Theme.of(context).colorScheme;

            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: slots.length,
              itemBuilder: (context, index) {
                final slot = slots[index];
                final entries =
                    (planner.days[dayKey] ?? const [])
                        .where((e) => e.slot == slot)
                        .toList();

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    side: BorderSide(
                      color: FocuslaneUI.borderColor(context),
                      width: FocuslaneUI.borderW,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: FocuslaneUI.accentSurface(
                            context,
                            opacity: 0.16,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppSpacing.radiusMd),
                            topRight: Radius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getConfiguredSlotIcon(slot),
                              color: FocuslaneUI.accent(context),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              _getConfiguredSlotName(slot),
                              style: AppTypography.heading4(
                                context,
                              ).copyWith(color: FocuslaneUI.accent(context)),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.add_circle,
                                color: FocuslaneUI.accent(context),
                              ),
                              onPressed:
                                  () => _openFoodSelector(
                                    planner,
                                    dayKey,
                                    slot,
                                    foodsMap,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (entries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: Text(
                              'Toca + para añadir alimento',
                              style: AppTypography.caption(context),
                            ),
                          ),
                        )
                      else
                        ...entries.asMap().entries.map((mapEntry) {
                          final entryIndex = mapEntry.key;
                          final entry = mapEntry.value;
                          final food = foodsMap[entry.refId];

                          if (food == null) {
                            return ListTile(
                              title: Text('Alimento no encontrado'),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.error,
                                ),
                                onPressed:
                                    () => _deleteEntry(
                                      planner,
                                      dayKey,
                                      slot,
                                      entryIndex,
                                    ),
                              ),
                            );
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              child: Icon(
                                food.isSupplement
                                    ? Icons.medication
                                    : Icons.restaurant,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(food.name),
                            subtitle: Text(
                              '${(food.kcal * entry.servings).toStringAsFixed(0)} kcal • ${entry.servings}x porción',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed:
                                  () => _deleteEntry(
                                    planner,
                                    dayKey,
                                    slot,
                                    entryIndex,
                                  ),
                            ),
                          );
                        }),
                    ],
                  ),
                ).animate().fadeIn(delay: (index * 100).ms);
              },
            );
          },
        );
      },
    );
  }

  IconData _getSlotIcon(MealSlot slot) {
    switch (slot) {
      case MealSlot.breakfast:
        return Icons.wb_sunny;
      case MealSlot.snack:
        return Icons.cookie;
      case MealSlot.lunch:
        return Icons.restaurant;
      case MealSlot.merienda:
        return Icons.icecream;
      case MealSlot.dinner:
        return Icons.dinner_dining;
    }
  }
}

class _MealSlotsConfigSheet extends StatefulWidget {
  final VoidCallback onConfigSaved;
  const _MealSlotsConfigSheet({required this.onConfigSaved});

  @override
  State<_MealSlotsConfigSheet> createState() => _MealSlotsConfigSheetState();
}

class _MealSlotsConfigSheetState extends State<_MealSlotsConfigSheet> {
  List<Map<String, dynamic>> _slots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final slotsJson = prefs.getString('meal_slots_config');

    if (slotsJson != null) {
      final List<dynamic> decoded = jsonDecode(slotsJson);
      setState(() {
        _slots = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _slots = [
          {
            'slot': 'breakfast',
            'name': 'Desayuno',
            'icon': Icons.wb_sunny.codePoint,
            'enabled': true,
          },
          {
            'slot': 'snack',
            'name': 'Media Mañana',
            'icon': Icons.cookie.codePoint,
            'enabled': true,
          },
          {
            'slot': 'lunch',
            'name': 'Almuerzo',
            'icon': Icons.restaurant.codePoint,
            'enabled': true,
          },
          {
            'slot': 'merienda',
            'name': 'Merienda',
            'icon': Icons.icecream.codePoint,
            'enabled': true,
          },
          {
            'slot': 'dinner',
            'name': 'Cena',
            'icon': Icons.dinner_dining.codePoint,
            'enabled': true,
          },
        ];
        _isLoading = false;
      });
    }
  }

  final List<IconData> _availableIcons = [
    Icons.wb_sunny,
    Icons.cookie,
    Icons.restaurant,
    Icons.lunch_dining,
    Icons.dinner_dining,
    Icons.local_cafe,
    Icons.bakery_dining,
    Icons.fastfood,
    Icons.ramen_dining,
    Icons.icecream,
    Icons.apple,
    Icons.egg,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
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

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    Icons.edit_calendar,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configurar Comidas',
                        style: AppTypography.heading2(context),
                      ),
                      Text(
                        'Personaliza las comidas del día',
                        style: AppTypography.caption(context),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _slots.length,
                itemBuilder: (context, index) {
                  final slot = _slots[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FocuslaneUI.radius),
                      side: BorderSide(
                        color: FocuslaneUI.borderColor(context),
                        width: FocuslaneUI.borderW,
                      ),
                    ),
                    child: ListTile(
                      leading: Switch(
                        value: slot['enabled'],
                        onChanged: (v) => setState(() => slot['enabled'] = v),
                        activeThumbColor: colorScheme.primary,
                      ),
                      title: TextFormField(
                        initialValue: slot['name'],
                        decoration: InputDecoration(
                          hintText: 'Nombre de la comida',
                          enabled: slot['enabled'],
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        style: AppTypography.body(context),
                        onChanged: (v) => slot['name'] = v,
                      ),
                      trailing: PopupMenuButton<int>(
                        icon: Icon(
                          IconData(slot['icon'], fontFamily: 'MaterialIcons'),
                          color:
                              slot['enabled']
                                  ? colorScheme.primary
                                  : Colors.grey,
                        ),
                        enabled: slot['enabled'],
                        onSelected:
                            (iconCode) =>
                                setState(() => slot['icon'] = iconCode),
                        itemBuilder:
                            (context) =>
                                _availableIcons.map((icon) {
                                  return PopupMenuItem(
                                    value: icon.codePoint,
                                    child: Icon(icon),
                                  );
                                }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _slots.clear();
                        _slots.addAll([
                          {
                            'slot': 'breakfast',
                            'name': 'Desayuno',
                            'icon': Icons.wb_sunny.codePoint,
                            'enabled': true,
                          },
                          {
                            'slot': 'snack',
                            'name': 'Media Mañana',
                            'icon': Icons.cookie.codePoint,
                            'enabled': true,
                          },
                          {
                            'slot': 'lunch',
                            'name': 'Almuerzo',
                            'icon': Icons.restaurant.codePoint,
                            'enabled': true,
                          },
                          {
                            'slot': 'merienda',
                            'name': 'Merienda',
                            'icon': Icons.icecream.codePoint,
                            'enabled': true,
                          },
                          {
                            'slot': 'dinner',
                            'name': 'Cena',
                            'icon': Icons.dinner_dining.codePoint,
                            'enabled': true,
                          },
                        ]);
                      });
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Restablecer'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: ModernPrimaryButton(
                    label: 'Guardar',
                    icon: Icons.check,
                    fullWidth: true,
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final slotsJson = jsonEncode(_slots);
                      await prefs.setString('meal_slots_config', slotsJson);

                      widget.onConfigSaved();

                      if (mounted) {
                        Navigator.pop(context);
                        FoodFeedback.showSuccess(
                          context,
                          'Configuración guardada',
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
