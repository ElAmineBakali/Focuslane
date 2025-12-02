import 'package:flutter/material.dart';
import '../services/food_firestore_service.dart';
import '../models/food_models.dart';

// ===================== DIARIO =====================
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
      appBar: AppBar(
        title: const Text('Diario'),
        actions: [
          IconButton(
            tooltip: 'Objetivos (globales)',
            icon: const Icon(Icons.flag),
            onPressed: () async {
              final kcal = await _promptNumber(
                context,
                'Kcal objetivo (vacío para ignorar)',
              );
              final p = await _promptNumber(context, 'Proteínas (g, opcional)');
              final c = await _promptNumber(context, 'Carbos (g, opcional)');
              final f = await _promptNumber(context, 'Grasas (g, opcional)');
              final fi = await _promptNumber(context, 'Fibra (g, opcional)');
              final water = await _promptInt(context, 'Agua (ml, opcional)');

              // 👉 objetivos GLOBALes
              await widget.svc.setGlobalTargets(
                kcal: kcal,
                protein: p,
                carbs: c,
                fat: f,
                fiber: fi,
                waterMl: water,
              );
            },
          ),
        ],
      ),
      floatingActionButton: _Fab(svc: widget.svc, dayId: dayId),
      body: Column(
        children: [
          _DayHeader(
            date: _date,
            onPrev:
                () => setState(
                  () => _date = _date.subtract(const Duration(days: 1)),
                ),
            onNext:
                () =>
                    setState(() => _date = _date.add(const Duration(days: 1))),
          ),
          Expanded(
            // 🔗 combinamos día + objetivos globales (stream)
            child: StreamBuilder<Map<String, double?>>(
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

                    // Merge: si en el día falta algo -> toma global
                    Map<String, double?> mergedTargets =
                        Map<String, double?>.from(d.targets);
                    for (final k in [
                      'kcal',
                      'protein',
                      'carbs',
                      'fat',
                      'fiber',
                    ]) {
                      mergedTargets[k] ??= globalTargets[k];
                    }
                    // Agua: si no hay objetivo por día, usa global (o 2000 por defecto al renderizar)
                    mergedTargets['water'] ??= globalTargets['water'];

                    return ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        ...d.entries.asMap().entries.map(
                          (e) => Card(
                            child: ListTile(
                              title: Text(e.value.nameSnapshot),
                              subtitle: Text(
                                'Porción: ${e.value.qty.toStringAsFixed(0)} ${e.value.unit.name} • '
                                'Kcal ${e.value.macrosSnapshot['kcal']?.toStringAsFixed(0) ?? '0'}',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'dup') {
                                    await widget.svc.addEntry(
                                      dayId,
                                      IntakeEntry(
                                        id: '',
                                        type: e.value.type,
                                        refId: e.value.refId,
                                        qty: e.value.qty,
                                        unit: e.value.unit,
                                        nameSnapshot: e.value.nameSnapshot,
                                        macrosSnapshot: e.value.macrosSnapshot,
                                      ),
                                    );
                                  }
                                  if (v == 'del') {
                                    await widget.svc.deleteEntry(dayId, e.key);
                                  }
                                },
                                itemBuilder:
                                    (_) => const [
                                      PopupMenuItem(
                                        value: 'dup',
                                        child: Text('Duplicar'),
                                      ),
                                      PopupMenuItem(
                                        value: 'del',
                                        child: Text('Eliminar'),
                                      ),
                                    ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _WaterBar(
                          water: d.waterMl,
                          waterTarget: (mergedTargets['water'] ?? 2000).toInt(),
                          onAdd250: () => widget.svc.incrementWater(dayId, 250),
                          onAdd500: () => widget.svc.incrementWater(dayId, 500),
                          onCustom: () async {
                            final add = await _promptInt(
                              context,
                              'Añadir agua (ml)',
                            );
                            if (add != null)
                              await widget.svc.incrementWater(dayId, add);
                          },
                        ),
                        const SizedBox(height: 16),
                        _TotalsCard(day: d, mergedTargets: mergedTargets),
                        const SizedBox(height: 100),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<double?> _promptNumber(BuildContext context, String label) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(label),
            content: TextField(
              controller: c,
              keyboardType: TextInputType.number,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('OK'),
              ),
            ],
          ),
    );
    if (ok == true) return double.tryParse(c.text);
    return null;
  }

  Future<int?> _promptInt(BuildContext context, String label) async {
    final v = await _promptNumber(context, label);
    return v?.toInt();
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _DayHeader({
    required this.date,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final dstr = date.toIso8601String().substring(0, 10);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: Center(
              child: Text(dstr, style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final DailyIntakeDoc day;
  final Map<String, double?> mergedTargets; // 👈 objetivos ya mezclados
  const _TotalsCard({required this.day, required this.mergedTargets});

  double _pct(double v, double? t) {
    if (t == null || t <= 0) return 0;
    return (v / t).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final t = day.totals;
    final g = mergedTargets;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Totales',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _row('Kcal', t['kcal'] ?? 0, g['kcal']),
            _row('Proteína', t['protein'] ?? 0, g['protein']),
            _row('Carbohidratos', t['carbs'] ?? 0, g['carbs']),
            _row('Grasas', t['fat'] ?? 0, g['fat']),
            _row('Fibra', t['fiber'] ?? 0, g['fiber']),
            const SizedBox(height: 8),
            Text('Sodio: ${(t['sodium'] ?? 0).toStringAsFixed(0)} mg'),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double val, double? target) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ${val.toStringAsFixed(0)}${target != null ? ' / ${target.toStringAsFixed(0)}' : ''}',
          ),
          LinearProgressIndicator(value: _pct(val, target)),
        ],
      ),
    );
  }
}

// ===== Agua responsivo (S22 OK) ==============================================
class _WaterBar extends StatelessWidget {
  final int water;
  final int waterTarget;
  final VoidCallback onAdd250;
  final VoidCallback onAdd500;
  final VoidCallback onCustom;
  const _WaterBar({
    required this.water,
    required this.waterTarget,
    required this.onAdd250,
    required this.onAdd500,
    required this.onCustom,
  });

  double _pct() {
    if (waterTarget <= 0) return 0;
    return (water / waterTarget).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: LayoutBuilder(
          builder: (_, cts) {
            final narrow = cts.maxWidth < 380;
            final buttons = [
              OutlinedButton(onPressed: onAdd250, child: const Text('+250')),
              OutlinedButton(onPressed: onAdd500, child: const Text('+500')),
              FilledButton(onPressed: onCustom, child: const Text('Custom')),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Agua: $water / $waterTarget ml'),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: _pct()),
                const SizedBox(height: 8),
                narrow
                    ? Wrap(spacing: 6, runSpacing: 6, children: buttons)
                    : Row(
                      children: [
                        ...buttons.map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: b,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}
// ============================================================================

/// FAB con quick add
class _Fab extends StatelessWidget {
  final FoodFirestoreService svc;
  final String dayId;
  const _Fab({required this.svc, required this.dayId});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      icon: const Icon(Icons.add),
      label: const Text('Añadir'),
      onPressed: () async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => _QuickAddOrFullSheet(svc: svc, dayId: dayId),
        );
      },
    );
  }
}

/// Primera hoja: elección entre Quick Add o búsqueda completa
class _QuickAddOrFullSheet extends StatelessWidget {
  final FoodFirestoreService svc;
  final String dayId;
  const _QuickAddOrFullSheet({required this.svc, required this.dayId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Cómo quieres añadir?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.flash_on),
              title: const Text('Quick Add (solo calorías)'),
              subtitle: const Text('Añade kcal y proteínas rápido'),
              onTap: () {
                Navigator.pop(context);
                _showQuickAddDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Buscar alimento/receta'),
              subtitle: const Text('Añadir desde tu lista'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => _AddEntrySheet(svc: svc, dayId: dayId),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showQuickAddDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final kcalCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Quick Add'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre (ej: Snack)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: kcalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Calorías'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: proteinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Proteína (g) - opcional',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  final name =
                      nameCtrl.text.trim().isEmpty
                          ? 'Quick add'
                          : nameCtrl.text.trim();
                  final kcal = double.tryParse(kcalCtrl.text) ?? 0;
                  final protein = double.tryParse(proteinCtrl.text) ?? 0;

                  await svc.addEntry(
                    dayId,
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
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Añadir'),
              ),
            ],
          ),
    );
  }
}

// ======= hoja para añadir (la misma que ya tenías) ===========================
// Copio todo lo tuyo tal cual, asegurando que _AddEntrySheet exista aquí.
class _AddEntrySheet extends StatefulWidget {
  final FoodFirestoreService svc;
  final String dayId;
  const _AddEntrySheet({required this.svc, required this.dayId});

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

// … pega aquí el MISMO cuerpo de tu _AddEntrySheetState, _FavList, _FoodList, _RecipeList
// (no lo repito para no saturar: usa exactamente el que ya tenías).
// ============================================================================

class _AddEntrySheetState extends State<_AddEntrySheet> {
  String _tab = 'fav'; // fav | food | recipe
  String _query = '';
  final _qtyCtrl = TextEditingController(text: '100');
  UnitKind _unit = UnitKind.g;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 12,
          right: 12,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ToggleButtons(
              isSelected: [_tab == 'fav', _tab == 'food', _tab == 'recipe'],
              onPressed:
                  (i) => setState(() => _tab = ['fav', 'food', 'recipe'][i]),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Favoritos'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Alimentos'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Recetas'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar...',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<UnitKind>(
                  value: _unit,
                  items: const [
                    DropdownMenuItem(value: UnitKind.g, child: Text('g')),
                    DropdownMenuItem(value: UnitKind.ml, child: Text('ml')),
                    DropdownMenuItem(
                      value: UnitKind.unit,
                      child: Text('unidad'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _unit = v ?? UnitKind.g),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 360,
              child:
                  _tab == 'fav'
                      ? _FavList(
                        svc: widget.svc,
                        query: _query,
                        onPick: _addFav,
                      )
                      : _tab == 'food'
                      ? _FoodList(
                        svc: widget.svc,
                        query: _query,
                        onPick: _addFood,
                      )
                      : _RecipeList(
                        svc: widget.svc,
                        query: _query,
                        onPick: _addRecipe,
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFav(Favorite f) async {
    final qty = double.tryParse(_qtyCtrl.text) ?? f.defaultQty;
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
      final perServing = {
        'kcal': (r.kcal ?? 0) / (r.servings == 0 ? 1 : r.servings),
        'protein': (r.protein ?? 0) / (r.servings == 0 ? 1 : r.servings),
        'carbs': (r.carbs ?? 0) / (r.servings == 0 ? 1 : r.servings),
        'fat': (r.fat ?? 0) / (r.servings == 0 ? 1 : r.servings),
        'fiber': (r.fiber ?? 0) / (r.servings == 0 ? 1 : r.servings),
        'sodium': (r.sodium ?? 0) / (r.servings == 0 ? 1 : r.servings),
      };
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
    final qty = double.tryParse(_qtyCtrl.text) ?? f.unitSize;
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
    final servings = double.tryParse(_qtyCtrl.text) ?? 1;
    final perServing = {
      'kcal': (r.kcal ?? 0) / (r.servings == 0 ? 1 : r.servings),
      'protein': (r.protein ?? 0) / (r.servings == 0 ? 1 : r.servings),
      'carbs': (r.carbs ?? 0) / (r.servings == 0 ? 1 : r.servings),
      'fat': (r.fat ?? 0) / (r.servings == 0 ? 1 : r.servings),
      'fiber': (r.fiber ?? 0) / (r.servings == 0 ? 1 : r.servings),
      'sodium': (r.sodium ?? 0) / (r.servings == 0 ? 1 : r.servings),
    };
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
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        var list = snap.data!;
        if (query.trim().isNotEmpty) {
          final ql = query.toLowerCase();
          list =
              list
                  .where((f) => (f.alias ?? '').toLowerCase().contains(ql))
                  .toList();
        }
        if (list.isEmpty) return const Center(child: Text('Sin favoritos'));
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final f = list[i];
            return ListTile(
              leading: Icon(
                f.type == FavoriteType.food
                    ? Icons.restaurant
                    : Icons.menu_book,
              ),
              title: Text(f.alias ?? '${f.type.name} • ${f.refId}'),
              subtitle: Text(
                'Default: ${f.defaultQty.toStringAsFixed(0)} ${f.defaultUnit.name}',
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
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final list = snap.data!;
        if (list.isEmpty) return const Center(child: Text('Sin resultados'));
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final f = list[i];
            return ListTile(
              leading: Icon(
                Icons.restaurant,
                color: f.color ?? Theme.of(context).colorScheme.primary,
              ),
              title: Text(f.name),
              subtitle: Text(
                '${f.kcal.toStringAsFixed(0)} kcal por ${f.unitSize.toStringAsFixed(0)} ${f.perUnit.name}',
              ),
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
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        var list = snap.data!;
        if (query.trim().isNotEmpty) {
          final ql = query.toLowerCase();
          list = list.where((r) => r.name.toLowerCase().contains(ql)).toList();
        }
        if (list.isEmpty) return const Center(child: Text('Sin recetas'));
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final r = list[i];
            return ListTile(
              leading: const Icon(Icons.menu_book),
              title: Text(r.name),
              subtitle: Text('Raciones: ${r.servings}'),
              onTap: () => onPick(r),
            );
          },
        );
      },
    );
  }
}
