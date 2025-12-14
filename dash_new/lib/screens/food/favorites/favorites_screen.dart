import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/global_ui_components.dart';
import '../services/food_service_facade.dart';
import '../models/food_models.dart';

/// ⭐ FAVORITES SCREEN
/// Gestión completa de favoritos con grid visual
class FavoritesScreen extends StatefulWidget {
  final FoodServiceFacade svc;
  const FavoritesScreen({super.key, required this.svc});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  FavoriteType? _filterType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⭐ Favoritos'),
        actions: [
          // Filtros
          PopupMenuButton<FavoriteType?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar',
            onSelected: (v) => setState(() => _filterType = v),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: null,
                child: Text('Todos'),
              ),
              const PopupMenuItem(
                value: FavoriteType.food,
                child: Row(
                  children: [
                    Icon(Icons.restaurant, size: 20),
                    SizedBox(width: 8),
                    Text('Alimentos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: FavoriteType.recipe,
                child: Row(
                  children: [
                    Icon(Icons.menu_book, size: 20),
                    SizedBox(width: 8),
                    Text('Recetas'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Favorite>>(
        stream: widget.svc.catalog.streamFavorites(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allFavs = snap.data ?? [];
          final filteredFavs = _filterType == null
              ? allFavs
              : allFavs.where((f) => f.type == _filterType).toList();

          if (filteredFavs.isEmpty) {
            return FocusEmptyState(
              icon: Icons.star_border,
              message: _filterType == null
                  ? 'Sin favoritos aún'
                  : 'Sin favoritos de este tipo',
              subtitle: _filterType == null
                  ? 'Marca alimentos o recetas como favoritos para acceso rápido'
                  : 'Cambia el filtro para ver otros favoritos',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(FocusSpacing.lg),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: FocusSpacing.lg,
              crossAxisSpacing: FocusSpacing.lg,
              childAspectRatio: 0.85,
            ),
            itemCount: filteredFavs.length,
            itemBuilder: (_, i) {
              final fav = filteredFavs[i];
              return _buildFavoriteCard(context, fav, i);
            },
          );
        },
      ),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, Favorite fav, int index) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
      ),
      child: InkWell(
        onTap: () => _showDetailSheet(context, fav),
        onLongPress: () => _showEditSheet(context, fav),
        borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(FocusSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono principal
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: fav.type == FavoriteType.food
                        ? [FocusColors.food, FocusColors.warning]
                        : [Colors.purple, Colors.deepPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  fav.type == FavoriteType.food
                      ? Icons.restaurant
                      : Icons.menu_book,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: FocusSpacing.md),

              // Alias o nombre
              Text(
                fav.alias ?? 'Favorito',
                style: FocusTypography.heading4(context),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: FocusSpacing.sm),

              // Badge de tipo
              FocusBadge(
                label: fav.type == FavoriteType.food ? 'Alimento' : 'Receta',
                color: fav.type == FavoriteType.food
                    ? FocusColors.food
                    : Colors.purple,
              ),

              const Spacer(),

              // Botón de acción rápida
              ElevatedButton.icon(
                onPressed: () => _addToToday(context, fav),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Añadir'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 50).ms)
        .scale(delay: (index * 50).ms);
  }

  Future<void> _showDetailSheet(BuildContext context, Favorite fav) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FavoriteDetailSheet(svc: widget.svc, fav: fav),
    );
  }

  Future<void> _showEditSheet(BuildContext context, Favorite fav) async {
    final aliasCtrl = TextEditingController(text: fav.alias);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: FocusSpacing.lg,
            right: FocusSpacing.lg,
            top: FocusSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + FocusSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar Favorito',
                style: FocusTypography.heading2(context),
              ),
              const SizedBox(height: FocusSpacing.lg),

              TextField(
                controller: aliasCtrl,
                decoration: InputDecoration(
                  labelText: 'Alias (opcional)',
                  hintText: 'Nombre personalizado',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                  ),
                ),
              ),

              const SizedBox(height: FocusSpacing.lg),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Eliminar
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final confirm = await _confirmDelete(context);
                      if (confirm == true) {
                        await widget.svc.catalog.removeFavorite(fav.id);
                      }
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),

                  // Guardar
                  ElevatedButton(
                    onPressed: () async {
                      final updated = fav.copyWith(
                        alias: aliasCtrl.text.isEmpty ? null : aliasCtrl.text,
                      );
                      await widget.svc.catalog.saveFavorite(updated);
                      Navigator.pop(context);
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Favorito'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este favorito?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _addToToday(BuildContext context, Favorite fav) async {
    final todayId = DateTime.now().toIso8601String().substring(0, 10);

    // Mostrar sheet de cantidad/porción
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddToTodaySheet(
        svc: widget.svc,
        fav: fav,
        todayId: todayId,
      ),
    );
  }
}

/// Sheet de detalle de favorito
class _FavoriteDetailSheet extends StatelessWidget {
  final FoodServiceFacade svc;
  final Favorite fav;

  const _FavoriteDetailSheet({required this.svc, required this.fav});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(FocusSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  fav.type == FavoriteType.food
                      ? Icons.restaurant
                      : Icons.menu_book,
                  color: fav.type == FavoriteType.food
                      ? FocusColors.food
                      : Colors.purple,
                  size: 32,
                ),
                const SizedBox(width: FocusSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fav.alias ?? 'Favorito',
                        style: FocusTypography.heading2(context),
                      ),
                      Text(
                        fav.type == FavoriteType.food
                            ? 'Alimento'
                            : 'Receta',
                        style: FocusTypography.caption(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: FocusSpacing.lg),

            // Cargar info real del alimento/receta
            if (fav.type == FavoriteType.food)
              StreamBuilder<Food?>(
                stream: svc.catalog.streamFoodById(fav.entityId),
                builder: (context, snap) {
                  final food = snap.data;
                  if (food == null) {
                    return const Text('No encontrado');
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: FocusTypography.heading4(context),
                      ),
                      const SizedBox(height: FocusSpacing.md),
                      _buildMacroChip('${food.kcal100} kcal', FocusColors.food),
                      _buildMacroChip('${food.protein100}g proteínas', Colors.red),
                      _buildMacroChip('${food.carbs100}g carbos', Colors.blue),
                      _buildMacroChip('${food.fat100}g grasas', Colors.green),
                    ],
                  );
                },
              )
            else
              StreamBuilder<Recipe?>(
                stream: svc.catalog.streamRecipeById(fav.entityId),
                builder: (context, snap) {
                  final recipe = snap.data;
                  if (recipe == null) {
                    return const Text('No encontrada');
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: FocusTypography.heading4(context),
                      ),
                      const SizedBox(height: FocusSpacing.md),
                      if (recipe.description != null) ...[
                        Text(
                          recipe.description!,
                          style: FocusTypography.body(context),
                        ),
                        const SizedBox(height: FocusSpacing.md),
                      ],
                      FutureBuilder<Map<String, double>>(
                        future: svc.catalog.calculateRecipeMacros(recipe),
                        builder: (context, macroSnap) {
                          final macros = macroSnap.data ?? {};
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildMacroChip(
                                '${macros['kcal']?.toStringAsFixed(0) ?? '0'} kcal',
                                FocusColors.food,
                              ),
                              _buildMacroChip(
                                '${macros['protein']?.toStringAsFixed(1) ?? '0'}g proteínas',
                                Colors.red,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
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
    );
  }

  Widget _buildMacroChip(String label, Color color) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}

/// Sheet para añadir favorito al diario de hoy
class _AddToTodaySheet extends StatefulWidget {
  final FoodServiceFacade svc;
  final Favorite fav;
  final String todayId;

  const _AddToTodaySheet({
    required this.svc,
    required this.fav,
    required this.todayId,
  });

  @override
  State<_AddToTodaySheet> createState() => _AddToTodaySheetState();
}

class _AddToTodaySheetState extends State<_AddToTodaySheet> {
  final _qtyCtrl = TextEditingController(text: '100');
  MealTag _selectedMeal = MealTag.breakfast;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: FocusSpacing.lg,
          right: FocusSpacing.lg,
          top: FocusSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + FocusSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Añadir a Hoy',
              style: FocusTypography.heading2(context),
            ),
            const SizedBox(height: FocusSpacing.lg),

            // Comida
            Text('Comida', style: FocusTypography.label(context)),
            const SizedBox(height: FocusSpacing.sm),
            DropdownButtonFormField<MealTag>(
              value: _selectedMeal,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                ),
              ),
              items: MealTag.values.map((m) {
                return DropdownMenuItem(
                  value: m,
                  child: Text(_mealName(m)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedMeal = v!),
            ),

            const SizedBox(height: FocusSpacing.md),

            // Cantidad
            Text('Cantidad (g)', style: FocusTypography.label(context)),
            const SizedBox(height: FocusSpacing.sm),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '100',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                ),
              ),
            ),

            const SizedBox(height: FocusSpacing.lg),

            ElevatedButton(
              onPressed: () async {
                final qty = double.tryParse(_qtyCtrl.text) ?? 100;
                
                if (widget.fav.type == FavoriteType.food) {
                  await widget.svc.diary.addEntry(
                    widget.todayId,
                    IntakeEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      type: EntryType.food,
                      foodId: widget.fav.entityId,
                      quantity: qty,
                      meal: _selectedMeal,
                    ),
                  );
                } else {
                  await widget.svc.diary.addEntry(
                    widget.todayId,
                    IntakeEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      type: EntryType.recipe,
                      recipeId: widget.fav.entityId,
                      quantity: qty,
                      meal: _selectedMeal,
                    ),
                  );
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Añadido al diario')),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Añadir'),
            ),
          ],
        ),
      ),
    );
  }

  String _mealName(MealTag m) {
    switch (m) {
      case MealTag.breakfast:
        return '🌅 Desayuno';
      case MealTag.lunch:
        return '🌞 Comida';
      case MealTag.dinner:
        return '🌙 Cena';
      case MealTag.snack:
        return '🍎 Snack';
    }
  }
}
