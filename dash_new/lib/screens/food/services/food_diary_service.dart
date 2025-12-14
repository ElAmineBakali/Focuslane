import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_models.dart';

/// 📅 Servicio del Diario de Alimentación
/// Gestiona el consumo diario, objetivos y agua
class FoodDiaryService {
  final String userId;
  FoodDiaryService(this.userId);

  DocumentReference<Map<String, dynamic>> get _root => FirebaseFirestore
      .instance
      .collection('users')
      .doc(userId.trim().isEmpty ? 'local' : userId.trim())
      .collection('food')
      .doc('root');

  // ══════════════════════════════════════════════════════════════════════════
  // OBJETIVOS GLOBALES
  // ══════════════════════════════════════════════════════════════════════════

  DocumentReference<Map<String, dynamic>> get _targetsRef =>
      _root.collection('config').doc('targets');

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

  Future<Map<String, double?>> getGlobalTargets() async {
    final snap = await _targetsRef.get();
    final m = Map<String, dynamic>.from(snap.data() ?? const {});
    double? n(String k) => (m[k] is num) ? (m[k] as num).toDouble() : null;
    return {
      'kcal': n('kcal'),
      'protein': n('protein'),
      'carbs': n('carbs'),
      'fat': n('fat'),
      'fiber': n('fiber'),
      'water': n('water'),
    };
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

  // ══════════════════════════════════════════════════════════════════════════
  // DIARIO DIARIO
  // ══════════════════════════════════════════════════════════════════════════

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
        targets: const {},
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
          targets: const {},
        );
      }
      return DailyIntakeDoc.fromMap(d.id, d.data() as Map<String, dynamic>);
    });
  }

  /// Stream de múltiples días (para historial)
  Stream<List<DailyIntakeDoc>> streamDays(List<String> dayIds) {
    if (dayIds.isEmpty) return Stream.value([]);
    
    return _root.collection('intake')
        .where(FieldPath.documentId, whereIn: dayIds)
        .snapshots()
        .map((s) => s.docs.map((d) => 
          DailyIntakeDoc.fromMap(d.id, d.data())).toList());
  }

  /// Obtener múltiples días de una vez
  Future<List<DailyIntakeDoc>> getDays(List<String> dayIds) async {
    if (dayIds.isEmpty) return [];
    
    final snapshots = await Future.wait(
      dayIds.map((id) => getDay(id)),
    );
    return snapshots;
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

  /// 🆕 Actualiza una entrada completa (cantidad y macros recalculados)
  Future<void> updateEntryComplete(
    String dayId,
    int index, {
    required double newQty,
    required UnitKind newUnit,
    required Map<String, double> newMacros,
  }) async {
    await updateEntry(dayId, index, {
      'qty': newQty,
      'unit': newUnit.name,
      'macrosSnapshot': newMacros,
    });
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

  /// Objetivos por día (opcional, legacy)
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

  Future<void> setWater(String dayId, int ml) async {
    await _dayRef(dayId).set({'waterMl': ml}, SetOptions(merge: true));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SUGERENCIAS INTELIGENTES
  // ══════════════════════════════════════════════════════════════════════════

  /// 🧠 Analiza el día actual y genera sugerencias
  Future<List<String>> generateSuggestions(String dayId) async {
    final day = await getDay(dayId);
    final targets = await getGlobalTargets();
    final suggestions = <String>[];

    final kcalTarget = targets['kcal'] ?? 2000;
    final proteinTarget = targets['protein'] ?? 150;
    
    final kcalConsumed = day.totals['kcal'] ?? 0;
    final proteinConsumed = day.totals['protein'] ?? 0;

    // Sugerencias calóricas
    if (kcalConsumed < kcalTarget * 0.7) {
      suggestions.add('📉 Estás por debajo de tu objetivo calórico. Considera añadir un snack rico en energía.');
    } else if (kcalConsumed > kcalTarget * 1.2) {
      suggestions.add('📈 Has superado tu objetivo calórico. Mantén el control el resto del día.');
    }

    // Sugerencias de proteína
    if (proteinConsumed < proteinTarget * 0.6) {
      suggestions.add('🥩 Proteína baja. Prueba añadir huevos, pollo, tofu o un batido de proteína.');
    }

    // Sugerencias de agua
    final waterTarget = (targets['water'] ?? 2000).toInt();
    if (day.waterMl < waterTarget * 0.5) {
      suggestions.add('💧 Recuerda hidratarte. Llevas ${day.waterMl}ml de ${waterTarget}ml.');
    }

    // Sugerencias de comidas pendientes
    if (day.entries.length < 3) {
      suggestions.add('🍽️ Has registrado pocas comidas hoy. No olvides registrar tus ingestas.');
    }

    return suggestions;
  }
}
