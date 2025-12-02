import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/blocks/toast/app_toast.dart';
import '../services/study_firestore_service.dart';
import '../models/study_models.dart';
import '../analytics/study_analytics_screen.dart';
import '../../study/tasks/study_tasks_screen.dart';
import 'presets_sheet.dart';
import 'session_summary_screen.dart';
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
  int _cycle = 0;
  Timer? _ticker;

  DateTime? _startedAt;
  int _accumulatedMinutes = 0;
  int _laps = 0;

  static const int _N_WORK_START = 41010;
  static const int _N_REST_START = 41011;
  static const int _N_WORK_END   = 41020;
  static const int _N_REST_END   = 41021;
  static const int _N_SESSION_SAVED = 41030;

  @override
  void initState() {
    super.initState();
    _courseId = widget.initialCourseId;
    _taskId = widget.initialTaskId;
  }

  @override
  void dispose() {
    _ticker?.cancel();
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
      _cycle = 0;
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
        final seq = (_cfg['sequence'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
        if (seq.isEmpty) {
          AppToast.error(context, 'Secuencia vacía');
          return;
        }
        final first = seq.first;
        _startBox('work', (first['work'] ?? 40).toInt());
        break;
      case StudyMethod.simple:
        _phase = 'counting';
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
    _changePhase('work', work, after: () {
      final isLong = (_cycle % ((_cfg['cycles'] ?? 4).toInt())) == 0;
      final restMin = isLong ? (_cfg['long'] ?? 15).toInt() : (_cfg['short'] ?? 5).toInt();
      _changePhase('rest', restMin * 60, after: () {});
    });
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

  void _changePhase(String newPhase, int seconds, {required VoidCallback after}) {
    _ticker?.cancel();
    setState(() {
      _phase = newPhase;
      _timeLeft = seconds;
    });

    _cancelStudyPhaseNotifs();
    _notifyPhaseStart(newPhase, seconds);

    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        if (_phase == 'work') _accumulatedMinutes += (seconds / 60).round();
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
          final seq = (_cfg['sequence'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
          final currentRest = (seq.first['rest'] ?? 10).toInt();
          _changePhase('rest', currentRest * 60, after: () {});
          return;
        }
        if (_method == StudyMethod.pomodoro) {
          _startPomodoro();
          return;
        }
        setState(() => _phase = 'ready');
        after();
      } else {
        setState(() => _timeLeft -= 1);
      }
    });
  }

  void _pause() {
    _ticker?.cancel();
    _cancelStudyPhaseNotifs();
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _phase = 'ready';
      _timeLeft = 0;
      _cycle = 0;
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
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => SessionSummaryScreen(session: session),
    ));
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
        case 'work': return cs.primaryContainer;
        case 'rest': return cs.tertiaryContainer;
        case 'counting': return cs.secondaryContainer;
        default: return cs.surfaceContainerHighest;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudio'),
        actions: [
          IconButton(
            tooltip: 'Presets',
            icon: const Icon(Icons.tune),
            onPressed: () async {
              final picked = await showModalBottomSheet<TimerPreset>(
                context: context,
                isScrollControlled: true,
                builder: (_) => PresetsSheet(svc: svc, courseId: _courseId),
              );
              if (picked != null) _loadPreset(picked);
            },
          ),
          IconButton(
            tooltip: 'Tareas',
            icon: const Icon(Icons.checklist),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => StudyTasksScreen(svc: svc, initialCourseId: _courseId),
              ));
            },
          ),
          IconButton(
            tooltip: 'Analytics',
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => StudyAnalyticsScreen(svc: svc, courseId: _courseId),
              ));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _HeaderSelectors(
            svc: svc,
            courseId: _courseId,
            onCourseChanged: (v) => setState(() => _courseId = v),
            taskId: _taskId,
            onTaskChanged: (v) => setState(() => _taskId = v),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: phaseColor(_phase),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_phase == 'work' ? Icons.play_circle_fill : _phase == 'rest' ? Icons.self_improvement : Icons.hourglass_empty),
                        const SizedBox(width: 8),
                        Text(phaseLabel, style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_formatTime(_timeLeft), style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold)),
                    if (_method != StudyMethod.simple)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Ciclo: $_cycle', style: const TextStyle(fontStyle: FontStyle.italic)),
                      ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(onPressed: _start, icon: const Icon(Icons.play_arrow), label: const Text('Iniciar')),
                        OutlinedButton.icon(onPressed: _pause, icon: const Icon(Icons.pause), label: const Text('Pausar')),
                        TextButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh), label: const Text('Reset')),
                        if (_courseId != null) FilledButton.tonalIcon(
                          onPressed: _stopAndSave,
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar sesión'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
    return StreamBuilder<List<Course>>(
      stream: svc.streamCourses(),
      builder: (context, csnap) {
        final courses = csnap.data ?? const [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<String?>(
                initialValue: courseId,
                hint: const Text('Curso'),
                items: [
                  ...courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: onCourseChanged,
              ),
            ),
            if (courseId != null)
              StreamBuilder<List<StudyTask>>(
                stream: svc.streamTasks(courseId: courseId!, status: TaskStatus.todo),
                builder: (context, tsnap) {
                  final tasks = tsnap.data ?? const [];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String?>(
                      initialValue: taskId,
                      hint: const Text('Vincular tarea (opcional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        ...tasks.map((t) => DropdownMenuItem(value: t.id, child: Text(t.title))),
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
