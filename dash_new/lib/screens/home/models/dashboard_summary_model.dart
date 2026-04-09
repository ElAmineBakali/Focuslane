import 'package:focuslane/screens/calendar/models/calendar_models.dart';
import 'package:focuslane/screens/habits/habit_model.dart';
import 'package:focuslane/screens/notes/note_model.dart';
import 'package:focuslane/screens/study/models/study_models.dart';
import 'package:focuslane/screens/tasks/task_model.dart';

class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.today,
    required this.pendingTasksToday,
    required this.tasksToday,
    required this.habits,
    required this.completedHabitsToday,
    required this.upcomingEvents,
    required this.studyTasks,
    required this.latestStudySession,
    required this.latestGymSession,
    required this.defaultGymRoutineName,
    required this.monthExpense,
    required this.monthIncome,
    required this.recentNotes,
  });

  final DateTime today;
  final int pendingTasksToday;
  final List<Task> tasksToday;
  final List<Habit> habits;
  final int completedHabitsToday;
  final List<CalendarItem> upcomingEvents;
  final List<StudyTask> studyTasks;
  final StudySession? latestStudySession;
  final DateTime? latestGymSession;
  final String? defaultGymRoutineName;
  final double monthExpense;
  final double monthIncome;
  final List<Note> recentNotes;

  int get activeHabitsCount => habits.length;

  double get habitCompletionRatio {
    if (habits.isEmpty) return 0;
    return completedHabitsToday / habits.length;
  }

  double get taskCompletionRatio {
    if (tasksToday.isEmpty) return 0;
    final completed = tasksToday.where((task) => task.completed).length;
    return completed / tasksToday.length;
  }

  double get weeklyConsistency {
    final a = habitCompletionRatio;
    final b = taskCompletionRatio;
    return (a + b) / 2;
  }

  bool get hasUsefulData {
    return pendingTasksToday > 0 ||
        completedHabitsToday > 0 ||
        upcomingEvents.isNotEmpty ||
        studyTasks.isNotEmpty ||
        latestStudySession != null ||
        latestGymSession != null ||
        recentNotes.isNotEmpty ||
        monthExpense > 0 ||
        monthIncome > 0;
  }
}

