import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/global_ui_components.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';

/// 📅 PLANIFICADOR - REDISEÑADO
class FoodPlannerScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  const FoodPlannerScreen({super.key, required this.svc});

  @override
  State<FoodPlannerScreen> createState() => _FoodPlannerScreenState();
}

class _FoodPlannerScreenState extends State<FoodPlannerScreen> {
  static const String _menuId = 'menu'; // <- ID fijo
  ShoppingScope _scope = ShoppingScope.weekly;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Planificador',
          style: FocusTypography.heading2(context).copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          DropdownButton<ShoppingScope>(
            value: _scope,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(
                value: ShoppingScope.weekly,
                child: Text('Semanal'),
              ),
              DropdownMenuItem(
                value: ShoppingScope.biweekly,
                child: Text('Quincenal (x2)'),
              ),
              DropdownMenuItem(
                value: ShoppingScope.monthly,
                child: Text('Mensual (x4)'),
              ),
              DropdownMenuItem(
                value: ShoppingScope.custom,
                child: Text('Custom'),
              ),
            ],
            onChanged:
                (v) => setState(() => _scope = v ?? ShoppingScope.weekly),
          ),
          IconButton(
            tooltip: 'Generar lista compra',
            icon: const Icon(Icons.shopping_cart_checkout),
            onPressed: () async {
              await widget.svc.generateShoppingFromWeek(
                _menuId,
                scopeOverride: _scope,
              );
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Lista generada')));
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<WeekPlanner>(
        stream: widget.svc.streamWeek(_menuId),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final w = snap.data!;
          final days = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final slots = MealSlot.values;

          return StreamBuilder<List<Food>>(
            stream: widget.svc.streamFoods(),
            builder: (context, foodsSnap) {
              if (!foodsSnap.hasData)
                return const Center(child: CircularProgressIndicator());
              final foods = foodsSnap.data!;
              final foodsMap = {for (final f in foods) f.id: f};

              // Scroll horizontal + zoom para móvil
              return LayoutBuilder(
                builder: (ctx, constraints) {
                  final viewW = constraints.maxWidth;
                  // MUCH wider canvas: 7 days × 250px + header = 1920px minimum for S22.
                  final contentW = viewW < 2100 ? 2100.0 : viewW;
                  return InteractiveViewer(
                    panEnabled: true,
                    scaleEnabled: true,
                    minScale: 0.8,
                    maxScale: 2.2,
                    boundaryMargin: const EdgeInsets.all(32),
                    child: Center(
                      child: SizedBox(
                        width: contentW,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Mantén pulsado para borrar',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Table(
                                columnWidths: const {0: FixedColumnWidth(190)},
                                defaultColumnWidth: const FixedColumnWidth(250),
                                border: TableBorder.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest,
                                    ),
                                    children: [
                                      const _HeaderCell(''),
                                      ...days.map((d) => _HeaderCell(d)),
                                    ],
                                  ),
                                  ...slots.map((slot) {
                                    return TableRow(
                                      children: [
                                        _HeaderCell(_slotName(slot)),
                                        ...days.map((d) {
                                          final entries = w.days[d] ?? const [];
                                          final here =
                                              entries
                                                  .where((e) => e.slot == slot)
                                                  .toList();
                                          final names =
                                              here
                                                  .map(
                                                    (e) =>
                                                        foodsMap[e.refId]
                                                            ?.name ??
                                                        e.refId,
                                                  )
                                                  .toList();
                                          return _PlannerCell(
                                            entries: here,
                                            names: names,
                                            onAdd:
                                                () => _openSlotMenu(
                                                  w,
                                                  d,
                                                  slot,
                                                  here,
                                                  foodsMap,
                                                ),
                                            onDelete: (idx) async {
                                              final dayList =
                                                  List<PlannerDayEntry>.from(
                                                    w.days[d] ?? const [],
                                                  );
                                              final filtered =
                                                  dayList
                                                      .where(
                                                        (e) => e.slot == slot,
                                                      )
                                                      .toList();
                                              final target = filtered[idx];
                                              dayList.remove(target);
                                              final newDays = Map<
                                                String,
                                                List<PlannerDayEntry>
                                              >.from(w.days);
                                              newDays[d] = dayList;
                                              await widget.svc.saveWeek(
                                                WeekPlanner(
                                                  id: _menuId,
                                                  scope: _scope,
                                                  days: newDays,
                                                ),
                                              );
                                            },
                                          );
                                        }),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(height: 48),
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
      ),
    );
  }

  String _slotName(MealSlot s) {
    switch (s) {
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

  /// Menú del slot
  Future<void> _openSlotMenu(
    WeekPlanner w,
    String dayKey,
    MealSlot slot,
    List<PlannerDayEntry> entries,
    Map<String, Food> foodsMap,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_slotName(slot)} • $dayKey',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No hay comidas en este slot'),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: entries.length,
                      itemBuilder: (ctx, i) {
                        final e = entries[i];
                        final f = foodsMap[e.refId];
                        final name = f?.name ?? e.refId;
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.restaurant),
                            title: Text(name),
                            subtitle: Text(
                              'Raciones: ${e.servings.toStringAsFixed(0)}',
                            ),
                            onTap: () {
                              showDialog(
                                context: ctx,
                                builder:
                                    (_) => AlertDialog(
                                      title: Text(name),
                                      content:
                                          f == null
                                              ? const Text(
                                                'No se encontró el alimento.',
                                              )
                                              : Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Marca: ${f.brand ?? '-'}',
                                                  ),
                                                  Text(
                                                    'Base: ${f.unitSize.toStringAsFixed(0)} ${f.perUnit.name}',
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Kcal: ${f.kcal.toStringAsFixed(0)}',
                                                  ),
                                                  Text(
                                                    'Proteína: ${f.protein.toStringAsFixed(1)} g',
                                                  ),
                                                  Text(
                                                    'Carbos: ${f.carbs.toStringAsFixed(1)} g',
                                                  ),
                                                  Text(
                                                    'Grasas: ${f.fat.toStringAsFixed(1)} g',
                                                  ),
                                                  Text(
                                                    'Fibra: ${f.fiber.toStringAsFixed(1)} g',
                                                  ),
                                                  Text(
                                                    'Sodio: ${f.sodium.toStringAsFixed(0)} mg',
                                                  ),
                                                ],
                                              ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cerrar'),
                                        ),
                                      ],
                                    ),
                              );
                            },
                            trailing: IconButton(
                              tooltip: 'Eliminar',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final dayList = List<PlannerDayEntry>.from(
                                  w.days[dayKey] ?? const [],
                                );
                                final filtered =
                                    dayList
                                        .where((x) => x.slot == slot)
                                        .toList();
                                final target = filtered[i];
                                dayList.remove(target);
                                final newDays =
                                    Map<String, List<PlannerDayEntry>>.from(
                                      w.days,
                                    );
                                newDays[dayKey] = dayList;
                                await widget.svc.saveWeek(
                                  WeekPlanner(
                                    id: _menuId,
                                    scope: _scope,
                                    days: newDays,
                                  ),
                                );
                                if (mounted) Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir alimento'),
                    onPressed: () async {
                      await _addEntryDialog(w, dayKey, slot);
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Selector de alimento + raciones
  Future<void> _addEntryDialog(
    WeekPlanner w,
    String dayKey,
    MealSlot slot,
  ) async {
    final servCtrl = TextEditingController(text: '1');
    String query = '';

    final picked = await showDialog<Food>(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (ctx, setState) {
              return AlertDialog(
                title: const Text('Añadir alimento al menú'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (v) => setState(() => query = v),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar alimento…',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 260,
                      width: 380,
                      child: StreamBuilder<List<Food>>(
                        stream: widget.svc.streamFoods(query: query),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final list = snap.data!;
                          if (list.isEmpty) {
                            return const Center(child: Text('Sin resultados'));
                          }
                          return ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final f = list[i];
                              return ListTile(
                                leading: Icon(
                                  Icons.restaurant,
                                  color:
                                      f.color ??
                                      Theme.of(context).colorScheme.primary,
                                ),
                                title: Text(f.name),
                                subtitle: Text(
                                  '${f.kcal.toStringAsFixed(0)} kcal por ${f.unitSize.toStringAsFixed(0)} ${f.perUnit.name}',
                                ),
                                onTap: () => Navigator.pop(ctx, f),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: servCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Raciones / unidades',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    child: const Text('Cancelar'),
                  ),
                ],
              );
            },
          ),
    );

    if (picked != null) {
      final newEntry = PlannerDayEntry(
        slot: slot,
        type: FavoriteType.food,
        refId: picked.id,
        servings: double.tryParse(servCtrl.text) ?? 1,
      );
      final dayList = List<PlannerDayEntry>.from(w.days[dayKey] ?? const []);
      dayList.add(newEntry);
      final newDays = Map<String, List<PlannerDayEntry>>.from(w.days);
      newDays[dayKey] = dayList;
      await widget.svc.saveWeek(
        WeekPlanner(id: _menuId, scope: _scope, days: newDays),
      );
    }
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}

class _PlannerCell extends StatelessWidget {
  final List<PlannerDayEntry> entries;
  final List<String>? names; // nombres a mostrar
  final VoidCallback onAdd;
  final ValueChanged<int> onDelete;
  const _PlannerCell({
    required this.entries,
    this.names,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontSize: 14.5, height: 1.25);

    return SizedBox(
      height: 140,
      child: InkWell(
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child:
              entries.isEmpty
                  ? const Center(
                    child: Text('—', style: TextStyle(fontSize: 12)),
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...List.generate(entries.length, (i) {
                        final e = entries[i];
                        final label =
                            (names != null && i < names!.length)
                                ? names![i]
                                : e.refId;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onLongPress: () => onDelete(i),
                          child: Text(
                            '• $label  ×${e.servings.toStringAsFixed(0)}',
                            overflow: TextOverflow.ellipsis,
                            style: textStyle,
                          ),
                        );
                      }),
                    ],
                  ),
        ),
      ),
    );
  }
}
