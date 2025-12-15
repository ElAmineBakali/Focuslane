import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/global_ui_components.dart';
import '../../../theme/global_ui_theme.dart';
import '../services/food_firestore_service.dart';
import '../models/food_models.dart';
import '../diary/food_diary_screen_v2.dart';
import '../foods/foods_list_screen_v2.dart';
import '../recipes/recipes_list_screen_v2.dart';
import '../planner/food_planner_screen_v2.dart';
import '../shopping/shopping_lists_screen_v2.dart';
import '../pantry/pantry_screen_v2.dart';
import '../history/food_history_screen_v2.dart';

/// 🏠 FOOD HOME SCREEN V2 - Rediseñado
/// Dashboard principal del módulo de alimentación con diseño moderno
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar moderno con gradiente
          FocusGradientAppBar(
            title: 'Alimentación',
            icon: Icons.restaurant,
            primaryColor: FocusColors.food,
            secondaryColor: FocusColors.warning,
            actions: [
              // Historial
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
              // Configuración de recordatorios
              IconButton(
                icon: const Icon(Icons.notifications_active_outlined),
                tooltip: 'Recordatorios',
                onPressed: () => _showRemindersSheet(context),
              ),
            ],
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(FocusSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alerta de stock bajo
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
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: -0.2, end: 0);
                    },
                  ),

                  // Resumen del día
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

                  // Sugerencias inteligentes
                  StreamBuilder<List<String>>(
                    stream: Stream.value([]),
                    builder: (context, snap) {
                      final suggestions = snap.data ?? [];
                      if (suggestions.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💡 Sugerencias',
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

                  // Favoritos
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
                                '⭐ Favoritos',
                                style: FocusTypography.heading3(context),
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Implementar FavoritesScreen
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

                  // Grid de acciones rápidas
                  Text(
                    'Acciones Rápidas',
                    style: FocusTypography.heading3(context),
                  ),
                  const SizedBox(height: FocusSpacing.md),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: FocusSpacing.md,
                    crossAxisSpacing: FocusSpacing.md,
                    childAspectRatio: 1.3,
                    children: [
                      FocusActionCard(
                        title: 'Diario',
                        icon: Icons.today,
                        color: FocusColors.food,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FoodDiaryScreenV2(svc: widget.svc),
                            ),
                          );
                        },
                        animationDelay: 100.ms,
                      ),
                      FocusActionCard(
                        title: 'Alimentos',
                        icon: Icons.restaurant,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FoodsListScreenV2(svc: widget.svc),
                            ),
                          );
                        },
                        animationDelay: 200.ms,
                      ),
                      FocusActionCard(
                        title: 'Recetas',
                        icon: Icons.menu_book,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecipesListScreenV2(svc: widget.svc),
                            ),
                          );
                        },
                        animationDelay: 300.ms,
                      ),
                      FocusActionCard(
                        title: 'Planificador',
                        icon: Icons.calendar_view_week,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FoodPlannerScreenV2(svc: widget.svc),
                            ),
                          );
                        },
                        animationDelay: 400.ms,
                      ),
                      FocusActionCard(
                        title: 'Compras',
                        icon: Icons.shopping_cart,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ShoppingListsScreenV2(svc: widget.svc),
                            ),
                          );
                        },
                        animationDelay: 500.ms,
                      ),
                      FocusActionCard(
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

            // Macros principales
            _buildMiniMacro(
              context,
              'Calorías',
              t['kcal'] ?? 0,
              mergedTargets['kcal'],
              FocusColors.food,
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

            // Agua
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
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: FocusSpacing.md),
      child: Material(
        color: FocusColors.food.withOpacity(0.1),
        borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
        child: InkWell(
          onTap: () async {
            // Añadir al diario desde favorito
            final todayId = _dayId(DateTime.now());
            // Lógica de añadir (implementar según sea food o recipe)
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
                  color: FocusColors.food,
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

/// Sheet de configuración de recordatorios
class _RemindersSheet extends StatelessWidget {
  final FoodFirestoreService svc;
  const _RemindersSheet({required this.svc});

  @override
  Widget build(BuildContext context) {
    final todayId = DateTime.now().toIso8601String().substring(0, 10);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(FocusSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔔 Recordatorios',
              style: FocusTypography.heading2(context),
            ),
            const SizedBox(height: FocusSpacing.lg),

            // TODO: Implementar reminders
            Column(
              children: [
                SwitchListTile(
                  value: false,
                  onChanged: (v) async {
                    // TODO: Implementar reminders
                    /* if (v) {
                      await svc.reminders.activateAwakeReminders(todayId);
                    } else {
                      await svc.reminders.deactivateAwakeReminders();
                    } */
                  },
                  title: Text(
                    'Despierto HOY',
                    style: FocusTypography.heading4(context),
                  ),
                  subtitle: const Text(
                    '5 notificaciones para comidas del día',
                  ),
                  secondary: const Icon(Icons.wb_sunny),
                ),
                  const Divider(),
                  SwitchListTile(
                    value: false,
                    onChanged: (v) async {
                      // TODO: Implementar reminders
                      /* if (v) {
                        await svc.reminders.activateWaterReminders();
                      } else {
                        await svc.reminders.deactivateWaterReminders();
                      } */
                    },
                    title: Text(
                      'Agua cada 2h',
                      style: FocusTypography.heading4(context),
                    ),
                    subtitle: const Text(
                      'Recordatorios recurrentes de hidratación',
                    ),
                    secondary: const Icon(Icons.water_drop),
                  ),
                ],
              ),

            const SizedBox(height: FocusSpacing.lg),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
