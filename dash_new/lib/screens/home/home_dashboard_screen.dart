import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:focuslane/core/constants/app_strings.dart';
import 'package:focuslane/design/ui/layouts/module_scaffold.dart';
import 'package:focuslane/design/ui/tokens/focuslane_semantic_tokens.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';

import 'home_dashboard_controller.dart';
import 'models/dashboard_summary_model.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
    super.key,
    required this.toggleTheme,
    required this.themeMode,
  });

  final void Function(bool isDark) toggleTheme;
  final ThemeMode themeMode;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  static const double _mobileMax = 760;
  static const double _tabletMax = 1180;

  late final HomeDashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeDashboardController(
      studyService: StudyFirestoreService(),
      gymService: GymFirestoreService(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      child: LayoutBuilder(
        builder: (context, rootConstraints) {
          final isMobile = rootConstraints.maxWidth < _mobileMax;

          return Scaffold(
            backgroundColor: FocuslaneSemanticTokens.backgroundMain(context),
            appBar: isMobile
                ? AppBar(
                    title: const Text(AppStrings.dashboard),
                    centerTitle: false,
                    scrolledUnderElevation: 0,
                  )
                : null,
            drawer: isMobile
                ? Drawer(
                    backgroundColor: FocuslaneSemanticTokens.backgroundMain(context),
                    child: SafeArea(
                      child: _PortalSidebar(
                        asDrawer: true,
                        onRoute: (route) {
                          Navigator.of(context).pop();
                          _openRoute(route);
                        },
                      ),
                    ),
                  )
                : null,
            body: SafeArea(
              top: !isMobile,
              child: StreamBuilder<DashboardSummaryModel>(
                stream: _controller.streamSummary(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return _CenteredMessage(
                      title: AppStrings.noDashboardDataTitle,
                      subtitle: AppStrings.noDashboardDataSubtitle,
                      actionLabel: AppStrings.retry,
                      onTap: () => setState(() {}),
                    );
                  }

                  final summary = snapshot.data!;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;

                      if (width < _mobileMax) {
                        return _MobileDashboard(
                          summary: summary,
                          controller: _controller,
                          onRoute: _openRoute,
                        );
                      }

                      if (width < _tabletMax) {
                        return _TabletDashboard(
                          summary: summary,
                          controller: _controller,
                          onRoute: _openRoute,
                        );
                      }

                      return _DesktopDashboard(
                        summary: summary,
                        controller: _controller,
                        onRoute: _openRoute,
                        toggleTheme: widget.toggleTheme,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _openRoute(String route) {
    Navigator.of(context).pushNamed(route);
  }
}

class _DesktopDashboard extends StatelessWidget {
  const _DesktopDashboard({
    required this.summary,
    required this.controller,
    required this.onRoute,
    required this.toggleTheme,
  });

  final DashboardSummaryModel summary;
  final HomeDashboardController controller;
  final void Function(String route) onRoute;
  final void Function(bool isDark) toggleTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PortalSidebar(onRoute: onRoute),
        Expanded(
          child: Column(
            children: [
              _PortalTopBar(
                title: AppStrings.dashboard,
                toggleTheme: toggleTheme,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PortalHero(
                        greeting: controller.greetingFor(summary.today),
                        dateLabel: controller.dayLabel(summary.today),
                      ),
                      const SizedBox(height: 16),
                      _KpiGrid(summary: summary, onRoute: onRoute, columns: 4),
                      const SizedBox(height: 16),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _TodayTasksCard(summary: summary, onRoute: onRoute),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: _QuickActionsCard(onRoute: onRoute),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _HabitsCard(summary: summary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: _UpcomingCard(summary: summary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: _HighlightsCard(summary: summary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _WeeklyProgressCard(summary: summary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: _RecentActivityCard(summary: summary, onRoute: onRoute),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: _ModuleLinksCard(onRoute: onRoute),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabletDashboard extends StatelessWidget {
  const _TabletDashboard({
    required this.summary,
    required this.controller,
    required this.onRoute,
  });

  final DashboardSummaryModel summary;
  final HomeDashboardController controller;
  final void Function(String route) onRoute;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _TabletHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PortalHero(
                  greeting: controller.greetingFor(summary.today),
                  dateLabel: controller.dayLabel(summary.today),
                  compact: true,
                ),
                const SizedBox(height: 16),
                _KpiGrid(summary: summary, onRoute: onRoute, columns: 2),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _TodayTasksCard(summary: summary, onRoute: onRoute)),
                      const SizedBox(width: 16),
                      Expanded(child: _QuickActionsCard(onRoute: onRoute)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 2, child: _HabitsCard(summary: summary)),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: _UpcomingCard(summary: summary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _HighlightsCard(summary: summary)),
                      const SizedBox(width: 16),
                      Expanded(child: _ModuleLinksCard(onRoute: onRoute)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 2, child: _WeeklyProgressCard(summary: summary)),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: _RecentActivityCard(summary: summary, onRoute: onRoute)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileDashboard extends StatelessWidget {
  const _MobileDashboard({
    required this.summary,
    required this.controller,
    required this.onRoute,
  });

  final DashboardSummaryModel summary;
  final HomeDashboardController controller;
  final void Function(String route) onRoute;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        _PortalHero(
          greeting: controller.greetingFor(summary.today),
          dateLabel: controller.dayLabel(summary.today),
          compact: true,
        ),
        const SizedBox(height: 16),
        _KpiGrid(summary: summary, onRoute: onRoute, columns: 2),
        const SizedBox(height: 16),
        _TodayTasksCard(summary: summary, onRoute: onRoute),
        const SizedBox(height: 16),
        _QuickActionsCard(onRoute: onRoute),
        const SizedBox(height: 16),
        _HabitsCard(summary: summary),
        const SizedBox(height: 16),
        _UpcomingCard(summary: summary),
        const SizedBox(height: 16),
        _HighlightsCard(summary: summary),
        const SizedBox(height: 16),
        _WeeklyProgressCard(summary: summary),
        const SizedBox(height: 16),
        _RecentActivityCard(summary: summary, onRoute: onRoute),
        const SizedBox(height: 16),
        _ModuleLinksCard(onRoute: onRoute),
      ],
    );
  }
}

class _PortalSidebar extends StatelessWidget {
  const _PortalSidebar({required this.onRoute, this.asDrawer = false});

  final void Function(String route) onRoute;
  final bool asDrawer;

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(AppStrings.moduloTareas, Icons.task_alt_outlined, AppRoutes.tasksDashboard),
      _NavItem(AppStrings.moduloHabitos, Icons.repeat, '/habits'),
      _NavItem(AppStrings.moduloNotas, Icons.note_alt_outlined, AppRoutes.notesDashboard),
      _NavItem(AppStrings.moduloCalendario, Icons.calendar_today_outlined, AppRoutes.calendarDashboard),
      _NavItem(AppStrings.moduloGym, Icons.fitness_center_outlined, AppRoutes.gymDashboard),
      _NavItem(AppStrings.moduloNutricion, Icons.restaurant_outlined, AppRoutes.foodDashboard),
      _NavItem(AppStrings.moduloFinanzas, Icons.account_balance_wallet_outlined, AppRoutes.financeDashboard),
      _NavItem(AppStrings.moduloEstudio, Icons.school_outlined, AppRoutes.studyDashboard),
    ];

    return Container(
      width: asDrawer ? double.infinity : 210,
      decoration: BoxDecoration(
        color: FocuslaneSemanticTokens.backgroundMain(context),
        border: asDrawer
            ? null
            : Border(
                right: BorderSide(color: FocuslaneSemanticTokens.border(context)),
              ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(radius: 15, child: Icon(Icons.person, size: 16)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.usuario, style: TextStyle(color: FocuslaneSemanticTokens.primary(context), fontWeight: FontWeight.w700)),
                  Text(AppStrings.portalProductividad, style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => onRoute('/tasks/create'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(AppStrings.nuevaEntrada),
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: item.label == AppStrings.moduloTareas ? FocuslaneSemanticTokens.sidebarActiveBackground(context) : Colors.transparent,
                onTap: () => onRoute(item.route),
                leading: Icon(item.icon, size: 18, color: item.label == AppStrings.moduloTareas ? FocuslaneSemanticTokens.primary(context) : FocuslaneSemanticTokens.textSecondary(context)),
                title: Text(item.label, style: TextStyle(color: item.label == AppStrings.moduloTareas ? FocuslaneSemanticTokens.primary(context) : FocuslaneSemanticTokens.textSecondary(context), fontSize: 14)),
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: ListTile(
              dense: true,
              onTap: () => onRoute('/settings'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              leading: Icon(Icons.settings_outlined, size: 18, color: FocuslaneSemanticTokens.textSecondary(context)),
              title: Text(AppStrings.ajustes, style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalTopBar extends StatelessWidget {
  const _PortalTopBar({required this.title, required this.toggleTheme});

  final String title;
  final void Function(bool isDark) toggleTheme;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: FocuslaneSemanticTokens.border(context))),
      ),
      child: Row(
        children: [
          Text(AppStrings.buenasTardes, style: TextStyle(color: FocuslaneSemanticTokens.primary(context), fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(width: 10),
          Text('/ $title', style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context))),
          const Spacer(),
          SizedBox(
            width: 240,
            child: TextField(
              decoration: const InputDecoration(
                hintText: AppStrings.buscarEntradas,
                suffixIcon: Icon(Icons.search, size: 16),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, size: 18)),
          IconButton(
            onPressed: () => toggleTheme(!isDark),
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 18),
          ),
        ],
      ),
    );
  }
}

class _TabletHeader extends StatelessWidget {
  const _TabletHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: FocuslaneSemanticTokens.border(context))),
      ),
      child: Row(
        children: [
          Text(AppStrings.dashboard, style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 18)),
          const Spacer(),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search, size: 18)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, size: 18)),
        ],
      ),
    );
  }
}

class _PortalHero extends StatelessWidget {
  const _PortalHero({required this.greeting, required this.dateLabel, this.compact = false});

  final String greeting;
  final String dateLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.heroTitle,
          style: TextStyle(
            color: FocuslaneSemanticTokens.textPrimary(context),
            fontSize: compact ? 28 : 42,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$greeting Â· $dateLabel',
          style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context)),
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.heroSubtitle,
          style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: compact ? 13 : 14),
        ),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary, required this.onRoute, required this.columns});

  final DashboardSummaryModel summary;
  final void Function(String route) onRoute;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiItem(AppStrings.kpiTareas, '${summary.pendingTasksToday}', AppStrings.kpiPendientesHoy, Icons.task_alt_outlined, AppRoutes.tasksDashboard),
      _KpiItem(AppStrings.kpiHabitos, '${summary.completedHabitsToday}/${summary.habits.length}', AppStrings.kpiCompletados, Icons.repeat, '/habits'),
      _KpiItem(AppStrings.kpiEventos, '${summary.upcomingEvents.length}', AppStrings.kpiProximos, Icons.calendar_today_outlined, AppRoutes.calendarDashboard),
      _KpiItem(
        AppStrings.kpiGymStudy,
        summary.defaultGymRoutineName ?? AppStrings.sinRutina,
        summary.latestStudySession == null ? AppStrings.sinSesionEstudio : AppStrings.sesionEstudioMinutos(summary.latestStudySession!.minutes),
        Icons.insights_outlined,
        AppRoutes.studyDashboard,
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: columns == 4 ? 2.05 : 1.8,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () => onRoute(item.route),
          borderRadius: BorderRadius.circular(12),
          child: _Panel(
            child: Row(
              children: [
                Icon(item.icon, color: FocuslaneSemanticTokens.primary(context), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.title, style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(item.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: FocuslaneSemanticTokens.textSecondary(context)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TodayTasksCard extends StatelessWidget {
  const _TodayTasksCard({required this.summary, required this.onRoute});

  final DashboardSummaryModel summary;
  final void Function(String route) onRoute;

  @override
  Widget build(BuildContext context) {
    final tasks = summary.tasksToday.take(4).toList(growable: false);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(AppStrings.tareasDeHoy, style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontSize: 23, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(AppStrings.tareasPendientes(summary.pendingTasksToday), style: TextStyle(color: FocuslaneSemanticTokens.primary(context), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
            ],
          ),
          const SizedBox(height: 10),
          if (tasks.isEmpty) _miniLine(context, AppStrings.sinTareasHoy, '-', true),
          for (final task in tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onRoute(AppRoutes.tasksDashboard),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: FocuslaneSemanticTokens.filledSurface(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _miniLine(context, task.title, task.description, task.completed, tag: task.priority.name.toUpperCase()),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniLine(BuildContext context, String title, String subtitle, bool done, {String? tag}) {
    return Row(
      children: [
        Icon(done ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, size: 18, color: done ? FocuslaneSemanticTokens.primary(context) : FocuslaneSemanticTokens.textSecondary(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontWeight: FontWeight.w600)),
              if (subtitle.isNotEmpty)
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 11)),
            ],
          ),
        ),
        if (tag != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: FocuslaneSemanticTokens.backgroundMain(context), borderRadius: BorderRadius.circular(6)),
            child: Text(tag, style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 10, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.onRoute});

  final void Function(String route) onRoute;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.accionesRapidas, style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontSize: 23, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _action(context, AppStrings.accionNuevaTarea, Icons.task_alt_outlined, '/tasks/create'),
          const SizedBox(height: 8),
          _action(context, AppStrings.accionRegistrarHabito, Icons.repeat, '/habits'),
          const SizedBox(height: 8),
          _action(context, AppStrings.accionNotaRapida, Icons.note_add_outlined, '/notes/editor'),
          const SizedBox(height: 8),
          _action(context, AppStrings.accionAbrirCalendario, Icons.calendar_today_outlined, AppRoutes.calendarDashboard),
          const SizedBox(height: 8),
          _action(context, AppStrings.accionIniciarEstudio, Icons.timer_outlined, '/study/timer'),
        ],
      ),
    );
  }

  Widget _action(BuildContext context, String label, IconData icon, String route) {
    return InkWell(
      onTap: () => onRoute(route),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: FocuslaneSemanticTokens.border(context)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: FocuslaneSemanticTokens.primary(context)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitsCard extends StatelessWidget {
  const _HabitsCard({required this.summary});

  final DashboardSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final habits = summary.habits.take(4).toList(growable: false);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.matrizHabitos, style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (habits.isEmpty) Text(AppStrings.sinHabitosActivos, style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context))),
          for (final habit in habits)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontWeight: FontWeight.w600),
                    ),
                  ),
                  _habitDots(context, habit.currentStreak),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _habitDots(BuildContext context, int streak) {
    final score = streak >= 20 ? 5 : streak >= 12 ? 4 : streak >= 7 ? 3 : streak >= 3 ? 2 : streak > 0 ? 1 : 0;
    return Row(
      children: List.generate(5, (i) {
        final active = i < score;
        return Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: active ? FocuslaneSemanticTokens.primary(context) : FocuslaneSemanticTokens.border(context),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.summary});

  final DashboardSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final events = summary.upcomingEvents.take(3).toList(growable: false);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.proximosEventos, style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (events.isEmpty) Text(AppStrings.sinEventosProximos, style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context))),
          for (final event in events)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: FocuslaneSemanticTokens.backgroundMain(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(DateFormat('MMM', 'es_ES').format(event.startAt).toUpperCase(), style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 9)),
                        Text(DateFormat('d').format(event.startAt), style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontWeight: FontWeight.w600)),
                        Text(DateFormat('HH:mm', 'es_ES').format(event.startAt), style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 11)),
                      ],
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

class _HighlightsCard extends StatelessWidget {
  const _HighlightsCard({required this.summary});

  final DashboardSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _highlight(
          context,
          title: summary.defaultGymRoutineName ?? AppStrings.sinRutinaActiva,
          subtitle: summary.latestGymSession == null ? AppStrings.sinSesionesGym : DateFormat('d MMM â€¢ HH:mm', 'es_ES').format(summary.latestGymSession!),
          chip: AppStrings.ultimaSesionGym,
          progress: summary.latestGymSession == null ? 0.2 : 0.72,
        ),
        const SizedBox(height: 10),
        _highlight(
          context,
          title: summary.latestStudySession == null ? AppStrings.sinSesion : AppStrings.sesionMinutos(summary.latestStudySession!.minutes),
          subtitle: AppStrings.tareasEstudioHoy(summary.studyTasks.length),
          chip: AppStrings.enfoqueEstudio,
          progress: summary.studyTasks.isEmpty ? 0.25 : 0.78,
        ),
      ],
    );
  }

  Widget _highlight(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String chip,
    required double progress,
  }) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(chip, style: TextStyle(color: FocuslaneSemanticTokens.primary(context), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
          const SizedBox(height: 4),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 11)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 4,
            borderRadius: BorderRadius.circular(5),
            backgroundColor: FocuslaneSemanticTokens.border(context),
            valueColor: AlwaysStoppedAnimation(FocuslaneSemanticTokens.primary(context)),
          ),
        ],
      ),
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard({required this.summary});

  final DashboardSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final progress = summary.weeklyConsistency.clamp(0.0, 1.0).toDouble();
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.progresoSemanal, style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: FocuslaneSemanticTokens.border(context),
            valueColor: AlwaysStoppedAnimation(FocuslaneSemanticTokens.primary(context)),
          ),
          const SizedBox(height: 6),
          Text(AppStrings.consistenciaSemanal((progress * 100).round()), style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            AppStrings.resumenHabitosTareas(summary.completedHabitsToday, summary.habits.length, summary.pendingTasksToday),
            style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.summary, required this.onRoute});

  final DashboardSummaryModel summary;
  final void Function(String route) onRoute;

  @override
  Widget build(BuildContext context) {
    final notes = summary.recentNotes.take(3).toList(growable: false);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.actividadReciente, style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (notes.isEmpty)
            Text(AppStrings.sinNotasRecientes, style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 12)),
          for (final note in notes)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              onTap: () => onRoute(AppRoutes.notesDashboard),
              title: Text(note.title.isEmpty ? AppStrings.notaSinTitulo : note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(DateFormat('d MMM, HH:mm', 'es_ES').format(note.lastEditedAt), style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 11)),
              trailing: Icon(Icons.chevron_right, size: 16, color: FocuslaneSemanticTokens.textSecondary(context)),
            ),
        ],
      ),
    );
  }
}

class _ModuleLinksCard extends StatelessWidget {
  const _ModuleLinksCard({required this.onRoute});

  final void Function(String route) onRoute;

  @override
  Widget build(BuildContext context) {
    final links = [
      (AppStrings.moduloTareas, AppRoutes.tasksDashboard),
      (AppStrings.moduloHabitos, '/habits'),
      (AppStrings.moduloNotas, AppRoutes.notesDashboard),
      (AppStrings.moduloCalendario, AppRoutes.calendarDashboard),
      (AppStrings.moduloGym, AppRoutes.gymDashboard),
      (AppStrings.moduloEstudio, AppRoutes.studyDashboard),
      (AppStrings.moduloFinanzas, AppRoutes.financeDashboard),
      (AppStrings.moduloNutricion, AppRoutes.foodDashboard),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.accesosRapidos, style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final link in links)
                ActionChip(
                  label: Text(link.$1),
                  onPressed: () => onRoute(link.$2),
                  backgroundColor: FocuslaneSemanticTokens.filledSurface(context),
                  side: BorderSide(color: FocuslaneSemanticTokens.border(context)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FocuslaneSemanticTokens.filledSurface(context).withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FocuslaneSemanticTokens.border(context)),
      ),
      child: child,
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.title, required this.subtitle, required this.actionLabel, required this.onTap});

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            FilledButton(onPressed: onTap, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _KpiItem {
  const _KpiItem(this.title, this.value, this.subtitle, this.icon, this.route);

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final String route;
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

