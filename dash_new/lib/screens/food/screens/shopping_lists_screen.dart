import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme/global_ui_theme.dart';
import '../widgets/food_compact_widgets.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';
import 'shopping_list_detail_screen.dart';

class ShoppingListsScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  const ShoppingListsScreen({super.key, required this.svc});

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listas de Compra'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva lista',
            onPressed: _createNewList,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            color: colorScheme.surfaceContainerHighest,
            child: TabBar(
              controller: _tabController,
              indicatorColor: colorScheme.primary,
              labelColor: colorScheme.onSurface,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              tabs: const [
                Tab(icon: Icon(Icons.shopping_cart), text: 'Activas'),
                Tab(icon: Icon(Icons.history), text: 'Historial'),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: [_buildActiveListsTab(), _buildHistoryTab()],
        ),
      ),
      floatingActionButton: Theme(
        data: Theme.of(context).copyWith(
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            extendedSizeConstraints: BoxConstraints.tightFor(height: 44),
          ),
        ),
        child: FloatingActionButton.extended(
          onPressed: _createNewList,
          icon: const Icon(Icons.add),
          label: const Text('Nueva Lista'),
          backgroundColor: Theme.of(context).colorScheme.primary,
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
        final activeLists = lists;

        if (activeLists.isEmpty) {
          return ModernEmptyState(
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

  Widget _buildHistoryTab() {
    return StreamBuilder<List<ShoppingList>>(
      stream: widget.svc.streamShoppingLists(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final lists = snapshot.data!;
        final completedLists =
            lists.where((list) => list.completedAt != null).toList()
              ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

        if (completedLists.isEmpty) {
          return const ModernEmptyState(
            icon: Icons.history,
            message: 'Sin historial',
            subtitle: 'Las listas completadas aparecerán aquí',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: completedLists.length,
          itemBuilder: (context, index) {
            final list = completedLists[index];
            return _HistoryListCard(
                  list: list,
                  onTap: () => _openListDetail(list),
                  onRestore: () => _restoreList(list),
                  onDelete: () => _deleteList(list),
                )
                .animate()
                .fadeIn(delay: Duration(milliseconds: index * 30))
                .slideX(begin: -0.2);
          },
        );
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
                                  : AppColors.borderLight,
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
                                  : AppColors.borderLight,
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                              backgroundColor: colorScheme.primary,
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

  Future<void> _restoreList(ShoppingList list) async {
    try {
      await widget.svc.updateShoppingList(list.id, {'completedAt': null});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.restore,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Lista "${list.name}" restaurada'),
              ],
            ),
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al restaurar: $e'),
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      }
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${list.name}" eliminada'),
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleDefault(ShoppingList list) async {
    await widget.svc.setDefaultList(list.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${list.name}" marcada como predeterminada'),
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
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
        '${list.items.length} productos • ${_getScopeLabel(list.scope)} • $purchased/${list.items.length} comprados${total > 0 ? ' • €${total.toStringAsFixed(2)}' : ''}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FoodCompactTile(
        height: 50,
        onTap: onTap,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            list.isDefault ? Icons.star : Icons.shopping_cart,
            color: colorScheme.onPrimaryContainer,
            size: 18,
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
                      Icon(
                        Icons.delete,
                        size: 20,
                        color: colorScheme.error,
                      ),
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
        return 'Custom';
    }
  }
}

class _HistoryListCard extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback onTap;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _HistoryListCard({
    required this.list,
    required this.onTap,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = list.items.fold<double>(
      0,
      (sum, item) => sum + (item.total ?? 0),
    );
    final completedDate =
        list.completedAt != null
            ? DateFormat('dd/MM/yyyy').format(list.completedAt!)
            : 'Fecha desconocida';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FoodCompactTile(
        height: 50,
        onTap: onTap,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.check_circle,
            color: colorScheme.onSecondaryContainer,
            size: 18,
          ),
        ),
        title: list.name,
        subtitle:
            'Completada el $completedDate • ${list.items.length} productos${total > 0 ? ' • €${total.toStringAsFixed(2)}' : ''}',
        trailing: PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          onSelected: (value) {
            if (value == 'restore') onRestore();
            if (value == 'delete') onDelete();
          },
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      Icon(
                        Icons.restore,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Restaurar',
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete,
                        size: 20,
                        color: colorScheme.error,
                      ),
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
}
