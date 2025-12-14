import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/global_ui_components.dart';
import '../../../services/notification_service.dart';
import '../services/food_firestore_service.dart';
import '../models/food_models.dart';
import '../diary/food_diary_screen.dart';
import '../foods/foods_list_screen.dart';
import '../recipes/recipes_list_screen.dart';
import '../planner/food_planner_screen.dart';
import '../shopping/shopping_lists_screen.dart';
import '../history/food_history_screen.dart';
import '../pantry/pantry_screen.dart';

/// 🏠 FOOD HOME SCREEN - REDISEÑADO
/// Dashboard principal del módulo de alimentación con diseño moderno
class FoodHomeScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  const FoodHomeScreen({super.key, required this.svc});

  @override
  State<FoodHomeScreen> createState() => _FoodHomeScreenState();
}

class _FoodHomeScreenState extends State<FoodHomeScreen> {
  String _dayId(DateTime d) => d.toIso8601String().substring(0, 10);

  static const int _awakeMealBaseId = 430000; // 430000..430004
  static const int _water2hBaseId = 431000; // 431000..431011

  bool _awakeToday = false;
  bool _waterEvery2hOn = false;

  @override
  void initState() {
    super.initState();
    // Si tienes flags en Firestore, cárgalos aquí y setState.
    // De momento iniciamos en false y cambiamos al pulsar.
  }

  void _toast(
    BuildContext c, {
    required bool ok,
    required String title,
    String? sub,
  }) {
    final s = Theme.of(c).colorScheme;
    final bg = ok ? s.primaryContainer : s.errorContainer;
    final fg = ok ? s.onPrimaryContainer : s.onErrorContainer;
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(ok ? Icons.check_circle : Icons.warning_amber, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                sub == null ? title : '$title\n$sub',
                style: TextStyle(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _iAmAwake() async {
    final labels = const ['Desayuno', 'Snack', 'Comida', 'Merienda', 'Cena'];
    // Limpia anteriores
    for (int i = 0; i < labels.length; i++) {
      await NotificationService.I.cancel(_awakeMealBaseId + i);
    }
    final now = DateTime.now();
    for (int i = 0; i < labels.length; i++) {
      final when = now.add(Duration(hours: 1 + 2 * i));
      await NotificationService.I.scheduleOnce(
        id: _awakeMealBaseId + i,
        title: 'Comida – ${labels[i]}',
        body: 'Toca para registrar tu ${labels[i]}',
        whenLocal: when,
        useExact: true,
        payload: 'OPEN_FOOD_DIARY',
      );
    }
    await widget.svc.markAwake(now, dayId: _dayId(now));
    setState(() => _awakeToday = true);
    _toast(
      context,
      ok: true,
      title: '¡Listo!',
      sub: 'Te avisaré durante el día.',
    );
  }

  Future<void> _cancelAwake() async {
    for (int i = 0; i < 5; i++) {
      await NotificationService.I.cancel(_awakeMealBaseId + i);
    }
    setState(() => _awakeToday = false);
    _toast(context, ok: false, title: 'Avisos de hoy cancelados');
  }

  Future<void> _scheduleWaterEvery2h() async {
    for (int i = 0; i < 12; i++) {
      await NotificationService.I.cancel(_water2hBaseId + i);
    }
    int id = 0;
    for (int h = 0; h <= 22; h += 2) {
      await NotificationService.I.scheduleDaily(
        id: _water2hBaseId + id,
        title: 'Agua',
        body: 'Bebe agua 💧',
        at: TimeOfDay(hour: h, minute: 0),
        useExact: false,
        payload: 'OPEN_FOOD_DIARY',
      );
      id++;
    }
    setState(() => _waterEvery2hOn = true);
    _toast(context, ok: true, title: 'Agua cada 2h ACTIVADO');
  }

  Future<void> _cancelWaterEvery2h() async {
    for (int i = 0; i < 12; i++) {
      await NotificationService.I.cancel(_water2hBaseId + i);
    }
    setState(() => _waterEvery2hOn = false);
    _toast(context, ok: false, title: 'Agua cada 2h DESACTIVADO');
  }

  @override
  Widget build(BuildContext context) {
    final todayId = _dayId(DateTime.now());
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 🎨 AppBar moderno con gradiente
          FocusGradientAppBar(
            title: 'Alimentación',
            icon: Icons.restaurant,
            primaryColor: FocusColors.food,
            secondaryColor: FocusColors.warning,
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Historial',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FoodHistoryScreen(svc: widget.svc),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications_active_outlined),
                tooltip: 'Recordatorios',
                onPressed: () => _openRemindersSheet(context),
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
                  // 🔔 Recordatorios visuales
                  _buildRemindersCard(context),
                  
                  const SizedBox(height: FocusSpacing.xl),

                  // 📊 Resumen del día
                  _buildDaySummaryCard(context, todayId),

                  const SizedBox(height: FocusSpacing.xl),

                  // 🚀 Acciones rápidas
                  Text(
                    'Acciones Rápidas',
                    style: FocusTypography.heading2(context),
                  ),
                  const SizedBox(height: FocusSpacing.md),
                  _buildActionGrid(context),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔔 Tarjeta de recordatorios moderna
  Widget _buildRemindersCard(BuildContext context) {
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
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: FocusColors.warning,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: FocusSpacing.md),
                Text(
                  'Recordatorios',
                  style: FocusTypography.heading3(context),
                ),
              ],
            ),
            const SizedBox(height: FocusSpacing.md),
            Wrap(
              spacing: FocusSpacing.md,
              runSpacing: FocusSpacing.sm,
              children: [
                FilterChip(
                  selected: _awakeToday,
                  label: const Text('Despierto HOY'),
                  avatar: Icon(
                    _awakeToday ? Icons.wb_sunny : Icons.wb_sunny_outlined,
                  ),
                  selectedColor: FocusColors.food.withOpacity(0.2),
                  onSelected: (v) => v ? _iAmAwake() : _cancelAwake(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                  ),
                ),
                FilterChip(
                  selected: _waterEvery2hOn,
                  label: const Text('Agua c/2h'),
                  avatar: Icon(
                    _waterEvery2hOn
                        ? Icons.water_drop
                        : Icons.water_drop_outlined,
                  ),
                  selectedColor: Colors.blue.withOpacity(0.2),
                  onSelected: (v) =>
                      v ? _scheduleWaterEvery2h() : _cancelWaterEvery2h(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  // 📊 Tarjeta de resumen del día moderna
  Widget _buildDaySummaryCard(BuildContext context, String todayId) {
    return StreamBuilder<DailyIntakeDoc>(
      stream: widget.svc.streamDay(todayId),
      builder: (context, snap) {
        final day = snap.data ??
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

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FoodDiaryScreen(svc: widget.svc),
              ),
            );
          },
          borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
          child: Card(
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
                  _buildMacroRow(
                    context,
                    'Calorías',
                    day.totals['kcal'] ?? 0,
                    day.targets['kcal'],
                    FocusColors.food,
                    'kcal',
                  ),
                  _buildMacroRow(
                    context,
                    'Proteínas',
                    day.totals['protein'] ?? 0,
                    day.targets['protein'],
                    Colors.red,
                    'g',
                  ),
                  _buildMacroRow(
                    context,
                    'Carbos',
                    day.totals['carbs'] ?? 0,
                    day.targets['carbs'],
                    Colors.blue,
                    'g',
                  ),
                  _buildMacroRow(
                    context,
                    'Grasas',
                    day.totals['fat'] ?? 0,
                    day.targets['fat'],
                    Colors.green,
                    'g',
                  ),
                  const SizedBox(height: FocusSpacing.md),
                  const Divider(),
                  const SizedBox(height: FocusSpacing.md),
                  _buildWaterRow(context, day.waterMl,
                      (day.targets['water'] ?? 2000).toInt()),
                ],
              ),
            ),
          ),
        ).animate().fadeIn().scale();
      },
    );
  }

  Widget _buildMacroRow(
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

  Widget _buildWaterRow(BuildContext context, int waterMl, int target) {
    final progress = target > 0 ? (waterMl / target).clamp(0.0, 1.0) : 0.0;

    return Row(
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
                  Text('Agua', style: FocusTypography.label(context)),
                  Text(
                    '$waterMl / $target ml',
                    style: FocusTypography.caption(context),
                  ),
                ],
              ),
              const SizedBox(height: FocusSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.blue.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.blue),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🚀 Grid de acciones modernos
  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
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
                builder: (_) => FoodDiaryScreen(svc: widget.svc),
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
                builder: (_) => FoodsListScreen(svc: widget.svc),
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
                builder: (_) => RecipesListScreen(svc: widget.svc),
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
                builder: (_) => FoodPlannerScreen(svc: widget.svc),
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
                builder: (_) => ShoppingListsScreen(svc: widget.svc),
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
                builder: (_) => PantryScreen(svc: widget.svc),
              ),
            );
          },
          animationDelay: 600.ms,
        ),
      ],
    );
  }

  Future<void> _openRemindersSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(FocusSpacing.radiusXl),
        ),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FocusSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔔 Recordatorios',
                style: FocusTypography.heading2(context),
              ),
              const SizedBox(height: FocusSpacing.lg),
              SwitchListTile(
                value: _awakeToday,
                onChanged: (v) {
                  Navigator.pop(context);
                  if (v) {
                    _iAmAwake();
                  } else {
                    _cancelAwake();
                  }
                },
                title: Text(
                  'Despierto HOY',
                  style: FocusTypography.heading4(context),
                ),
                subtitle: const Text('5 notificaciones para comidas del día'),
                secondary: Icon(
                  Icons.wb_sunny,
                  color: _awakeToday ? FocusColors.food : null,
                ),
              ),
              const Divider(),
              SwitchListTile(
                value: _waterEvery2hOn,
                onChanged: (v) {
                  Navigator.pop(context);
                  if (v) {
                    _scheduleWaterEvery2h();
                  } else {
                    _cancelWaterEvery2h();
                  }
                },
                title: Text(
                  'Agua cada 2h',
                  style: FocusTypography.heading4(context),
                ),
                subtitle: const Text('Recordatorios recurrentes de hidratación'),
                secondary: Icon(
                  Icons.water_drop,
                  color: _waterEvery2hOn ? Colors.blue : null,
                ),
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
      ),
    );
  }
}