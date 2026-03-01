import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design/theme/global_ui_theme.dart';
import '../widgets/food_compact_widgets.dart';
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
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FoodCompactAppBar(
        title: 'Alimentos',
        subtitle: 'CatÃ¡logo',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => _showAddFoodSheet(context),
            tooltip: 'AÃ±adir alimento',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: [
                FoodCompactTextField(
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
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: ModernChip(
                        label: 'SÃ³lo suplementos',
                        icon: _suppsOnly ? Icons.check : Icons.filter_list,
                        color:
                            _suppsOnly
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                        onTap: () => setState(() => _suppsOnly = !_suppsOnly),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ModernChip(
                      label: 'Todos',
                      icon: Icons.restaurant,
                      color:
                          !_suppsOnly
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
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
                            : 'No hay alimentos en tu catÃ¡logo',
                    subtitle:
                        _searchQuery.isNotEmpty
                            ? 'Intenta con otro tÃ©rmino de bÃºsqueda'
                            : 'AÃ±ade tu primer alimento para comenzar',
                    actionLabel:
                        _searchQuery.isEmpty ? 'AÃ±adir alimento' : null,
                    onAction:
                        _searchQuery.isEmpty
                            ? () => _showAddFoodSheet(context)
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

  Widget _buildListView(List<Food> foods) {
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
          itemCount: foods.length,
          itemBuilder: (context, index) {
            final food = foods[index];
            return _FoodGridCard(
              food: food,
              onTap: () => _showEditFoodSheet(context, food),
              onToggleFavorite: () => _toggleFavorite(food),
            ).animate().fadeIn(delay: (50 + index * 30).ms).scale(begin: const Offset(0.95, 0.95), duration: 200.ms);
          },
        );
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
        FoodFeedback.showInfo(context, '${food.name} eliminado de favoritos');
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
        FoodFeedback.showSuccess(context, '${food.name} aÃ±adido a favoritos');
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

        return _buildCard(context, isFavorite);
      },
    );
  }

  Widget _buildCard(BuildContext context, bool isFavorite) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return FoodCompactCard(
      onTap: widget.onTap,
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
                  widget.food.isSupplement ? Icons.medication : Icons.restaurant,
                  color: colorScheme.onPrimaryContainer,
                  size: 18,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onToggleFavorite,
                child: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  size: 20,
                  color: isFavorite ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            widget.food.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.food.kcal.toStringAsFixed(0)} kcal',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.food.brand != null)
            Text(
              widget.food.brand!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
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

        return _buildCard(context, isFavorite);
      },
    );
  }

  Widget _buildCard(BuildContext context, bool isFavorite) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle =
        '${widget.food.kcal.toStringAsFixed(0)} kcal â€¢ ${widget.food.unitSize.toStringAsFixed(0)}${widget.food.perUnit.name}${widget.food.brand != null ? ' â€¢ ${widget.food.brand!}' : ''}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FoodCompactTile(
        height: 46,
        onTap: widget.onTap,
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.food.isSupplement ? Icons.medication : Icons.restaurant,
            color: colorScheme.onPrimaryContainer,
            size: 16,
          ),
        ),
        title: widget.food.name,
        subtitle: subtitle,
        trailing: IconButton(
          icon: Icon(isFavorite ? Icons.star : Icons.star_border),
          color:
              isFavorite
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
          onPressed: widget.onToggleFavorite,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        ),
      ),
    );
  }
}

