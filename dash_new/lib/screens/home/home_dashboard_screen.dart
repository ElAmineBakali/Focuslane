import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:focuslane/core/constants/app_strings.dart';
import 'package:focuslane/design/ui/layouts/module_scaffold.dart';
import 'package:focuslane/design/ui/tokens/focuslane_semantic_tokens.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/habits/habit_utils.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';

import 'home_dashboard_controller.dart';
import 'models/dashboard_summary_model.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

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
          final isTablet =
              rootConstraints.maxWidth >= _mobileMax &&
              rootConstraints.maxWidth < _tabletMax;

          return Scaffold(
            backgroundColor: FocuslaneSemanticTokens.backgroundMain(context),
            appBar: isMobile
                ? AppBar(
                    title: const Text(AppStrings.dashboard),
                    centerTitle: false,
                    scrolledUnderElevation: 0,
                    actions: [
                      IconButton(
                        onPressed: () => _openRoute(AppRoutes.notifications),
                        icon: const Icon(Icons.notifications_none, size: 18),
                        tooltip: 'Notificaciones',
                      ),
                    ],
                  )
                : null,
            drawer: (isMobile || isTablet)
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
                          onOpenMenu: () => Scaffold.maybeOf(context)?.openDrawer(),
                        );
                      }

                      return _DesktopDashboard(
                        summary: summary,
                        controller: _controller,
                        onRoute: _openRoute,
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
  });

  final DashboardSummaryModel summary;
  final HomeDashboardController controller;
  final void Function(String route) onRoute;
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
                onOpenNotifications: () => onRoute(AppRoutes.notifications),
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
                        phrase: controller.motivationalPhraseFor(summary.today),
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
                            Expanded(flex: 1, child: _UpcomingCard(summary: summary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _HabitsCard(summary: summary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(flex: 3, child: _RecentActivityCard(summary: summary, onRoute: onRoute)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _WeeklyProgressCard(summary: summary),
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
    required this.onOpenMenu,
  });

  final DashboardSummaryModel summary;
  final HomeDashboardController controller;
  final void Function(String route) onRoute;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TabletHeader(
          onOpenMenu: onOpenMenu,
          onOpenNotifications: () => onRoute(AppRoutes.notifications),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PortalHero(
                  greeting: controller.greetingFor(summary.today),
                  dateLabel: controller.dayLabel(summary.today),
                  phrase: controller.motivationalPhraseFor(summary.today),
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
                      Expanded(child: _UpcomingCard(summary: summary)),
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
                      Expanded(flex: 1, child: _RecentActivityCard(summary: summary, onRoute: onRoute)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _WeeklyProgressCard(summary: summary),
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
          phrase: controller.motivationalPhraseFor(summary.today),
          compact: true,
        ),
        const SizedBox(height: 16),
        _KpiGrid(summary: summary, onRoute: onRoute, columns: 1),
        const SizedBox(height: 16),
        _TodayTasksCard(summary: summary, onRoute: onRoute),
        const SizedBox(height: 16),
        _HabitsCard(summary: summary),
        const SizedBox(height: 16),
        _UpcomingCard(summary: summary),
        const SizedBox(height: 16),
        _WeeklyProgressCard(summary: summary),
        const SizedBox(height: 16),
        _RecentActivityCard(summary: summary, onRoute: onRoute),
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
      _NavItem(AppStrings.moduloCalendario, Icons.calendar_today_outlined, AppRoutes.calendarDashboard),
      _NavItem(AppStrings.moduloTareas, Icons.task_alt_outlined, AppRoutes.tasksDashboard),
      _NavItem(AppStrings.moduloNotas, Icons.note_alt_outlined, AppRoutes.notesDashboard),
      _NavItem(AppStrings.moduloHabitos, Icons.repeat, '/habits'),
      _NavItem(AppStrings.moduloEstudio, Icons.school_outlined, AppRoutes.studyDashboard),
      _NavItem(AppStrings.moduloGym, Icons.fitness_center_outlined, AppRoutes.gymDashboard),
      _NavItem(AppStrings.moduloNutricion, Icons.restaurant_outlined, AppRoutes.foodDashboard),
      _NavItem(AppStrings.moduloFinanzas, Icons.account_balance_wallet_outlined, AppRoutes.financeDashboard),
    ];

    final user = FirebaseAuth.instance.currentUser;
    final profileRef = user == null
        ? null
        : FirebaseFirestore.instance.collection('users').doc(user.uid).collection('profile').doc('info');

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
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: profileRef?.snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() ?? const <String, dynamic>{};
              final displayName = ((data['displayName'] as String?) ?? '').trim();
              final photoUrl = ((data['photoUrl'] as String?) ?? '').trim();
              final resolvedName = displayName.isNotEmpty ? displayName : (user?.displayName?.trim().isNotEmpty == true ? user!.displayName!.trim() : 'FocusLane');

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty ? const Icon(Icons.person, size: 16) : null,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(resolvedName, style: TextStyle(color: FocuslaneSemanticTokens.primary(context), fontWeight: FontWeight.w700)),
                      Text(AppStrings.portalProductividad, style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 11)),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: Colors.transparent,
                onTap: () => onRoute(item.route),
                leading: Icon(item.icon, size: 18, color: FocuslaneSemanticTokens.textSecondary(context)),
                title: Text(item.label, style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 14)),
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: ListTile(
              dense: true,
              onTap: () => onRoute(AppRoutes.notifications),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              leading: Icon(Icons.notifications_outlined, size: 18, color: FocuslaneSemanticTokens.textSecondary(context)),
              title: Text('Notificaciones', style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 14)),
            ),
          ),
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
  const _PortalTopBar({required this.title, required this.onOpenNotifications});

  final String title;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: FocuslaneSemanticTokens.border(context))),
      ),
      child: Row(
        children: [
          Text(AppStrings.saludoSegunHora(), style: TextStyle(color: FocuslaneSemanticTokens.primary(context), fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(width: 10),
          Text('/ $title', style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context))),
          const Spacer(),
          const SizedBox(width: 10),
          IconButton(
            onPressed: onOpenNotifications,
            icon: const Icon(Icons.notifications_none, size: 18),
            tooltip: 'Notificaciones',
          ),
        ],
      ),
    );
  }
}

class _TabletHeader extends StatelessWidget {
  const _TabletHeader({required this.onOpenMenu, required this.onOpenNotifications});

  final VoidCallback onOpenMenu;
  final VoidCallback onOpenNotifications;

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
          IconButton(
            onPressed: onOpenMenu,
            icon: const Icon(Icons.menu_rounded, size: 20),
            tooltip: 'Abrir menu',
          ),
          Text(AppStrings.dashboard, style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 18)),
          const Spacer(),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search, size: 18)),
          IconButton(
            onPressed: onOpenNotifications,
            icon: const Icon(Icons.notifications_none, size: 18),
            tooltip: 'Notificaciones',
          ),
        ],
      ),
    );
  }
}

class _PortalHero extends StatelessWidget {
  const _PortalHero({required this.greeting, required this.dateLabel, required this.phrase, this.compact = false});

  final String greeting;
  final String dateLabel;
  final String phrase;
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
          '$greeting · $dateLabel',
          style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context)),
        ),
        const SizedBox(height: 4),
        Text(
          'Frase del día',
          style: TextStyle(
            color: FocuslaneSemanticTokens.textSecondary(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          phrase,
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
      _KpiItem(
        AppStrings.kpiEnfoque,
        '${summary.pendingTasksToday}',
        summary.pendingTasksToday == 1 ? '1 tarea pendiente hoy' : '${summary.pendingTasksToday} tareas pendientes hoy',
        Icons.task_alt_outlined,
        AppRoutes.tasksDashboard,
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
        childAspectRatio: columns == 1 ? 3.2 : 1.9,
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

class _HabitsCard extends StatefulWidget {
  const _HabitsCard({required this.summary});

  final DashboardSummaryModel summary;

  @override
  State<_HabitsCard> createState() => _HabitsCardState();
}

class _HabitsCardState extends State<_HabitsCard> {
  late final Random _reloadRandom;
  final Map<String, double> _randomOrderByHabitId = <String, double>{};

  @override
  void initState() {
    super.initState();
    _reloadRandom = Random(DateTime.now().microsecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    final habits = _selectHabits(widget.summary.habits);
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.matrizHabitos, style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Filas: hábitos · Columnas: lunes a domingo · Estado: verde completado / gris pendiente',
            style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 120),
              for (final day in weekDays)
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('E', 'es_ES').format(day).substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: FocuslaneSemanticTokens.textSecondary(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (habits.isEmpty) Text(AppStrings.sinHabitosActivos, style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context))),
          for (final habit in habits)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontWeight: FontWeight.w600),
                    ),
                  ),
                  ...weekDays.map((day) {
                    final done = _isHabitDoneOnDay(habit, day);
                    final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
                    return Expanded(
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: done ? FocuslaneSemanticTokens.primary(context) : FocuslaneSemanticTokens.border(context),
                            borderRadius: BorderRadius.circular(4),
                            border: isToday
                                ? Border.all(color: FocuslaneSemanticTokens.textPrimary(context), width: 1)
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: FocuslaneSemanticTokens.primary(context), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Text('Completado', style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 11)),
              const SizedBox(width: 14),
              Container(width: 10, height: 10, decoration: BoxDecoration(color: FocuslaneSemanticTokens.border(context), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Text('Pendiente', style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  List<dynamic> _selectHabits(List<dynamic> allHabits) {
    if (allHabits.isEmpty) return const [];

    final today = DateTime.now();
    dynamic markedFirst;
    final markedToday = allHabits
        .where((h) => _isHabitDoneOnDay(h, today))
        .toList(growable: false)
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    if (markedToday.isNotEmpty) {
      markedFirst = markedToday.first;
    }

    final selected = <dynamic>[];

    if (allHabits.length > 4) {
      final latestRegistered = allHabits.toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      selected.addAll(latestRegistered.take(4));
    } else {
      final randomized = allHabits.toList(growable: false)
        ..sort((a, b) {
          final aw = _randomOrderByHabitId.putIfAbsent(a.id, () => _reloadRandom.nextDouble());
          final bw = _randomOrderByHabitId.putIfAbsent(b.id, () => _reloadRandom.nextDouble());
          return bw.compareTo(aw);
        });
      selected.addAll(randomized.take(4));
    }

    if (markedFirst != null) {
      selected.removeWhere((h) => h.id == markedFirst.id);
      selected.insert(0, markedFirst);
      if (selected.length > 4) {
        selected.removeRange(4, selected.length);
      }
    }

    return selected;
  }

  bool _isHabitDoneOnDay(dynamic habit, DateTime day) {
    final value = habitHistoryValueForDate(habit.history, day);
    return isHabitCompletedValue(habit, value);
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

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard({required this.summary});

  final DashboardSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final progress = summary.weeklyConsistency.clamp(0.0, 1.0).toDouble();
    final weeklyPercent = (progress * 100).round();
    final habitsLine = 'Hábitos: ${summary.weeklyHabitChecksDone}/${summary.weeklyHabitChecksTotal} checks completados';
    final tasksLine = 'Tareas: ${summary.weeklyTasksDone}/${summary.weeklyTasksTotal} completadas';
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progreso semanal (lunes a domingo)', style: TextStyle(color: FocuslaneSemanticTokens.textPrimary(context), fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: FocuslaneSemanticTokens.border(context),
            valueColor: AlwaysStoppedAnimation(FocuslaneSemanticTokens.primary(context)),
          ),
          const SizedBox(height: 6),
          Text('Consistencia semanal: $weeklyPercent%', style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 12)),
          const SizedBox(height: 4),
          Text(habitsLine, style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 11)),
          const SizedBox(height: 4),
          Text(tasksLine, style: TextStyle(color: FocuslaneSemanticTokens.textSecondary(context), fontSize: 11)),
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

