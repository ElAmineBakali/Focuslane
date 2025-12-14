import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/global_ui_theme.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';

/// 🍳 DESPENSA V2 - Diseño moderno con alertas de stock bajo y gestión inteligente
class PantryScreenV2 extends StatefulWidget {
  final FoodFirestoreService svc;
  const PantryScreenV2({super.key, required this.svc});

  @override
  State<PantryScreenV2> createState() => _PantryScreenV2State();
}

class _PantryScreenV2State extends State<PantryScreenV2> {
  bool _isGridView = true;
  bool _showLowStockOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernGradientAppBar(
        title: 'Despensa',
        gradient: LinearGradient(
          colors: [Colors.brown.shade700, Colors.brown.shade500],
        ),
        actions: [
          IconButton(
            icon: Icon(_showLowStockOnly ? Icons.warning_amber : Icons.inventory_2),
            tooltip: _showLowStockOnly ? 'Mostrar todo' : 'Solo stock bajo',
            onPressed: () => setState(() => _showLowStockOnly = !_showLowStockOnly),
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'Vista lista' : 'Vista cuadrícula',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Añadir producto',
            onPressed: () => _editItem(),
          ),
        ],
      ),
      body: StreamBuilder<List<PantryItem>>(
        stream: widget.svc.streamPantry(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allItems = snapshot.data!;
          final items = _showLowStockOnly
              ? allItems.where((item) {
                  return item.minQty != null && item.qty <= item.minQty!;
                }).toList()
              : allItems;

          final lowStockCount = allItems.where((item) {
            return item.minQty != null && item.qty <= item.minQty!;
          }).length;

          if (items.isEmpty) {
            return ModernEmptyState(
              icon: _showLowStockOnly ? Icons.check_circle_outline : Icons.kitchen_outlined,
              title: _showLowStockOnly ? 'Sin alertas de stock' : 'Despensa vacía',
              message: _showLowStockOnly
                  ? 'Todos los productos tienen stock suficiente'
                  : 'Añade productos a tu despensa',
              actionLabel: _showLowStockOnly ? null : 'Añadir Producto',
              onAction: _showLowStockOnly ? null : () => _editItem(),
            );
          }

          return Column(
            children: [
              // Alerta de stock bajo
              if (lowStockCount > 0 && !_showLowStockOnly)
                Container(
                  margin: const EdgeInsets.all(AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade700, Colors.amber.shade500],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.white, size: 32),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stock Bajo',
                              style: AppTypography.heading4(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$lowStockCount productos necesitan reposición',
                              style: AppTypography.caption(context).copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _showLowStockOnly = true),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                        child: Text(
                          'Ver',
                          style: AppTypography.button(context).copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.2),
              // Lista de productos
              Expanded(
                child: _isGridView
                    ? _buildGridView(items)
                    : _buildListView(items),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editItem(),
        icon: const Icon(Icons.add),
        label: const Text('Añadir'),
        backgroundColor: Colors.brown,
      ),
    );
  }

  Widget _buildGridView(List<PantryItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isLowStock = item.minQty != null && item.qty <= item.minQty!;
        
        return _PantryCard(
          item: item,
          isLowStock: isLowStock,
          onTap: () => _showItemDetails(item),
          onConsume: () => _consumeItem(item),
          onEdit: () => _editItem(initial: item, id: item.id),
          onDelete: () => _deleteItem(item),
        ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).scale();
      },
    );
  }

  Widget _buildListView(List<PantryItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isLowStock = item.minQty != null && item.qty <= item.minQty!;
        
        return _PantryTile(
          item: item,
          isLowStock: isLowStock,
          onTap: () => _showItemDetails(item),
          onConsume: () => _consumeItem(item),
          onEdit: () => _editItem(initial: item, id: item.id),
          onDelete: () => _deleteItem(item),
        ).animate().fadeIn(delay: Duration(milliseconds: index * 30)).slideX(begin: -0.2);
      },
    );
  }

  // Acciones
  Future<void> _editItem({PantryItem? initial, String? id}) async {
    final nameController = TextEditingController(text: initial?.name ?? '');
    final qtyController = TextEditingController(text: (initial?.qty ?? 1).toString());
    final minQtyController = TextEditingController(
      text: initial?.minQty?.toString() ?? '',
    );
    UnitKind unit = initial?.unit ?? UnitKind.unit;

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
              Text(
                initial == null ? 'Añadir a Despensa' : 'Editar Producto',
                style: AppTypography.heading3(context),
              ),
              const SizedBox(height: AppSpacing.md),
              ModernTextField(
                controller: nameController,
                label: 'Nombre del producto',
                hint: 'Ej: Arroz, Pasta, Atún...',
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: ModernTextField(
                      controller: qtyController,
                      label: 'Cantidad actual',
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
                      child: DropdownButton<UnitKind>(
                        value: unit,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: UnitKind.unit, child: Text('unidades')),
                          DropdownMenuItem(value: UnitKind.g, child: Text('gramos')),
                          DropdownMenuItem(value: UnitKind.ml, child: Text('ml')),
                        ],
                        onChanged: (v) => setModalState(() => unit = v ?? UnitKind.unit),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ModernTextField(
                controller: minQtyController,
                label: 'Stock mínimo (opcional)',
                hint: 'Alerta cuando esté por debajo',
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
                        'minQty': double.tryParse(minQtyController.text),
                      }),
                      style: FilledButton.styleFrom(backgroundColor: Colors.brown),
                      child: Text(initial == null ? 'Añadir' : 'Guardar'),
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

      if (id != null) {
        // Editar
        final updated = PantryItem(
          id: id,
          name: name,
          qty: result['qty'] as double,
          unit: result['unit'] as UnitKind,
          minQty: result['minQty'] as double?,
        );
        await widget.svc.savePantry(updated);
      } else {
        // Crear nuevo
        final newItem = PantryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          qty: result['qty'] as double,
          unit: result['unit'] as UnitKind,
          minQty: result['minQty'] as double?,
        );
        await widget.svc.savePantry(newItem);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(id == null ? 'Producto añadido' : 'Producto actualizado'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _consumeItem(PantryItem item) async {
    final controller = TextEditingController(text: '1');

    final qty = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Consumir ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Stock actual: ${item.qty.toStringAsFixed(0)} ${_getUnitLabel(item.unit)}',
              style: AppTypography.body(context),
            ),
            const SizedBox(height: AppSpacing.md),
            ModernTextField(
              controller: controller,
              label: 'Cantidad a consumir',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
            style: FilledButton.styleFrom(backgroundColor: Colors.brown),
            child: const Text('Consumir'),
          ),
        ],
      ),
    );

    if (qty != null && qty > 0) {
      await widget.svc.consumePantry(item.id, qty);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${qty.toStringAsFixed(0)} ${_getUnitLabel(item.unit)} consumidos'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(PantryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que quieres eliminar "${item.name}"?'),
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
      await widget.svc.deletePantry(item.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${item.name}" eliminado'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showItemDetails(PantryItem item) {
    final isLowStock = item.minQty != null && item.qty <= item.minQty!;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLowStock
                          ? [Colors.amber.shade600, Colors.amber.shade400]
                          : [Colors.brown.shade600, Colors.brown.shade400],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    isLowStock ? Icons.warning_amber : Icons.kitchen,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppTypography.heading3(context)),
                      if (isLowStock)
                        Text(
                          'Stock bajo',
                          style: AppTypography.caption(context).copyWith(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Detalles
            _DetailRow(
              icon: Icons.inventory_2,
              label: 'Stock actual',
              value: '${item.qty.toStringAsFixed(0)} ${_getUnitLabel(item.unit)}',
            ),
            if (item.minQty != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _DetailRow(
                icon: Icons.warning_outline,
                label: 'Stock mínimo',
                value: '${item.minQty!.toStringAsFixed(0)} ${_getUnitLabel(item.unit)}',
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            // Acciones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _consumeItem(item);
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text('Consumir'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editItem(initial: item, id: item.id);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.brown),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getUnitLabel(UnitKind unit) {
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

// Widgets auxiliares
class _PantryCard extends StatelessWidget {
  final PantryItem item;
  final bool isLowStock;
  final VoidCallback onTap;
  final VoidCallback onConsume;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PantryCard({
    required this.item,
    required this.isLowStock,
    required this.onTap,
    required this.onConsume,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isLowStock ? Colors.amber : AppColors.borderLight,
            width: isLowStock ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLowStock
                      ? [Colors.amber.shade600, Colors.amber.shade400]
                      : [Colors.brown.shade600, Colors.brown.shade400],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isLowStock ? Icons.warning_amber : Icons.kitchen,
                    color: Colors.white,
                    size: 28,
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'consume') onConsume();
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'consume',
                        child: Row(
                          children: [
                            Icon(Icons.remove_circle_outline, size: 20),
                            SizedBox(width: AppSpacing.sm),
                            Text('Consumir'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: AppSpacing.sm),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
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
                ],
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: AppTypography.heading4(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (isLowStock)
                      ModernBadge(
                        text: 'STOCK BAJO',
                        color: Colors.amber,
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Stock: ${item.qty.toStringAsFixed(0)} ${_getUnitLabel(item.unit)}',
                      style: AppTypography.label(context).copyWith(
                        color: Colors.brown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.minQty != null)
                      Text(
                        'Mín: ${item.minQty!.toStringAsFixed(0)} ${_getUnitLabel(item.unit)}',
                        style: AppTypography.caption(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getUnitLabel(UnitKind unit) {
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

class _PantryTile extends StatelessWidget {
  final PantryItem item;
  final bool isLowStock;
  final VoidCallback onTap;
  final VoidCallback onConsume;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PantryTile({
    required this.item,
    required this.isLowStock,
    required this.onTap,
    required this.onConsume,
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
          color: isLowStock ? Colors.amber : AppColors.borderLight,
          width: isLowStock ? 2 : 1,
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
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLowStock
                  ? [Colors.amber.shade600, Colors.amber.shade400]
                  : [Colors.brown.shade600, Colors.brown.shade400],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            isLowStock ? Icons.warning_amber : Icons.kitchen,
            color: Colors.white,
          ),
        ),
        title: Text(item.name, style: AppTypography.body(context)),
        subtitle: Row(
          children: [
            Text(
              'Stock: ${item.qty.toStringAsFixed(0)} ${_getUnitLabel(item.unit)}',
              style: AppTypography.caption(context),
            ),
            if (item.minQty != null) ...[
              const Text(' • '),
              Text(
                'Mín: ${item.minQty!.toStringAsFixed(0)}',
                style: AppTypography.caption(context),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'consume') onConsume();
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'consume',
              child: Row(
                children: [
                  Icon(Icons.remove_circle_outline, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text('Consumir'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem(
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

  String _getUnitLabel(UnitKind unit) {
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTypography.body(context)),
        const Spacer(),
        Text(
          value,
          style: AppTypography.label(context).copyWith(
            color: Colors.brown,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
