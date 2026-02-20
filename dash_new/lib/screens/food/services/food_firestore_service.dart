import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_models.dart';

class FoodFirestoreService {
  final String userId;
  FoodFirestoreService(this.userId);

  DocumentReference<Map<String, dynamic>> get _root => FirebaseFirestore
      .instance
      .collection('users')
      .doc(userId.trim().isEmpty ? 'local' : userId.trim())
      .collection('food')
      .doc('root');

  DocumentReference<Map<String, dynamic>> get _targetsRef =>
      _root.collection('config').doc('targets');

  DocumentReference<Map<String, dynamic>> get _flagsRef =>
      _root.collection('config').doc('flags');

  DocumentReference<Map<String, dynamic>> get _alertsRef =>
      _root.collection('config').doc('alerts');

  Stream<Map<String, dynamic>> streamFlags() {
    return _flagsRef.snapshots().map((d) => Map<String, dynamic>.from(d.data() ?? const {}));
  }

  Stream<Map<String, dynamic>> streamAlerts() {
    return _alertsRef.snapshots().map((d) => Map<String, dynamic>.from(d.data() ?? const {}));
  }

  Stream<Map<String, double?>> streamGlobalTargets() {
    return _targetsRef.snapshots().map((d) {
      final m = Map<String, dynamic>.from(d.data() ?? const {});
      double? n(String k) => (m[k] is num) ? (m[k] as num).toDouble() : null;
      return {
        'kcal': n('kcal'),
        'protein': n('protein'),
        'carbs': n('carbs'),
        'fat': n('fat'),
        'fiber': n('fiber'),
        'water': n('water'),
      };
    });
  }

  Future<void> setGlobalTargets({
    double? kcal,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    int? waterMl,
  }) async {
    final patch = <String, dynamic>{};
    if (kcal != null) patch['kcal'] = kcal;
    if (protein != null) patch['protein'] = protein;
    if (carbs != null) patch['carbs'] = carbs;
    if (fat != null) patch['fat'] = fat;
    if (fiber != null) patch['fiber'] = fiber;
    if (waterMl != null) patch['water'] = waterMl.toDouble();
    if (patch.isEmpty) return;
    await _targetsRef.set(patch, SetOptions(merge: true));
  }

  Stream<List<Food>> streamFoods({
    String? query,
    bool supplementsOnly = false,
  }) {
    Query<Map<String, dynamic>> q = _root.collection('foods').orderBy('name');

    return q.snapshots().map((s) {
      var list = s.docs.map((d) => Food.fromMap(d.id, d.data())).toList();

      if (supplementsOnly) {
        list = list.where((f) => f.isSupplement).toList();
      }

      if (query != null && query.trim().isNotEmpty) {
        final ql = query.trim().toLowerCase();
        list =
            list
                .where(
                  (f) =>
                      f.name.toLowerCase().contains(ql) ||
                      (f.brand ?? '').toLowerCase().contains(ql),
                )
                .toList();
      }

      return list;
    });
  }

  Future<String> createFood(Food f) async {
    final doc = _root.collection('foods').doc();
    await doc.set(f.toMap());
    return doc.id;
  }

  Future<void> updateFood(String id, Map<String, dynamic> data) async {
    await _root.collection('foods').doc(id).update(data);
  }

  Future<void> deleteFood(String id) async {
    await _root.collection('foods').doc(id).delete();
  }

  Stream<List<Recipe>> streamRecipes() {
    return _root
        .collection('recipes')
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => Recipe.fromMap(d.id, d.data())).toList());
  }

  Future<String> createRecipe(Recipe r) async {
    final doc = _root.collection('recipes').doc();
    await doc.set(r.toMap());
    return doc.id;
  }

  Future<void> updateRecipe(String id, Map<String, dynamic> data) async {
    await _root.collection('recipes').doc(id).update(data);
  }

  Future<void> deleteRecipe(String id) async {
    await _root.collection('recipes').doc(id).delete();
  }

  Stream<List<Favorite>> streamFavorites() {
    return _root
        .collection('favorites')
        .orderBy('alias', descending: false)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Favorite.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<String> saveFavorite(Favorite f) async {
    final doc = _root.collection('favorites').doc();
    await doc.set(f.toMap());
    return doc.id;
  }

  Future<void> deleteFavorite(String id) async {
    await _root.collection('favorites').doc(id).delete();
  }

  Future<String> addFavorite(Favorite f) => saveFavorite(f);
  Future<void> removeFavorite(String id) => deleteFavorite(id);

  DocumentReference<Map<String, dynamic>> _dayRef(String dayId) =>
      _root.collection('intake').doc(dayId);

  Future<DailyIntakeDoc> getDay(String dayId) async {
    final snap = await _dayRef(dayId).get();
    if (!snap.exists) {
      final empty = DailyIntakeDoc(
        id: dayId,
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
      await _dayRef(dayId).set(empty.toMap());
      return empty;
    }
    return DailyIntakeDoc.fromMap(snap.id, snap.data() as Map<String, dynamic>);
  }

  Stream<DailyIntakeDoc> streamDay(String dayId) {
    return _dayRef(dayId).snapshots().map((d) {
      if (!d.exists) {
        return DailyIntakeDoc(
          id: dayId,
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
      }
      return DailyIntakeDoc.fromMap(d.id, d.data() as Map<String, dynamic>);
    });
  }

  Future<void> _recalcTotals(
    String dayId,
    List<Map<String, dynamic>> entries,
  ) async {
    double kcal = 0, p = 0, c = 0, f = 0, fib = 0, s = 0;
    for (final e in entries) {
      final m = Map<String, dynamic>.from(e['macrosSnapshot'] as Map);
      kcal += (m['kcal'] as num?)?.toDouble() ?? 0;
      p += (m['protein'] as num?)?.toDouble() ?? 0;
      c += (m['carbs'] as num?)?.toDouble() ?? 0;
      f += (m['fat'] as num?)?.toDouble() ?? 0;
      fib += (m['fiber'] as num?)?.toDouble() ?? 0;
      s += (m['sodium'] as num?)?.toDouble() ?? 0;
    }
    await _dayRef(dayId).set({
      'entries': entries,
      'totals': {
        'kcal': kcal,
        'protein': p,
        'carbs': c,
        'fat': f,
        'fiber': fib,
        'sodium': s,
      },
    }, SetOptions(merge: true));
  }

  Future<void> addEntry(String dayId, IntakeEntry entry) async {
    final snap = await _dayRef(dayId).get();
    final data = snap.data() ?? {};
    final entries =
        ((data['entries'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    entries.add(entry.toMap());
    await _recalcTotals(dayId, entries);
  }

  Future<void> updateEntry(
    String dayId,
    int index,
    Map<String, dynamic> patch,
  ) async {
    final snap = await _dayRef(dayId).get();
    if (!snap.exists) return;
    final entries =
        ((snap.data()!['entries'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    if (index < 0 || index >= entries.length) return;
    entries[index].addAll(patch);
    await _recalcTotals(dayId, entries);
  }

  Future<void> deleteEntry(String dayId, int index) async {
    final snap = await _dayRef(dayId).get();
    if (!snap.exists) return;
    final entries =
        ((snap.data()!['entries'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    if (index < 0 || index >= entries.length) return;
    entries.removeAt(index);
    await _recalcTotals(dayId, entries);
  }

  Future<void> setTargets(
    String dayId, {
    double? kcal,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    int? waterMl,
  }) async {
    final snap = await _dayRef(dayId).get();
    final data = snap.data() ?? {};
    final targets = Map<String, dynamic>.from(data['targets'] ?? {});
    if (kcal != null) targets['kcal'] = kcal;
    if (protein != null) targets['protein'] = protein;
    if (carbs != null) targets['carbs'] = carbs;
    if (fat != null) targets['fat'] = fat;
    if (fiber != null) targets['fiber'] = fiber;
    if (waterMl != null) targets['water'] = waterMl.toDouble();
    await _dayRef(dayId).set({'targets': targets}, SetOptions(merge: true));
  }

  Future<void> incrementWater(String dayId, int addMl) async {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final ref = _dayRef(dayId);
      final snap = await tx.get(ref);
      final current = (snap.data()?['waterMl'] as num?)?.toInt() ?? 0;
      tx.set(ref, {'waterMl': current + addMl}, SetOptions(merge: true));
    });
  }

  Stream<DailyIntakeDoc> streamDailyIntake(String dayId) => streamDay(dayId);
  Future<void> addIntakeEntry(String dayId, IntakeEntry entry) =>
      addEntry(dayId, entry);
  Future<void> removeIntakeEntry(String dayId, String entryId) async {
    final index = int.tryParse(entryId);
    if (index != null) await deleteEntry(dayId, index);
  }

  Future<void> addWater(String dayId, int ml) => incrementWater(dayId, ml);

  Stream<List<DailyIntakeDoc>> streamLastNDays(int n) {
    final today = DateTime.now();
    final dayIds = List.generate(n, (i) {
      final d = today.subtract(Duration(days: i));
      return d.toIso8601String().substring(0, 10);
    });

    return _root.collection('intake').snapshots().map((snap) {
      final docs = <DailyIntakeDoc>[];
      for (final dayId in dayIds) {
        final doc = snap.docs.where((d) => d.id == dayId).firstOrNull;
        if (doc != null) {
          docs.add(DailyIntakeDoc.fromMap(doc.id, doc.data()));
        } else {
          docs.add(
            DailyIntakeDoc(
              id: dayId,
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
            ),
          );
        }
      }
      return docs;
    });
  }

  CollectionReference<Map<String, dynamic>> get _weekPlannersRef =>
      FirebaseFirestore.instance.collection('weekPlanners');

  DocumentReference<Map<String, dynamic>> _plannerRef(String weekId) =>
      _weekPlannersRef.doc(weekId);

  Future<WeekPlanner> getWeek(String weekId) async {
    final snap = await _plannerRef(weekId).get();
    if (!snap.exists) {
      final empty = WeekPlanner(
        id: weekId,
        scope: ShoppingScope.weekly,
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
      await _plannerRef(weekId).set(empty.toMap());
      return empty;
    }
    return WeekPlanner.fromMap(snap.id, snap.data() as Map<String, dynamic>);
  }

  Stream<WeekPlanner> streamWeek(String weekId) {
    return _plannerRef(weekId).snapshots().map((d) {
      if (!d.exists) {
        return WeekPlanner(
          id: weekId,
          scope: ShoppingScope.weekly,
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

  Future<void> saveWeek(WeekPlanner w) async {
    await _plannerRef(w.id).set({
      ...w.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<dynamic>> streamPlanners() {
    return Stream.value([]);
  }

  Stream<List<Map<String, dynamic>>> streamWeekPlannersRaw() {
    return _weekPlannersRef.snapshots().map((snap) {
      return snap.docs
          .map(
            (d) => {
              'id': d.id,
              ...d.data(),
            },
          )
          .toList();
    });
  }

  Future<void> setActiveWeekPlanner(String id) async {
    final all = await _weekPlannersRef.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in all.docs) {
      batch.update(d.reference, {'isActive': d.id == id});
    }
    await batch.commit();
  }

  Future<String> createPlanner(String name) async {
    final doc = _root.collection('mealPlanners').doc();
    await doc.set({
      'name': name,
      'days': {for (var i = 0; i < 7; i++) '$i': []},
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> deletePlanner(String id) async {
    await _root.collection('mealPlanners').doc(id).delete();
  }

  Future<void> updatePlannerName(String id, String name) async {
    await _root.collection('mealPlanners').doc(id).update({'name': name});
  }

  Stream<List<PlannerDayEntry>> streamPlannerDay(
    String plannerId,
    int dayIndex,
  ) {
    return _root.collection('mealPlanners').doc(plannerId).snapshots().map((
      snap,
    ) {
      if (!snap.exists) return [];
      final data = snap.data() as Map<String, dynamic>;
      final days = data['days'] as Map<String, dynamic>?;
      if (days == null) return [];
      final dayData = days['$dayIndex'] as List?;
      if (dayData == null) return [];
      return dayData
          .map(
            (e) => PlannerDayEntry.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    });
  }

  Future<void> addPlannerEntry(
    String plannerId,
    int dayIndex,
    PlannerDayEntry entry,
  ) async {
    final ref = _root.collection('mealPlanners').doc(plannerId);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final days = Map<String, dynamic>.from(data['days'] ?? {});
    final dayList = List.from(days['$dayIndex'] ?? []);
    dayList.add(entry.toMap());
    days['$dayIndex'] = dayList;
    await ref.update({'days': days});
  }

  Future<void> removePlannerEntry(
    String plannerId,
    int dayIndex,
    String entryId,
  ) async {
    final ref = _root.collection('mealPlanners').doc(plannerId);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final days = Map<String, dynamic>.from(data['days'] ?? {});
    final dayList = List.from(days['$dayIndex'] ?? []);
    dayList.removeWhere((e) => e['id'] == entryId);
    days['$dayIndex'] = dayList;
    await ref.update({'days': days});
  }

  Stream<List<ShoppingList>> streamShoppingLists() {
    return _root
        .collection('shoppingLists')
        .orderBy('name')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => ShoppingList.fromMap(d.id, d.data())).toList(),
        );
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
    String listId,
    String itemId,
    ShoppingListItem item,
  ) async {
    await upsertShoppingItemInternal(listId, itemId: itemId, item: item);
  }

  Future<void> upsertShoppingItemInternal(
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

  Future<void> removeShoppingItem(String listId, String itemId) async {
    final index = int.tryParse(itemId) ?? -1;
    await removeShoppingItemByIndex(listId, index);
  }

  Future<void> removeShoppingItemByIndex(String listId, int index) async {
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

  Future<void> toggleChecked(String listId, String itemId, bool checked) async {
    final index = int.tryParse(itemId) ?? -1;
    await toggleCheckedByIndex(listId, index, checked);
  }

  Future<void> toggleCheckedByIndex(
    String listId,
    int index,
    bool checked,
  ) async {
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

  Future<void> setAllChecked(String listId, bool checked) async {
    final ref = _root.collection('shoppingLists').doc(listId);
    final snap = await ref.get();
    final items =
        ((snap.data()?['items'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    for (final item in items) {
      item['checked'] = checked;
    }
    await ref.set({
      'items': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> clearCompleted(String listId) async {
    final ref = _root.collection('shoppingLists').doc(listId);
    final snap = await ref.get();
    final items =
        ((snap.data()?['items'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    items.removeWhere((item) => item['checked'] == true);
    await ref.set({
      'items': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<PantryItem>> streamPantry() {
    return _root
        .collection('pantry')
        .orderBy('name')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => PantryItem.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> upsertPantry(PantryItem item) async {
    await upsertPantryWithId(item, id: item.id.isEmpty ? null : item.id);
  }

  Future<void> upsertPantryWithId(PantryItem item, {String? id}) async {
    final col = _root.collection('pantry');
    if (id == null) {
      await col.add(item.toMap());
    } else {
      await col.doc(id).set(item.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deletePantry(String id) async {
    await _root.collection('pantry').doc(id).delete();
  }

  Future<void> consumePantry(String id, double qty) async {
    final ref = _root.collection('pantry').doc(id);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = (snap.data()?['qty'] as num?)?.toDouble() ?? 0;
      tx.update(ref, {'qty': (current - qty).clamp(0, double.infinity)});
    });
  }

  Future<void> generateShoppingFromWeek(
    String weekId, {
    ShoppingScope? scopeOverride,
    String? targetListId,
  }) async {
    final week = await _plannerRef(weekId).get();
    if (!week.exists) return;
    final w = WeekPlanner.fromMap(week.id, week.data() as Map<String, dynamic>);

    final foodsMap = <String, Food>{};
    final foodsSnap = await _root.collection('foods').get();
    for (final d in foodsSnap.docs) {
      final f = Food.fromMap(d.id, d.data());
      foodsMap[f.id] = f;
    }

    final aggregate = <String, Map<String, dynamic>>{};
    double multiplier = 1.0;
    final scope = scopeOverride ?? w.scope;
    if (scope == ShoppingScope.biweekly) multiplier = 2.0;
    if (scope == ShoppingScope.monthly) multiplier = 4.0;

    Future<void> addFood(
      String? foodId,
      String name,
      double qty,
      UnitKind unit,
    ) async {
      final key = foodId ?? name.toLowerCase();
      final current = aggregate[key];
      if (current == null) {
        aggregate[key] = {
          'foodId': foodId,
          'name': name,
          'qty': qty * multiplier,
          'unit': unit.name,
        };
      } else {
        current['qty'] = (current['qty'] as double) + qty * multiplier;
      }
    }

    for (final day in w.days.values) {
      for (final entry in day) {
        if (entry.type == FavoriteType.food) {
          final f = foodsMap[entry.refId];
          if (f != null) {
            await addFood(f.id, f.name, entry.servings * f.unitSize, f.perUnit);
          }
        } else {
          final recSnap =
              await _root.collection('recipes').doc(entry.refId).get();
          if (!recSnap.exists) continue;
          final rec = Recipe.fromMap(
            recSnap.id,
            recSnap.data() as Map<String, dynamic>,
          );
          final ratio = entry.servings / (rec.servings == 0 ? 1 : rec.servings);
          for (final ing in rec.ingredients) {
            if (ing.foodId != null) {
              final f = foodsMap[ing.foodId!];
              if (f != null) {
                await addFood(f.id, f.name, ing.qty * ratio, ing.unit);
              }
            } else {
              await addFood(
                null,
                (ing.freeName ?? 'Ingrediente'),
                ing.qty * ratio,
                ing.unit,
              );
            }
          }
        }
      }
    }

    String listId = targetListId ?? '';
    if (listId.isEmpty) {
      listId = await createShoppingList(
        'Lista $weekId',
        scope: scope,
        isDefault: false,
      );
    }
    final items =
        aggregate.values
            .map(
              (e) =>
                  ShoppingListItem(
                    id: '',
                    foodId: e['foodId'] as String?,
                    name: e['name'] as String,
                    qty: (e['qty'] as double),
                    unit: UnitKind.values.firstWhere(
                      (u) => u.name == e['unit'],
                    ),
                  ).toMap(),
            )
            .toList();

    await _root.collection('shoppingLists').doc(listId).set({
      'items': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  DocumentReference<Map<String, dynamic>> get _remindersRef =>
      _root.collection('config').doc('reminders');

  Future<Map<String, dynamic>> getRemindersConfig() async {
    final snap = await _remindersRef.get();
    return Map<String, dynamic>.from(snap.data() ?? const {});
  }

  Future<void> saveRemindersConfig(Map<String, dynamic> data) async {
    await _remindersRef.set(data, SetOptions(merge: true));
  }

  Future<void> markAwake(DateTime when, {required String dayId}) async {
    await _remindersRef.set({
      'lastAwakeAt': Timestamp.fromDate(when),
      'lastAwakeDayId': dayId,
    }, SetOptions(merge: true));
  }
}
