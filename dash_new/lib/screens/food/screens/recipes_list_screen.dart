import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design/theme/global_ui_theme.dart';
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
      appBar: FoodCompactAppBar(
        title: 'Recetas',
        subtitle: 'CatÃ¡logo',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeEditScreen(svc: widget.svc),
                  ),
                ),
            tooltip: 'AÃ±adir receta',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(AppSpacing.sm),
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
                            : 'No hay recetas en tu catÃ¡logo',
                    subtitle:
                        _searchQuery.isNotEmpty
                            ? 'Intenta con otro tÃ©rmino de bÃºsqueda'
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // En PC: 6 columnas, tablet: 4, mÃ³vil: 2
        final crossAxisCount = constraints.maxWidth >= 1200
            ? 6
            : constraints.maxWidth >= 900
                ? 5
                : constraints.maxWidth >= 600
                    ? 4
                    : 2;
        
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return _RecipeGridCard(
              recipe: recipe,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeEditScreen(
                    svc: widget.svc,
                    initial: recipe,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: (50 + index * 30).ms).scale(begin: const Offset(0.95, 0.95), duration: 200.ms);
          },
        );
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
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final hasNutrition = recipe.kcal != null;

    return FoodCompactCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
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
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: colorScheme.outline,
              ),
            ],
          ),
          const Spacer(),
          Text(
            recipe.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${recipe.servings} raciones',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (hasNutrition)
            Text(
              '${recipe.kcal!.toStringAsFixed(0)} kcal',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

