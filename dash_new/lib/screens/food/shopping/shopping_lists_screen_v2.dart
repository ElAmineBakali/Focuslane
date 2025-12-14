import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/global_ui_theme.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';
import 'shopping_list_detail_screen_v2.dart';

/// 🛍️ LISTAS DE COMPRA V2 - Diseño moderno con historial y estadísticas
class ShoppingListsScreenV2 extends StatefulWidget {
  final FoodFirestoreService svc;
  const ShoppingListsScreenV2({super.key, required this.svc});

  @override
  State<ShoppingListsScreenV2> createState() => _ShoppingListsScreenV2State();
}

class _ShoppingListsScreenV2State extends State<ShoppingListsScreenV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGridView = true;

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
    return Scaffold(
      appBar: ModernGradientAppBar(
        title: 'Listas de Compra',
        gradient: LinearGradient(
          colors: [Colors.orange.shade700, Colors.orange.shade500],
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'Vista lista' : 'Vista cuadrícula',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva lista',
            onPressed: _createNewList,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_cart), text: 'Activas'),
            Tab(icon: Icon(Icons.history), text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveListsTab(),
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewList,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Lista'),
        backgroundColor: Colors.orange,
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
        final activeLists = lists.where((l) => !l.isCompleted).toList();

        if (activeLists.isEmpty) {
          return ModernEmptyState(
            icon: Icons.shopping_cart_outlined,
            title: 'Sin listas de compra',
            message: 'Crea tu primera lista para comenzar',
            actionLabel: 'Crear Lista',
            onAction: _createNewList,
          );
        }

        return _isGridView
            ? _buildGridView(activeLists)
            : _buildListView(activeLists);
      },
    );
  }

  Widget _buildGridView(List<ShoppingList> lists) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        return _ShoppingListCard(
          list: list,
          onTap: () => _openListDetail(list),
          onDelete: () => _deleteList(list),
          onToggleDefault: () => _toggleDefault(list),
        ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).scale();
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
        ).animate().fadeIn(delay: Duration(milliseconds: index * 30)).slideX(begin: -0.2);
      },
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shoppingLists')
          .where('isCompleted', isEqualTo: true)
          .orderBy('completedAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return ModernEmptyState(
            icon: Icons.history,
            title: 'Sin historial',
            message: 'Completa listas de compra para ver el historial',
          );
        }

        // Calcular estadísticas
        double totalSpent = 0;
        int totalItems = 0;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final items = (data['items'] as List?) ?? [];
          for (final item in items) {
            totalSpent += (item['total'] as num?)?.toDouble() ?? 0;
            totalItems++;
          }
        }

        return Column(
          children: [
            // Estadísticas
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.receipt_long,
                    label: 'Listas',
                    value: docs.length.toString(),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white30,
                  ),
                  _StatItem(
                    icon: Icons.shopping_basket,
                    label: 'Productos',
                    value: totalItems.toString(),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white30,
                  ),
                  _StatItem(
                    icon: Icons.euro,
                    label: 'Total Gastado',
                    value: '€${totalSpent.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.2),
            // Lista del historial
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  
                  return _HistoryListTile(
                    data: data,
                    docId: doc.id,
                  ).animate().fadeIn(delay: Duration(milliseconds: index * 30));
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Acciones
  Future<void> _createNewList() async {
    final nameController = TextEditingController();
    ShoppingScope scope = ShoppingScope.custom;
    bool makeDefault = false;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
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
              // Título
              Text('Nueva Lista de Compra', style: AppTypography.heading3(context)),
              const SizedBox(height: AppSpacing.md),
              // Nombre
              ModernTextField(
                controller: nameController,
                label: 'Nombre de la lista',
                hint: 'Ej: Compra semanal, Supermercado...',
              ),
              const SizedBox(height: AppSpacing.md),
              // Scope
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tipo de lista', style: AppTypography.label(context)),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        ChoiceChip(
                          label: const Text('Semanal'),
                          selected: scope == ShoppingScope.weekly,
                          onSelected: (v) => setModalState(() => scope = ShoppingScope.weekly),
                        ),
                        ChoiceChip(
                          label: const Text('Quincenal'),
                          selected: scope == ShoppingScope.biweekly,
                          onSelected: (v) => setModalState(() => scope = ShoppingScope.biweekly),
                        ),
                        ChoiceChip(
                          label: const Text('Mensual'),
                          selected: scope == ShoppingScope.monthly,
                          onSelected: (v) => setModalState(() => scope = ShoppingScope.monthly),
                        ),
                        ChoiceChip(
                          label: const Text('Custom'),
                          selected: scope == ShoppingScope.custom,
                          onSelected: (v) => setModalState(() => scope = ShoppingScope.custom),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Predeterminada
              CheckboxListTile(
                value: makeDefault,
                onChanged: (v) => setModalState(() => makeDefault = v ?? false),
                title: const Text('Marcar como predeterminada'),
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.orange,
              ),
              const SizedBox(height: AppSpacing.md),
              // Botones
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
                        'scope': scope,
                        'makeDefault': makeDefault,
                      }),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Crear'),
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

      final listId = await widget.svc.createShoppingList(
        name,
        scope: result['scope'] as ShoppingScope,
        isDefault: result['makeDefault'] as bool,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShoppingListDetailScreenV2(
              svc: widget.svc,
              listId: listId,
            ),
          ),
        );
      }
    }
  }

  void _openListDetail(ShoppingList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingListDetailScreenV2(
          svc: widget.svc,
          listId: list.id,
        ),
      ),
    );
  }

  Future<void> _deleteList(ShoppingList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar lista'),
        content: Text('¿Seguro que quieres eliminar "${list.name}"?'),
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
      await widget.svc.deleteShoppingList(list.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${list.name}" eliminada'),
            backgroundColor: AppColors.success,
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
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}

// Widgets auxiliares
class _ShoppingListCard extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleDefault;

  const _ShoppingListCard({
    required this.list,
    required this.onTap,
    required this.onDelete,
    required this.onToggleDefault,
  });

  @override
  Widget build(BuildContext context) {
    final total = list.items.fold<double>(0, (sum, item) => sum + (item.total ?? 0));
    final purchased = list.items.where((i) => i.purchased).length;
    final progress = list.items.isEmpty ? 0.0 : purchased / list.items.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
            // Header con gradiente
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade600, Colors.orange.shade400],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    list.isDefault ? Icons.star : Icons.shopping_cart,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      list.name,
                      style: AppTypography.heading4(context).copyWith(
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'default') onToggleDefault();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(
                              list.isDefault ? Icons.star_border : Icons.star,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(list.isDefault ? 'Quitar predeterminada' : 'Predeterminada'),
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
                ],
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ModernBadge(
                      text: _getScopeLabel(list.scope),
                      color: Colors.orange,
                    ),
                    const Spacer(),
                    Text(
                      '${list.items.length} productos',
                      style: AppTypography.body(context),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (total > 0)
                      Text(
                        'Estimado: €${total.toStringAsFixed(2)}',
                        style: AppTypography.label(context).copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    // Barra de progreso
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comprado: $purchased/${list.items.length}',
                          style: AppTypography.caption(context),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ModernProgressBar(
                          progress: progress,
                          color: Colors.orange,
                        ),
                      ],
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
    final total = list.items.fold<double>(0, (sum, item) => sum + (item.total ?? 0));
    final purchased = list.items.where((i) => i.purchased).length;
    final progress = list.items.isEmpty ? 0.0 : purchased / list.items.length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
              colors: [Colors.orange.shade600, Colors.orange.shade400],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            list.isDefault ? Icons.star : Icons.shopping_cart,
            color: Colors.white,
          ),
        ),
        title: Text(list.name, style: AppTypography.body(context)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${list.items.length} productos • ${_getScopeLabel(list.scope)}'
              '${total > 0 ? ' • €${total.toStringAsFixed(2)}' : ''}',
              style: AppTypography.caption(context),
            ),
            const SizedBox(height: AppSpacing.xs),
            ModernProgressBar(progress: progress, color: Colors.orange),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'default') onToggleDefault();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'default',
              child: Row(
                children: [
                  Icon(list.isDefault ? Icons.star_border : Icons.star, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(list.isDefault ? 'Quitar predeterminada' : 'Predeterminada'),
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

class _HistoryListTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _HistoryListTile({
    required this.data,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Lista';
    final items = (data['items'] as List?) ?? [];
    final completedAt = data['completedAt'] as Timestamp?;
    final total = items.fold<double>(
      0,
      (sum, item) => sum + ((item['total'] as num?)?.toDouble() ?? 0),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(Icons.check_circle, color: Colors.green.shade600),
        ),
        title: Text(name, style: AppTypography.body(context)),
        subtitle: Text(
          '${items.length} productos • €${total.toStringAsFixed(2)}\n${_formatDate(completedAt)}',
          style: AppTypography.caption(context),
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
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
