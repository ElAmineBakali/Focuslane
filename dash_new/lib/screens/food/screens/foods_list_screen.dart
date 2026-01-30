import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/global_ui_theme.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';
import 'food_edit_sheet.dart';

class FoodsListScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  const FoodsListScreen({super.key, required this.svc});

  @override
  State<FoodsListScreen> createState() => _FoodsListScreenState();
}

class _FoodsListScreenState extends State<FoodsListScreen> {
  String _searchQuery = '';
  bool _suppsOnly = false;
  bool _showGridView = true;
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernGradientAppBar(
        title: 'Catálogo de Alimentos',
        icon: Icons.restaurant,
        useThemeColors: true,
        actions: [
          IconButton(
            icon: Icon(_showGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _showGridView = !_showGridView),
            tooltip: _showGridView ? 'Vista de lista' : 'Vista de cuadrícula',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddFoodSheet(context),
            tooltip: 'Añadir alimento',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.grey100,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                ModernTextField(
                  label: 'Buscar alimentos',
                  hint: 'Nombre, marca, etiquetas...',
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
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: ModernChip(
                        label: 'Sólo suplementos',
                        icon: _suppsOnly ? Icons.check : Icons.filter_list,
                        color: _suppsOnly ? AppColors.gym : AppColors.grey600,
                        onTap: () => setState(() => _suppsOnly = !_suppsOnly),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ModernChip(
                      label: 'Todos',
                      icon: Icons.restaurant,
                      color: !_suppsOnly ? AppColors.food : AppColors.grey600,
                      onTap: () => setState(() => _suppsOnly = false),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().slideY(begin: -0.2, duration: 300.ms),

          Expanded(
            child: StreamBuilder<List<Food>>(
              stream: widget.svc.streamFoods(
                query: _searchQuery,
                supplementsOnly: _suppsOnly,
              ),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final list = snap.data!;

                if (list.isEmpty) {
                  return ModernEmptyState(
                    icon: Icons.restaurant_outlined,
                    message:
                        _searchQuery.isNotEmpty
                            ? 'No se encontraron alimentos'
                            : 'No hay alimentos en tu catálogo',
                    subtitle:
                        _searchQuery.isNotEmpty
                            ? 'Intenta con otro término de búsqueda'
                            : 'Añade tu primer alimento para comenzar',
                    actionLabel:
                        _searchQuery.isEmpty ? 'Añadir alimento' : null,
                    onAction:
                        _searchQuery.isEmpty
                            ? () => _showAddFoodSheet(context)
                            : null,
                  );
                }

                return _showGridView
                    ? _buildGridView(list)
                    : _buildListView(list);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<Food> foods) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: foods.length,
      itemBuilder: (context, index) {
        final food = foods[index];
        return _FoodGridCard(
              food: food,
              onTap: () => _showEditFoodSheet(context, food),
              onToggleFavorite: () => _toggleFavorite(food),
            )
            .animate()
            .fadeIn(delay: (100 + index * 50).ms)
            .scale(duration: 200.ms);
      },
    );
  }

  Widget _buildListView(List<Food> foods) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: foods.length,
      itemBuilder: (context, index) {
        final food = foods[index];
        return _FoodListCard(
              food: food,
              onTap: () => _showEditFoodSheet(context, food),
              onToggleFavorite: () => _toggleFavorite(food),
            )
            .animate()
            .fadeIn(delay: (100 + index * 50).ms)
            .slideX(begin: -0.2, duration: 300.ms);
      },
    );
  }

  void _showAddFoodSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FoodEditSheet(svc: widget.svc),
    );
  }

  void _showEditFoodSheet(BuildContext context, Food food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FoodEditSheet(svc: widget.svc, food: food),
    );
  }

  Future<void> _toggleFavorite(Food food) async {
    final favs = await widget.svc.streamFavorites().first;
    final existing =
        favs
            .where((f) => f.type == FavoriteType.food && f.refId == food.id)
            .toList();

    if (existing.isNotEmpty) {
      for (final fav in existing) {
        await widget.svc.removeFavorite(fav.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.star_border,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Text('${food.name} eliminado de favoritos'),
              ],
            ),
            backgroundColor: AppColors.grey700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        );
      }
    } else {
      await widget.svc.addFavorite(
        Favorite(
          id: '',
          type: FavoriteType.food,
          refId: food.id,
          alias: food.name,
          defaultQty: food.unitSize,
          defaultUnit: food.perUnit,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text('${food.name} añadido a favoritos'),
              ],
            ),
            backgroundColor: AppColors.grey700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        );
      }
    }
  }
}

class _FoodGridCard extends StatefulWidget {
  final Food food;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _FoodGridCard({
    required this.food,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  State<_FoodGridCard> createState() => _FoodGridCardState();
}

class _FoodGridCardState extends State<_FoodGridCard> {
  @override
  Widget build(BuildContext context) {
    final color = widget.food.color ?? AppColors.food;

    return StreamBuilder<List<Favorite>>(
      stream:
          context
              .findAncestorStateOfType<_FoodsListScreenState>()
              ?.widget
              .svc
              .streamFavorites(),
      builder: (context, favSnap) {
        final isFavorite =
            favSnap.data?.any(
              (f) => f.type == FavoriteType.food && f.refId == widget.food.id,
            ) ??
            false;

        return _buildCard(context, color, isFavorite);
      },
    );
  }

  Widget _buildCard(BuildContext context, Color color, bool isFavorite) {
    return Card(
      elevation: AppSpacing.elevationMd,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
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
                      widget.food.isSupplement
                          ? Icons.medication
                          : Icons.restaurant,
                      size: 48,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: IconButton(
                      icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                      color:
                          isFavorite
                              ? Colors.amber
                              : Theme.of(context).colorScheme.onPrimary,
                      onPressed: widget.onToggleFavorite,
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
                      widget.food.name,
                      style: AppTypography.heading4(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.food.brand != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.food.brand!,
                        style: AppTypography.caption(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.food.kcal.toStringAsFixed(0)} kcal',
                          style: AppTypography.caption(context, color: color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'por ${widget.food.unitSize.toStringAsFixed(0)}${widget.food.perUnit.name}',
                      style: AppTypography.caption(context),
                    ),
                    if (widget.food.isSupplement)
                      ModernBadge(label: 'SUPLEMENTO', color: AppColors.gym),
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

class _FoodListCard extends StatefulWidget {
  final Food food;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _FoodListCard({
    required this.food,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  State<_FoodListCard> createState() => _FoodListCardState();
}

class _FoodListCardState extends State<_FoodListCard> {
  @override
  Widget build(BuildContext context) {
    final color = widget.food.color ?? AppColors.food;

    return StreamBuilder<List<Favorite>>(
      stream:
          context
              .findAncestorStateOfType<_FoodsListScreenState>()
              ?.widget
              .svc
              .streamFavorites(),
      builder: (context, favSnap) {
        final isFavorite =
            favSnap.data?.any(
              (f) => f.type == FavoriteType.food && f.refId == widget.food.id,
            ) ??
            false;

        return _buildCard(context, color, isFavorite);
      },
    );
  }

  Widget _buildCard(BuildContext context, Color color, bool isFavorite) {
    return Card(
      elevation: AppSpacing.elevationSm,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  widget.food.isSupplement
                      ? Icons.medication
                      : Icons.restaurant,
                  color: color,
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
                        Expanded(
                          child: Text(
                            widget.food.name,
                            style: AppTypography.heading4(context),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                          ),
                          color: isFavorite ? Colors.amber : color,
                          onPressed: widget.onToggleFavorite,
                        ),
                      ],
                    ),
                    if (widget.food.brand != null) ...[
                      Text(
                        widget.food.brand!,
                        style: AppTypography.caption(context),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.food.kcal.toStringAsFixed(0)} kcal',
                          style: AppTypography.body(context, color: color),
                        ),
                        Text(
                          ' por ${widget.food.unitSize.toStringAsFixed(0)}${widget.food.perUnit.name}',
                          style: AppTypography.caption(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        if (widget.food.isSupplement)
                          ModernBadge(
                            label: 'SUPLEMENTO',
                            color: AppColors.gym,
                          ),
                        _MacroBadge(
                          label: 'P',
                          value: widget.food.protein,
                          color: AppColors.error,
                        ),
                        _MacroBadge(
                          label: 'C',
                          value: widget.food.carbs,
                          color: AppColors.warning,
                        ),
                        _MacroBadge(
                          label: 'G',
                          value: widget.food.fat,
                          color: AppColors.info,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroBadge extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label${value.toStringAsFixed(0)}g',
        style: AppTypography.caption(
          context,
          color: color,
        ).copyWith(fontSize: 11),
      ),
    );
  }
}
