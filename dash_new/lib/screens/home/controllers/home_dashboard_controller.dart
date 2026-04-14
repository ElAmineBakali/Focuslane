import 'dart:async';

import 'package:intl/intl.dart';
import 'package:focuslane/screens/calendar/models/calendar_models.dart';
import 'package:focuslane/screens/calendar/services/calendar_aggregator_service.dart';
import 'package:focuslane/screens/finance/services/transaction_service.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';
import 'package:focuslane/screens/habits/services/habit_firestore_service.dart';
import 'package:focuslane/screens/habits/models/habit_model.dart';
import 'package:focuslane/screens/habits/utils/habit_utils.dart';
import 'package:focuslane/screens/notes/services/note_firestore_service.dart';
import 'package:focuslane/screens/notes/models/note_model.dart';
import 'package:focuslane/screens/study/models/study_models.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';
import 'package:focuslane/screens/tasks/services/task_firestore_service.dart';
import 'package:focuslane/screens/tasks/models/task_model.dart';
import 'package:rxdart/rxdart.dart';

import '../models/dashboard_summary_model.dart';

class HomeDashboardController {
  HomeDashboardController({
    required this.studyService,
    required this.gymService,
  });

  final StudyFirestoreService studyService;
  final GymFirestoreService gymService;

  static const List<String> _dailyMotivation = [
    'Hoy no se improvisa: hoy se avanza.',
    'Una tarea terminada vale más que diez pendientes.',
    'Menos ruido, más foco.',
    'Constancia pequeña, resultados grandes.',
    'Lo importante primero, lo urgente después.',
    'Hazlo simple, hazlo bien, hazlo hoy.',
    'Tu progreso de hoy es la calma de mañana.',
    'Empieza por una cosa y termínala.',
    'La disciplina de hoy evita el estrés de mañana.',
    'Prioriza lo que te acerca a tu objetivo.',
    'Siete días consistentes valen más que uno perfecto.',
    'Si es importante, ponlo en calendario y hazlo.',
  ];

  Stream<DashboardSummaryModel> streamSummary() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 14));
    final safeMonthlyStats = TransactionService.I
        .monthlyStats(now)
        .onErrorReturn(const {
          'income': 0,
          'expense': 0,
          'balance': 0,
        });

    return Rx.combineLatest9(
      TaskFirestoreService.getTasks(),
      HabitFirestoreService.getHabits(),
      CalendarAggregatorService.I.combinedItems(start, end),
      studyService.streamTasks(),
      studyService.streamSessions(limit: 20),
      gymService.streamSessions(limit: 20),
      gymService.streamDefaultRoutine(),
      safeMonthlyStats,
      NoteFirestoreService.getNotes(),
      (
        List<Task> tasks,
        List<Habit> habits,
        List<CalendarItem> events,
        List<StudyTask> studyTasks,
        List<StudySession> studySessions,
        List<SessionDoc> gymSessions,
        Routine? defaultRoutine,
        Map<String, double> monthlyStats,
        List<Note> notes,
      ) {
        final todayTasks = tasks.where((task) => _isSameDay(task.dueDate, now)).toList();
        final pending = todayTasks.where((task) => !task.completed).length;
        final habitsDone = habits.where((habit) => _isHabitCompletedToday(habit, now)).length;

        final upcomingEvents = events
            .where((item) => !item.startAt.isBefore(start))
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));

        final todayStudyTasks = studyTasks
            .where((task) => _isSameDay(task.due, now))
            .toList();

        final weekStart = start.subtract(Duration(days: start.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        final weekTasks = tasks
            .where((task) => task.dueDate != null)
            .where((task) => !task.dueDate!.isBefore(weekStart) && task.dueDate!.isBefore(weekEnd))
            .toList();
        final weeklyTasksDone = weekTasks.where((task) => task.completed).length;
        final weeklyTasksTotal = weekTasks.length;
        final weeklyTaskCompletion = weeklyTasksTotal == 0
          ? 0.0
          : weeklyTasksDone / weeklyTasksTotal;

        int habitsWithActivity = 0;
        for (final habit in habits) {
          var completedThisWeek = false;
          for (var i = 0; i < 7; i++) {
            final day = weekStart.add(Duration(days: i));
            if (_isHabitCompletedOnDay(habit, day)) {
              completedThisWeek = true;
              break;
            }
          }
          if (completedThisWeek) {
            habitsWithActivity += 1;
          }
        }
        final weeklyHabitCompletion = habits.isEmpty ? 0.0 : habitsWithActivity / habits.length;

        final recentNotes = notes.take(5).toList(growable: false);

        final latestStudy = studySessions.isEmpty ? null : studySessions.first;

        DateTime? latestGymSession;
        if (gymSessions.isNotEmpty) {
          latestGymSession = DateTime.tryParse(gymSessions.first.date.toString());
        }

        return DashboardSummaryModel(
          today: now,
          pendingTasksToday: pending,
          tasksToday: todayTasks,
          habits: habits,
          completedHabitsToday: habitsDone,
          upcomingEvents: upcomingEvents.take(6).toList(growable: false),
          studyTasks: todayStudyTasks,
          latestStudySession: latestStudy,
          latestGymSession: latestGymSession,
          defaultGymRoutineName: defaultRoutine?.name,
          monthExpense: monthlyStats['expense'] ?? 0,
          monthIncome: monthlyStats['income'] ?? 0,
          recentNotes: recentNotes,
          weeklyHabitCompletion: weeklyHabitCompletion,
          weeklyTaskCompletion: weeklyTaskCompletion,
          weeklyHabitChecksDone: habitsWithActivity,
          weeklyHabitChecksTotal: habits.length,
          weeklyTasksDone: weeklyTasksDone,
          weeklyTasksTotal: weeklyTasksTotal,
        );
      },
    );
  }

  String motivationalPhraseFor(DateTime now) {
    final idx = phraseIndexForDate(now);
    return _dailyMotivation[idx];
  }

  int phraseIndexForDate(DateTime now) {
    final seed = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    return seed % _dailyMotivation.length;
  }

  String greetingFor(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Buenos dias';
    if (hour < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String dayLabel(DateTime date) {
    return DateFormat('EEEE, d MMM', 'es_ES').format(date);
  }

  String todayShortSummary(DashboardSummaryModel summary) {
    final pieces = <String>[];
    pieces.add('${summary.pendingTasksToday} tareas pendientes');
    pieces.add('${summary.completedHabitsToday}/${summary.activeHabitsCount} habitos');
    pieces.add('${summary.upcomingEvents.length} eventos proximos');
    return pieces.join(' · ');
  }

  static bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isHabitCompletedToday(Habit habit, DateTime today) {
    return _isHabitCompletedOnDay(habit, today);
  }

  static bool _isHabitCompletedOnDay(Habit habit, DateTime day) {
    final value = habitHistoryValueForDate(habit.history, day);
    return isHabitCompletedValue(habit, value);
  }
}


