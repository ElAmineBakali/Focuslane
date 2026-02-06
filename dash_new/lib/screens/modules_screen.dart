import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_dashboard_personal/navigation/app_routes.dart';

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModuleRow {
  final String route;
  final String title;
  final IconData icon;
  bool visible;
  _ModuleRow({
    required this.route,
    required this.title,
    required this.icon,
    required this.visible,
  });
}

class _ModulesScreenState extends State<ModulesScreen> {
  static const _kOrder = 'home_modules_order';
  static const _kHidden = 'home_modules_hidden';

  List<_ModuleRow> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final order = sp.getStringList(_kOrder);
    final hidden = (sp.getStringList(_kHidden) ?? const <String>[]).toSet();

    const base = [
      ('/calendar', 'Calendario', Icons.calendar_month),
      ('/tasks', 'Tareas', Icons.check_circle_outlined),
      ('/notes', 'Notas', Icons.notes_outlined),
      ('/habits', 'Hábitos', Icons.checklist_outlined),
      (AppRoutes.studyDashboard, 'Estudio', Icons.school_outlined),
      (AppRoutes.gymDashboard, 'Gimnasio', Icons.fitness_center_outlined),
      ('/meditation', 'Meditación', Icons.self_improvement_outlined),
      (AppRoutes.foodDashboard, 'Food', Icons.restaurant_outlined),
      ('/finance', 'Finanzas', Icons.account_balance_wallet_outlined),
      ('/trading', 'Trading', Icons.candlestick_chart),
      ('/culture', 'Cultura', Icons.smart_display),
      ('/skills', 'Hobbies', Icons.interests),
      ('/ropa', 'Ropa', Icons.checkroom),
      ('/goals', 'Metas', Icons.sports_score),
    ];

    final byRoute = {for (final t in base) t.$1: t};
    final orderedRoutes = order ?? base.map((t) => t.$1).toList();

    final rows = <_ModuleRow>[
      for (final r in orderedRoutes)
        if (byRoute.containsKey(r))
          _ModuleRow(
            route: r,
            title: byRoute[r]!.$2,
            icon: byRoute[r]!.$3,
            visible: !hidden.contains(r),
          ),
    ];

    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_kOrder, _rows.map((e) => e.route).toList());
    await sp.setStringList(
      _kHidden,
      _rows.where((e) => !e.visible).map((e) => e.route).toList(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Módulos guardados'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulos de inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Revertir cambios no guardados',
            onPressed: _load,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _rows.length,
                          onReorder: (oldIndex, newIndex) async {
                            if (newIndex > oldIndex) newIndex--;
                            final item = _rows.removeAt(oldIndex);
                            _rows.insert(newIndex, item);
                            setState(() {});
                            await _save();
                          },
                          itemBuilder: (context, i) {
                            final r = _rows[i];
                            return SwitchListTile.adaptive(
                              key: ValueKey(r.route),
                              value: r.visible,
                              onChanged: (v) async {
                                setState(() => r.visible = v);
                                await _save();
                              },
                              title: Row(
                                children: [
                                  const Icon(
                                    Icons.drag_handle_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(r.icon, size: 20),
                                  const SizedBox(width: 8),
                                  Text(r.title),
                                ],
                              ),
                              subtitle: Text(
                                r.route,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tip: mantén pulsado un módulo en la Home para abrir esta pantalla.',
                    ),
                  ],
                ),
      ),
    );
  }
}
