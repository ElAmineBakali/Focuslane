import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Focuslane theme + shared UI
import 'package:mi_dashboard_personal/theme/global_ui_theme.dart';
import 'package:mi_dashboard_personal/widgets/module_shell.dart';
import 'package:mi_dashboard_personal/widgets/ui/kpi_compact.dart';

/// Variantes de Home para Focuslane.
/// Cada una es un Scaffold independiente y conviven en paralelo.
///
/// Inspiradas en:
/// 1. Hub Modular
/// 2. Timeline Diario
/// 3. Dashboard KPI
/// 4. Control Central
/// 5. Minimalista Clean

// Utilidades internas para datos demo
class _DemoData {
  static const int habitsDoneToday = 5;
  static const int tasksDueToday = 3;
  static const double studyMinutes = 45;
  static const double spentToday = 23.8;
}

// Acceso rápido a rutas conocidas (ajusta según tus rutas reales)
void _go(BuildContext context, String route) {
  try {
    Navigator.pushNamed(context, route);
  } catch (_) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ruta no disponible aún')));
  }
}

// ---------- V1: Estilo Hub Modular ----------
class HomeScreenV1HubModular extends StatelessWidget {
  const HomeScreenV1HubModular({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FocusModuleShell(
      title: 'Focuslane',
      titleIcon: Icons.apps_rounded,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => _go(context, '/settings'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPIs horizontales
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                KpiCompact(
                  icon: Icons.check_circle,
                  label: 'Hábitos',
                  value: '${_DemoData.habitsDoneToday}',
                  sub: 'Completados hoy',
                ),
                KpiCompact(
                  icon: Icons.event_available,
                  label: 'Tareas',
                  value: '${_DemoData.tasksDueToday}',
                  sub: 'Vencen hoy',
                ),
                KpiCompact(
                  icon: Icons.menu_book,
                  label: 'Estudio',
                  value: '${_DemoData.studyMinutes} min',
                  sub: 'Sesión actual',
                ),
                KpiCompact(
                  icon: Icons.payments,
                  label: 'Gasto',
                  value: '€${_DemoData.spentToday.toStringAsFixed(2)}',
                  sub: 'Hoy',
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),

          const SizedBox(height: AppSpacing.lg),

          Text('Módulos', style: AppTypography.heading3(context)),
          const SizedBox(height: AppSpacing.md),

          // Tarjetas grandes por módulo
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width < 700 ? 2 : 3,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.1,
            children: [
              _ModuleCard(
                color: AppColors.gym,
                title: 'Gym',
                icon: Icons.fitness_center,
                onView: () => _go(context, '/gym'),
                onAdd: () => _go(context, '/gym/routines'),
                summary: '2 sesiones esta semana',
              ),
              _ModuleCard(
                color: AppColors.study,
                title: 'Study',
                icon: Icons.menu_book,
                onView: () => _go(context, '/study'),
                onAdd: () => _go(context, '/study/sessions'),
                summary: '45 min hoy',
              ),
              _ModuleCard(
                color: AppColors.finance,
                title: 'Finance',
                icon: Icons.attach_money,
                onView: () => _go(context, '/finance'),
                onAdd: () => _go(context, '/finance/transactions'),
                summary: '€23.80 hoy',
              ),
              _ModuleCard(
                color: AppColors.habits,
                title: 'Habits',
                icon: Icons.checklist_rtl,
                onView: () => _go(context, '/habits'),
                onAdd: () => _go(context, '/habits/new'),
                summary: '5/8 completos',
              ),
              _ModuleCard(
                color: AppColors.goals,
                title: 'Goals',
                icon: Icons.flag,
                onView: () => _go(context, '/goals'),
                onAdd: () => _go(context, '/goals/new'),
                summary: '1 objetivo en foco',
              ),
              _ModuleCard(
                color: AppColors.meditation,
                title: 'Meditation',
                icon: Icons.self_improvement,
                onView: () => _go(context, '/meditation'),
                onAdd: () => _go(context, '/meditation/session'),
                summary: '10 min promedio',
              ),
            ],
          ).animate().fadeIn(duration: 500.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: AppSpacing.lg),

          // Acciones rápidas
          Text('Accesos rápidos', style: AppTypography.heading4(context)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _QuickAction(
                label: 'Añadir tarea',
                icon: Icons.add_task,
                color: cs.primary,
                onTap: () => _go(context, '/tasks/new'),
              ),
              _QuickAction(
                label: 'Registrar gasto',
                icon: Icons.receipt_long,
                color: cs.secondary,
                onTap: () => _go(context, '/finance/transactions/new'),
              ),
              _QuickAction(
                label: 'Nueva sesión Gym',
                icon: Icons.timer,
                color: AppColors.gym,
                onTap: () => _go(context, '/gym'),
              ),
              _QuickAction(
                label: 'Notas rápidas',
                icon: Icons.note_add,
                color: cs.tertiary,
                onTap: () => _go(context, '/notes/new'),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _go(context, '/tasks/new'),
        label: const Text('Añadir'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

// ---------- V2: Estilo Timeline Diario ----------
class HomeScreenV2DailyTimeline extends StatelessWidget {
  const HomeScreenV2DailyTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    int segment = 0; // 0 mañana, 1 tarde, 2 noche
    if (now.hour >= 12 && now.hour < 18) {
      segment = 1;
    } else if (now.hour >= 18) {
      segment = 2;
    }

    return FocusModuleShell(
      title: 'Tu día',
      titleIcon: Icons.calendar_today,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DaySegment(
            title: 'Mañana',
            highlight: segment == 0,
            items: const [
              _TimelineItem(
                icon: Icons.checklist,
                title: 'Revisión de tareas',
                subtitle: 'Prioriza las 3 más importantes',
              ),
              _TimelineItem(
                icon: Icons.menu_book,
                title: 'Bloque de estudio',
                subtitle: '45 min • Matemáticas',
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: AppSpacing.md),
          _DaySegment(
            title: 'Tarde',
            highlight: segment == 1,
            items: const [
              _TimelineItem(
                icon: Icons.fitness_center,
                title: 'Sesión Gym',
                subtitle: 'Empuje • 60 min',
              ),
              _TimelineItem(
                icon: Icons.flag,
                title: 'Objetivo mensual',
                subtitle: 'Avance del 10%',
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
          const SizedBox(height: AppSpacing.md),
          _DaySegment(
            title: 'Noche',
            highlight: segment == 2,
            items: const [
              _TimelineItem(
                icon: Icons.self_improvement,
                title: 'Meditación',
                subtitle: '10 min • Resp. guiada',
              ),
              _TimelineItem(
                icon: Icons.receipt_long,
                title: 'Registro de gastos',
                subtitle: 'Cierra el día',
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
        ],
      ),
    );
  }
}

// ---------- V3: Estilo Dashboard KPI ----------
class HomeScreenV3DashboardKPI extends StatelessWidget {
  const HomeScreenV3DashboardKPI({super.key});

  @override
  Widget build(BuildContext context) {
    return FocusModuleShell(
      title: 'Panel',
      titleIcon: Icons.dashboard_rounded,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                KpiCompact(
                  icon: Icons.check_circle,
                  label: 'Hábitos',
                  value: '5',
                  sub: 'Hoy',
                ),
                KpiCompact(
                  icon: Icons.event_available,
                  label: 'Tareas',
                  value: '3',
                  sub: 'Pendientes',
                ),
                KpiCompact(
                  icon: Icons.menu_book,
                  label: 'Estudio',
                  value: '45 min',
                  sub: 'Semana',
                ),
                KpiCompact(
                  icon: Icons.attach_money,
                  label: 'Gasto',
                  value: '€23.80',
                  sub: 'Hoy',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Indicadores', style: AppTypography.heading3(context)),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width < 700 ? 1 : 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.6,
            children: [
              _KpiCard(
                title: 'Hábitos completados',
                value: 5,
                target: 8,
                color: AppColors.habits,
                icon: Icons.auto_graph,
              ),
              _KpiCard(
                title: 'Progreso de estudio',
                value: 3,
                target: 5,
                color: AppColors.study,
                icon: Icons.menu_book,
              ),
              _KpiCard(
                title: 'Gasto diario',
                value: 24,
                target: 30,
                color: AppColors.finance,
                icon: Icons.payments,
              ),
              _KpiCard(
                title: 'Sesiones de Gym',
                value: 2,
                target: 4,
                color: AppColors.gym,
                icon: Icons.fitness_center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- V4: Estilo Control Central ----------
class HomeScreenV4ControlCenter extends StatelessWidget {
  const HomeScreenV4ControlCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return FocusModuleShell(
      title: 'Control',
      titleIcon: Icons.tune,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _go(context, '/search'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Acciones frecuentes', style: AppTypography.heading3(context)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _QuickButton(
                label: 'Añadir tarea',
                icon: Icons.add_task,
                onTap: () => _go(context, '/tasks/new'),
              ),
              _QuickButton(
                label: 'Registrar gasto',
                icon: Icons.receipt_long,
                onTap: () => _go(context, '/finance/transactions/new'),
              ),
              _QuickButton(
                label: 'Nueva nota',
                icon: Icons.note_add,
                onTap: () => _go(context, '/notes/new'),
              ),
              _QuickButton(
                label: 'Sesión Gym',
                icon: Icons.timer,
                onTap: () => _go(context, '/gym'),
              ),
              _QuickButton(
                label: 'Estudiar 25m',
                icon: Icons.menu_book,
                onTap: () => _go(context, '/study/session/start'),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: AppSpacing.xl),

          Text('Módulos', style: AppTypography.heading3(context)),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ModuleShortcut(
                  'Gym',
                  Icons.fitness_center,
                  AppColors.gym,
                  () => _go(context, '/gym'),
                ),
                _ModuleShortcut(
                  'Study',
                  Icons.menu_book,
                  AppColors.study,
                  () => _go(context, '/study'),
                ),
                _ModuleShortcut(
                  'Finance',
                  Icons.attach_money,
                  AppColors.finance,
                  () => _go(context, '/finance'),
                ),
                _ModuleShortcut(
                  'Habits',
                  Icons.checklist_rtl,
                  AppColors.habits,
                  () => _go(context, '/habits'),
                ),
                _ModuleShortcut(
                  'Goals',
                  Icons.flag,
                  AppColors.goals,
                  () => _go(context, '/goals'),
                ),
                _ModuleShortcut(
                  'Meditation',
                  Icons.self_improvement,
                  AppColors.meditation,
                  () => _go(context, '/meditation'),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          Text('Panel rápido', style: AppTypography.heading3(context)),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width < 700 ? 1 : 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.6,
            children: const [
              _QuickPanelCard(
                title: 'Tareas hoy',
                icon: Icons.event_available,
                value: '3 pendientes',
              ),
              _QuickPanelCard(
                title: 'Gasto',
                icon: Icons.payments,
                value: '€23.80 • hoy',
              ),
              _QuickPanelCard(
                title: 'Estudio',
                icon: Icons.menu_book,
                value: '45 min • esta semana',
              ),
              _QuickPanelCard(
                title: 'Hábitos',
                icon: Icons.check_circle,
                value: '5/8 completados',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- V5: Estilo Minimalista Clean ----------
class HomeScreenV5MinimalClean extends StatelessWidget {
  const HomeScreenV5MinimalClean({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Focuslane',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lo más urgente', style: AppTypography.heading3(context)),
            const SizedBox(height: AppSpacing.md),
            const _MinimalItem(
              title: 'Entregar informe',
              subtitle: 'Hoy • Study',
            ),
            const _MinimalItem(
              title: 'Pagar suscripción',
              subtitle: 'Mañana • Finance',
            ),
            const _MinimalItem(title: 'Sesión Gym', subtitle: '19:00'),
            const _MinimalItem(title: 'Meditación', subtitle: '10 min'),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => _go(context, '/tasks/new'),
              icon: const Icon(Icons.add),
              label: const Text('Añadir rápido'),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Siguientes', style: AppTypography.heading4(context)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Mantén el enfoque en lo imprescindible. Esta vista es limpia, clara y sin ruido visual.',
              style: AppTypography.body(context, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Selector/Galería para probar variantes ----------
class HomeVariantsGallery extends StatelessWidget {
  const HomeVariantsGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final variants = <_VariantEntry>[
      _VariantEntry('Hub Modular', const HomeScreenV1HubModular()),
      _VariantEntry('Timeline Diario', const HomeScreenV2DailyTimeline()),
      _VariantEntry('Dashboard KPI', const HomeScreenV3DashboardKPI()),
      _VariantEntry('Control Central', const HomeScreenV4ControlCenter()),
      _VariantEntry('Minimalista Clean', const HomeScreenV5MinimalClean()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Variantes de Home')),
      body: ListView.separated(
        itemCount: variants.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final v = variants[i];
          return ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(v.title),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => v.widget),
                ),
          );
        },
      ),
    );
  }
}

class _VariantEntry {
  final String title;
  final Widget widget;
  const _VariantEntry(this.title, this.widget);
}

// ---------- Widgets auxiliares ----------
class _ModuleCard extends StatelessWidget {
  final Color color;
  final String title;
  final String summary;
  final IconData icon;
  final VoidCallback onView;
  final VoidCallback onAdd;

  const _ModuleCard({
    required this.color,
    required this.title,
    required this.icon,
    required this.onView,
    required this.onAdd,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppSpacing.elevationMd,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withAlpha(204)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 36),
                const Spacer(),
                Text(
                  title,
                  style: AppTypography.heading3(context, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  summary,
                  style: AppTypography.caption(context, color: Colors.white70),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _PillButton(
                      label: 'Ver',
                      icon: Icons.open_in_new,
                      onTap: onView,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _PillButton(label: 'Añadir', icon: Icons.add, onTap: onAdd),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.98, 0.98));
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PillButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(51),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withAlpha(102)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.label(context, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, color: color),
      label: Text(label),
      elevation: 2,
    );
  }
}

class _DaySegment extends StatelessWidget {
  final String title;
  final bool highlight;
  final List<_TimelineItem> items;
  const _DaySegment({
    required this.title,
    required this.highlight,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: highlight ? AppSpacing.elevationLg : AppSpacing.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: AppTypography.heading3(context)),
                const Spacer(),
                if (highlight)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Ahora',
                      style: AppTypography.caption(context, color: cs.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...items,
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: cs.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.heading4(context)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption(
                    context,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final int value;
  final int target;
  final Color color;
  final IconData icon;
  const _KpiCard({
    required this.title,
    required this.value,
    required this.target,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / target).clamp(0.0, 1.0);
    return Card(
      elevation: AppSpacing.elevationMd,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(title, style: AppTypography.heading4(context)),
                ),
                Text('$value/$target'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(value: progress, color: color),
            const SizedBox(height: AppSpacing.sm),
            Text('Objetivo', style: AppTypography.caption(context)),
          ],
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _ModuleShortcut extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ModuleShortcut(this.title, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            gradient: LinearGradient(
              colors: [color, color.withAlpha(204)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white),
              const Spacer(),
              Text(
                title,
                style: AppTypography.label(context, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickPanelCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  const _QuickPanelCard({
    required this.title,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: AppSpacing.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cs.primary),
                const SizedBox(width: AppSpacing.md),
                Text(title, style: AppTypography.heading4(context)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(value, style: AppTypography.body(context)),
          ],
        ),
      ),
    );
  }
}

class _MinimalItem extends StatelessWidget {
  final String title;
  final String subtitle;
  const _MinimalItem({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.heading4(context)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption(
                    context,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}
