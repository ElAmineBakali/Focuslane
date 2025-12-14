import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_models.dart';

/// 📋 Servicio de Planificador y Compras
/// Gestiona planificadores múltiples y listas de compra
class FoodPlannerService {
  final String userId;
  FoodPlannerService(this.userId);

  DocumentReference<Map<String, dynamic>> get _root => FirebaseFirestore
      .instance
      .collection('users')
      .doc(userId.trim().isEmpty ? 'local' : userId.trim())
      .collection('food')
      .doc('root');

  // ══════════════════════════════════════════════════════════════════════════
  // PLANIFICADORES (Múltiples)
  // ══════════════════════════════════════════════════════════════════════════

  DocumentReference<Map<String, dynamic>> _plannerRef(String plannerId) =>
      _root.collection('planners').doc(plannerId);

  /// Stream de todos los planificadores
  Stream<List<WeekPlanner>> streamPlanners() {
    return _root
        .collection('planners')
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => 
          WeekPlanner.fromMap(d.id, d.data())).toList());
  }

  /// Stream de un planificador específico
  Stream<WeekPlanner> streamPlanner(String plannerId) {
    return _plannerRef(plannerId).snapshots().map((d) {
      if (!d.exists) {
        return WeekPlanner(
          id: plannerId,
          name: 'Planificador',
          scope: ShoppingScope.weekly,
          customMultiplier: 1.0,
          days: {
            'Mon': const [],
            'Tue': const [],
            'Wed': const [],
            'Thu': const [],
            'Fri': const [],
            'Sat': const [],
            'Sun': const [],
          },
        );
      }
      return WeekPlanner.fromMap(d.id, d.data() as Map<String, dynamic>);
    });
  }

  Future<WeekPlanner> getPlanner(String plannerId) async {
    final snap = await _plannerRef(plannerId).get();
    if (!snap.exists) {
      final empty = WeekPlanner(
        id: plannerId,
        name: 'Planificador',
        scope: ShoppingScope.weekly,
        customMultiplier: 1.0,
        days: {
          'Mon': const [],
          'Tue': const [],
          'Wed': const [],
          'Thu': const [],
          'Fri': const [],
          'Sat': const [],
          'Sun': const [],
        },
      );
      await _plannerRef(plannerId).set(empty.toMap());
      return empty;
    }
    return WeekPlanner.fromMap(snap.id, snap.data() as Map<String, dynamic>);
  }

  Future<String> createPlanner(String name, {ShoppingScope? scope}) async {
    final doc = _root.collection('planners').doc();
    final planner = WeekPlanner(
      id: doc.id,
      name: name,
      scope: scope ?? ShoppingScope.weekly,
      customMultiplier: 1.0,
      days: {
        'Mon': const [],
        'Tue': const [],
        'Wed': const [],
        'Thu': const [],
        'Fri': const [],
        'Sat': const [],
        'Sun': const [],
      },
    );
    await doc.set(planner.toMap());
    return doc.id;
  }

  Future<void> updatePlanner(String plannerId, Map<String, dynamic> data) async {
    await _plannerRef(plannerId).update(data);
  }

  Future<void> savePlanner(WeekPlanner planner) async {
    await _plannerRef(planner.id).set(planner.toMap(), SetOptions(merge: true));
  }

  Future<void> deletePlanner(String plannerId) async {
    await _plannerRef(plannerId).delete();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHOPPING LISTS
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<ShoppingList>> streamShoppingLists() {
    return _root
        .collection('shoppingLists')
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => 
          ShoppingList.fromMap(d.id, d.data())).toList());
  }

  Future<ShoppingList?> getShoppingList(String id) async {
    final snap = await _root.collection('shoppingLists').doc(id).get();
    if (!snap.exists) return null;
    return ShoppingList.fromMap(snap.id, snap.data() as Map<String, dynamic>);
  }

  Future<String> createShoppingList(
    String name, {
    ShoppingScope scope = ShoppingScope.custom,
    bool isDefault = false,
  }) async {
    if (isDefault) {
      final all = await _root.collection('shoppingLists').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in all.docs) {
        batch.update(d.reference, {'isDefault': false});
      }
      await batch.commit();
    }
    final doc = _root.collection('shoppingLists').doc();
    await doc.set({
      'name': name,
      'scope': scope.name,
      'isDefault': isDefault,
      'items': [],
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> setDefaultList(String id) async {
    final all = await _root.collection('shoppingLists').get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in all.docs) {
      batch.update(d.reference, {'isDefault': d.id == id});
    }
    await batch.commit();
  }

  Future<void> updateShoppingList(String id, Map<String, dynamic> patch) async {
    await _root.collection('shoppingLists').doc(id).update(patch);
  }

  Future<void> deleteShoppingList(String id) async {
    await _root.collection('shoppingLists').doc(id).delete();
  }

  Future<void> upsertShoppingItem(
    String listId, {
    String? itemId,
    required ShoppingListItem item,
  }) async {
    final ref = _root.collection('shoppingLists').doc(listId);
    final snap = await ref.get();
    final data = (snap.data() ?? {});
    final items =
        ((data['items'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    if (itemId == null) {
      items.add(item.toMap());
    } else {
      final idx = int.tryParse(itemId);
      if (idx != null && idx >= 0 && idx < items.length) {
        items[idx] = item.toMap();
      } else {
        items.add(item.toMap());
      }
    }
    await ref.set({
      'items': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeShoppingItem(String listId, int index) async {
    final ref = _root.collection('shoppingLists').doc(listId);
    final snap = await ref.get();
    final items =
        ((snap.data()?['items'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    if (index < 0 || index >= items.length) return;
    items.removeAt(index);
    await ref.set({
      'items': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> toggleChecked(String listId, int index, bool checked) async {
    final ref = _root.collection('shoppingLists').doc(listId);
    final snap = await ref.get();
    final items =
        ((snap.data()?['items'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    if (index < 0 || index >= items.length) return;
    items[index]['checked'] = checked;
    await ref.set({
      'items': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 🆕 Marca una lista como completada y la mueve al historial
  Future<void> completeShoppingList(String listId, {double? totalSpent}) async {
    final list = await getShoppingList(listId);
    if (list == null) return;

    // Crear copia en historial
    final historyRef = _root.collection('completedShoppingLists').doc();
    await historyRef.set({
      ...list.toMap(),
      'originalId': listId,
      'completedAt': FieldValue.serverTimestamp(),
      'totalSpent': totalSpent,
    });

    // Eliminar lista actual
    await deleteShoppingList(listId);
  }

  /// Stream del historial de compras completadas
  Stream<List<CompletedShoppingList>> streamCompletedShoppingLists() {
    return _root
        .collection('completedShoppingLists')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => 
          CompletedShoppingList.fromMap(d.id, d.data())).toList());
  }

  /// Obtener historial por mes
  Future<List<CompletedShoppingList>> getCompletedListsByMonth(
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    final snap = await _root
        .collection('completedShoppingLists')
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('completedAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('completedAt', descending: true)
        .get();

    return snap.docs.map((d) => 
      CompletedShoppingList.fromMap(d.id, d.data())).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GENERACIÓN AUTOMÁTICA DE LISTA DESDE PLANIFICADOR
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> generateShoppingFromPlanner(
    String plannerId, {
    String? targetListId,
  }) async {
    final planner = await getPlanner(plannerId);
    
    // Obtener Foods y Recipes
    final foodsSnap = await _root.collection('foods').get();
    final foodsMap = <String, Map<String, dynamic>>{};
    for (final d in foodsSnap.docs) {
      foodsMap[d.id] = d.data();
    }

    final recipesSnap = await _root.collection('recipes').get();
    final recipesMap = <String, Map<String, dynamic>>{};
    for (final d in recipesSnap.docs) {
      recipesMap[d.id] = d.data();
    }

    // Calcular multiplicador
    double multiplier = planner.customMultiplier ?? 1.0;
    if (planner.scope == ShoppingScope.biweekly) multiplier = 2.0;
    if (planner.scope == ShoppingScope.monthly) multiplier = 4.0;

    // Agregar ingredientes
    final aggregate = <String, Map<String, dynamic>>{};

    void addIngredient(String? foodId, String name, double qty, String unit) {
      final key = foodId ?? name.toLowerCase();
      if (aggregate.containsKey(key)) {
        aggregate[key]!['qty'] = (aggregate[key]!['qty'] as double) + qty * multiplier;
      } else {
        aggregate[key] = {
          'foodId': foodId,
          'name': name,
          'qty': qty * multiplier,
          'unit': unit,
        };
      }
    }

    for (final dayEntries in planner.days.values) {
      for (final entry in dayEntries) {
        if (entry.type == FavoriteType.food) {
          final foodData = foodsMap[entry.refId];
          if (foodData != null) {
            final unitSize = (foodData['unitSize'] as num?)?.toDouble() ?? 100;
            final unit = foodData['perUnit'] ?? 'g';
            addIngredient(
              entry.refId,
              foodData['name'] ?? 'Alimento',
              entry.servings * unitSize,
              unit.toString(),
            );
          }
        } else {
          // Recipe
          final recipeData = recipesMap[entry.refId];
          if (recipeData != null) {
            final servings = (recipeData['servings'] as num?)?.toInt() ?? 1;
            final ratio = entry.servings / (servings == 0 ? 1 : servings);
            final ingredients = (recipeData['ingredients'] as List?) ?? [];
            
            for (final ing in ingredients) {
              final ingMap = Map<String, dynamic>.from(ing as Map);
              final foodId = ingMap['foodId'];
              final qty = (ingMap['qty'] as num?)?.toDouble() ?? 0;
              final unit = ingMap['unit'] ?? 'unit';
              
              if (foodId != null) {
                final foodData = foodsMap[foodId];
                addIngredient(
                  foodId,
                  foodData?['name'] ?? 'Ingrediente',
                  qty * ratio,
                  unit.toString(),
                );
              } else {
                addIngredient(
                  null,
                  ingMap['freeName'] ?? 'Ingrediente',
                  qty * ratio,
                  unit.toString(),
                );
              }
            }
          }
        }
      }
    }

    // Crear o actualizar lista
    String listId = targetListId ?? '';
    if (listId.isEmpty) {
      listId = await createShoppingList(
        'Lista de ${planner.name}',
        scope: planner.scope,
      );
    }

    final items = aggregate.values.map((e) {
      UnitKind unitKind = UnitKind.unit;
      if (e['unit'] == 'g') unitKind = UnitKind.g;
      if (e['unit'] == 'ml') unitKind = UnitKind.ml;
      
      return {
        'foodId': e['foodId'],
        'name': e['name'],
        'qty': e['qty'],
        'unit': unitKind.name,
        'checked': false,
      };
    }).toList();

    await _root.collection('shoppingLists').doc(listId).set({
      'items': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
