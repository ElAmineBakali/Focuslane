import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focuslane/core/constants/app_strings.dart';
import 'package:focuslane/core/services/module_visibility_service.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';
import 'package:focuslane/screens/habits/models/habit_model.dart';
import 'package:focuslane/screens/habits/utils/habit_utils.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';
import 'package:focuslane/screens/tasks/models/task_model.dart';

import '../controllers/home_dashboard_controller.dart';
import '../models/dashboard_summary_model.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  late final HomeDashboardController _controller;
  final ModuleVisibilityService _visibility = ModuleVisibilityService.instance;

  @override
  void initState() {
    super.initState();
    _visibility.ensureLoaded();
    _controller = HomeDashboardController(
      studyService: StudyFirestoreService(),
      gymService: GymFirestoreService(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: AppStrings.dashboard,
      subtitle: AppStrings.saludoSegunHora(),
      activeRoute: AppRoutes.home,
      onNavigate: _openRoute,
      child: StreamBuilder<DashboardSummaryModel>(
        stream: _controller.streamSummary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return PageContainer(
              child: FocusEmptyState(
                icon: Icons.dashboard_customize_outlined,
                message: AppStrings.noDashboardDataTitle,
                subtitle: AppStrings.noDashboardDataSubtitle,
                actionLabel: AppStrings.retry,
                onAction: () => setState(() {}),
              ),
            );
          }

          return _HomeDashboardContent(
            summary: snapshot.data!,
            controller: _controller,
            onRoute: _openRoute,
          );
        },
      ),
    );
  }

  Future<void> _openRoute(String route) async {
    if (route == AppRoutes.home) return;
    await _visibility.ensureLoaded();
    if (_visibility.managesRoute(route) && !_visibility.isEnabled(route)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este modulo esta desactivado. Puedes activarlo en Ajustes > Modulos de la app.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).pushNamed(route);
    if (!mounted) return;
    setState(() {});
  }
}

class _HomeDashboardContent extends StatelessWidget {
  const _HomeDashboardContent({
    required this.summary,
    required this.controller,
    required this.onRoute,
  });

  final DashboardSummaryModel summary;
  final HomeDashboardController controller;
  final ValueChanged<String> onRoute;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 760;
        final isDesktop = constraints.maxWidth >= 1180;
        final pageGap = FocuslaneTokens.pageGapFor(context);

        return SingleChildScrollView(
          child: PageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WelcomeHeader(
                  greeting: controller.greetingFor(summary.today),
                  dateLabel: controller.dayLabel(summary.today),
                  phrase: controller.motivationalPhraseFor(summary.today),
                  onRoute: onRoute,
                ),
                SizedBox(height: pageGap),
                _StatsGrid(summary: summary, onRoute: onRoute),
                SizedBox(height: pageGap),
                if (isDesktop)
                  _DesktopBento(summary: summary, onRoute: onRoute)
                else
                  _StackedBento(
                    summary: summary,
                    onRoute: onRoute,
                    isMobile: isMobile,
                  ),
                SizedBox(height: pageGap),
                _QuickAccessSection(onRoute: onRoute),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({
    required this.greeting,
    required this.dateLabel,
    required this.phrase,
    required this.onRoute,
  });

  final String greeting;
  final String dateLabel;
  final String phrase;
  final ValueChanged<String> onRoute;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final rawName = (user?.displayName ?? user?.email ?? '').trim();
    final firstName = rawName.isEmpty ? 'FocusLane' : rawName.split('@').first;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final titleStyle =
            compact
                ? Theme.of(context).textTheme.headlineMedium
                : Theme.of(context).textTheme.displaySmall;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, $firstName',
              style: titleStyle?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FocusBadge(
                  label: dateLabel,
                  color: scheme.secondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                Text(
                  phrase,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            SizedBox(height: FocuslaneTokens.sectionGapFor(context)),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FocusPrimaryButton(
                  label: 'Nueva tarea',
                  icon: Icons.add_task_rounded,
                  onPressed: () => onRoute('/tasks/create'),
                ),
                FocusSecondaryButton(
                  label: 'Nueva nota',
                  icon: Icons.edit_note_rounded,
                  onPressed: () => onRoute('/notes/editor'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.summary, required this.onRoute});

  final DashboardSummaryModel summary;
  final ValueChanged<String> onRoute;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ResponsiveGrid(
      minItemWidth: 220,
      spacing: 16,
      children: [
        FocusStatCard(
          title: 'Tareas hoy',
          value: '${summary.pendingTasksToday}',
          subtitle: 'pendientes',
          icon: Icons.task_alt_rounded,
          color: scheme.primary,
          onTap: () => onRoute(AppRoutes.tasksDashboard),
        ),
        FocusStatCard(
          title: 'Habitos',
          value: '${summary.completedHabitsToday}/${summary.activeHabitsCount}',
          subtitle: 'completados hoy',
          icon: Icons.repeat_rounded,
          color: scheme.secondary,
          onTap: () => onRoute(AppRoutes.habitsDashboard),
        ),
        FocusStatCard(
          title: 'Eventos',
          value: '${summary.upcomingEvents.length}',
          subtitle: 'proximos 14 dias',
          icon: Icons.calendar_month_rounded,
          color: scheme.tertiary,
          onTap: () => onRoute(AppRoutes.calendarDashboard),
        ),
        FocusStatCard(
          title: 'Notas',
          value: '${summary.recentNotes.length}',
          subtitle: 'recientes',
          icon: Icons.description_rounded,
          color: scheme.primaryContainer,
          onTap: () => onRoute(AppRoutes.notesDashboard),
        ),
      ],
    );
  }
}

class _DesktopBento extends StatelessWidget {
  const _DesktopBento({required this.summary, required this.onRoute});

  final DashboardSummaryModel summary;
  final ValueChanged<String> onRoute;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 8,
                child: _TodayTasksCard(summary: summary, onRoute: onRoute),
              ),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: _WeeklyProgressCard(summary: summary)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _HabitsCard(summary: summary)),
              const SizedBox(width: 24),
              Expanded(child: _UpcomingEventsCard(summary: summary)),
              const SizedBox(width: 24),
              Expanded(
                child: _RecentNotesCard(summary: summary, onRoute: onRoute),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StackedBento extends StatelessWidget {
  const _StackedBento({
    required this.summary,
    required this.onRoute,
    required this.isMobile,
  });

  final DashboardSummaryModel summary;
  final ValueChanged<String> onRoute;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          _TodayTasksCard(summary: summary, onRoute: onRoute),
          SizedBox(height: FocuslaneTokens.pageGapFor(context)),
          _WeeklyProgressCard(summary: summary),
          SizedBox(height: FocuslaneTokens.pageGapFor(context)),
          _HabitsCard(summary: summary),
          SizedBox(height: FocuslaneTokens.pageGapFor(context)),
          _UpcomingEventsCard(summary: summary),
          SizedBox(height: FocuslaneTokens.pageGapFor(context)),
          _RecentNotesCard(summary: summary, onRoute: onRoute),
        ],
      );
    }

    return Column(
      children: [
        _TodayTasksCard(summary: summary, onRoute: onRoute),
        const SizedBox(height: 20),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _WeeklyProgressCard(summary: summary)),
              const SizedBox(width: 20),
              Expanded(child: _HabitsCard(summary: summary)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _UpcomingEventsCard(summary: summary)),
              const SizedBox(width: 20),
              Expanded(
                child: _RecentNotesCard(summary: summary, onRoute: onRoute),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayTasksCard extends StatelessWidget {
  const _TodayTasksCard({required this.summary, required this.onRoute});

  final DashboardSummaryModel summary;
  final ValueChanged<String> onRoute;

  @override
  Widget build(BuildContext context) {
    final tasks = summary.tasksToday.take(5).toList(growable: false);

    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionHeader(
            title: AppStrings.tareasDeHoy,
            subtitle: AppStrings.tareasPendientes(summary.pendingTasksToday),
            icon: Icons.checklist_rounded,
            trailing: TextButton(
              onPressed: () => onRoute(AppRoutes.tasksDashboard),
              child: const Text('Ver todas'),
            ),
          ),
          SizedBox(height: FocuslaneTokens.sectionGapFor(context)),
          if (tasks.isEmpty)
            const _InlineEmptyState(
              icon: Icons.task_alt_rounded,
              title: AppStrings.sinTareasHoy,
              subtitle: 'Tu dia esta despejado.',
            )
          else
            Column(
              children: [for (final task in tasks) _TaskPreviewRow(task: task)],
            ),
        ],
      ),
    );
  }
}

class _TaskPreviewRow extends StatelessWidget {
  const _TaskPreviewRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dueLabel =
        task.dueDate == null
            ? 'Sin fecha'
            : DateFormat('HH:mm', 'es_ES').format(task.dueDate!);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.75),
        ),
      ),
      child: Row(
        children: [
          Icon(
            task.completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: task.completed ? scheme.primary : scheme.onSurfaceVariant,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    decoration:
                        task.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (task.description.trim().isNotEmpty)
                  Text(
                    task.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FocusBadge(
            label: task.priority.label,
            color: task.priority.getColor(),
          ),
          const SizedBox(width: 8),
          Text(
            dueLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
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
    final scheme = Theme.of(context).colorScheme;
    final progress = summary.weeklyConsistency.clamp(0.0, 1.0).toDouble();

    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FocusSectionHeader(
            title: AppStrings.progresoSemanal,
            subtitle: 'Lunes a domingo',
            icon: Icons.trending_up_rounded,
          ),
          SizedBox(height: FocuslaneTokens.sectionGapFor(context)),
          Center(
            child: FocusProgressRing(
              value: progress,
              subtitle: 'consistencia',
              color: scheme.primary,
            ),
          ),
          SizedBox(height: FocuslaneTokens.sectionGapFor(context)),
          _MetricLine(
            label: 'Habitos',
            value:
                '${summary.weeklyHabitChecksDone}/${summary.weeklyHabitChecksTotal}',
          ),
          const SizedBox(height: 8),
          _MetricLine(
            label: 'Tareas',
            value: '${summary.weeklyTasksDone}/${summary.weeklyTasksTotal}',
          ),
        ],
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

    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FocusSectionHeader(
            title: AppStrings.matrizHabitos,
            subtitle: 'Estado de hoy',
            icon: Icons.repeat_rounded,
          ),
          SizedBox(height: FocuslaneTokens.sectionGapFor(context)),
          if (habits.isEmpty)
            const _InlineEmptyState(
              icon: Icons.repeat_rounded,
              title: AppStrings.sinHabitosActivos,
              subtitle: 'Crea habitos para ver tu avance aqui.',
            )
          else
            Column(
              children: [
                for (final habit in habits) _HabitPreviewRow(habit: habit),
              ],
            ),
        ],
      ),
    );
  }
}

class _HabitPreviewRow extends StatelessWidget {
  const _HabitPreviewRow({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = habitHistoryValueForDate(habit.history, DateTime.now());
    final done = isHabitCompletedValue(habit, value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color:
                  done
                      ? scheme.primary.withValues(alpha: 0.14)
                      : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.circle_outlined,
              color: done ? scheme.primary : scheme.onSurfaceVariant,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              habit.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FocusBadge(label: done ? 'Hecho' : 'Pendiente'),
        ],
      ),
    );
  }
}

class _UpcomingEventsCard extends StatelessWidget {
  const _UpcomingEventsCard({required this.summary});

  final DashboardSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final events = summary.upcomingEvents.take(4).toList(growable: false);

    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FocusSectionHeader(
            title: AppStrings.proximosEventos,
            subtitle: 'Agenda cercana',
            icon: Icons.calendar_month_rounded,
          ),
          SizedBox(height: FocuslaneTokens.sectionGapFor(context)),
          if (events.isEmpty)
            const _InlineEmptyState(
              icon: Icons.event_available_rounded,
              title: AppStrings.sinEventosProximos,
              subtitle: 'Tu calendario esta tranquilo.',
            )
          else
            Column(
              children: [
                for (final event in events)
                  _EventPreviewRow(title: event.title, startsAt: event.startAt),
              ],
            ),
        ],
      ),
    );
  }
}

class _EventPreviewRow extends StatelessWidget {
  const _EventPreviewRow({required this.title, required this.startsAt});

  final String title;
  final DateTime startsAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('MMM', 'es_ES').format(startsAt).toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  DateFormat('d', 'es_ES').format(startsAt),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  DateFormat('EEEE HH:mm', 'es_ES').format(startsAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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

class _RecentNotesCard extends StatelessWidget {
  const _RecentNotesCard({required this.summary, required this.onRoute});

  final DashboardSummaryModel summary;
  final ValueChanged<String> onRoute;

  @override
  Widget build(BuildContext context) {
    final notes = summary.recentNotes.take(4).toList(growable: false);

    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionHeader(
            title: AppStrings.actividadReciente,
            subtitle: 'Ultimas ediciones',
            icon: Icons.description_rounded,
            trailing: TextButton(
              onPressed: () => onRoute(AppRoutes.notesDashboard),
              child: const Text('Abrir'),
            ),
          ),
          SizedBox(height: FocuslaneTokens.sectionGapFor(context)),
          if (notes.isEmpty)
            const _InlineEmptyState(
              icon: Icons.note_add_rounded,
              title: AppStrings.sinNotasRecientes,
              subtitle: 'Tus notas recientes apareceran aqui.',
            )
          else
            Column(
              children: [
                for (final note in notes)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onTap: () => onRoute(AppRoutes.notesDashboard),
                    title: Text(
                      note.title.isEmpty
                          ? AppStrings.notaSinTitulo
                          : note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      DateFormat(
                        'd MMM, HH:mm',
                        'es_ES',
                      ).format(note.lastEditedAt),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _QuickAccessSection extends StatelessWidget {
  const _QuickAccessSection({required this.onRoute});

  final ValueChanged<String> onRoute;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FocusSectionHeader(
          title: AppStrings.accesosRapidos,
          subtitle: 'Entradas directas a los modulos principales',
          icon: Icons.grid_view_rounded,
        ),
        SizedBox(height: FocuslaneTokens.pageGapFor(context)),
        ResponsiveGrid(
          minItemWidth: 180,
          spacing: 16,
          children: [
            FocusModuleCard(
              title: 'Tareas',
              subtitle: 'Organiza pendientes',
              icon: Icons.checklist_rounded,
              color: scheme.primary,
              onTap: () => onRoute(AppRoutes.tasksDashboard),
            ),
            FocusModuleCard(
              title: 'Notas',
              subtitle: 'Captura ideas',
              icon: Icons.description_rounded,
              color: scheme.secondary,
              onTap: () => onRoute(AppRoutes.notesDashboard),
            ),
            FocusModuleCard(
              title: 'Calendario',
              subtitle: 'Revisa agenda',
              icon: Icons.calendar_month_rounded,
              color: scheme.tertiary,
              onTap: () => onRoute(AppRoutes.calendarDashboard),
            ),
            FocusModuleCard(
              title: 'Finanzas',
              subtitle: 'Gestiona presupuesto',
              icon: Icons.account_balance_wallet_rounded,
              color: scheme.primaryContainer,
              onTap: () => onRoute(AppRoutes.financeDashboard),
            ),
            FocusModuleCard(
              title: 'Gimnasio',
              subtitle: 'Entrena con foco',
              icon: Icons.fitness_center_rounded,
              color: scheme.secondary,
              onTap: () => onRoute(AppRoutes.gymDashboard),
            ),
            FocusModuleCard(
              title: 'Alimentacion',
              subtitle: 'Registra comidas',
              icon: Icons.restaurant_rounded,
              color: scheme.tertiary,
              onTap: () => onRoute(AppRoutes.foodDashboard),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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
