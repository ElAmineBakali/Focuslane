import 'dart:async';

import 'package:intl/intl.dart';
import 'package:mi_dashboard_personal/screens/calendar/models/calendar_models.dart';
import 'package:mi_dashboard_personal/screens/calendar/services/calendar_aggregator_service.dart';
import 'package:mi_dashboard_personal/screens/finance/services/transaction_service.dart';
import 'package:mi_dashboard_personal/screens/gym/services/gym_firestore_service.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_firestore_service.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_model.dart';
import 'package:mi_dashboard_personal/screens/notes/note_firestore_service.dart';
import 'package:mi_dashboard_personal/screens/notes/note_model.dart';
import 'package:mi_dashboard_personal/screens/study/models/study_models.dart';
import 'package:mi_dashboard_personal/screens/study/services/study_firestore_service.dart';
import 'package:mi_dashboard_personal/screens/tasks/task_firestore_service.dart';
import 'package:mi_dashboard_personal/screens/tasks/task_model.dart';
import 'package:rxdart/rxdart.dart';

import 'models/dashboard_summary_model.dart';

class HomeDashboardController {
  HomeDashboardController({
    required this.studyService,
    required this.gymService,
  });

  final StudyFirestoreService studyService;
  final GymFirestoreService gymService;

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
        );
      },
    );
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
    final key = DateFormat('yyyy-MM-dd').format(today);
    if (habit.completedDates.contains(key)) {
      return true;
    }

    final dynamic value = habit.history[key];
    if (value is bool) return value;
    if (value is num) return value > 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == 'done' || lower == '1';
    }
    return false;
  }
}
