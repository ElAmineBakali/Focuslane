import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/global_ui_theme.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';

class ShoppingListDetailScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  final String listId;

  const ShoppingListDetailScreen({
    super.key,
    required this.svc,
    required this.listId,
  });

  @override
  State<ShoppingListDetailScreen> createState() =>
      _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState
    extends State<ShoppingListDetailScreen> {
  bool _hideCompleted = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ShoppingList>>(
      stream: widget.svc.streamShoppingLists(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Cargando...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final list = snapshot.data!.firstWhere(
          (l) => l.id == widget.listId,
          orElse:
              () => ShoppingList(
                id: widget.listId,
                name: 'Lista',
                scope: ShoppingScope.custom,
                isDefault: false,
                items: const [],
                createdAt: DateTime.now(),
              ),
        );

        final visibleItems =
            _hideCompleted
                ? list.items.where((i) => !i.checked).toList()
                : list.items;

        final purchasedCount = list.items.where((i) => i.checked).length;
        final progress =
            list.items.isEmpty ? 0.0 : purchasedCount / list.items.length;
        final total = list.items.fold<double>(
          0,
          (sum, item) => sum + (item.total ?? 0),
        );
        final totalPurchased = list.items
            .where((i) => i.checked)
            .fold<double>(0, (sum, item) => sum + (item.total ?? 0));

        return Scaffold(
          appBar: ModernGradientAppBar(
            title: list.name,
            useThemeColors: true,
            actions: [
              IconButton(
                icon: Icon(
                  _hideCompleted ? Icons.visibility : Icons.visibility_off,
                ),
                tooltip: _hideCompleted ? 'Mostrar todos' : 'Ocultar comprados',
                onPressed:
                    () => setState(() => _hideCompleted = !_hideCompleted),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Añadir producto',
                onPressed: () => _addItemDialog(list),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'clear') _clearPurchased(list);
                  if (value == 'pantry') _sendToPantry(list);
                  if (value == 'complete') _completeList(list);
                },
                itemBuilder:
                    (context) => [
                      if (progress >= 1.0 && list.completedAt == null)
                        const PopupMenuItem(
                          value: 'complete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.archive,
                                size: 20,
                                color: Colors.green,
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                'Archivar al historial',
                                style: TextStyle(color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(Icons.clear_all, size: 20),
                            SizedBox(width: AppSpacing.sm),
                            Text('Limpiar comprados'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'pantry',
                        child: Row(
                          children: [
                            Icon(Icons.kitchen, size: 20),
                            SizedBox(width: AppSpacing.sm),
                            Text('Enviar a despensa'),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
          body: Column(
            children: [
              Builder(
                builder: (context) {
                  final colorScheme = Theme.of(context).colorScheme;
                  return Container(
                    margin: const EdgeInsets.all(AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _SummaryItem(
                              icon: Icons.shopping_basket,
                              label: 'Productos',
                              value: '${list.items.length}',
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.3),
                            ),
                            _SummaryItem(
                              icon: Icons.check_circle,
                              label: 'Comprados',
                              value: '$purchasedCount',
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.3),
                            ),
                            _SummaryItem(
                              icon: Icons.euro,
                              label: 'Total',
                              value: '€${total.toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progreso',
                                  style: AppTypography.label(context).copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: AppTypography.label(context).copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            ModernProgressBar(
                              value: progress,
                              color: Theme.of(context).colorScheme.onPrimary,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.3),
                            ),
                          ],
                        ),
                        if (totalPurchased > 0) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Gastado hasta ahora: €${totalPurchased.toStringAsFixed(2)}',
                            style: AppTypography.caption(context).copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ).animate().fadeIn().slideY(begin: -0.2),
              Expanded(
                child:
                    visibleItems.isEmpty
                        ? ModernEmptyState(
                          icon: Icons.shopping_cart_outlined,
                          message:
                              _hideCompleted ? 'Todo comprado' : 'Lista vacía',
                          subtitle:
                              _hideCompleted
                                  ? '¡Excelente! Has comprado todo'
                                  : 'Añade productos con el botón +',
                          actionLabel:
                              _hideCompleted ? null : 'Añadir Producto',
                          onAction:
                              _hideCompleted
                                  ? null
                                  : () => _addItemDialog(list),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          itemCount: visibleItems.length,
                          itemBuilder: (context, index) {
                            final item = visibleItems[index];
                            final originalIndex = list.items.indexOf(item);

                            return _ShoppingItemCard(
                                  item: item,
                                  onToggle:
                                      () => widget.svc.toggleChecked(
                                        list.id,
                                        originalIndex.toString(),
                                        !item.checked,
                                      ),
                                  onEdit:
                                      () => _editItemDialog(
                                        list,
                                        originalIndex,
                                        item,
                                      ),
                                  onDelete:
                                      () => _deleteItem(list, originalIndex),
                                )
                                .animate()
                                .fadeIn(
                                  delay: Duration(milliseconds: index * 30),
                                )
                                .slideX(begin: -0.2);
                          },
                        ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addItemDialog(list),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _addItemDialog(ShoppingList list) async {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    UnitKind unit = UnitKind.unit;

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
                      'Añadir Producto',
                      style: AppTypography.heading3(context),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ModernTextField(
                      controller: nameController,
                      label: 'Nombre del producto',
                      hint: 'Ej: Leche, Pan, Tomates...',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: ModernTextField(
                            controller: qtyController,
                            label: 'Cantidad',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.borderLight),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                            child: DropdownButton<UnitKind>(
                              value: unit,
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              items:
                                  UnitKind.values.map((u) {
                                    return DropdownMenuItem(
                                      value: u,
                                      child: Text(_getUnitLabel(u)),
                                    );
                                  }).toList(),
                              onChanged:
                                  (v) => setModalState(
                                    () => unit = v ?? UnitKind.unit,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ModernTextField(
                      controller: priceController,
                      label: 'Precio total (opcional)',
                      hint: 'Ej: 2.50',
                      keyboardType: TextInputType.number,
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
                                  'qty':
                                      double.tryParse(qtyController.text) ??
                                      1.0,
                                  'unit': unit,
                                  'price': double.tryParse(
                                    priceController.text,
                                  ),
                                }),
                            child: const Text('Añadir'),
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

    if (result != null && mounted) {
      final name = result['name'] as String;
      if (name.isEmpty) return;

      final item = ShoppingListItem(
        id: '',
        name: name,
        qty: result['qty'] as double,
        unit: result['unit'] as UnitKind,
        pricePerUnit: result['price'] as double?,
        total: result['price'] as double?,
        checked: false,
      );

      await widget.svc.upsertShoppingItem(list.id, '', item);
    }
  }

  Future<void> _editItemDialog(
    ShoppingList list,
    int index,
    ShoppingListItem item,
  ) async {
    final nameController = TextEditingController(text: item.name);
    final qtyController = TextEditingController(text: item.qty.toString());
    final priceController = TextEditingController(
      text: item.total?.toString() ?? '',
    );
    UnitKind unit = item.unit;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              final colorScheme = Theme.of(context).colorScheme;
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
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Editar Producto',
                      style: AppTypography.heading3(context),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ModernTextField(
                      controller: nameController,
                      label: 'Nombre del producto',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: ModernTextField(
                            controller: qtyController,
                            label: 'Cantidad',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.borderLight),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                            child: DropdownButton<UnitKind>(
                              value: unit,
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              items:
                                  UnitKind.values.map((u) {
                                    return DropdownMenuItem(
                                      value: u,
                                      child: Text(_getUnitLabel(u)),
                                    );
                                  }).toList(),
                              onChanged:
                                  (v) => setModalState(
                                    () => unit = v ?? UnitKind.unit,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ModernTextField(
                      controller: priceController,
                      label: 'Precio total (opcional)',
                      keyboardType: TextInputType.number,
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
                                  'qty':
                                      double.tryParse(qtyController.text) ??
                                      1.0,
                                  'unit': unit,
                                  'price': double.tryParse(
                                    priceController.text,
                                  ),
                                }),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.food,
                            ),
                            child: const Text('Guardar'),
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

    if (result != null && mounted) {
      final name = result['name'] as String;
      if (name.isEmpty) return;

      final updatedItem = ShoppingListItem(
        id: item.id,
        foodId: item.foodId,
        name: name,
        qty: result['qty'] as double,
        unit: result['unit'] as UnitKind,
        pricePerUnit: result['price'] as double?,
        total: result['price'] as double?,
        checked: item.checked,
        tags: item.tags,
        notes: item.notes,
      );

      await widget.svc.upsertShoppingItem(
        list.id,
        index.toString(),
        updatedItem,
      );
    }
  }

  Future<void> _deleteItem(ShoppingList list, int index) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colorScheme.surface,
            title: const Text('Eliminar producto'),
            content: Text(
              '¿Seguro que quieres eliminar "${list.items[index].name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      await widget.svc.removeShoppingItem(list.id, index.toString());
    }
  }

  Future<void> _clearPurchased(ShoppingList list) async {
    final purchased = list.items.where((i) => i.checked).toList();
    if (purchased.isEmpty) return;

    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colorScheme.surface,
            title: const Text('Limpiar comprados'),
            content: Text(
              '¿Eliminar ${purchased.length} productos ya comprados?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Limpiar'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      for (int i = list.items.length - 1; i >= 0; i--) {
        if (list.items[i].checked) {
          await widget.svc.removeShoppingItem(list.id, i.toString());
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Productos comprados eliminados'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendToPantry(ShoppingList list) async {
    final purchased = list.items.where((i) => i.checked).toList();
    if (purchased.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos comprados para enviar'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    for (final item in purchased) {
      final pantryItem = PantryItem(
        id: '',
        foodId: item.foodId,
        name: item.name,
        qty: item.qty,
        unit: item.unit,
      );
      await widget.svc.upsertPantry(pantryItem);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${purchased.length} productos enviados a la despensa'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _completeList(ShoppingList list) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colorScheme.surface,
            title: const Text('Archivar lista'),
            content: const Text(
              '¿Marcar esta lista como completada y enviarla al historial?\n\nPodrás restaurarla más tarde si lo necesitas.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                child: const Text('Archivar'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.svc.updateShoppingList(list.id, {
          'completedAt': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.archive,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Lista archivada correctamente'),
                ],
              ),
              backgroundColor: AppColors.success,
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
              content: Text('Error al archivar: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  String _getUnitLabel(UnitKind unit) {
    switch (unit) {
      case UnitKind.unit:
        return 'unidades';
      case UnitKind.g:
        return 'gramos';
      case UnitKind.ml:
        return 'mililitros';
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 24),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.heading3(context).copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption(context).copyWith(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _ShoppingItemCard extends StatelessWidget {
  final ShoppingListItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ShoppingItemCard({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color:
              item.checked
                  ? AppColors.success.withOpacity(0.5)
                  : AppColors.borderLight,
          width: item.checked ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Checkbox(
          value: item.checked,
          onChanged: (_) => onToggle(),
          activeColor: AppColors.success,
        ),
        title: Text(
          item.name,
          style: AppTypography.body(context).copyWith(
            decoration: item.checked ? TextDecoration.lineThrough : null,
            color:
                item.checked ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '${item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 1)} ${_getUnitShort(item.unit)}',
              style: AppTypography.caption(context),
            ),
            if (item.total != null) ...[
              const Text(' • '),
              Text(
                'Total: €${item.total!.toStringAsFixed(2)}',
                style: AppTypography.caption(
                  context,
                ).copyWith(color: AppColors.food, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: AppSpacing.sm),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
        ),
      ),
    );
  }

  String _getUnitShort(UnitKind unit) {
    switch (unit) {
      case UnitKind.unit:
        return 'u';
      case UnitKind.g:
        return 'g';
      case UnitKind.ml:
        return 'ml';
    }
  }
}
