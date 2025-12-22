import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/global_ui_components.dart';
import '../../../theme/global_ui_theme.dart';
import '../../../widgets/module_shell.dart';
import '../services/food_firestore_service.dart';
import '../models/food_models.dart';
import '../diary/food_diary_screen_v2.dart';
import '../foods/foods_list_screen_v2.dart';
import '../recipes/recipes_list_screen_v2.dart';
import '../planner/food_planner_screen_v2.dart';
import '../shopping/shopping_lists_screen_v2.dart';
import '../pantry/pantry_screen_v2.dart';
import '../history/food_history_screen_v2.dart';

   class FoodHomeScreenV2 extends StatefulWidget {
  final FoodFirestoreService svc;
  const FoodHomeScreenV2({super.key, required this.svc});

  @override
  State<FoodHomeScreenV2> createState() => _FoodHomeScreenV2State();
}

class _FoodHomeScreenV2State extends State<FoodHomeScreenV2> {
  String _dayId(DateTime d) => d.toIso8601String().substring(0, 10);

  @override
  Widget build(BuildContext context) {
    final todayId = _dayId(DateTime.now());
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FocusModuleShell(
      title: 'Alimentación',
      titleIcon: Icons.restaurant,
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'Historial',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FoodHistoryScreenV2(svc: widget.svc),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications_active_outlined),
          tooltip: 'Recordatorios',
          onPressed: () => _showRemindersSheet(context),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                  StreamBuilder<int>(
                    stream: widget.svc.streamPantry().map((items) => items.where((i) => (i.qty ?? 0) < (i.minQty ?? 0)).length),
                    builder: (context, snap) {
                      final count = snap.data ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: FocusSpacing.lg),
                        padding: const EdgeInsets.all(FocusSpacing.lg),
                        decoration: BoxDecoration(
                          color: FocusColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
                          border: Border.all(
                            color: FocusColors.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: FocusColors.warning,
                              size: 32,
                            ),
                            const SizedBox(width: FocusSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stock bajo en despensa',
                                    style: FocusTypography.heading4(context),
                                  ),
                                  Text(
                                    '$count producto${count > 1 ? 's' : ''} necesita${count > 1 ? 'n' : ''} reposición',
                                    style: FocusTypography.caption(context),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PantryScreenV2(svc: widget.svc),
                                  ),
                                );
                    },
                  ),

                  StreamBuilder<DailyIntakeDoc>(
                    stream: widget.svc.streamDay(todayId),
                    builder: (context, daySnap) {
                      return StreamBuilder<Map<String, double?>>(
                        stream: widget.svc.streamGlobalTargets(),
                        builder: (context, targetsSnap) {
                          final day = daySnap.data ??
                              DailyIntakeDoc(
                                id: todayId,
                                entries: const [],
                                waterMl: 0,
                                totals: const {
                                  'kcal': 0.0,
                                  'protein': 0.0,
                                  'carbs': 0.0,
                                  'fat': 0.0,
                                  'fiber': 0.0,
                                  'sodium': 0.0,
                                },
                                targets: const {},
                              );

                          final globalTargets = targetsSnap.data ?? const {};

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FoodDiaryScreenV2(svc: widget.svc),
                                ),
                              );
                            },
                            borderRadius:
                                BorderRadius.circular(FocusSpacing.radiusLg),
                            child: _buildDaySummary(
                              context,
                              day,
                              globalTargets,
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: FocusSpacing.xl),

                  StreamBuilder<List<String>>(
                    stream: Stream.value([]),
                    builder: (context, snap) {
                      final suggestions = snap.data ?? [];
                      if (suggestions.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sugerencias',
                            style: FocusTypography.heading3(context),
                          ),
                          const SizedBox(height: FocusSpacing.md),
                          ...suggestions.map((s) => Container(
                                margin: const EdgeInsets.only(
                                    bottom: FocusSpacing.sm),
                                padding: const EdgeInsets.all(FocusSpacing.md),
                                decoration: BoxDecoration(
                                  color: FocusColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      FocusSpacing.radiusMd),
                                  border: Border.all(
                                    color: FocusColors.info.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: FocusColors.info,
                                      size: 20,
                                    ),
                                    const SizedBox(width: FocusSpacing.md),
                                    Expanded(
                                      child: Text(
                                        s,
                                        style:
                                            FocusTypography.bodySmall(context),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: FocusSpacing.xl),
                        ],
                      );
                    },
                  ),

                  StreamBuilder<List<Favorite>>(
                    stream: widget.svc.streamFavorites(),
                    builder: (context, snap) {
                      final favs = snap.data ?? [];
                      if (favs.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Favoritos',
                                style: FocusTypography.heading3(context),
                              ),
                              TextButton(
                                onPressed: () {
                                  /* Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          FavoritesScreen(svc: widget.svc),
                                    ),
                                  ); */
                                },
                                child: const Text('Ver todos'),
                              ),
                            ],
                          ),
                          const SizedBox(height: FocusSpacing.md),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: favs.length,
                              itemBuilder: (_, i) {
                                final fav = favs[i];
                                return _buildFavoriteChip(context, fav);
                              },
                            ),
                          ),
                          const SizedBox(height: FocusSpacing.xl),
                        ],
                      );
                    },
                  ),

                  Text(
                    'Acciones Rápidas',
                    style: FocusTypography.heading3(context),
                  ),
                  const SizedBox(height: FocusSpacing.md),
                  FocusActionsGrid(
                    items: [
                      FocusActionItem(
                        title: 'Diario',
                        icon: Icons.today,
                        color: colorScheme.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FoodDiaryScreenV2(svc: widget.svc),
                            ),
                          );
                        },
                        animationDelay: 100.ms,
                      ),
                      FocusActionItem(
                        title: 'Alimentos',
                        icon: Icons.restaurant,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FoodsListScreenV2(svc: widget.svc),
                            ),
                          );
                        },
                        animationDelay: 200.ms,
                      ),
                      FocusActionItem(
                        title: 'Recetas',
                        icon: Icons.menu_book,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipesListScreenV2(svc: widget.svc),
                            ),
                          );
                        },
                        animationDelay: 300.ms,
                      ),
                      FocusActionItem(
                        title: 'Planificador',
                        icon: Icons.calendar_view_week,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FoodPlannerScreenV2(svc: widget.svc),
                            ),
                          );
                        },
                        animationDelay: 400.ms,
                      ),
                      FocusActionItem(
                        title: 'Compras',
                        icon: Icons.shopping_cart,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShoppingListsScreenV2(svc: widget.svc),
                            ),
                          );
                        },
                        animationDelay: 500.ms,
                      ),
                      FocusActionItem(
                        title: 'Despensa',
                        icon: Icons.kitchen,
                        color: Colors.brown,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PantryScreenV2(svc: widget.svc),
                            ),
                          );
                        },
                        animationDelay: 600.ms,
                      ),
                    ],
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySummary(
    BuildContext context,
    DailyIntakeDoc day,
    Map<String, double?> globalTargets,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final mergedTargets = Map<String, double?>.from(day.targets);
    for (final k in ['kcal', 'protein', 'carbs', 'fat', 'fiber']) {
      mergedTargets[k] ??= globalTargets[k];
    }
    mergedTargets['water'] ??= globalTargets['water'];

    final t = day.totals;
    final waterTarget = (mergedTargets['water'] ?? 2000).toInt();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FocusSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumen de Hoy',
                  style: FocusTypography.heading3(context),
                ),
                Icon(Icons.chevron_right, color: FocusColors.grey600),
              ],
            ),
            const SizedBox(height: FocusSpacing.lg),

            _buildMiniMacro(
              context,
              'Calorías',
              t['kcal'] ?? 0,
              mergedTargets['kcal'],
              colorScheme.primary,
              'kcal',
            ),
            _buildMiniMacro(
              context,
              'Proteínas',
              t['protein'] ?? 0,
              mergedTargets['protein'],
              Colors.red,
              'g',
            ),
            _buildMiniMacro(
              context,
              'Carbos',
              t['carbs'] ?? 0,
              mergedTargets['carbs'],
              Colors.blue,
              'g',
            ),
            _buildMiniMacro(
              context,
              'Grasas',
              t['fat'] ?? 0,
              mergedTargets['fat'],
              Colors.green,
              'g',
            ),

            const SizedBox(height: FocusSpacing.md),
            const Divider(),
            const SizedBox(height: FocusSpacing.md),

            Row(
              children: [
                Icon(Icons.water_drop, color: Colors.blue, size: 20),
                const SizedBox(width: FocusSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Agua',
                            style: FocusTypography.label(context),
                          ),
                          Text(
                            '${day.waterMl} / $waterTarget ml',
                            style: FocusTypography.caption(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: FocusSpacing.xs),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(FocusSpacing.radiusSm),
                        child: LinearProgressIndicator(
                          value: waterTarget > 0
                              ? (day.waterMl / waterTarget).clamp(0.0, 1.0)
                              : 0,
                          backgroundColor: Colors.blue.withOpacity(0.2),
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.blue),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildMiniMacro(
    BuildContext context,
    String label,
    double value,
    double? target,
    Color color,
    String unit,
  ) {
    final progress = target != null && target > 0
        ? (value / target).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: FocusSpacing.md),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: FocusSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: FocusTypography.label(context)),
                    Text(
                      '${value.toStringAsFixed(0)}${target != null ? ' / ${target.toStringAsFixed(0)}' : ''} $unit',
                      style: FocusTypography.caption(context),
                    ),
                  ],
                ),
                const SizedBox(height: FocusSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: color.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteChip(BuildContext context, Favorite fav) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: FocusSpacing.md),
      child: Material(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
        child: InkWell(
          onTap: () async {
                         final todayId = _dayId(DateTime.now());
                       },
          borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(FocusSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  fav.type == FavoriteType.food
                      ? Icons.restaurant
                      : Icons.menu_book,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(height: FocusSpacing.sm),
                Text(
                  fav.alias ?? 'Favorito',
                  style: FocusTypography.bodySmall(context),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRemindersSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RemindersSheet(svc: widget.svc),
    );
  }
}

 class _RemindersSheet extends StatefulWidget {
  final FoodFirestoreService svc;
  const _RemindersSheet({required this.svc});

  @override
  State<_RemindersSheet> createState() => _RemindersSheetState();
}

class _RemindersSheetState extends State<_RemindersSheet> {
  bool _mealReminders = false;
  bool _waterReminders = false;
  bool _supplementReminders = false;
  bool _goalReminders = false;
  
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 20, minute: 0);
  
  int _waterIntervalMinutes = 120;
  TimeOfDay _waterStartTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _waterEndTime = const TimeOfDay(hour: 22, minute: 0);
  
     TimeOfDay _goalReminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _weekendsOnly = false;
  
     List<bool> _mealDays = List.filled(7, true);    List<bool> _waterDays = List.filled(7, true);
  List<bool> _goalDays = List.filled(7, true);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.onSurface.withOpacity(0.3) : AppColors.grey300,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
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
                      Icons.notifications_active,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Recordatorios',
                      style: AppTypography.heading2(context),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              _buildReminderSection(
                icon: Icons.restaurant_menu,
                title: 'Comidas del día',
                subtitle: 'Notificaciones para desayuno, comida y cena',
                value: _mealReminders,
                onChanged: (v) => setState(() => _mealReminders = v),
                expanded: _mealReminders,
                children: [
                  _buildTimeSelector(
                    'Desayuno',
                    Icons.wb_sunny,
                    _breakfastTime,
                    (time) => setState(() => _breakfastTime = time),
                  ),
                  _buildTimeSelector(
                    'Comida',
                    Icons.restaurant,
                    _lunchTime,
                    (time) => setState(() => _lunchTime = time),
                  ),
                  _buildTimeSelector(
                    'Cena',
                    Icons.dinner_dining,
                    _dinnerTime,
                    (time) => setState(() => _dinnerTime = time),
                  ),
                  _buildDaysSelector('Días activos', _mealDays),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              _buildReminderSection(
                icon: Icons.water_drop,
                title: 'Hidratación',
                subtitle: 'Recordatorios recurrentes de agua',
                value: _waterReminders,
                onChanged: (v) => setState(() => _waterReminders = v),
                expanded: _waterReminders,
                children: [
                  ListTile(
                    leading: Icon(Icons.schedule, color: colorScheme.primary),
                    title: const Text('Intervalo'),
                    trailing: DropdownButton<int>(
                      value: _waterIntervalMinutes,
                      items: const [
                        DropdownMenuItem(value: 15, child: Text('15 min')),
                        DropdownMenuItem(value: 30, child: Text('30 min')),
                        DropdownMenuItem(value: 45, child: Text('45 min')),
                        DropdownMenuItem(value: 60, child: Text('1 hora')),
                        DropdownMenuItem(value: 90, child: Text('1.5 horas')),
                        DropdownMenuItem(value: 120, child: Text('2 horas')),
                        DropdownMenuItem(value: 180, child: Text('3 horas')),
                        DropdownMenuItem(value: 240, child: Text('4 horas')),
                      ],
                      onChanged: (v) => setState(() => _waterIntervalMinutes = v!),
                    ),
                  ),
                  _buildTimeRangeSelector(
                    'Horario activo',
                    Icons.access_time,
                    _waterStartTime,
                    _waterEndTime,
                    (start) => setState(() => _waterStartTime = start),
                    (end) => setState(() => _waterEndTime = end),
                  ),
                  _buildDaysSelector('Días activos', _waterDays),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              _buildReminderSection(
                icon: Icons.medication,
                title: 'Suplementos',
                subtitle: 'Recuerda tomar tus suplementos',
                value: _supplementReminders,
                onChanged: (v) => setState(() => _supplementReminders = v),
                expanded: _supplementReminders,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'Configura horarios personalizados para cada suplemento en su ficha individual',
                      style: AppTypography.caption(context),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              _buildReminderSection(
                icon: Icons.flag,
                title: 'Objetivos diarios',
                subtitle: 'Revisa tu progreso de calorías y macros',
                value: _goalReminders,
                onChanged: (v) => setState(() => _goalReminders = v),
                expanded: _goalReminders,
                children: [
                  _buildTimeSelector(
                    'Hora del recordatorio',
                    Icons.schedule,
                    _goalReminderTime,
                    (time) => setState(() => _goalReminderTime = time),
                  ),
                  SwitchListTile(
                    value: _weekendsOnly,
                    onChanged: (v) => setState(() => _weekendsOnly = v),
                    title: const Text('Solo en fin de semana'),
                    secondary: const Icon(Icons.weekend),
                  ),
                  if (!_weekendsOnly) _buildDaysSelector('Días activos', _goalDays),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              ModernPrimaryButton(
                label: 'Guardar Preferencias',
                icon: Icons.save,
                fullWidth: true,
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: AppSpacing.sm),
                          const Text('Preferencias guardadas'),
                        ],
                      ),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      margin: const EdgeInsets.all(AppSpacing.md),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool expanded,
    List<Widget> children = const [],
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 2,
      child: Column(
        children: [
          SwitchListTile(
            value: value,
            onChanged: onChanged,
            title: Text(title, style: AppTypography.heading4(context)),
            subtitle: Text(subtitle),
            secondary: Icon(icon, color: colorScheme.primary),
          ),
          if (expanded && children.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppSpacing.radiusMd),
                  bottomRight: Radius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Column(children: children),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(
    String label,
    IconData icon,
    TimeOfDay time,
    ValueChanged<TimeOfDay> onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(label),
      trailing: TextButton(
        onPressed: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (picked != null) onChanged(picked);
        },
        child: Text(
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          style: AppTypography.heading4(context).copyWith(
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector(
    String label,
    IconData icon,
    TimeOfDay startTime,
    TimeOfDay endTime,
    ValueChanged<TimeOfDay> onStartChanged,
    ValueChanged<TimeOfDay> onEndChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: AppTypography.caption(context)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: startTime,
                    );
                    if (picked != null) onStartChanged(picked);
                  },
                  icon: const Icon(Icons.alarm_on, size: 16),
                  label: Text(
                    '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Icon(Icons.arrow_forward, size: 16),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: endTime,
                    );
                    if (picked != null) onEndChanged(picked);
                  },
                  icon: const Icon(Icons.alarm_off, size: 16),
                  label: Text(
                    '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaysSelector(String label, List<bool> days) {
    final colorScheme = Theme.of(context).colorScheme;
    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              return GestureDetector(
                onTap: () => setState(() => days[index] = !days[index]),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: days[index] 
                      ? colorScheme.primary 
                      : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: days[index] 
                        ? colorScheme.primary 
                        : colorScheme.outline,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      dayLabels[index],
                      style: AppTypography.body(context).copyWith(
                        color: days[index] 
                          ? Colors.white 
                          : colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
