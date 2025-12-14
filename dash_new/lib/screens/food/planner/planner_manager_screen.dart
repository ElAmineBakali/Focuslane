import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/global_ui_components.dart';
import '../services/food_service_facade.dart';
import '../models/food_models.dart';
import 'planner_detail_screen.dart';

/// 📅 PLANNER MANAGER SCREEN
/// Gestión de múltiples planificadores semanales
class PlannerManagerScreen extends StatefulWidget {
  final FoodServiceFacade svc;
  const PlannerManagerScreen({super.key, required this.svc});

  @override
  State<PlannerManagerScreen> createState() => _PlannerManagerScreenState();
}

class _PlannerManagerScreenState extends State<PlannerManagerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 Planificadores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo planificador',
            onPressed: () => _showCreateSheet(context),
          ),
        ],
      ),
      body: StreamBuilder<List<WeekPlanner>>(
        stream: widget.svc.planner.streamPlanners(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final planners = snap.data ?? [];

          if (planners.isEmpty) {
            return FocusEmptyState(
              icon: Icons.calendar_view_week,
              message: 'Sin planificadores aún',
              subtitle: 'Crea un planificador semanal para organizar tus comidas',
              actionLabel: 'Crear Planificador',
              onAction: () => _showCreateSheet(context),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(FocusSpacing.lg),
            itemCount: planners.length,
            itemBuilder: (_, i) {
              final planner = planners[i];
              return _buildPlannerCard(context, planner, i);
            },
          );
        },
      ),
    );
  }

  Widget _buildPlannerCard(
      BuildContext context, WeekPlanner planner, int index) {
    final theme = Theme.of(context);

    // Contar recetas del planificador
    final totalMeals = planner.dayMap.values
        .expand((day) => [
              ...day.breakfast,
              ...day.lunch,
              ...day.dinner,
              ...day.snack,
            ])
        .length;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: FocusSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlannerDetailScreen(
                svc: widget.svc,
                plannerId: planner.id,
              ),
            ),
          );
        },
        onLongPress: () => _showOptionsSheet(context, planner),
        borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(FocusSpacing.lg),
          child: Row(
            children: [
              // Icono
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.calendar_view_week,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: FocusSpacing.lg),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planner.name,
                      style: FocusTypography.heading3(context),
                    ),
                    const SizedBox(height: FocusSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 16,
                          color: FocusColors.grey600,
                        ),
                        const SizedBox(width: FocusSpacing.xs),
                        Text(
                          '$totalMeals comidas',
                          style: FocusTypography.caption(context),
                        ),
                        const SizedBox(width: FocusSpacing.md),
                        if (planner.customMultiplier != null) ...[
                          Icon(
                            Icons.tune,
                            size: 16,
                            color: FocusColors.info,
                          ),
                          const SizedBox(width: FocusSpacing.xs),
                          Text(
                            '×${planner.customMultiplier}',
                            style: FocusTypography.caption(context).copyWith(
                              color: FocusColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Botón de opciones
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showOptionsSheet(context, planner),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 50).ms)
        .slideX(begin: -0.2, end: 0, delay: (index * 50).ms);
  }

  Future<void> _showCreateSheet(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final multiplierCtrl = TextEditingController(text: '1.0');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: FocusSpacing.lg,
            right: FocusSpacing.lg,
            top: FocusSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + FocusSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nuevo Planificador',
                style: FocusTypography.heading2(context),
              ),
              const SizedBox(height: FocusSpacing.lg),

              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Volumen, Definición, Mantenimiento...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                  ),
                  prefixIcon: const Icon(Icons.label),
                ),
              ),

              const SizedBox(height: FocusSpacing.md),

              TextField(
                controller: multiplierCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Multiplicador (opcional)',
                  hintText: '1.0',
                  helperText: 'Para escalar cantidades del menú',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                  ),
                  prefixIcon: const Icon(Icons.tune),
                ),
              ),

              const SizedBox(height: FocusSpacing.lg),

              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Ingresa un nombre')),
                    );
                    return;
                  }

                  final multiplier = double.tryParse(multiplierCtrl.text);

                  await widget.svc.planner.createPlanner(
                    name: nameCtrl.text,
                    customMultiplier: multiplier,
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Planificador creado')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Crear'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showOptionsSheet(
      BuildContext context, WeekPlanner planner) async {
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Ver detalle'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlannerDetailScreen(
                      svc: widget.svc,
                      plannerId: planner.id,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Renombrar'),
              onTap: () {
                Navigator.pop(context);
                _showRenameSheet(context, planner);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Ajustar multiplicador'),
              onTap: () {
                Navigator.pop(context);
                _showMultiplierSheet(context, planner);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Generar lista de compras'),
              onTap: () async {
                Navigator.pop(context);
                await widget.svc.planner.generateShoppingFromPlanner(
                  plannerId: planner.id,
                  multiplier: planner.customMultiplier,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Lista de compras generada'),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title:
                  const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await _confirmDelete(context, planner);
                if (confirm == true) {
                  await widget.svc.planner.deletePlanner(planner.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🗑️ Planificador eliminado')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameSheet(
      BuildContext context, WeekPlanner planner) async {
    final nameCtrl = TextEditingController(text: planner.name);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: FocusSpacing.lg,
            right: FocusSpacing.lg,
            top: FocusSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + FocusSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Renombrar Planificador',
                style: FocusTypography.heading2(context),
              ),
              const SizedBox(height: FocusSpacing.lg),

              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nuevo nombre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                  ),
                ),
              ),

              const SizedBox(height: FocusSpacing.lg),

              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Ingresa un nombre')),
                    );
                    return;
                  }

                  final updated = planner.copyWith(name: nameCtrl.text);
                  await widget.svc.planner.updatePlanner(updated);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Planificador renombrado')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMultiplierSheet(
      BuildContext context, WeekPlanner planner) async {
    final multiplierCtrl = TextEditingController(
      text: planner.customMultiplier?.toString() ?? '1.0',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: FocusSpacing.lg,
            right: FocusSpacing.lg,
            top: FocusSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + FocusSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajustar Multiplicador',
                style: FocusTypography.heading2(context),
              ),
              const SizedBox(height: FocusSpacing.sm),
              Text(
                'Escala las cantidades del menú semanal',
                style: FocusTypography.caption(context),
              ),
              const SizedBox(height: FocusSpacing.lg),

              TextField(
                controller: multiplierCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Multiplicador',
                  hintText: '1.0',
                  helperText: 'Ejemplo: 1.5 = 50% más cantidad',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                  ),
                  prefixIcon: const Icon(Icons.tune),
                ),
              ),

              const SizedBox(height: FocusSpacing.lg),

              ElevatedButton(
                onPressed: () async {
                  final multiplier = double.tryParse(multiplierCtrl.text);

                  final updated = planner.copyWith(
                    customMultiplier: multiplier,
                  );
                  await widget.svc.planner.updatePlanner(updated);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Multiplicador actualizado')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, WeekPlanner planner) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Planificador'),
        content: Text(
          '¿Estás seguro de eliminar "${planner.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
