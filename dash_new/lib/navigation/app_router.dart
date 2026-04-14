import 'package:flutter/material.dart';

import 'package:focuslane/core/auth/auth_gate.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/auth/screens/login_screen.dart';
import 'package:focuslane/screens/auth/screens/register_screen.dart';
import 'package:focuslane/screens/calendar/screens/calendar_screen.dart';
import 'package:focuslane/screens/finance/routes/finance_routes.dart';
import 'package:focuslane/screens/food/screens/main/food_main_screen.dart';
import 'package:focuslane/screens/food/services/food_firestore_service.dart';
import 'package:focuslane/screens/gym/screens/analytics/gym_analytics_screen.dart';
import 'package:focuslane/screens/gym/screens/main/gym_main_screen.dart';
import 'package:focuslane/screens/gym/screens/routines/routines_list_screen.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';
import 'package:focuslane/screens/habits/screens/habit_create_screen.dart';
import 'package:focuslane/screens/habits/screens/habit_detail_screen.dart';
import 'package:focuslane/screens/habits/models/habit_model.dart';
import 'package:focuslane/screens/habits/screens/habit_stats_screen.dart';
import 'package:focuslane/screens/habits/screens/habits_table_screen.dart';
import 'package:focuslane/screens/home_screen.dart';
import 'package:focuslane/screens/modules_screen.dart';
import 'package:focuslane/screens/notes/screens/note_editor_screen.dart';
import 'package:focuslane/screens/notes/models/note_model.dart';
import 'package:focuslane/screens/notes/screens/notes_list_screen.dart';
import 'package:focuslane/screens/notifications/screens/global_notifications_screen.dart';
import 'package:focuslane/screens/settings/screens/settings_screen.dart';
import 'package:focuslane/screens/study/screens/analytics/study_analytics_screen.dart';
import 'package:focuslane/screens/study/screens/main/study_main_screen.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';
import 'package:focuslane/screens/study/screens/timer/study_timer_screen.dart';
import 'package:focuslane/screens/tasks/screens/task_create_screen.dart';
import 'package:focuslane/screens/tasks/screens/task_edit_screen.dart';
import 'package:focuslane/screens/tasks/models/task_model.dart';
import 'package:focuslane/screens/tasks/screens/tasks_main_screen.dart';

class AppRouterDependencies {
  const AppRouterDependencies({
    required this.foodService,
    required this.gymService,
    required this.studyService,
    required this.themeMode,
    required this.onThemeModeChanged,
  });
  final FoodFirestoreService Function() foodService;
  final GymFirestoreService Function() gymService;
  final StudyFirestoreService Function() studyService;
  final ThemeMode Function() themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
}

Map<String, WidgetBuilder> buildAppRoutes(AppRouterDependencies deps) {
  return {
    AppRoutes.login: (_) => const LoginScreen(),
    AppRoutes.register: (_) => const RegisterScreen(),
    AppRoutes.home: (_) => AuthGate(
      authenticated: const HomeScreen(),
      unauthenticated: const LoginScreen(),
    ),
    '/settings': (_) => SettingsScreen(
      currentThemeMode: deps.themeMode(),
      onThemeModeChanged: deps.onThemeModeChanged,
    ),
    AppRoutes.notifications: (_) => GlobalNotificationsScreen(
      foodService: deps.foodService(),
      studyService: deps.studyService(),
    ),
    '/modules': (_) => const ModulesScreen(),
    AppRoutes.tasksDashboard: (_) => const TasksMainScreen(),
    '/tasks/create': (_) => const TaskCreateScreen(),
    '/tasks/detail': (ctx) {
      final task = ModalRoute.of(ctx)!.settings.arguments as Task;
      return TaskEditScreen(task: task);
    },
    AppRoutes.notesDashboard: (_) => const NotesListScreen(),
    '/notes/list': (_) => const NotesListScreen(),
    '/notes/editor': (ctx) {
      final args = ModalRoute.of(ctx)!.settings.arguments;
      if (args is Note) {
        return NoteEditorScreen(note: args);
      } else if (args is String) {
        return NoteEditorScreen(noteId: args);
      }
      return const NoteEditorScreen();
    },
    '/habits': (_) => const HabitsTableScreen(),
    '/habits/create': (_) => const HabitCreateScreen(),
    '/habit-create': (_) => const HabitCreateScreen(),
    '/habits/detail': (ctx) {
      final habit = ModalRoute.of(ctx)!.settings.arguments as Habit;
      return HabitDetailScreen(habit: habit);
    },
    '/habit-detail': (ctx) {
      final habit = ModalRoute.of(ctx)!.settings.arguments as Habit;
      return HabitDetailScreen(habit: habit);
    },
    '/habits/stats': (ctx) {
      final habit = ModalRoute.of(ctx)!.settings.arguments as Habit;
      return HabitStatsScreen(habit: habit);
    },
    AppRoutes.gymDashboard: (_) {
      final service = deps.gymService();
      return GymMainScreen(svc: service);
    },
    '/gym/routines': (_) {
      final service = deps.gymService();
      return RoutinesListScreen(svc: service);
    },
    '/gym/analytics': (_) {
      final service = deps.gymService();
      return GymAnalyticsScreen(svc: service);
    },
    AppRoutes.studyDashboard: (_) {
      final service = deps.studyService();
      return StudyMainScreen(svc: service);
    },
    '/study/timer': (_) {
      final service = deps.studyService();
      return StudyTimerScreen(svc: service);
    },
    '/study/analytics': (_) {
      final service = deps.studyService();
      return StudyAnalyticsScreen(svc: service);
    },
    AppRoutes.foodDashboard: (_) {
      return FoodMainScreen(svc: deps.foodService());
    },
    '/calendar': (_) => const CalendarScreen(),
    ...financeRoutes,
  };
}


