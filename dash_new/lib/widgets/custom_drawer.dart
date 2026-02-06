import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/navigation/app_routes.dart';

class CustomDrawer extends StatelessWidget {
  final Function(bool) toggleTheme;
  final ThemeMode themeMode;

  const CustomDrawer({
    super.key,
    required this.toggleTheme,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: Container(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: theme.colorScheme.primary),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Mi Dashboard',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerTile(
                      context,
                      Icons.calendar_month,
                      'Calendario',
                    ),
                    _buildDrawerTile(context, Icons.task, 'Tareas', '/tasks'),
                    _buildDrawerTile(context, Icons.notes, 'Notas', '/notes'),
                    _buildDrawerTile(
                      context,
                      Icons.check_circle_outline,
                      'Hábitos',
                      '/habits',
                    ),
                    _buildDrawerTile(
                      context,
                      Icons.backpack,
                      'Estudio',
                      AppRoutes.studyDashboard,
                    ),
                    _buildDrawerTile(
                      context,
                      Icons.fitness_center,
                      'Gimnasio',
                      AppRoutes.gymDashboard,
                    ),
                    _buildDrawerTile(
                      context,
                      Icons.self_improvement,
                      'Meditación',
                      '/meditation',
                    ),
                    _buildDrawerTile(
                      context,
                      Icons.restaurant,
                      'Alimentación',
                      AppRoutes.foodDashboard,
                    ),
                    _buildDrawerTile(
                      context,
                      Icons.currency_exchange,
                      'Finanzas',
                      '/finance',
                    ),
                    _buildDrawerTile(
                      context,
                      Icons.candlestick_chart,
                      'Trading',
                      '/trading',
                    ),
                    _buildDrawerTile(
                      context,
                      Icons.candlestick_chart,
                      'Cultura',
                      '/culture',
                    ),
                    _buildDrawerTile(
                      context,
                      Icons.candlestick_chart,
                      'Hobbies',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: 'Ajustes',
                    onPressed:
                        () => Navigator.of(context).pushNamed('/settings'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context,
    IconData icon,
    String title, [
    String? route,
  ]) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.iconTheme.color),
      title: Text(title, style: theme.textTheme.bodyLarge),
      onTap: () {
        if (route != null) Navigator.of(context).pushNamed(route);
      },
    );
  }
}
