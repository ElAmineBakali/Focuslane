import 'package:flutter/material.dart';
import '../../../design/theme/focuslane_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design/theme/global_ui_theme.dart';
import '../widgets/food_compact_widgets.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';

class PantryScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  const PantryScreen({super.key, required this.svc});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  bool _showLowStockOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FoodCompactAppBar(
        title: 'Despensa',
        subtitle: _showLowStockOnly ? 'Solo stock bajo' : 'Inventario',
        actions: [
          IconButton(
            icon: Icon(
              _showLowStockOnly ? Icons.warning_amber : Icons.inventory_2,
              size: 18,
            ),
            tooltip: _showLowStockOnly ? 'Mostrar todo' : 'Solo stock bajo',
            onPressed:
                () => setState(() => _showLowStockOnly = !_showLowStockOnly),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
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
          final items =
              _showLowStockOnly
                  ? allItems.where((item) {
                    return item.minQty != null && item.qty <= item.minQty!;
                  }).toList()
                  : allItems;

          final lowStockCount =
              allItems.where((item) {
                return item.minQty != null && item.qty <= item.minQty!;
              }).length;

          if (items.isEmpty) {
            return ModernEmptyState(
              icon:
                  _showLowStockOnly
                      ? Icons.check_circle_outline
                      : Icons.kitchen_outlined,
              message:
                  _showLowStockOnly ? 'Sin alertas de stock' : 'Despensa vacía',
              subtitle:
                  _showLowStockOnly
                      ? 'Todos los productos tienen stock suficiente'
                      : 'Añade productos a tu despensa',
              actionLabel: _showLowStockOnly ? null : 'Añadir Producto',
              onAction: _showLowStockOnly ? null : () => _editItem(),
            );
          }

          return Column(
            children: [
              if (lowStockCount > 0 && !_showLowStockOnly)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: FoodInlineBanner(
                    icon: Icons.warning_amber,
                    title: 'Stock bajo',
                    subtitle: '$lowStockCount productos necesitan reposición',
                    actionLabel: 'Ver',
                    onAction: () => setState(() => _showLowStockOnly = true),
                  ),
                ).animate().fadeIn().slideY(begin: -0.2),
              Expanded(child: _buildListView(items)),
            ],
          );
        },
      ),
      floatingActionButton: Theme(
        data: Theme.of(context).copyWith(
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            extendedSizeConstraints: BoxConstraints.tightFor(height: 44),
          ),
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _editItem(),
          icon: const Icon(Icons.add),
          label: const Text('Añadir'),
          backgroundColor: FocuslaneUI.accent(context),
        ),
      ),
    );
  }

  Widget _buildListView(List<PantryItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // En PC: 6 columnas, tablet: 4, móvil: 2
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
            childAspectRatio: 1.0,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isLowStock = item.minQty != null && item.qty <= item.minQty!;

            return _PantryGridCard(
              item: item,
              isLowStock: isLowStock,
              onTap: () => _showItemDetails(item),
              onConsume: () => _consumeItem(item),
              onEdit: () => _editItem(initial: item, id: item.id),
              onDelete: () => _deleteItem(item),
            ).animate().fadeIn(delay: Duration(milliseconds: index * 30)).scale(begin: const Offset(0.95, 0.95), duration: const Duration(milliseconds: 200));
          },
        );
      },
    );
  }

  Future<void> _editItem({PantryItem? initial, String? id}) async {
    final nameController = TextEditingController(text: initial?.name ?? '');
    final qtyController = TextEditingController(
      text: (initial?.qty ?? 1).toString(),
    );
    final minQtyController = TextEditingController(
      text: initial?.minQty?.toString() ?? '',
    );
    UnitKind unit = initial?.unit ?? UnitKind.unit;

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
                      initial == null ? 'Añadir a Despensa' : 'Editar Producto',
                      style: AppTypography.heading3(context),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FoodCompactTextField(
                      controller: nameController,
                      label: 'Nombre del producto',
                      hint: 'Ej: Arroz, Pasta, Atún...',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: FoodCompactTextField(
                            controller: qtyController,
                            label: 'Cantidad actual',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: DropdownButtonFormField<UnitKind>(
                              initialValue: unit,
                              isExpanded: true,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    FocuslaneUI.radius,
                                  ),
                                  borderSide: BorderSide(
                                    color: FocuslaneUI.borderColor(context),
                                    width: FocuslaneUI.borderW,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    FocuslaneUI.radius,
                                  ),
                                  borderSide: BorderSide(
                                    color: FocuslaneUI.borderColor(context),
                                    width: FocuslaneUI.borderW,
                                  ),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: UnitKind.unit,
                                  child: Text('unidades'),
                                ),
                                DropdownMenuItem(
                                  value: UnitKind.g,
                                  child: Text('gramos'),
                                ),
                                DropdownMenuItem(
                                  value: UnitKind.ml,
                                  child: Text('ml'),
                                ),
                              ],
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
                    FoodCompactTextField(
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
                            onPressed:
                                () => Navigator.pop(context, {
                                  'name': nameController.text,
                                  'qty':
                                      double.tryParse(qtyController.text) ??
                                      1.0,
                                  'unit': unit,
                                  'minQty': double.tryParse(
                                    minQtyController.text,
                                  ),
                                }),
                            style: FilledButton.styleFrom(
                              backgroundColor: FocuslaneUI.accent(context),
                            ),
                            child: Text(initial == null ? 'Añadir' : 'Guardar'),
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

      if (id != null) {
        final updated = PantryItem(
          id: id,
          name: name,
          qty: result['qty'] as double,
          unit: result['unit'] as UnitKind,
          minQty: result['minQty'] as double?,
        );
        await widget.svc.upsertPantryWithId(updated, id: id);
      } else {
        final newItem = PantryItem(
          id: '',
          name: name,
          qty: result['qty'] as double,
          unit: result['unit'] as UnitKind,
          minQty: result['minQty'] as double?,
        );
        await widget.svc.upsertPantry(newItem);
      }

      if (mounted) {
        FoodFeedback.showSuccess(
          context,
          id == null ? 'Producto añadido' : 'Producto actualizado',
        );
      }
    }
  }

  Future<void> _consumeItem(PantryItem item) async {
    final controller = TextEditingController(text: '1');

    final qty = await showDialog<double>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Consumir ${item.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Stock actual: ${item.qty.toStringAsFixed(0)} ${_getUnitLabel(item.unit)}',
                  style: AppTypography.body(context),
                ),
                const SizedBox(height: AppSpacing.md),
                FoodCompactTextField(
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
                onPressed:
                    () => Navigator.pop(
                      context,
                      double.tryParse(controller.text),
                    ),
                style: FilledButton.styleFrom(
                  backgroundColor: FocuslaneUI.accent(context),
                ),
                child: const Text('Consumir'),
              ),
            ],
          ),
    );

    if (qty != null && qty > 0) {
      await widget.svc.consumePantry(item.id, qty);

      if (mounted) {
        FoodFeedback.showSuccess(
          context,
          '${qty.toStringAsFixed(0)} ${_getUnitLabel(item.unit)} consumidos',
        );
      }
    }
  }

  Future<void> _deleteItem(PantryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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
        FoodFeedback.showSuccess(context, '"${item.name}" eliminado');
      }
    }
  }

  void _showItemDetails(PantryItem item) {
    final isLowStock = item.minQty != null && item.qty <= item.minQty!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXl),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: FocuslaneUI.borderColor(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color:
                            isLowStock
                                ? Theme.of(context).colorScheme.errorContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Icon(
                        isLowStock ? Icons.warning_amber : Icons.kitchen,
                        color:
                            Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppTypography.heading3(context),
                          ),
                          if (isLowStock)
                            Text(
                              'Stock bajo',
                              style: AppTypography.caption(context).copyWith(
                                color: FocuslaneUI.accent(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _DetailRow(
                  icon: Icons.inventory_2,
                  label: 'Stock actual',
                  value:
                      '${item.qty.toStringAsFixed(0)} ${_getUnitLabel(item.unit)}',
                ),
                if (item.minQty != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _DetailRow(
                    icon: Icons.warning_amber_outlined,
                    label: 'Stock mínimo',
                    value:
                        '${item.minQty!.toStringAsFixed(0)} ${_getUnitLabel(item.unit)}',
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
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
                        style: FilledButton.styleFrom(
                          backgroundColor: FocuslaneUI.accent(context),
                        ),
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

class _PantryGridCard extends StatelessWidget {
  final PantryItem item;
  final bool isLowStock;
  final VoidCallback onTap;
  final VoidCallback onConsume;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PantryGridCard({
    required this.item,
    required this.isLowStock,
    required this.onTap,
    required this.onConsume,
    required this.onEdit,
    required this.onDelete,
  });

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

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
                  color: isLowStock
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isLowStock ? Icons.warning_amber : Icons.kitchen,
                  color: isLowStock
                      ? colorScheme.error
                      : colorScheme.onPrimaryContainer,
                  size: 18,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 18,
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
                        Icon(Icons.remove_circle_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Consumir'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(
            item.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${item.qty.toStringAsFixed(0)} ${_getUnitLabel(item.unit)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isLowStock ? colorScheme.error : colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (item.minQty != null)
            Text(
              'Mín: ${item.minQty!.toStringAsFixed(0)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FoodCompactTile(
        height: 48,
        onTap: onTap,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color:
                isLowStock
                    ? colorScheme.errorContainer
                    : colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isLowStock ? Icons.warning_amber : Icons.kitchen,
            color: colorScheme.onPrimaryContainer,
            size: 18,
          ),
        ),
        title: item.name,
        subtitle:
            'Stock: ${item.qty.toStringAsFixed(0)} ${_getUnitLabel(item.unit)}${item.minQty != null ? ' • Mín: ${item.minQty!.toStringAsFixed(0)}' : ''}',
        trailing: PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          onSelected: (value) {
            if (value == 'consume') onConsume();
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder:
              (context) => const [
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
                      Icon(Icons.delete, size: 20, color: AppColors.error),
                      SizedBox(width: AppSpacing.sm),
                      Text('Eliminar', style: TextStyle(color: AppColors.error)),
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
          style: AppTypography.label(
            context,
          ).copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

