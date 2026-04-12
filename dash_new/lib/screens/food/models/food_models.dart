import 'package:flutter/material.dart';

enum UnitKind { g, ml, unit }

enum FavoriteType { food, recipe, photoAi }

enum MealSlot { breakfast, snack, lunch, merienda, dinner }

enum MealTag { breakfast, lunch, dinner, snack }

enum ShoppingScope { weekly, biweekly, monthly, custom }

enum EntryType { food, recipe }

class ShoppingItem {
  final String name;
  final String category;
  final bool checked;
  
  const ShoppingItem({
    required this.name,
    required this.category,
    this.checked = false,
  });
}

Color? _hex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  try {
    final v = int.parse(
      hex.startsWith('0x') ? hex.substring(2) : hex,
      radix: 16,
    );
    return Color(v);
  } catch (_) {
    return null;
  }
}

class Food {
  final String id;
  final String name;
  final UnitKind perUnit;
  final double unitSize;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodium;
  final bool isSupplement;
  final String? brand;
  final List<String> tags;
  final String? colorHex;

  const Food({
    required this.id,
    required this.name,
    required this.perUnit,
    required this.unitSize,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sodium,
    required this.isSupplement,
    this.brand,
    this.tags = const [],
    this.colorHex,
  });

  Color? get color => _hex(colorHex);
  
  double get servingSize => unitSize;
  String get servingUnit => perUnit.name;
  bool get isSupp => isSupplement;

  factory Food.fromMap(String id, Map<String, dynamic> m) {
    UnitKind u(dynamic v) {
      switch ('$v') {
        case 'g':
          return UnitKind.g;
        case 'ml':
          return UnitKind.ml;
        default:
          return UnitKind.unit;
      }
    }

    return Food(
      id: id,
      name: m['name'] ?? '',
      perUnit: u(m['perUnit']),
      unitSize: (m['unitSize'] as num?)?.toDouble() ?? 100,
      kcal: (m['kcal'] as num?)?.toDouble() ?? 0,
      protein: (m['protein'] as num?)?.toDouble() ?? 0,
      carbs: (m['carbs'] as num?)?.toDouble() ?? 0,
      fat: (m['fat'] as num?)?.toDouble() ?? 0,
      fiber: (m['fiber'] as num?)?.toDouble() ?? 0,
      sodium: (m['sodium'] as num?)?.toDouble() ?? 0,
      isSupplement: m['isSupplement'] == true,
      brand: m['brand'],
      tags: (m['tags'] as List?)?.cast<String>() ?? const [],
      colorHex: m['colorHex'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'perUnit': perUnit.name,
    'unitSize': unitSize,
    'kcal': kcal,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'sodium': sodium,
    'isSupplement': isSupplement,
    if (brand != null) 'brand': brand,
    if (tags.isNotEmpty) 'tags': tags,
    if (colorHex != null) 'colorHex': colorHex,
  };

  Map<String, double> macrosFor(double qty) {
    final ratio = unitSize == 0 ? 0 : qty / unitSize;
    return {
      'kcal': kcal * ratio,
      'protein': protein * ratio,
      'carbs': carbs * ratio,
      'fat': fat * ratio,
      'fiber': fiber * ratio,
      'sodium': sodium * ratio,
    };
  }
}

class RecipeIngredient {
  final String? foodId;
  final String? freeName;
  final double qty;
  final UnitKind unit;

  const RecipeIngredient({
    this.foodId,
    this.freeName,
    required this.qty,
    required this.unit,
  });

  factory RecipeIngredient.fromMap(Map<String, dynamic> m) {
    UnitKind u(dynamic v) {
      switch ('$v') {
        case 'g':
          return UnitKind.g;
        case 'ml':
          return UnitKind.ml;
        default:
          return UnitKind.unit;
      }
    }

    return RecipeIngredient(
      foodId: m['foodId'],
      freeName: m['freeName'],
      qty: (m['qty'] as num?)?.toDouble() ?? 0,
      unit: u(m['unit']),
    );
  }

  Map<String, dynamic> toMap() => {
    if (foodId != null) 'foodId': foodId,
    if (freeName != null) 'freeName': freeName,
    'qty': qty,
    'unit': unit.name,
  };
}

class Recipe {
  final String id;
  final String name;
  final String? description;
  final List<String> tags;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final String steps;
  final double? kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;
  final double? sodium;

  const Recipe({
    required this.id,
    required this.name,
    this.description,
    this.tags = const [],
    required this.servings,
    required this.ingredients,
    this.steps = '',
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sodium,
  });

  factory Recipe.fromMap(String id, Map<String, dynamic> m) {
    return Recipe(
      id: id,
      name: m['name'] ?? '',
      description: m['description'],
      tags: (m['tags'] as List?)?.cast<String>() ?? const [],
      servings: (m['servings'] as num?)?.toInt() ?? 1,
      ingredients:
          ((m['ingredients'] as List?) ?? const [])
              .map(
                (e) => RecipeIngredient.fromMap(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList(),
      steps: m['steps'] ?? '',
      kcal: (m['kcal'] as num?)?.toDouble(),
      protein: (m['protein'] as num?)?.toDouble(),
      carbs: (m['carbs'] as num?)?.toDouble(),
      fat: (m['fat'] as num?)?.toDouble(),
      fiber: (m['fiber'] as num?)?.toDouble(),
      sodium: (m['sodium'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    if (description != null) 'description': description,
    if (tags.isNotEmpty) 'tags': tags,
    'servings': servings,
    'ingredients': ingredients.map((e) => e.toMap()).toList(),
    'steps': steps,
    if (kcal != null) 'kcal': kcal,
    if (protein != null) 'protein': protein,
    if (carbs != null) 'carbs': carbs,
    if (fat != null) 'fat': fat,
    if (fiber != null) 'fiber': fiber,
    if (sodium != null) 'sodium': sodium,
  };
}

class Favorite {
  final String id;
  final FavoriteType type;
  final String refId;
  final double defaultQty;
  final UnitKind defaultUnit;
  final String? alias;

  const Favorite({
    required this.id,
    required this.type,
    required this.refId,
    required this.defaultQty,
    required this.defaultUnit,
    this.alias,
  });

  factory Favorite.fromMap(String id, Map<String, dynamic> m) {
    FavoriteType t(dynamic v) {
      final raw = '$v';
      if (raw == 'recipe') return FavoriteType.recipe;
      if (raw == 'photo_ai' || raw == 'photoAi') return FavoriteType.photoAi;
      return FavoriteType.food;
    }
    UnitKind u(dynamic v) {
      switch ('$v') {
        case 'g':
          return UnitKind.g;
        case 'ml':
          return UnitKind.ml;
        default:
          return UnitKind.unit;
      }
    }

    return Favorite(
      id: id,
      type: t(m['type']),
      refId: m['refId'] ?? '',
      defaultQty: (m['defaultQty'] as num?)?.toDouble() ?? 0,
      defaultUnit: u(m['defaultUnit']),
      alias: m['alias'],
    );
  }

  Map<String, dynamic> toMap() => {
    'type': _favoriteTypeStorage(type),
    'refId': refId,
    'defaultQty': defaultQty,
    'defaultUnit': defaultUnit.name,
    if (alias != null) 'alias': alias,
  };
}

String _favoriteTypeStorage(FavoriteType type) {
  switch (type) {
    case FavoriteType.food:
      return 'food';
    case FavoriteType.recipe:
      return 'recipe';
    case FavoriteType.photoAi:
      return 'photo_ai';
  }
}

class IntakeEntry {
  final String id;
  final FavoriteType type;
  final String refId;
  final double qty;
  final UnitKind unit;
  final String nameSnapshot;
  final Map<String, double> macrosSnapshot;
  final MealSlot meal;
  final Map<String, dynamic>? aiMeta;

  const IntakeEntry({
    required this.id,
    required this.type,
    required this.refId,
    required this.qty,
    required this.unit,
    required this.nameSnapshot,
    required this.macrosSnapshot,
    required this.meal,
    this.aiMeta,
  });

  factory IntakeEntry.fromMap(String id, Map<String, dynamic> m) {
    FavoriteType t(dynamic v) {
      final raw = '$v';
      if (raw == 'recipe') return FavoriteType.recipe;
      if (raw == 'photo_ai' || raw == 'photoAi') return FavoriteType.photoAi;
      return FavoriteType.food;
    }
    UnitKind u(dynamic v) {
      switch ('$v') {
        case 'g':
          return UnitKind.g;
        case 'ml':
          return UnitKind.ml;
        default:
          return UnitKind.unit;
      }
    }
    MealSlot meal(dynamic v) {
      switch ('$v') {
        case 'breakfast':
          return MealSlot.breakfast;
        case 'lunch':
          return MealSlot.lunch;
        case 'merienda':
          return MealSlot.merienda;
        case 'dinner':
          return MealSlot.dinner;
        case 'snack':
        default:
          return MealSlot.snack;
      }
    }

    return IntakeEntry(
      id: id,
      type: t(m['type']),
      refId: m['refId'] ?? '',
      qty: (m['qty'] as num?)?.toDouble() ?? 0,
      unit: u(m['unit']),
      nameSnapshot: m['nameSnapshot'] ?? '',
      macrosSnapshot: Map<String, double>.from(
        (m['macrosSnapshot'] as Map?)?.map(
              (k, v) => MapEntry('$k', (v as num).toDouble()),
            ) ??
            const {},
      ),
      meal: meal(m['meal']),
      aiMeta: (m['aiMeta'] as Map?)?.cast<String, dynamic>(),
    );
  }

  Map<String, dynamic> toMap() => {
    'type': _favoriteTypeStorage(type),
    'refId': refId,
    'qty': qty,
    'unit': unit.name,
    'nameSnapshot': nameSnapshot,
    'macrosSnapshot': macrosSnapshot,
    'meal': meal.name,
    if (aiMeta != null) 'aiMeta': aiMeta,
  };
}

class DailyIntakeDoc {
  final String id;
  final List<IntakeEntry> entries;
  final int waterMl;
  final Map<String, double> totals;
  final Map<String, double?> targets;

  const DailyIntakeDoc({
    required this.id,
    required this.entries,
    required this.waterMl,
    required this.totals,
    required this.targets,
  });

  factory DailyIntakeDoc.fromMap(String id, Map<String, dynamic> m) {
    return DailyIntakeDoc(
      id: id,
      entries:
          ((m['entries'] as List?) ?? const [])
              .asMap()
              .entries
              .map(
                (e) => IntakeEntry.fromMap(
                  e.key.toString(),
                  Map<String, dynamic>.from(e.value as Map),
                ),
              )
              .toList(),
      waterMl: (m['waterMl'] as num?)?.toInt() ?? 0,
      totals: Map<String, double>.from(
        (m['totals'] as Map?)?.map(
              (k, v) => MapEntry('$k', (v as num).toDouble()),
            ) ??
            const {},
      ),
      targets: Map<String, double?>.from(
        (m['targets'] as Map?)?.map(
              (k, v) => MapEntry('$k', (v as num?)?.toDouble()),
            ) ??
            const {},
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'entries': entries.map((e) => e.toMap()).toList(),
    'waterMl': waterMl,
    'totals': totals,
    'targets': targets,
  };
}

class PlannerDayEntry {
  final MealSlot slot;
  final FavoriteType type;
  final String refId;
  final double servings;

  const PlannerDayEntry({
    required this.slot,
    required this.type,
    required this.refId,
    required this.servings,
  });

  factory PlannerDayEntry.fromMap(Map<String, dynamic> m) {
    MealSlot slot(dynamic v) {
      switch ('$v') {
        case 'breakfast':
          return MealSlot.breakfast;
        case 'snack':
          return MealSlot.snack;
        case 'lunch':
          return MealSlot.lunch;
        case 'merienda':
          return MealSlot.merienda;
        default:
          return MealSlot.dinner;
      }
    }

    FavoriteType t(dynamic v) =>
        ('$v' == 'recipe') ? FavoriteType.recipe : FavoriteType.food;

    return PlannerDayEntry(
      slot: slot(m['slot']),
      type: t(m['type']),
      refId: m['refId'] ?? '',
      servings: (m['servings'] as num?)?.toDouble() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
    'slot': slot.name,
    'type': type.name,
    'refId': refId,
    'servings': servings,
  };
}

class WeekPlanner {
  final String id;
  final ShoppingScope scope;
  final Map<String, List<PlannerDayEntry>> days;

  const WeekPlanner({
    required this.id,
    required this.scope,
    required this.days,
  });

  factory WeekPlanner.fromMap(String id, Map<String, dynamic> m) {
    final daysRaw = Map<String, dynamic>.from(m['days'] ?? const {});
    final parsed = <String, List<PlannerDayEntry>>{};
    for (final k in daysRaw.keys) {
      parsed[k] =
          ((daysRaw[k] as List?) ?? const [])
              .map(
                (e) => PlannerDayEntry.fromMap(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
    }
    ShoppingScope scope(dynamic v) {
      switch ('$v') {
        case 'weekly':
          return ShoppingScope.weekly;
        case 'biweekly':
          return ShoppingScope.biweekly;
        case 'monthly':
          return ShoppingScope.monthly;
        default:
          return ShoppingScope.custom;
      }
    }

    return WeekPlanner(id: id, scope: scope(m['scope']), days: parsed);
  }

  Map<String, dynamic> toMap() => {
    'scope': scope.name,
    'days': days.map((k, v) => MapEntry(k, v.map((e) => e.toMap()).toList())),
  };
}

class ShoppingListItem {
  final String id;
  final String? foodId;
  final String name;
  final double qty;
  final UnitKind unit;
  final bool checked;
  final double? pricePerUnit;
  final double? total;
  final List<String> tags;
  final String? notes;

  const ShoppingListItem({
    required this.id,
    this.foodId,
    required this.name,
    required this.qty,
    required this.unit,
    this.checked = false,
    this.pricePerUnit,
    this.total,
    this.tags = const [],
    this.notes,
  });

  factory ShoppingListItem.fromMap(String id, Map<String, dynamic> m) {
    UnitKind u(dynamic v) {
      switch ('$v') {
        case 'g':
          return UnitKind.g;
        case 'ml':
          return UnitKind.ml;
        default:
          return UnitKind.unit;
      }
    }

    return ShoppingListItem(
      id: id,
      foodId: m['foodId'],
      name: m['name'] ?? '',
      qty: (m['qty'] as num?)?.toDouble() ?? 0,
      unit: u(m['unit']),
      checked: m['checked'] == true,
      pricePerUnit: (m['pricePerUnit'] as num?)?.toDouble(),
      total: (m['total'] as num?)?.toDouble(),
      tags: (m['tags'] as List?)?.cast<String>() ?? const [],
      notes: m['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
    if (foodId != null) 'foodId': foodId,
    'name': name,
    'qty': qty,
    'unit': unit.name,
    'checked': checked,
    if (pricePerUnit != null) 'pricePerUnit': pricePerUnit,
    if (total != null) 'total': total,
    if (tags.isNotEmpty) 'tags': tags,
    if (notes != null) 'notes': notes,
  };
}

class ShoppingList {
  final String id;
  final String name;
  final ShoppingScope scope;
  final bool isDefault;
  final bool isCompleted;
  final List<ShoppingListItem> items;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ShoppingList({
    required this.id,
    required this.name,
    required this.scope,
    required this.isDefault,
    required this.isCompleted,
    required this.items,
    required this.createdAt,
    this.updatedAt,
  });

  factory ShoppingList.fromMap(String id, Map<String, dynamic> m) {
    DateTime parse(dynamic v) {
      try {
        if (v == null) return DateTime.now();
        if (v is DateTime) return v;
        return DateTime.parse(v.toDate().toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    ShoppingScope scope(dynamic v) {
      switch ('$v') {
        case 'weekly':
          return ShoppingScope.weekly;
        case 'biweekly':
          return ShoppingScope.biweekly;
        case 'monthly':
          return ShoppingScope.monthly;
        default:
          return ShoppingScope.custom;
      }
    }

    return ShoppingList(
      id: id,
      name: m['name'] ?? '',
      scope: scope(m['scope']),
      isDefault: m['isDefault'] == true,
        isCompleted: m['isCompleted'] == true,
      items:
          ((m['items'] as List?) ?? const [])
              .asMap()
              .entries
              .map(
                (e) => ShoppingListItem.fromMap(
                  e.key.toString(),
                  Map<String, dynamic>.from(e.value as Map),
                ),
              )
              .toList(),
      createdAt: parse(m['createdAt']),
      updatedAt: m['updatedAt'] != null ? parse(m['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'scope': scope.name,
    'isDefault': isDefault,
    'isCompleted': isCompleted,
    'items': items.map((e) => e.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  ShoppingList copyWith({
    String? name,
    bool? isCompleted,
    List<ShoppingListItem>? items,
  }) {
    return ShoppingList(
      id: id,
      name: name ?? this.name,
      scope: scope,
      isDefault: isDefault,
      isCompleted: isCompleted ?? this.isCompleted,
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class PantryItem {
  final String id;
  final String? foodId;
  final String name;
  final double qty;
  final UnitKind unit;
  final double? minQty;

  const PantryItem({
    required this.id,
    this.foodId,
    required this.name,
    required this.qty,
    required this.unit,
    this.minQty,
  });

  factory PantryItem.fromMap(String id, Map<String, dynamic> m) {
    UnitKind u(dynamic v) {
      switch ('$v') {
        case 'g':
          return UnitKind.g;
        case 'ml':
          return UnitKind.ml;
        default:
          return UnitKind.unit;
      }
    }

    return PantryItem(
      id: id,
      foodId: m['foodId'],
      name: m['name'] ?? '',
      qty: (m['qty'] as num?)?.toDouble() ?? 0,
      unit: u(m['unit']),
      minQty: (m['minQty'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    if (foodId != null) 'foodId': foodId,
    'name': name,
    'qty': qty,
    'unit': unit.name,
    if (minQty != null) 'minQty': minQty,
  };
}

class PlannedMeal {
  final String recipeId;
  final String? note;

  const PlannedMeal({required this.recipeId, this.note});

  factory PlannedMeal.fromMap(Map<String, dynamic> m) {
    return PlannedMeal(recipeId: m['recipeId'] ?? '', note: m['note']);
  }

  Map<String, dynamic> toMap() => {
    'recipeId': recipeId,
    if (note != null) 'note': note,
  };
}

class DayMenu {
  final List<PlannedMeal> breakfast;
  final List<PlannedMeal> lunch;
  final List<PlannedMeal> dinner;
  final List<PlannedMeal> snack;

  const DayMenu({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
  });

  factory DayMenu.fromMap(Map<String, dynamic> m) {
    List<PlannedMeal> list(String key) {
      return ((m[key] as List?) ?? const [])
          .map((e) => PlannedMeal.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return DayMenu(
      breakfast: list('breakfast'),
      lunch: list('lunch'),
      dinner: list('dinner'),
      snack: list('snack'),
    );
  }

  Map<String, dynamic> toMap() => {
    'breakfast': breakfast.map((e) => e.toMap()).toList(),
    'lunch': lunch.map((e) => e.toMap()).toList(),
    'dinner': dinner.map((e) => e.toMap()).toList(),
    'snack': snack.map((e) => e.toMap()).toList(),
  };

  DayMenu copyWith({
    List<PlannedMeal>? breakfast,
    List<PlannedMeal>? lunch,
    List<PlannedMeal>? dinner,
    List<PlannedMeal>? snack,
  }) {
    return DayMenu(
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      snack: snack ?? this.snack,
    );
  }
}

extension FavoriteX on Favorite {
  Favorite copyWith({String? alias}) {
    return Favorite(
      id: id,
      type: type,
      refId: refId,
      defaultQty: defaultQty,
      defaultUnit: defaultUnit,
      alias: alias ?? this.alias,
    );
  }

  String get entityId => refId;
}

extension WeekPlannerX on WeekPlanner {
  String get name => id.startsWith('planner_') ? id.substring(8) : id;

  double? get customMultiplier => null;

  Map<int, DayMenu> get dayMap {
    return {};
  }

  WeekPlanner copyWith({
    String? name,
    double? customMultiplier,
    Map<int, DayMenu>? dayMap,
  }) {
    return WeekPlanner(id: id, scope: scope, days: days);
  }
}

extension DailyIntakeDocX on DailyIntakeDoc {
  DailyIntakeDoc copyWith({
    int? waterMl,
    List<IntakeEntry>? entries,
    Map<String, double>? totals,
    Map<String, double?>? targets,
  }) {
    return DailyIntakeDoc(
      id: id,
      entries: entries ?? this.entries,
      waterMl: waterMl ?? this.waterMl,
      totals: totals ?? this.totals,
      targets: targets ?? this.targets,
    );
  }
}
