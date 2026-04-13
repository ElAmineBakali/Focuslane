import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:focuslane/core/notifications/local/android_channel_catalog.dart';
import 'package:focuslane/core/notifications/models/notification_action.dart';
import 'package:focuslane/core/notifications/models/notification_content.dart';
import 'package:focuslane/core/notifications/models/notification_delivery.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/models/notification_intent.dart';
import 'package:focuslane/core/notifications/models/notification_schedule.dart';
import 'package:focuslane/core/notifications/notifications_facade.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:focuslane/design/blocks/toast/app_toast.dart';
import 'package:focuslane/design/ui/tokens/focuslane_tokens.dart';
import '../services/study_firestore_service.dart';
import '../models/study_models.dart';
import '../analytics/study_analytics_screen.dart';
import 'presets_sheet.dart';
import 'session_summary_screen.dart';
import 'circular_timer_widget.dart';
import '../../../design/ui/components/focus_module_header.dart';

class StudyTimerScreen extends StatefulWidget {
  final StudyFirestoreService svc;
  final String? initialCourseId;
  final String? initialTaskId;
  const StudyTimerScreen({
    super.key,
    required this.svc,
    this.initialCourseId,
    this.initialTaskId,
  });

  @override
  State<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends State<StudyTimerScreen> {
  String? _courseId;
  String? _taskId;

  StudyMethod _method = StudyMethod.pomodoro;
  Map<String, dynamic> _cfg = {'work': 25, 'short': 5, 'long': 15, 'cycles': 4};
  String _phase = 'ready';
  int _timeLeft = 0;
  int _totalTime = 0;
  int _cycle = 0;
  Timer? _ticker;
  bool _isRunning = false;

  DateTime? _startedAt;
  int _accumulatedMinutes = 0;
  int _laps = 0;

  late ConfettiController _confettiController;

  static const int _N_WORK_START = 41010;
  static const int _N_REST_START = 41011;
  static const int _N_SESSION_SAVED = 41030;

  String get _uid => fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'local';

  @override
  void initState() {
    super.initState();
    _courseId = widget.initialCourseId;
    _taskId = widget.initialTaskId;
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _confettiController.dispose();
    _cancelStudyPhaseNotifs();
    super.dispose();
  }

  Future<void> _cancelStudyPhaseNotifs() async {
    await NotificationsFacade.I.cancelByEntity(
      const NotificationEntityRef(
        module: NotificationModule.study,
        kind: 'timer_phase_end',
        id: 'work',
      ),
    );
    await NotificationsFacade.I.cancelByEntity(
      const NotificationEntityRef(
        module: NotificationModule.study,
        kind: 'timer_phase_end',
        id: 'rest',
      ),
    );
  }

  Future<void> _notifyPhaseStart(String phase, int seconds) async {
    if (phase == 'work') {
      final now = DateTime.now();
      await NotificationsFacade.I.scheduleIntent(
        NotificationIntent(
          module: NotificationModule.study,
          type: 'TIMER_WORK_STARTED',
          entity: const NotificationEntityRef(
            module: NotificationModule.study,
            kind: 'timer_phase_start',
            id: 'work',
          ),
          content: NotificationContent(
            title: 'Estudio',
            body: 'Trabajo iniciado (${(seconds / 60).round()} min)',
          ),
          action: const NotificationAction(
            kind: NotificationActionKind.openRoute,
            route: '/study',
          ),
          schedule: NotificationSchedule(
            kind: NotificationScheduleKind.immediate,
            scheduledAtUtc: now.toUtc(),
            timezone: now.timeZoneName,
          ),
          delivery: const NotificationDelivery(
            kind: NotificationDeliveryKind.localOnly,
            channel: AndroidChannelCatalog.studyReminders,
            priority: NotificationPriority.normal,
          ),
          dedupeKey: 'study:timer:work_start:${now.millisecondsSinceEpoch}',
          userId: _uid,
          source: 'study.timer',
          notificationId: 'ntf_study_timer_work_start_${now.millisecondsSinceEpoch}',
        ),
      );
      final end = now.add(Duration(seconds: seconds));
      await NotificationsFacade.I.cancelByEntity(
        const NotificationEntityRef(
          module: NotificationModule.study,
          kind: 'timer_phase_end',
          id: 'work',
        ),
      );
      await NotificationsFacade.I.scheduleIntent(
        NotificationIntent(
          module: NotificationModule.study,
          type: 'TIMER_WORK_ENDED',
          entity: const NotificationEntityRef(
            module: NotificationModule.study,
            kind: 'timer_phase_end',
            id: 'work',
          ),
          content: const NotificationContent(
            title: 'Fin del trabajo',
            body: 'Toca descanso',
          ),
          action: const NotificationAction(
            kind: NotificationActionKind.openRoute,
            route: '/study',
          ),
          schedule: NotificationSchedule(
            kind: NotificationScheduleKind.oneShot,
            scheduledAtUtc: end.toUtc(),
            timezone: end.timeZoneName,
          ),
          delivery: const NotificationDelivery(
            kind: NotificationDeliveryKind.localOnly,
            channel: AndroidChannelCatalog.studyReminders,
            priority: NotificationPriority.high,
          ),
          dedupeKey: 'study:timer:work_end',
          userId: _uid,
          source: 'study.timer',
          notificationId: 'ntf_study_timer_work_end',
        ),
      );
    } else if (phase == 'rest') {
      final now = DateTime.now();
      await NotificationsFacade.I.scheduleIntent(
        NotificationIntent(
          module: NotificationModule.study,
          type: 'TIMER_REST_STARTED',
          entity: const NotificationEntityRef(
            module: NotificationModule.study,
            kind: 'timer_phase_start',
            id: 'rest',
          ),
          content: NotificationContent(
            title: 'Estudio',
            body: 'Descanso iniciado (${(seconds / 60).round()} min)',
          ),
          action: const NotificationAction(
            kind: NotificationActionKind.openRoute,
            route: '/study',
          ),
          schedule: NotificationSchedule(
            kind: NotificationScheduleKind.immediate,
            scheduledAtUtc: now.toUtc(),
            timezone: now.timeZoneName,
          ),
          delivery: const NotificationDelivery(
            kind: NotificationDeliveryKind.localOnly,
            channel: AndroidChannelCatalog.studyReminders,
            priority: NotificationPriority.normal,
          ),
          dedupeKey: 'study:timer:rest_start:${now.millisecondsSinceEpoch}',
          userId: _uid,
          source: 'study.timer',
          notificationId: 'ntf_study_timer_rest_start_${now.millisecondsSinceEpoch}',
        ),
      );
      final end = now.add(Duration(seconds: seconds));
      await NotificationsFacade.I.cancelByEntity(
        const NotificationEntityRef(
          module: NotificationModule.study,
          kind: 'timer_phase_end',
          id: 'rest',
        ),
      );
      await NotificationsFacade.I.scheduleIntent(
        NotificationIntent(
          module: NotificationModule.study,
          type: 'TIMER_REST_ENDED',
          entity: const NotificationEntityRef(
            module: NotificationModule.study,
            kind: 'timer_phase_end',
            id: 'rest',
          ),
          content: const NotificationContent(
            title: 'Fin del descanso',
            body: 'Vuelve al trabajo',
          ),
          action: const NotificationAction(
            kind: NotificationActionKind.openRoute,
            route: '/study',
          ),
          schedule: NotificationSchedule(
            kind: NotificationScheduleKind.oneShot,
            scheduledAtUtc: end.toUtc(),
            timezone: end.timeZoneName,
          ),
          delivery: const NotificationDelivery(
            kind: NotificationDeliveryKind.localOnly,
            channel: AndroidChannelCatalog.studyReminders,
            priority: NotificationPriority.high,
          ),
          dedupeKey: 'study:timer:rest_end',
          userId: _uid,
          source: 'study.timer',
          notificationId: 'ntf_study_timer_rest_end',
        ),
      );
    }
  }

  void _loadPreset(TimerPreset p) {
    setState(() {
      _method = p.method;
      _cfg = Map<String, dynamic>.from(p.params);
      _phase = 'ready';
      _timeLeft = 0;
      _totalTime = 0;
      _cycle = 0;
      _isRunning = false;
      _ticker?.cancel();
      _startedAt = null;
      _accumulatedMinutes = 0;
      _laps = 0;
    });
    _cancelStudyPhaseNotifs();
  }

  void _start() {
    if (_courseId == null) {
      AppToast.error(context, 'Selecciona un curso');
      return;
    }
    _startedAt ??= DateTime.now();
    setState(() => _isRunning = true);
    switch (_method) {
      case StudyMethod.pomodoro:
        _startPomodoro();
        break;
      case StudyMethod.flowtime:
        _startFlowtimeWork();
        break;
      case StudyMethod.timeboxing:
        _startBox('work', (_cfg['block'] ?? 50).toInt());
        break;
      case StudyMethod.simple:
        _phase = 'counting';
        _totalTime = 0;
        _ticker?.cancel();
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {
            _timeLeft += 1;
          });
        });
        setState(() {});
        final now = DateTime.now();
        NotificationsFacade.I.scheduleIntent(
          NotificationIntent(
            module: NotificationModule.study,
            type: 'TIMER_SESSION_STARTED',
            entity: const NotificationEntityRef(
              module: NotificationModule.study,
              kind: 'timer_session',
              id: 'simple',
            ),
            content: const NotificationContent(
              title: 'Estudio',
              body: 'Sesion iniciada',
            ),
            action: const NotificationAction(
              kind: NotificationActionKind.openRoute,
              route: '/study',
            ),
            schedule: NotificationSchedule(
              kind: NotificationScheduleKind.immediate,
              scheduledAtUtc: now.toUtc(),
              timezone: now.timeZoneName,
            ),
            delivery: const NotificationDelivery(
              kind: NotificationDeliveryKind.localOnly,
              channel: AndroidChannelCatalog.studyReminders,
              priority: NotificationPriority.normal,
            ),
            dedupeKey: 'study:timer:simple_start:${now.millisecondsSinceEpoch}',
            userId: _uid,
            source: 'study.timer',
            notificationId: 'ntf_study_timer_simple_start_${now.millisecondsSinceEpoch}',
          ),
        );
        break;
    }
  }

  void _startPomodoro() {
    final work = (_cfg['work'] ?? 25).toInt() * 60;
    _cycle++;
    _changePhase(
      'work',
      work,
      after: () {
        final isLong = (_cycle % ((_cfg['cycles'] ?? 4).toInt())) == 0;
        final restMin =
            isLong
                ? (_cfg['long'] ?? 15).toInt()
                : (_cfg['short'] ?? 5).toInt();
        _changePhase('rest', restMin * 60, after: () {});
      },
    );
  }

  void _startFlowtimeWork() {
    _phase = 'work';
    _timeLeft = 0;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _timeLeft += 60);
    });
    final now = DateTime.now();
    NotificationsFacade.I.scheduleIntent(
      NotificationIntent(
        module: NotificationModule.study,
        type: 'TIMER_FLOWTIME_STARTED',
        entity: const NotificationEntityRef(
          module: NotificationModule.study,
          kind: 'timer_session',
          id: 'flowtime',
        ),
        content: const NotificationContent(
          title: 'Estudio',
          body: 'Trabajo iniciado (Flowtime)',
        ),
        action: const NotificationAction(
          kind: NotificationActionKind.openRoute,
          route: '/study',
        ),
        schedule: NotificationSchedule(
          kind: NotificationScheduleKind.immediate,
          scheduledAtUtc: now.toUtc(),
          timezone: now.timeZoneName,
        ),
        delivery: const NotificationDelivery(
          kind: NotificationDeliveryKind.localOnly,
          channel: AndroidChannelCatalog.studyReminders,
          priority: NotificationPriority.normal,
        ),
        dedupeKey: 'study:timer:flowtime_start:${now.millisecondsSinceEpoch}',
        userId: _uid,
        source: 'study.timer',
        notificationId: 'ntf_study_timer_flowtime_start_${now.millisecondsSinceEpoch}',
      ),
    );
    _cancelStudyPhaseNotifs();
  }

  void _startBox(String phase, int minutes) {
    _changePhase(phase, minutes * 60, after: () {});
  }

  void _changePhase(
    String newPhase,
    int seconds, {
    required VoidCallback after,
  }) {
    _ticker?.cancel();
    setState(() {
      _phase = newPhase;
      _timeLeft = seconds;
      _totalTime = seconds;
      _isRunning = true;
    });

    _cancelStudyPhaseNotifs();
    _notifyPhaseStart(newPhase, seconds);

    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        if (_phase == 'work') {
          _accumulatedMinutes += (seconds / 60).round();
          _confettiController.play();
        }
        if (_method == StudyMethod.flowtime && _phase == 'work') {
          final ratio = (_cfg['ratio'] ?? 0.2).toDouble();
          final rest = (seconds * ratio).round();
          _changePhase('rest', rest, after: () {});
          return;
        }
        if (_method == StudyMethod.timeboxing && _phase == 'work') {
          _changePhase('rest', (_cfg['rest'] ?? 10).toInt() * 60, after: () {});
          return;
        }
        if (_method == StudyMethod.pomodoro) {
          _startPomodoro();
          return;
        }
        setState(() {
          _phase = 'ready';
          _isRunning = false;
        });
        after();
      } else {
        setState(() => _timeLeft -= 1);
      }
    });
  }

  void _pause() {
    _ticker?.cancel();
    setState(() => _isRunning = false);
    _cancelStudyPhaseNotifs();
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _phase = 'ready';
      _timeLeft = 0;
      _totalTime = 0;
      _cycle = 0;
      _isRunning = false;
      _startedAt = null;
      _accumulatedMinutes = 0;
      _laps = 0;
    });
    _cancelStudyPhaseNotifs();
  }

  Future<void> _stopAndSave() async {
    _ticker?.cancel();
    int minutes;
    if (_method == StudyMethod.simple) {
      minutes = (_timeLeft / 60).round();
    } else {
      minutes = _accumulatedMinutes;
    }
    final session = StudySession(
      id: '',
      courseId: _courseId!,
      taskId: _taskId,
      method: _method,
      minutes: minutes,
      laps: _method == StudyMethod.simple ? _laps : null,
      cycles: _method == StudyMethod.pomodoro ? _cycle : null,
      configSnapshot: {'method': _method.name, ..._cfg},
      notes: null,
      date: DateTime.now(),
    );
    await widget.svc.addSession(session);

    _cancelStudyPhaseNotifs();
    final now = DateTime.now();
    await NotificationsFacade.I.scheduleIntent(
      NotificationIntent(
        module: NotificationModule.study,
        type: 'TIMER_SESSION_SAVED',
        entity: const NotificationEntityRef(
          module: NotificationModule.study,
          kind: 'timer_session',
          id: 'saved',
        ),
        content: NotificationContent(
          title: 'Estudio',
          body: 'Sesion guardada ($minutes min)',
        ),
        action: const NotificationAction(
          kind: NotificationActionKind.openRoute,
          route: '/study',
        ),
        schedule: NotificationSchedule(
          kind: NotificationScheduleKind.immediate,
          scheduledAtUtc: now.toUtc(),
          timezone: now.timeZoneName,
        ),
        delivery: const NotificationDelivery(
          kind: NotificationDeliveryKind.localOnly,
          channel: AndroidChannelCatalog.studyReminders,
          priority: NotificationPriority.normal,
        ),
        dedupeKey: 'study:timer:session_saved:${now.millisecondsSinceEpoch}',
        userId: _uid,
        source: 'study.timer',
        notificationId: 'ntf_study_timer_session_saved_${now.millisecondsSinceEpoch}',
      ),
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionSummaryScreen(session: session, svc: widget.svc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.svc;
    final phaseLabel = switch (_phase) {
      'work' => 'Trabajo',
      'rest' => 'Descanso',
      'counting' => 'Estudiando',
      _ => 'Listo',
    };
    final cs = Theme.of(context).colorScheme;
    final gradient = LinearGradient(
      colors: [cs.primary.withOpacity(0.16), cs.surface],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    Color phaseColor(String p) {
      switch (p) {
        case 'work':
          return cs.primary;
        case 'rest':
          return cs.tertiary;
        case 'counting':
          return cs.secondary;
        default:
          return cs.outline;
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.3,
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar.large(
                backgroundColor: Colors.transparent,
                foregroundColor: cs.onSurface,
                leading: FocusModuleHeader.buildLeading(
                  context,
                  mode: FocusModuleLeadingMode.backToModuleDashboard,
                  backRouteName: AppRoutes.studyDashboard,
                ),
                leadingWidth: 96,
                flexibleSpace: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [phaseColor(_phase), cs.secondary, cs.surface],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                title: Text(
                  'Timer de estudio',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Presets',
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: () async {
                      final picked = await showModalBottomSheet<TimerPreset>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder:
                            (_) => PresetsSheet(svc: svc, courseId: _courseId),
                      );
                      if (picked != null) _loadPreset(picked);
                    },
                  ),
                  IconButton(
                    tooltip: 'Analíticas',
                    icon: const Icon(Icons.stacked_line_chart_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => StudyAnalyticsScreen(
                                svc: svc,
                                courseId: _courseId,
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      _PhasePill(label: phaseLabel, color: phaseColor(_phase)),
                      const SizedBox(height: AppSpacing.lg),
                      _TimerHeroCard(
                            colorScheme: cs,
                            phaseColor: phaseColor(_phase),
                            phaseLabel: phaseLabel,
                            timeLeft: _formatTime(_timeLeft),
                            totalTimeLabel:
                                _totalTime > 0
                                    ? _formatTime(_totalTime)
                                    : '--:--',
                            cycle: _cycle,
                            controls: _buildControlButtons(context),
                            timer: CircularTimerWidget(
                              timeLeft: _timeLeft,
                              totalTime: _totalTime,
                              phase: phaseLabel,
                              color: phaseColor(_phase),
                              isRunning: _isRunning,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .move(begin: const Offset(0, 20)),
                      const SizedBox(height: AppSpacing.lg),
                      if (_method != StudyMethod.simple)
                        _buildStatsRow(
                          context,
                        ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
                      const SizedBox(height: AppSpacing.lg),
                      _MethodCard(
                        method: _method,
                        configSummary: _methodSummary(),
                        onShowPresets: () async {
                          final picked =
                              await showModalBottomSheet<TimerPreset>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder:
                                    (_) => PresetsSheet(
                                      svc: svc,
                                      courseId: _courseId,
                                    ),
                              );
                          if (picked != null) _loadPreset(picked);
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SelectorsCard(
                        child: _HeaderSelectors(
                          svc: svc,
                          courseId: _courseId,
                          onCourseChanged: (v) => setState(() => _courseId = v),
                          taskId: _taskId,
                          onTaskChanged: (v) => setState(() => _taskId = v),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatCard(
            icon: Icons.loop_rounded,
            label: 'Ciclos',
            value: '$_cycle',
            color: cs.primary,
          ),
          _StatCard(
            icon: Icons.timer_outlined,
            label: 'Minutos',
            value: '$_accumulatedMinutes',
            color: cs.secondary,
          ),
          if (_method == StudyMethod.simple)
            _StatCard(
              icon: Icons.flag_outlined,
              label: 'Vueltas',
              value: '$_laps',
              color: cs.tertiary,
            ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          FilledButton.icon(
            onPressed: _isRunning ? null : _start,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: Text(
              'Iniciar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: _isRunning ? _pause : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.pause_rounded, size: 24),
            label: Text(
              'Pausar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _reset,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 24),
            label: Text(
              'Reset',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_courseId != null &&
              (_phase != 'ready' || _accumulatedMinutes > 0))
            FilledButton.icon(
              onPressed: _stopAndSave,
              style: FilledButton.styleFrom(
                backgroundColor: cs.tertiary,
                foregroundColor: cs.onTertiary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.save_rounded, size: 24),
              label: Text(
                'Guardar sesión',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final s = seconds.abs();
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  String _methodSummary() {
    switch (_method) {
      case StudyMethod.pomodoro:
        final work = (_cfg['work'] ?? 25).toString();
        final short = (_cfg['short'] ?? 5).toString();
        final long = (_cfg['long'] ?? 15).toString();
        final cycles = (_cfg['cycles'] ?? 4).toString();
        return 'Pomodoro • $work trabajo / $short descanso (largo $long cada $cycles)';
      case StudyMethod.flowtime:
        final ratio = (_cfg['ratio'] ?? 0.2).toString();
        return 'Flowtime • Descanso proporcional (ratio $ratio)';
      case StudyMethod.timeboxing:
        final block = (_cfg['block'] ?? 50).toString();
        final rest = (_cfg['rest'] ?? 10).toString();
        return 'Timeboxing • $block min bloque / $rest min pausa';
      case StudyMethod.simple:
        return 'Cronómetro simple • cuenta ascendente';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhasePill extends StatelessWidget {
  final String label;
  final Color color;
  const _PhasePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerHeroCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final Color phaseColor;
  final String phaseLabel;
  final String timeLeft;
  final String totalTimeLabel;
  final int cycle;
  final Widget timer;
  final Widget controls;

  const _TimerHeroCard({
    required this.colorScheme,
    required this.phaseColor,
    required this.phaseLabel,
    required this.timeLeft,
    required this.totalTimeLabel,
    required this.cycle,
    required this.timer,
    required this.controls,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [phaseColor.withOpacity(0.9), colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: phaseColor.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phaseLabel,
                    style: GoogleFonts.plusJakartaSans(
                      color: colorScheme.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Ciclo $cycle',
                    style: GoogleFonts.plusJakartaSans(
                      color: colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: colorScheme.onPrimary.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  'Total ${totalTimeLabel == '--:--' ? 'n/a' : totalTimeLabel}',
                  style: GoogleFonts.jetBrainsMono(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          Center(child: timer),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              timeLeft,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          controls,
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final StudyMethod method;
  final String configSummary;
  final VoidCallback onShowPresets;

  const _MethodCard({
    required this.method,
    required this.configSummary,
    required this.onShowPresets,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(Icons.schema_rounded, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo: ${method.name.toUpperCase()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(configSummary, style: AppTypography.caption(context)),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: onShowPresets,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            child: const Text('Presets'),
          ),
        ],
      ),
    );
  }
}

class _SelectorsCard extends StatelessWidget {
  final Widget child;
  const _SelectorsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
      ),
      child: child,
    );
  }
}

class _HeaderSelectors extends StatelessWidget {
  final StudyFirestoreService svc;
  final String? courseId;
  final ValueChanged<String?> onCourseChanged;
  final String? taskId;
  final ValueChanged<String?> onTaskChanged;
  const _HeaderSelectors({
    required this.svc,
    required this.courseId,
    required this.onCourseChanged,
    required this.taskId,
    required this.onTaskChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<Course>>(
      stream: svc.streamCourses(),
      builder: (context, csnap) {
        final courses = csnap.data ?? const [];

        final validCourseId =
            courses.any((c) => c.id == courseId) ? courseId : null;
        if (validCourseId != courseId &&
            validCourseId == null &&
            courseId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onCourseChanged(null);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecciona un curso',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (courses.isEmpty)
                    Text(
                      'No hay cursos disponibles',
                      style: GoogleFonts.plusJakartaSans(
                        color: colorScheme.error,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          courses.map((course) {
                            final isSelected = validCourseId == course.id;
                            final courseColor =
                                course.color ?? colorScheme.primary;

                            return InkWell(
                              onTap: () => onCourseChanged(course.id),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? courseColor.withOpacity(0.15)
                                          : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? courseColor
                                            : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: courseColor,
                                        shape: BoxShape.circle,
                                        boxShadow:
                                            isSelected
                                                ? [
                                                  BoxShadow(
                                                    color: courseColor
                                                        .withOpacity(0.4),
                                                    blurRadius: 8,
                                                  ),
                                                ]
                                                : null,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      course.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                        color:
                                            isSelected
                                                ? courseColor
                                                : colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                ],
              ),
            ),
            if (courseId != null)
              StreamBuilder<List<StudyTask>>(
                stream: svc.streamTasks(
                  courseId: courseId!,
                  status: TaskStatus.todo,
                ),
                builder: (context, tsnap) {
                  final tasks = tsnap.data ?? const [];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String?>(
                      initialValue: taskId,
                      hint: const Text('Vincular tarea (opcional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('–')),
                        ...tasks.map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.title),
                          ),
                        ),
                      ],
                      onChanged: onTaskChanged,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}


