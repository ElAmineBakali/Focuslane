import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/global_ui_theme.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';

/// 📅 PLANIFICADOR V2 - Diseño moderno con gestión de múltiples planners
class FoodPlannerScreenV2 extends StatefulWidget {
  final FoodFirestoreService svc;
  const FoodPlannerScreenV2({super.key, required this.svc});

  @override
  State<FoodPlannerScreenV2> createState() => _FoodPlannerScreenV2State();
}

class _FoodPlannerScreenV2State extends State<FoodPlannerScreenV2> {
  String _currentPlannerId = 'menu';
  ShoppingScope _scope = ShoppingScope.weekly;
  bool _showPlannersList = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernGradientAppBar(
        title: 'Planificador de Comidas',
        primaryColor: AppColors.food,
        secondaryColor: AppColors.warning,
        actions: [
          // Selector de planner actual
          TextButton.icon(
            onPressed: () => setState(() => _showPlannersList = !_showPlannersList),
            icon: const Icon(Icons.restaurant_menu, color: Colors.white, size: 18),
            label: Text(
              _getPlannerName(),
              style: AppTypography.button(context).copyWith(color: Colors.white),
            ),
          ),
          // Selector de scope
          PopupMenuButton<ShoppingScope>(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            tooltip: 'Alcance del planner',
            onSelected: (scope) => setState(() => _scope = scope),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ShoppingScope.weekly,
                child: Row(
                  children: [
                    Icon(
                      _scope == ShoppingScope.weekly ? Icons.check : Icons.calendar_view_week,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Semanal'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ShoppingScope.biweekly,
                child: Row(
                  children: [
                    Icon(
                      _scope == ShoppingScope.biweekly ? Icons.check : Icons.calendar_view_week,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Quincenal (x2)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ShoppingScope.monthly,
                child: Row(
                  children: [
                    Icon(
                      _scope == ShoppingScope.monthly ? Icons.check : Icons.calendar_view_month,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Mensual (x4)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ShoppingScope.custom,
                child: Row(
                  children: [
                    Icon(
                      _scope == ShoppingScope.custom ? Icons.check : Icons.settings,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Personalizado'),
                  ],
                ),
              ),
            ],
          ),
          // Generar lista de compras
          IconButton(
            icon: const Icon(Icons.shopping_cart_checkout, color: Colors.white),
            tooltip: 'Generar lista de compras',
            onPressed: _generateShoppingList,
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista de planners (desplegable)
          if (_showPlannersList) _buildPlannersList(),
          // Tabla del planner actual
          Expanded(
            child: _buildWeekPlannerTable(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewPlanner,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Planner'),
        backgroundColor: AppColors.food,
      ),
    );
  }

  Widget _buildPlannersList() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.foodGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('weekPlanners')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }

          final planners = snapshot.data!.docs;
          
          return SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              itemCount: planners.length,
              itemBuilder: (context, index) {
                final planner = planners[index];
                final isSelected = planner.id == _currentPlannerId;
                
                return GestureDetector(
                  onTap: () => setState(() {
                    _currentPlannerId = planner.id;
                    _showPlannersList = false;
                  }),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: isSelected ? AppColors.food : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              color: isSelected ? AppColors.food : AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                planner.id,
                                style: AppTypography.label(context).copyWith(
                                  color: isSelected ? AppColors.food : AppColors.textSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Última edición',
                          style: AppTypography.caption(context).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatDate(planner.get('updatedAt')),
                          style: AppTypography.caption(context).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().scale(delay: Duration(milliseconds: index * 50));
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
        final slots = MealSlot.values;

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
                final contentW = viewW < 1800 ? 1800.0 : viewW;

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
                            // Instrucciones
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'Tap para añadir • Mantén pulsado para eliminar',
                                      style: AppTypography.caption(context).copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                ModernBadge(
                                  label: _getScopeLabel(_scope),
                                  color: AppColors.food,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Tabla moderna
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Table(
                                columnWidths: const {
                                  0: FixedColumnWidth(140),
                                },
                                defaultColumnWidth: const FixedColumnWidth(240),
                                border: TableBorder.all(
                                  color: AppColors.borderLight,
                                  width: 1,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                ),
                                children: [
                                  // Header row
                                  TableRow(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.foodGradient,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(AppSpacing.radiusLg),
                                        topRight: Radius.circular(AppSpacing.radiusLg),
                                      ),
                                    ),
                                    children: [
                                      _buildHeaderCell(''),
                                      ...days.map((d) => _buildHeaderCell(d)),
                                    ],
                                  ),
                                  // Meal slot rows
                                  ...slots.asMap().entries.map((entry) {
                                    final slotIndex = entry.key;
                                    final slot = entry.value;
                                    
                                    return TableRow(
                                      decoration: BoxDecoration(
                                        color: slotIndex.isEven
                                            ? Colors.grey[50]
                                            : Colors.white,
                                      ),
                                      children: [
                                        _buildSlotHeaderCell(_getSlotName(slot)),
                                        ...dayKeys.asMap().entries.map((dayEntry) {
                                          final dayIndex = dayEntry.key;
                                          final dayKey = dayEntry.value;
                                          final entries = planner.days[dayKey] ?? const [];
                                          final slotEntries = entries.where((e) => e.slot == slot).toList();
                                          
                                          return _buildMealCell(
                                            planner: planner,
                                            dayKey: dayKey,
                                            slot: slot,
                                            entries: slotEntries,
                                            foodsMap: foodsMap,
                                            delay: (slotIndex * 7 + dayIndex) * 30,
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTypography.label(context).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSlotHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(_getSlotIcon(text), size: 18, color: AppColors.food),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: AppTypography.label(context).copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
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
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: entries.isEmpty
            ? Center(
                child: Icon(
                  Icons.add_circle_outline,
                  color: AppColors.textSecondary.withOpacity(0.5),
                  size: 32,
                ),
              )
            : Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: entries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final plannerEntry = entry.value;
                  final food = foodsMap[plannerEntry.refId];
                  
                  return GestureDetector(
                    onLongPress: () => _deleteEntry(planner, dayKey, slot, index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.food.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.food.withOpacity(0.3)),
                      ),
                      child: Text(
                        food?.name ?? plannerEntry.refId,
                        style: AppTypography.caption(context).copyWith(
                          color: AppColors.food,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay));
  }

  // Métodos auxiliares
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
        return 'Snack';
      case MealSlot.lunch:
        return 'Comida';
      case MealSlot.merienda:
        return 'Merienda';
      case MealSlot.dinner:
        return 'Cena';
    }
  }

  IconData _getSlotIcon(String slotName) {
    switch (slotName) {
      case 'Desayuno':
        return Icons.wb_sunny_outlined;
      case 'Snack':
        return Icons.apple;
      case 'Comida':
        return Icons.lunch_dining;
      case 'Merienda':
        return Icons.coffee;
      case 'Cena':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
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

  // Acciones
  Future<void> _generateShoppingList() async {
    try {
      await widget.svc.generateShoppingFromWeek(
        _currentPlannerId,
        scopeOverride: _scope,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Text('Lista de compras generada (${_getScopeLabel(_scope)})'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _createNewPlanner() async {
    final controller = TextEditingController();
    
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Planner'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre del planner',
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
      final newPlanner = WeekPlanner(
        id: name,
        scope: _scope,
        days: {},
      );
      await widget.svc.saveWeek(newPlanner);
      
      setState(() {
        _currentPlannerId = name;
        _showPlannersList = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Planner "$name" creado'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
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
              const Divider(height: 1),
              // Lista de alimentos
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.food.withOpacity(0.2),
                        child: const Icon(Icons.restaurant, size: 20),
                      ),
                      title: Text(food.name, style: AppTypography.body(context)),
                      subtitle: food.brand != null
                          ? Text(food.brand!, style: AppTypography.caption(context))
                          : null,
                      trailing: Text(
                        '${food.kcal.toStringAsFixed(0)} kcal',
                        style: AppTypography.label(context).copyWith(color: AppColors.food),
                      ),
                      onTap: () async {
                        await _addFoodToSlot(planner, dayKey, slot, food.id);
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
    final dayList = List<PlannerDayEntry>.from(planner.days[dayKey] ?? const []);
    dayList.add(PlannerDayEntry(
      slot: slot,
      type: FavoriteType.food,
      refId: foodId,
      servings: 1.0,
    ));
    
    final newDays = Map<String, List<PlannerDayEntry>>.from(planner.days);
    newDays[dayKey] = dayList;
    
    await widget.svc.saveWeek(
      WeekPlanner(
        id: _currentPlannerId,
        scope: _scope,
        days: newDays,
      ),
    );
  }

  Future<void> _deleteEntry(
    WeekPlanner planner,
    String dayKey,
    MealSlot slot,
    int index,
  ) async {
    final dayList = List<PlannerDayEntry>.from(planner.days[dayKey] ?? const []);
    final filtered = dayList.where((e) => e.slot == slot).toList();
    
    if (index >= filtered.length) return;
    
    final target = filtered[index];
    dayList.remove(target);
    
    final newDays = Map<String, List<PlannerDayEntry>>.from(planner.days);
    newDays[dayKey] = dayList;
    
    await widget.svc.saveWeek(
      WeekPlanner(
        id: _currentPlannerId,
        scope: _scope,
        days: newDays,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alimento eliminado'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
