import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focuslane/navigation/app_routes.dart';

class ModuleVisibilityDefinition {
  const ModuleVisibilityDefinition({
    required this.route,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String route;
  final String title;
  final String subtitle;
  final IconData icon;
}

class ModuleVisibilityService {
  ModuleVisibilityService._();

  static const String hiddenModulesKey = 'home_modules_hidden';
  static const String orderKey = 'home_modules_order';

  static final ModuleVisibilityService instance = ModuleVisibilityService._();

  static const List<ModuleVisibilityDefinition> modules =
      <ModuleVisibilityDefinition>[
        ModuleVisibilityDefinition(
          route: AppRoutes.calendarDashboard,
          title: 'Calendario',
          subtitle: 'Planificación y agenda',
          icon: Icons.calendar_month_rounded,
        ),
        ModuleVisibilityDefinition(
          route: AppRoutes.tasksDashboard,
          title: 'Tareas',
          subtitle: 'Pendientes y seguimiento diario',
          icon: Icons.check_circle_outline_rounded,
        ),
        ModuleVisibilityDefinition(
          route: AppRoutes.notesDashboard,
          title: 'Notas',
          subtitle: 'Apuntes e ideas rápidas',
          icon: Icons.notes_rounded,
        ),
        ModuleVisibilityDefinition(
          route: '/habits',
          title: 'Hábitos',
          subtitle: 'Rutinas y constancia',
          icon: Icons.repeat_rounded,
        ),
        ModuleVisibilityDefinition(
          route: AppRoutes.studyDashboard,
          title: 'Study',
          subtitle: 'Cursos, sesiones y progreso',
          icon: Icons.school_outlined,
        ),
        ModuleVisibilityDefinition(
          route: AppRoutes.gymDashboard,
          title: 'Gym',
          subtitle: 'Entrenamientos y rendimiento',
          icon: Icons.fitness_center_outlined,
        ),
        ModuleVisibilityDefinition(
          route: AppRoutes.foodDashboard,
          title: 'Food',
          subtitle: 'Comidas, planner y control',
          icon: Icons.restaurant_outlined,
        ),
        ModuleVisibilityDefinition(
          route: AppRoutes.financeDashboard,
          title: 'Finanzas',
          subtitle: 'Movimientos y panorama económico',
          icon: Icons.account_balance_wallet_outlined,
        ),
      ];

  final ValueNotifier<Set<String>> hiddenRoutes = ValueNotifier<Set<String>>(
    <String>{},
  );
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    hiddenRoutes.value =
        (prefs.getStringList(hiddenModulesKey) ?? const <String>[]).toSet();
    _loaded = true;
  }

  bool managesRoute(String route) {
    return modules.any((module) => module.route == route);
  }

  bool isEnabled(String route) => !hiddenRoutes.value.contains(route);

  Future<void> setEnabled(String route, bool enabled) async {
    await ensureLoaded();
    final next = hiddenRoutes.value.toSet();
    if (enabled) {
      next.remove(route);
    } else {
      next.add(route);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(hiddenModulesKey, next.toList()..sort());
    hiddenRoutes.value = next;
  }
}
