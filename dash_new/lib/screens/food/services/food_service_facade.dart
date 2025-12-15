import '../models/food_models.dart';
import 'food_firestore_service.dart';

/// Facade que envuelve FoodFirestoreService y provee acceso a submódulos
/// para las pantallas V2
class FoodServiceFacade {
  final FoodFirestoreService _firestore;

  FoodServiceFacade(this._firestore);

  // Acceso directo a métodos del firestore
  Stream<List<Food>> streamFoods({String? query, bool supplementsOnly = false}) =>
      _firestore.streamFoods(query: query, supplementsOnly: supplementsOnly);

  Future<String> createFood(Food f) => _firestore.createFood(f);
  Future<void> updateFood(String id, Map<String, dynamic> data) =>
      _firestore.updateFood(id, data);
  Future<void> deleteFood(String id) => _firestore.deleteFood(id);

  Stream<List<Recipe>> streamRecipes() => _firestore.streamRecipes();
  Future<String> createRecipe(Recipe r) => _firestore.createRecipe(r);
  Future<void> updateRecipe(String id, Map<String, dynamic> data) =>
      _firestore.updateRecipe(id, data);
  Future<void> deleteRecipe(String id) => _firestore.deleteRecipe(id);

  Stream<List<ShoppingList>> streamShoppingLists() =>
      _firestore.streamShoppingLists();
  Future<String> createShoppingList(String name) =>
      _firestore.createShoppingList(name);
  Future<void> deleteShoppingList(String listId) =>
      _firestore.deleteShoppingList(listId);
  Future<void> upsertShoppingItem(
    String listId,
    String itemId,
    ShoppingListItem item,
  ) =>
      _firestore.upsertShoppingItem(listId, itemId, item);
  Future<void> removeShoppingItem(String listId, String itemId) =>
      _firestore.removeShoppingItem(listId, itemId);
  Future<void> toggleChecked(String listId, String itemId, bool checked) =>
      _firestore.toggleChecked(listId, itemId, checked);

  Stream<List<PantryItem>> streamPantry() => _firestore.streamPantry();
  Future<void> upsertPantry(PantryItem item) => _firestore.upsertPantry(item);
  Future<void> deletePantry(String id) => _firestore.deletePantry(id);
  Future<void> consumePantry(String id, double qtyConsumed) =>
      _firestore.consumePantry(id, qtyConsumed);

  // Submódulos
  DiarySubService get diary => DiarySubService(_firestore);
  CatalogSubService get catalog => CatalogSubService(_firestore);
  PlannerSubService get planner => PlannerSubService(_firestore);
  Stream<List<PantryItem>> get pantry => _firestore.streamPantry();
}

/// Submódulo Diary
class DiarySubService {
  final FoodFirestoreService _firestore;
  DiarySubService(this._firestore);

  Stream<DailyIntakeDoc?> streamDay(String dayId) =>
      _firestore.streamDailyIntake(dayId);
  
  Future<DailyIntakeDoc?> getDay(String dayId) async {
    final snapshot = await _firestore.streamDailyIntake(dayId).first;
    return snapshot;
  }

  Stream<Map<String, double?>> streamGlobalTargets() =>
      _firestore.streamGlobalTargets();

  Stream<List<DailyIntakeDoc>> streamLastDays(int days) =>
      _firestore.streamLastNDays(days);

  Future<void> addEntry(String dayId, IntakeEntry entry) =>
      _firestore.addIntakeEntry(dayId, entry);

  Future<void> removeEntry(String dayId, String entryId) =>
      _firestore.removeIntakeEntry(dayId, entryId);

  Future<void> addWater(String dayId, int ml) =>
      _firestore.addWater(dayId, ml);
}

/// Submódulo Catalog
class CatalogSubService {
  final FoodFirestoreService _firestore;
  CatalogSubService(this._firestore);

  Stream<List<Favorite>> streamFavorites() => _firestore.streamFavorites();
  Future<void> addFavorite(Favorite fav) => _firestore.addFavorite(fav);
  Future<void> removeFavorite(String id) => _firestore.removeFavorite(id);
}

/// Submódulo Planner
class PlannerSubService {
  final FoodFirestoreService _firestore;
  PlannerSubService(this._firestore);

  Stream<List<MealPlanner>> streamPlanners() => _firestore.streamPlanners();
  Future<String> createPlanner(String name) => _firestore.createPlanner(name);
  Future<void> deletePlanner(String id) => _firestore.deletePlanner(id);
  Future<void> updatePlannerName(String id, String name) =>
      _firestore.updatePlannerName(id, name);

  Stream<List<PlannerDayEntry>> streamPlannerDay(String plannerId, int dayIndex) =>
      _firestore.streamPlannerDay(plannerId, dayIndex);

  Future<void> addPlannerEntry(
    String plannerId,
    int dayIndex,
    PlannerDayEntry entry,
  ) =>
      _firestore.addPlannerEntry(plannerId, dayIndex, entry);

  Future<void> removePlannerEntry(
    String plannerId,
    int dayIndex,
    String entryId,
  ) =>
      _firestore.removePlannerEntry(plannerId, dayIndex, entryId);

  // Para historial de shopping completadas (implementación futura)
  Stream<List<CompletedShoppingList>> streamCompletedShoppingLists() {
    // Por ahora retorna lista vacía
    return Stream.value([]);
  }
}

/// Modelo para historial de compras completadas (futuro)
class CompletedShoppingList {
  final String id;
  final String name;
  final DateTime completedAt;
  final List<ShoppingListItem> items;
  final double totalSpent;

  const CompletedShoppingList({
    required this.id,
    required this.name,
    required this.completedAt,
    required this.items,
    required this.totalSpent,
  });
}
