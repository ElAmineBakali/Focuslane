import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/global_ui_theme.dart';
import '../widgets/food_compact_widgets.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';
import 'recipe_edit_screen.dart';

class RecipesListScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  const RecipesListScreen({super.key, required this.svc});

  @override
  State<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends State<RecipesListScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernGradientAppBar(
        title: 'Catálogo de Recetas',
        icon: Icons.menu_book,
        useThemeColors: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeEditScreen(svc: widget.svc),
                  ),
                ),
            tooltip: 'Añadir receta',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FoodCompactTextField(
              label: 'Buscar recetas',
              hint: 'Nombre, ingredientes...',
              controller: _searchController,
              prefixIcon: Icons.search,
              onChanged: (v) => setState(() => _searchQuery = v),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                      : null,
            ),
          ).animate().slideY(begin: -0.2, duration: 300.ms),

          Expanded(
            child: StreamBuilder<List<Recipe>>(
              stream: widget.svc.streamRecipes(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var list = snap.data!;
                if (_searchQuery.isNotEmpty) {
                  final ql = _searchQuery.toLowerCase();
                  list =
                      list
                          .where((r) => r.name.toLowerCase().contains(ql))
                          .toList();
                }

                if (list.isEmpty) {
                  return ModernEmptyState(
                    icon: Icons.menu_book_outlined,
                    message:
                        _searchQuery.isNotEmpty
                            ? 'No se encontraron recetas'
                            : 'No hay recetas en tu catálogo',
                    subtitle:
                        _searchQuery.isNotEmpty
                            ? 'Intenta con otro término de búsqueda'
                            : 'Crea tu primera receta para comenzar',
                    actionLabel: _searchQuery.isEmpty ? 'Crear receta' : null,
                    onAction:
                        _searchQuery.isEmpty
                            ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => RecipeEditScreen(svc: widget.svc),
                              ),
                            )
                            : null,
                  );
                }

                return _buildListView(list);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<Recipe> recipes) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return _RecipeListCard(
              recipe: recipe,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => RecipeEditScreen(
                            svc: widget.svc,
                            initial: recipe,
                          ),
                    ),
                  ),
            )
            .animate()
            .fadeIn(delay: (100 + index * 50).ms)
            .slideX(begin: -0.2, duration: 300.ms);
      },
    );
  }
}

class _RecipeListCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipeListCard({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasNutrition = recipe.kcal != null;
    final subtitle =
        '${recipe.servings} raciones${hasNutrition ? ' • ${recipe.kcal!.toStringAsFixed(0)} kcal' : ''}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FoodCompactTile(
        height: 52,
        onTap: onTap,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.menu_book,
            color: colorScheme.onPrimaryContainer,
            size: 18,
          ),
        ),
        title: recipe.name,
        subtitle: subtitle,
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: colorScheme.outline,
        ),
      ),
    );
  }
}
