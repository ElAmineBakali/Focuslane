import 'package:flutter/material.dart';
import 'package:focuslane/design/ui/tokens/focuslane_tokens.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:focuslane/design/ui/components/focus_empty_state.dart';
import 'package:focuslane/screens/food/models/food_models.dart';
import 'package:focuslane/screens/food/services/food_firestore_service.dart';
import 'shopping_list_detail_screen.dart';
import 'package:focuslane/screens/food/widgets/food_compact_widgets.dart';

class ShoppingListsScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  final bool embedded;
  const ShoppingListsScreen({
    super.key,
    required this.svc,
    this.embedded = false,
  });

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          widget.embedded
              ? null
              : FoodCompactAppBar(
                title: 'Listas de compra',
                subtitle: 'Listas activas',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    tooltip: 'Nueva lista',
                    onPressed: _createNewList,
                  ),
                ],
              ),
      body: _buildActiveListsTab(),
      floatingActionButton: Theme(
        data: Theme.of(context).copyWith(
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            extendedSizeConstraints: BoxConstraints.tightFor(height: 44),
          ),
        ),
        child: FloatingActionButton.extended(
          heroTag: 'shoppingListsFab',
          onPressed: _createNewList,
          icon: const Icon(Icons.add),
          label: const Text('Nueva lista'),
          backgroundColor: FocuslaneUI.accent(context),
        ),
      ),
    );
  }

  Widget _buildActiveListsTab() {
    return StreamBuilder<List<ShoppingList>>(
      stream: widget.svc.streamShoppingLists(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final lists = snapshot.data!;
        final activeLists = lists.where((list) => !list.isCompleted).toList();

        if (activeLists.isEmpty) {
          return FocusEmptyState(
            icon: Icons.shopping_cart_outlined,
            message: 'Sin listas de compra',
            subtitle: 'Crea tu primera lista para comenzar',
            actionLabel: 'Crear Lista',
            onAction: _createNewList,
          );
        }

        return _buildListView(activeLists);
      },
    );
  }

  Widget _buildListView(List<ShoppingList> lists) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        return _ShoppingListTile(
              list: list,
              onTap: () => _openListDetail(list),
              onDelete: () => _deleteList(list),
              onToggleDefault: () => _toggleDefault(list),
            )
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 30))
            .slideX(begin: -0.2);
      },
    );
  }

  Future<void> _createNewList() async {
    final nameController = TextEditingController();
    ShoppingScope scope = ShoppingScope.custom;
    bool makeDefault = false;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              final colorScheme = Theme.of(context).colorScheme;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusXl),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? colorScheme.onSurface.withOpacity(0.3)
                                  : FocuslaneUI.borderColor(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Nueva Lista de Compra',
                      style: AppTypography.heading3(context),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FoodCompactTextField(
                      controller: nameController,
                      label: 'Nombre de la lista',
                      hint: 'Ej: Compra semanal, Supermercado...',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              isDark
                                  ? colorScheme.outline
                                  : FocuslaneUI.borderColor(context),
                          width: FocuslaneUI.borderW,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        color: colorScheme.surfaceContainerHighest,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tipo de lista',
                            style: AppTypography.label(context),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              ChoiceChip(
                                label: const Text('Semanal'),
                                selected: scope == ShoppingScope.weekly,
                                onSelected:
                                    (v) => setModalState(
                                      () => scope = ShoppingScope.weekly,
                                    ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              ChoiceChip(
                                label: const Text('Quincenal'),
                                selected: scope == ShoppingScope.biweekly,
                                onSelected:
                                    (v) => setModalState(
                                      () => scope = ShoppingScope.biweekly,
                                    ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              ChoiceChip(
                                label: const Text('Mensual'),
                                selected: scope == ShoppingScope.monthly,
                                onSelected:
                                    (v) => setModalState(
                                      () => scope = ShoppingScope.monthly,
                                    ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              ChoiceChip(
                                label: const Text('Personalizada'),
                                selected: scope == ShoppingScope.custom,
                                onSelected:
                                    (v) => setModalState(
                                      () => scope = ShoppingScope.custom,
                                    ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CheckboxListTile(
                      value: makeDefault,
                      onChanged:
                          (v) => setModalState(() => makeDefault = v ?? false),
                      title: const Text('Marcar como predeterminada'),
                      contentPadding: EdgeInsets.zero,
                      activeColor: colorScheme.primary,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: FilledButton(
                            onPressed:
                                () => Navigator.pop(context, {
                                  'name': nameController.text,
                                  'scope': scope,
                                  'makeDefault': makeDefault,
                                }),
                            style: FilledButton.styleFrom(
                              backgroundColor: FocuslaneUI.accent(context),
                            ),
                            child: const Text('Crear'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
    );

    if (result != null) {
      final name = result['name'] as String;
      if (name.isEmpty) return;

      final listId = await widget.svc.createShoppingList(
        name,
        scope: result['scope'] as ShoppingScope,
        isDefault: result['makeDefault'] as bool,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) =>
                    ShoppingListDetailScreen(svc: widget.svc, listId: listId),
          ),
        );
      }
    }
  }

  void _openListDetail(ShoppingList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ShoppingListDetailScreen(svc: widget.svc, listId: list.id),
      ),
    );
  }

  Future<void> _deleteList(ShoppingList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar lista'),
            content: Text('¿Seguro que quieres eliminar "${list.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await widget.svc.deleteShoppingList(list.id);
      if (mounted) {
        FoodFeedback.showSuccess(context, '"${list.name}" eliminada');
      }
    }
  }

  Future<void> _toggleDefault(ShoppingList list) async {
    await widget.svc.setDefaultList(list.id);
    if (mounted) {
      FoodFeedback.showSuccess(
        context,
        '"${list.name}" marcada como predeterminada',
      );
    }
  }
}

class _ShoppingListTile extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleDefault;

  const _ShoppingListTile({
    required this.list,
    required this.onTap,
    required this.onDelete,
    required this.onToggleDefault,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = list.items.fold<double>(
      0,
      (sum, item) => sum + (item.total ?? 0),
    );
    final purchased = list.items.where((i) => i.checked).length;
    final subtitle =
        '${list.items.length} productos - ${_getScopeLabel(list.scope)} - $purchased/${list.items.length} comprados${total > 0 ? ' - €${total.toStringAsFixed(2)}' : ''}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FoodCompactTile(
        height: 46,
        onTap: onTap,
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            list.isDefault ? Icons.star : Icons.shopping_cart,
            color: colorScheme.onPrimaryContainer,
            size: 16,
          ),
        ),
        title: list.name,
        subtitle: subtitle,
        trailing: PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          onSelected: (value) {
            if (value == 'default') onToggleDefault();
            if (value == 'delete') onDelete();
          },
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'default',
                  child: Row(
                    children: [
                      Icon(
                        list.isDefault ? Icons.star_border : Icons.star,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        list.isDefault
                            ? 'Quitar predeterminada'
                            : 'Predeterminada',
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: colorScheme.error),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Eliminar',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
        ),
      ),
    );
  }

  String _getScopeLabel(ShoppingScope scope) {
    switch (scope) {
      case ShoppingScope.weekly:
        return 'Semanal';
      case ShoppingScope.biweekly:
        return 'Quincenal';
      case ShoppingScope.monthly:
        return 'Mensual';
      case ShoppingScope.custom:
        return 'Personalizada';
    }
  }
}
