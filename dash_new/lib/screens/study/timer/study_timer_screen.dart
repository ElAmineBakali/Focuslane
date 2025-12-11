import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:mi_dashboard_personal/blocks/toast/app_toast.dart';
import '../services/study_firestore_service.dart';
import '../models/study_models.dart';
import '../analytics/study_analytics_screen.dart';
import '../../study/tasks/study_tasks_screen.dart';
import 'presets_sheet.dart';
import 'session_summary_screen.dart';
import 'circular_timer_widget.dart';
import 'package:mi_dashboard_personal/services/notification_service.dart';

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
  static const int _N_WORK_END = 41020;
  static const int _N_REST_END = 41021;
  static const int _N_SESSION_SAVED = 41030;

  @override
  void initState() {
    super.initState();
    _courseId = widget.initialCourseId;
    _taskId = widget.initialTaskId;
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _confettiController.dispose();
    _cancelStudyPhaseNotifs();
    super.dispose();
  }

  Future<void> _cancelStudyPhaseNotifs() async {
    await NotificationService.I.cancel(_N_WORK_END);
    await NotificationService.I.cancel(_N_REST_END);
  }

  Future<void> _notifyPhaseStart(String phase, int seconds) async {
    if (phase == 'work') {
      await NotificationService.I.showNow(
        id: _N_WORK_START,
        title: 'Estudio',
        body: 'Trabajo iniciado (${(seconds / 60).round()} min)',
      );
      await NotificationService.I.scheduleOnce(
        id: _N_WORK_END,
        title: 'Fin del trabajo',
        body: 'Toca descanso',
        whenLocal: DateTime.now().add(Duration(seconds: seconds)),
        useExact: true,
      );
    } else if (phase == 'rest') {
      await NotificationService.I.showNow(
        id: _N_REST_START,
        title: 'Estudio',
        body: 'Descanso iniciado (${(seconds / 60).round()} min)',
      );
      await NotificationService.I.scheduleOnce(
        id: _N_REST_END,
        title: 'Fin del descanso',
        body: 'Vuelve al trabajo',
        whenLocal: DateTime.now().add(Duration(seconds: seconds)),
        useExact: true,
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
      case StudyMethod.custom:
        final seq =
            (_cfg['sequence'] as List?)?.cast<Map<String, dynamic>>() ??
            const [];
        if (seq.isEmpty) {
          AppToast.error(context, 'Secuencia vacía');
          return;
        }
        final first = seq.first;
        _startBox('work', (first['work'] ?? 40).toInt());
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
        NotificationService.I.showNow(
          id: _N_WORK_START,
          title: 'Estudio',
          body: 'Sesión iniciada',
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
    NotificationService.I.showNow(
      id: _N_WORK_START,
      title: 'Estudio',
      body: 'Trabajo iniciado (Flowtime)',
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
          // Show confetti on work completion
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
        if (_method == StudyMethod.custom && _phase == 'work') {
          final seq =
              (_cfg['sequence'] as List?)?.cast<Map<String, dynamic>>() ??
              const [];
          final currentRest = (seq.first['rest'] ?? 10).toInt();
          _changePhase('rest', currentRest * 60, after: () {});
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
    await NotificationService.I.showNow(
      id: _N_SESSION_SAVED,
      title: 'Estudio',
      body: 'Sesión guardada ($minutes min)',
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SessionSummaryScreen(session: session)),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Estudio',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
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
                builder: (_) => PresetsSheet(svc: svc, courseId: _courseId),
              );
              if (picked != null) _loadPreset(picked);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  phaseColor(_phase).withOpacity(0.1),
                  cs.surface,
                  cs.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Confetti overlay
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
          // Main content
          SafeArea(
            child: Column(
              children: [
                _HeaderSelectors(
                  svc: svc,
                  courseId: _courseId,
                  onCourseChanged: (v) => setState(() => _courseId = v),
                  taskId: _taskId,
                  onTaskChanged: (v) => setState(() => _taskId = v),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Circular timer
                        CircularTimerWidget(
                          timeLeft: _timeLeft,
                          totalTime: _totalTime,
                          phase: phaseLabel,
                          color: phaseColor(_phase),
                          isRunning: _isRunning,
                        )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .scale(begin: const Offset(0.8, 0.8)),
                        const SizedBox(height: 32),
                        // Stats row
                        if (_method != StudyMethod.simple)
                          _buildStatsRow(context).animate().fadeIn(
                                delay: 200.ms,
                                duration: 400.ms,
                              ),
                        const SizedBox(height: 32),
                        // Control buttons
                        _buildControlButtons(context).animate().fadeIn(
                              delay: 400.ms,
                              duration: 400.ms,
                            ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
          if (_courseId != null && (_phase != 'ready' || _accumulatedMinutes > 0))
            FilledButton.icon(
              onPressed: _stopAndSave,
              style: FilledButton.styleFrom(
                backgroundColor: cs.tertiary,
                foregroundColor: cs.onTertiary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
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
        
        // FIX: Validar que el courseId existe en la lista actual
        final validCourseId = courses.any((c) => c.id == courseId) ? courseId : null;
        if (validCourseId != courseId && validCourseId == null && courseId != null) {
          // Resetear el courseId si ya no existe
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
                      children: courses.map((course) {
                        final isSelected = validCourseId == course.id;
                        final courseColor = course.color ?? colorScheme.primary;
                        
                        return InkWell(
                          onTap: () => onCourseChanged(course.id),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? courseColor.withOpacity(0.15)
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
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
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: courseColor.withOpacity(0.4),
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
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
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
                        const DropdownMenuItem(value: null, child: Text('—')),
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
