import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/global_ui_theme.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';
import 'recipe_edit_screen_v2.dart';

class RecipesListScreenV2 extends StatefulWidget {
  final FoodFirestoreService svc;
  const RecipesListScreenV2({super.key, required this.svc});

  @override
  State<RecipesListScreenV2> createState() => _RecipesListScreenV2State();
}

class _RecipesListScreenV2State extends State<RecipesListScreenV2> {
  String _searchQuery = '';
  bool _showGridView = true;
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
            icon: Icon(_showGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _showGridView = !_showGridView),
            tooltip: _showGridView ? 'Vista de lista' : 'Vista de cuadrícula',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RecipeEditScreenV2(svc: widget.svc)),
                ),
            tooltip: 'Añadir receta',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.grey100,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ModernTextField(
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
                  list = list.where((r) => r.name.toLowerCase().contains(ql)).toList();
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
                                builder: (_) => RecipeEditScreenV2(svc: widget.svc),
                              ),
                            )
                            : null,
                  );
                }

                return _showGridView ? _buildGridView(list) : _buildListView(list);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<Recipe> recipes) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return _RecipeGridCard(
          recipe: recipe,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeEditScreenV2(svc: widget.svc, initial: recipe),
                ),
              ),
        ).animate().fadeIn(delay: (100 + index * 50).ms).scale(duration: 200.ms);
      },
    );
  }

  Widget _buildListView(List<Recipe> recipes) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return _RecipeListCard(
          recipe: recipe,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeEditScreenV2(svc: widget.svc, initial: recipe),
                ),
              ),
        ).animate().fadeIn(delay: (100 + index * 50).ms).slideX(begin: -0.2, duration: 300.ms);
      },
    );
  }
}

class _RecipeGridCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipeGridCard({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasNutrition = recipe.kcal != null;

    return Card(
      elevation: AppSpacing.elevationMd,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.menu_book,
                      size: 48,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  if (hasNutrition)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: ModernBadge(
                        label: 'AUTO',
                        color: AppColors.success,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: AppTypography.heading4(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('${recipe.servings} raciones', style: AppTypography.caption(context)),
                    const Spacer(),
                    if (hasNutrition) ...[
                      Row(
                        children: [
                          Icon(Icons.local_fire_department, size: 16, color: Colors.purple),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.kcal!.toStringAsFixed(0)} kcal',
                            style: AppTypography.caption(context, color: Colors.purple),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('totales', style: AppTypography.caption(context)),
                    ] else ...[
                      ModernBadge(label: 'Sin macros', color: AppColors.grey500),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeListCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipeListCard({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasNutrition = recipe.kcal != null;

    return Card(
      elevation: AppSpacing.elevationSm,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.menu_book,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 32,
                ),
              ),

              const SizedBox(width: AppSpacing.lg),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(recipe.name, style: AppTypography.heading4(context))),
                        if (hasNutrition) ModernBadge(label: 'MACROS', color: AppColors.success),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${recipe.servings} raciones', style: AppTypography.body(context)),
                    if (recipe.description != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        recipe.description!,
                        style: AppTypography.caption(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (hasNutrition) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(Icons.local_fire_department, size: 16, color: Colors.purple),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.kcal!.toStringAsFixed(0)} kcal totales',
                            style: AppTypography.caption(context, color: Colors.purple),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}
