import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/global_ui_theme.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';

/// 🛒 DETALLE LISTA DE COMPRA V2 - Diseño moderno con marcado de productos
class ShoppingListDetailScreenV2 extends StatefulWidget {
  final FoodFirestoreService svc;
  final String listId;

  const ShoppingListDetailScreenV2({
    super.key,
    required this.svc,
    required this.listId,
  });

  @override
  State<ShoppingListDetailScreenV2> createState() =>
      _ShoppingListDetailScreenV2State();
}

class _ShoppingListDetailScreenV2State
    extends State<ShoppingListDetailScreenV2> {
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
          orElse: () => ShoppingList(
            id: widget.listId,
            name: 'Lista',
            scope: ShoppingScope.custom,
            isDefault: false,
            items: const [],
            createdAt: DateTime.now(),
          ),
        );

        final visibleItems = _hideCompleted
            ? list.items.where((i) => !i.purchased).toList()
            : list.items;

        final purchasedCount = list.items.where((i) => i.purchased).length;
        final progress = list.items.isEmpty ? 0.0 : purchasedCount / list.items.length;
        final total = list.items.fold<double>(0, (sum, item) => sum + (item.total ?? 0));
        final totalPurchased = list.items
            .where((i) => i.purchased)
            .fold<double>(0, (sum, item) => sum + (item.total ?? 0));

        return Scaffold(
          appBar: ModernGradientAppBar(
            title: list.name,
            gradient: LinearGradient(
              colors: [Colors.orange.shade700, Colors.orange.shade500],
            ),
            actions: [
              IconButton(
                icon: Icon(_hideCompleted ? Icons.visibility : Icons.visibility_off),
                tooltip: _hideCompleted ? 'Mostrar todos' : 'Ocultar comprados',
                onPressed: () => setState(() => _hideCompleted = !_hideCompleted),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Añadir producto',
                onPressed: () => _addItemDialog(list),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'complete') _completeList(list);
                  if (value == 'clear') _clearPurchased(list);
                  if (value == 'pantry') _sendToPantry(list);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Text('Completar lista'),
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
              // Resumen
              Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade700, Colors.orange.shade500],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
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
                        Container(width: 1, height: 40, color: Colors.white30),
                        _SummaryItem(
                          icon: Icons.check_circle,
                          label: 'Comprados',
                          value: '$purchasedCount',
                        ),
                        Container(width: 1, height: 40, color: Colors.white30),
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
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: AppTypography.label(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ModernProgressBar(
                          progress: progress,
                          color: Colors.white,
                          backgroundColor: Colors.white30,
                        ),
                      ],
                    ),
                    if (totalPurchased > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Gastado hasta ahora: €${totalPurchased.toStringAsFixed(2)}',
                        style: AppTypography.caption(context).copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2),
              // Lista de productos
              Expanded(
                child: visibleItems.isEmpty
                    ? ModernEmptyState(
                        icon: Icons.shopping_cart_outlined,
                        title: _hideCompleted ? 'Todo comprado' : 'Lista vacía',
                        message: _hideCompleted
                            ? '¡Excelente! Has comprado todo'
                            : 'Añade productos con el botón +',
                        actionLabel: _hideCompleted ? null : 'Añadir Producto',
                        onAction: _hideCompleted ? null : () => _addItemDialog(list),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemCount: visibleItems.length,
                        itemBuilder: (context, index) {
                          final item = visibleItems[index];
                          final originalIndex = list.items.indexOf(item);
                          
                          return _ShoppingItemCard(
                            item: item,
                            onToggle: () => widget.svc.togglePurchased(
                              list.id,
                              originalIndex,
                              !item.purchased,
                            ),
                            onEdit: () => _editItemDialog(list, originalIndex, item),
                            onDelete: () => _deleteItem(list, originalIndex),
                          )
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: index * 30))
                              .slideX(begin: -0.2);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addItemDialog(list),
            backgroundColor: Colors.orange,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  // Diálogos y acciones
  Future<void> _addItemDialog(ShoppingList list) async {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    ShoppingUnit unit = ShoppingUnit.unit;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
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
              Text('Añadir Producto', style: AppTypography.heading3(context)),
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
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: DropdownButton<ShoppingUnit>(
                        value: unit,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: ShoppingUnit.values.map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(_getUnitLabel(u)),
                          );
                        }).toList(),
                        onChanged: (v) => setModalState(() => unit = v ?? ShoppingUnit.unit),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ModernTextField(
                controller: priceController,
                label: 'Precio por unidad (opcional)',
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
                      onPressed: () => Navigator.pop(context, {
                        'name': nameController.text,
                        'qty': double.tryParse(qtyController.text) ?? 1.0,
                        'unit': unit,
                        'price': double.tryParse(priceController.text),
                      }),
                      style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text('Añadir'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      final name = result['name'] as String;
      if (name.isEmpty) return;

      final item = ShoppingItem(
        name: name,
        qty: result['qty'] as double,
        unit: result['unit'] as ShoppingUnit,
        pricePerUnit: result['price'] as double?,
        total: result['price'] != null
            ? (result['qty'] as double) * (result['price'] as double)
            : null,
        checked: false,
        purchased: false,
      );

      await widget.svc.addShoppingItem(list.id, item);
    }
  }

  Future<void> _editItemDialog(
    ShoppingList list,
    int index,
    ShoppingItem item,
  ) async {
    final nameController = TextEditingController(text: item.name);
    final qtyController = TextEditingController(text: item.qty.toString());
    final priceController = TextEditingController(
      text: item.pricePerUnit?.toString() ?? '',
    );
    ShoppingUnit unit = item.unit;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
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
              Text('Editar Producto', style: AppTypography.heading3(context)),
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
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: DropdownButton<ShoppingUnit>(
                        value: unit,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: ShoppingUnit.values.map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(_getUnitLabel(u)),
                          );
                        }).toList(),
                        onChanged: (v) => setModalState(() => unit = v ?? ShoppingUnit.unit),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ModernTextField(
                controller: priceController,
                label: 'Precio por unidad (opcional)',
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
                      onPressed: () => Navigator.pop(context, {
                        'name': nameController.text,
                        'qty': double.tryParse(qtyController.text) ?? 1.0,
                        'unit': unit,
                        'price': double.tryParse(priceController.text),
                      }),
                      style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      final name = result['name'] as String;
      if (name.isEmpty) return;

      final updatedItem = ShoppingItem(
        name: name,
        qty: result['qty'] as double,
        unit: result['unit'] as ShoppingUnit,
        pricePerUnit: result['price'] as double?,
        total: result['price'] != null
            ? (result['qty'] as double) * (result['price'] as double)
            : null,
        checked: item.checked,
        purchased: item.purchased,
      );

      await widget.svc.updateShoppingItem(list.id, index, updatedItem);
    }
  }

  Future<void> _deleteItem(ShoppingList list, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que quieres eliminar "${list.items[index].name}"?'),
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

    if (confirmed == true) {
      await widget.svc.removeShoppingItem(list.id, index);
    }
  }

  Future<void> _completeList(ShoppingList list) async {
    // TODO: Marcar lista como completada y mover al historial
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lista completada'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _clearPurchased(ShoppingList list) async {
    final purchased = list.items.where((i) => i.purchased).toList();
    if (purchased.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar comprados'),
        content: Text('¿Eliminar ${purchased.length} productos ya comprados?'),
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

    if (confirmed == true) {
      // TODO: Implementar limpieza de comprados
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Productos comprados eliminados'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendToPantry(ShoppingList list) async {
    // TODO: Enviar productos comprados a la despensa
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Productos enviados a la despensa'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getUnitLabel(ShoppingUnit unit) {
    switch (unit) {
      case ShoppingUnit.unit:
        return 'unidades';
      case ShoppingUnit.kg:
        return 'kg';
      case ShoppingUnit.g:
        return 'g';
      case ShoppingUnit.l:
        return 'litros';
      case ShoppingUnit.ml:
        return 'ml';
      case ShoppingUnit.pack:
        return 'paquetes';
    }
  }
}

// Widgets auxiliares
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
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.heading3(context).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption(context).copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _ShoppingItemCard extends StatelessWidget {
  final ShoppingItem item;
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: item.purchased
              ? AppColors.success.withOpacity(0.5)
              : AppColors.borderLight,
          width: item.purchased ? 2 : 1,
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
          value: item.purchased,
          onChanged: (_) => onToggle(),
          activeColor: AppColors.success,
        ),
        title: Text(
          item.name,
          style: AppTypography.body(context).copyWith(
            decoration: item.purchased ? TextDecoration.lineThrough : null,
            color: item.purchased ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '${item.qty.toStringAsFixed(0)} ${_getUnitLabel(item.unit)}',
              style: AppTypography.caption(context),
            ),
            if (item.pricePerUnit != null) ...[
              const Text(' • '),
              Text(
                '€${item.pricePerUnit!.toStringAsFixed(2)}/u',
                style: AppTypography.caption(context),
              ),
            ],
            if (item.total != null) ...[
              const Text(' • '),
              Text(
                'Total: €${item.total!.toStringAsFixed(2)}',
                style: AppTypography.caption(context).copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
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

  String _getUnitLabel(ShoppingUnit unit) {
    switch (unit) {
      case ShoppingUnit.unit:
        return 'u';
      case ShoppingUnit.kg:
        return 'kg';
      case ShoppingUnit.g:
        return 'g';
      case ShoppingUnit.l:
        return 'L';
      case ShoppingUnit.ml:
        return 'ml';
      case ShoppingUnit.pack:
        return 'paq';
    }
  }
}
