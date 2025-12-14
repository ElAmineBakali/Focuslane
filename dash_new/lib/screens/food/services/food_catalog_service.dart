import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_models.dart';

/// 🗂️ Servicio de Catálogo de Alimentos y Recetas
/// Gestiona CRUD de alimentos, recetas y favoritos
class FoodCatalogService {
  final String userId;
  FoodCatalogService(this.userId);

  DocumentReference<Map<String, dynamic>> get _root => FirebaseFirestore
      .instance
      .collection('users')
      .doc(userId.trim().isEmpty ? 'local' : userId.trim())
      .collection('food')
      .doc('root');

  // ══════════════════════════════════════════════════════════════════════════
  // FOODS
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<Food>> streamFoods({
    String? query,
    bool supplementsOnly = false,
    List<String>? tags,
  }) {
    Query<Map<String, dynamic>> q = _root.collection('foods').orderBy('name');
    if (supplementsOnly) q = q.where('isSupplement', isEqualTo: true);
    
    return q.snapshots().map((s) {
      var list = s.docs.map((d) => Food.fromMap(d.id, d.data())).toList();
      
      // Filtro por query
      if (query != null && query.trim().isNotEmpty) {
        final ql = query.trim().toLowerCase();
        list = list.where((f) =>
            f.name.toLowerCase().contains(ql) ||
            (f.brand ?? '').toLowerCase().contains(ql),
        ).toList();
      }
      
      // Filtro por tags
      if (tags != null && tags.isNotEmpty) {
        list = list.where((f) => 
          f.tags.any((tag) => tags.contains(tag))
        ).toList();
      }
      
      return list;
    });
  }

  Future<Food?> getFood(String id) async {
    final snap = await _root.collection('foods').doc(id).get();
    if (!snap.exists) return null;
    return Food.fromMap(snap.id, snap.data() as Map<String, dynamic>);
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

  // ══════════════════════════════════════════════════════════════════════════
  // RECIPES
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<Recipe>> streamRecipes({
    String? query,
    List<String>? tags,
  }) {
    var stream = _root
        .collection('recipes')
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => Recipe.fromMap(d.id, d.data())).toList());
    
    return stream.map((list) {
      var filtered = list;
      
      // Filtro por query
      if (query != null && query.trim().isNotEmpty) {
        final ql = query.trim().toLowerCase();
        filtered = filtered.where((r) =>
          r.name.toLowerCase().contains(ql) ||
          (r.description ?? '').toLowerCase().contains(ql),
        ).toList();
      }
      
      // Filtro por tags
      if (tags != null && tags.isNotEmpty) {
        filtered = filtered.where((r) =>
          r.tags.any((tag) => tags.contains(tag))
        ).toList();
      }
      
      return filtered;
    });
  }

  Future<Recipe?> getRecipe(String id) async {
    final snap = await _root.collection('recipes').doc(id).get();
    if (!snap.exists) return null;
    return Recipe.fromMap(snap.id, snap.data() as Map<String, dynamic>);
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

  /// 🧮 Calcula macros totales de una receta basándose en sus ingredientes
  Future<Map<String, double>> calculateRecipeMacros(Recipe recipe) async {
    double kcal = 0, protein = 0, carbs = 0, fat = 0, fiber = 0, sodium = 0;

    for (final ing in recipe.ingredients) {
      if (ing.foodId != null) {
        final food = await getFood(ing.foodId!);
        if (food != null) {
          final macros = food.macrosFor(ing.qty);
          kcal += macros['kcal'] ?? 0;
          protein += macros['protein'] ?? 0;
          carbs += macros['carbs'] ?? 0;
          fat += macros['fat'] ?? 0;
          fiber += macros['fiber'] ?? 0;
          sodium += macros['sodium'] ?? 0;
        }
      }
      // Si no tiene foodId, ignoramos (ingrediente de texto libre)
    }

    return {
      'kcal': kcal,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sodium': sodium,
    };
  }

  /// 💾 Actualiza los macros de una receta con los valores calculados
  Future<void> updateRecipeMacros(String recipeId) async {
    final recipe = await getRecipe(recipeId);
    if (recipe == null) return;

    final macros = await calculateRecipeMacros(recipe);
    await updateRecipe(recipeId, macros);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FAVORITES
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<Favorite>> streamFavorites() {
    return _root
        .collection('favorites')
        .orderBy('alias', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => Favorite.fromMap(d.id, d.data())).toList());
  }

  Future<Favorite?> getFavorite(String id) async {
    final snap = await _root.collection('favorites').doc(id).get();
    if (!snap.exists) return null;
    return Favorite.fromMap(snap.id, snap.data() as Map<String, dynamic>);
  }

  Future<String> saveFavorite(Favorite f) async {
    if (f.id.isNotEmpty) {
      await _root.collection('favorites').doc(f.id).set(f.toMap());
      return f.id;
    } else {
      final doc = _root.collection('favorites').doc();
      await doc.set(f.toMap());
      return doc.id;
    }
  }

  Future<void> updateFavorite(String id, Map<String, dynamic> data) async {
    await _root.collection('favorites').doc(id).update(data);
  }

  Future<void> deleteFavorite(String id) async {
    await _root.collection('favorites').doc(id).delete();
  }

  /// Verifica si un alimento/receta ya es favorito
  Future<bool> isFavorite(String refId) async {
    final query = await _root
        .collection('favorites')
        .where('refId', isEqualTo: refId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }
}
