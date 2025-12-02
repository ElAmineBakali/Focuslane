import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/services/notification_service.dart';
import '../services/food_firestore_service.dart';
import '../models/food_models.dart';
import '../diary/food_diary_screen.dart';
import '../foods/foods_list_screen.dart';
import '../recipes/recipes_list_screen.dart';
import '../planner/food_planner_screen.dart';
import '../shopping/shopping_lists_screen.dart';
import '../history/food_history_screen.dart';

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
    final s = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food'),
        actions: [
          IconButton(
            tooltip: 'Hoy',
            icon: const Icon(Icons.today),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodDiaryScreen(svc: widget.svc),
                  ),
                ),
          ),
          IconButton(
            tooltip: 'Historial',
            icon: const Icon(Icons.history),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodHistoryScreen(svc: widget.svc),
                  ),
                ),
          ),
          IconButton(
            tooltip: 'Recordatorios',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () => _openRemindersSheet(context),
          ),
        ],
      ),
      body: StreamBuilder<DailyIntakeDoc>(
        stream: widget.svc.streamDay(todayId),
        builder: (context, snap) {
          final day =
              snap.data ??
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
                targets: const {
                  'kcal': null,
                  'protein': null,
                  'carbs': null,
                  'fat': null,
                  'fiber': null,
                },
              );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---- Controles rápidos bonitos (estado claro) ----
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilterChip(
                        selected: _awakeToday,
                        label: Text(
                          _awakeToday ? 'Despierto HOY' : 'Despierto HOY',
                        ),
                        avatar: Icon(
                          _awakeToday
                              ? Icons.wb_sunny
                              : Icons.wb_sunny_outlined,
                        ),
                        selectedColor: s.primaryContainer,
                        onSelected: (v) => v ? _iAmAwake() : _cancelAwake(),
                      ),
                      FilterChip(
                        selected: _waterEvery2hOn,
                        label: Text(
                          _waterEvery2hOn ? 'Agua c/2h' : 'Agua c/2h',
                        ),
                        avatar: Icon(
                          _waterEvery2hOn
                              ? Icons.water_drop
                              : Icons.water_drop_outlined,
                        ),
                        selectedColor: s.secondaryContainer,
                        onSelected:
                            (v) =>
                                v
                                    ? _scheduleWaterEvery2h()
                                    : _cancelWaterEvery2h(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 👉 Tappable para abrir Diario
              InkWell(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FoodDiaryScreen(svc: widget.svc),
                      ),
                    ),
                child: _SummaryCard(day: day),
              ),
              const SizedBox(height: 12),
              _navRow(
                context,
                'Alimentos',
                Icons.restaurant,
                FoodsListScreen(svc: widget.svc),
              ),
              _navRow(
                context,
                'Recetas',
                Icons.menu_book,
                RecipesListScreen(svc: widget.svc),
              ),
              _navRow(
                context,
                'Planner',
                Icons.calendar_view_week,
                FoodPlannerScreen(svc: widget.svc),
              ),
              _navRow(
                context,
                'Listas de compra',
                Icons.shopping_cart,
                ShoppingListsScreen(svc: widget.svc),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---- hoja de recordatorios (igual que la tuya; sin cambios de UX fuertes) ----
  Future<void> _openRemindersSheet(BuildContext context) async {
    // … pega aquí tu implementación actual de _openRemindersSheet() …
  }

  Widget _navRow(
    BuildContext ctx,
    String title,
    IconData icon,
    Widget screen,
  ) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap:
          () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen)),
    ),
  );
}

// ---- _SummaryCard se queda igual que el tuyo ----

class _SummaryCard extends StatelessWidget {
  final DailyIntakeDoc day;
  const _SummaryCard({required this.day});

  double _pct(double? v, double? target) {
    if (target == null || target <= 0) return 0;
    final p = (v ?? 0) / target;
    return p.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final t = day.totals;
    final g = day.targets;
    final waterTarget = (g['water'] ?? 2000).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de hoy',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _row(context, 'Kcal', t['kcal'] ?? 0.0, g['kcal']),
            _row(context, 'Proteína', t['protein'] ?? 0.0, g['protein']),
            _row(context, 'Carbohidratos', t['carbs'] ?? 0.0, g['carbs']),
            _row(context, 'Grasas', t['fat'] ?? 0.0, g['fat']),
            _row(context, 'Fibra', t['fiber'] ?? 0.0, g['fiber']),
            const SizedBox(height: 8),
            Text('Agua: ${day.waterMl} / ${waterTarget.toInt()} ml'),
            LinearProgressIndicator(
              value: _pct(day.waterMl.toDouble(), waterTarget),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext ctx, String label, double val, double? target) {
    final pct = _pct(val, target);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ${val.toStringAsFixed(0)}${target != null ? ' / ${target.toStringAsFixed(0)}' : ''}',
          ),
          LinearProgressIndicator(value: pct),
        ],
      ),
    );
  }
}
