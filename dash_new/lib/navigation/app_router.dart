import 'package:flutter/material.dart';

import 'package:mi_dashboard_personal/core/auth/auth_gate.dart';
import 'package:mi_dashboard_personal/design/theme/theme.dart';
import 'package:mi_dashboard_personal/design/theme/prefs.dart';
import 'package:mi_dashboard_personal/navigation/app_routes.dart';
import 'package:mi_dashboard_personal/screens/auth/login_screen.dart';
import 'package:mi_dashboard_personal/screens/auth/register_screen.dart';
import 'package:mi_dashboard_personal/screens/calendar/calendar_screen.dart';
import 'package:mi_dashboard_personal/screens/finance/main/finance_routes.dart';
import 'package:mi_dashboard_personal/screens/food/main/food_main_screen.dart';
import 'package:mi_dashboard_personal/screens/food/services/food_firestore_service.dart';
import 'package:mi_dashboard_personal/screens/gym/analytics/gym_analytics_screen.dart';
import 'package:mi_dashboard_personal/screens/gym/body/bodyweight_screen.dart';
import 'package:mi_dashboard_personal/screens/gym/body/measurements_screen.dart';
import 'package:mi_dashboard_personal/screens/gym/goals/gym_goals_screen.dart';
import 'package:mi_dashboard_personal/screens/gym/main/gym_main_screen.dart';
import 'package:mi_dashboard_personal/screens/gym/routines/routines_list_screen.dart';
import 'package:mi_dashboard_personal/screens/gym/services/gym_firestore_service.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_create_screen.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_detail_screen.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_model.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_stats_screen.dart';
import 'package:mi_dashboard_personal/screens/habits/habits_table_screen.dart';
import 'package:mi_dashboard_personal/screens/home_screen.dart';
import 'package:mi_dashboard_personal/screens/modules_screen.dart';
import 'package:mi_dashboard_personal/screens/notes/note_editor_screen.dart';
import 'package:mi_dashboard_personal/screens/notes/note_model.dart';
import 'package:mi_dashboard_personal/screens/notes/notes_list_screen.dart';
import 'package:mi_dashboard_personal/screens/settings/settings_screen.dart';
import 'package:mi_dashboard_personal/screens/study/analytics/study_analytics_screen.dart';
import 'package:mi_dashboard_personal/screens/study/main/study_main_screen.dart';
import 'package:mi_dashboard_personal/screens/study/services/study_firestore_service.dart';
import 'package:mi_dashboard_personal/screens/study/timer/study_timer_screen.dart';
import 'package:mi_dashboard_personal/screens/tasks/task_create_screen.dart';
import 'package:mi_dashboard_personal/screens/tasks/task_edit_screen.dart';
import 'package:mi_dashboard_personal/screens/tasks/task_model.dart';
import 'package:mi_dashboard_personal/screens/tasks/tasks_main_screen.dart';

class AppRouterDependencies {
  const AppRouterDependencies({
    required this.preset,
    required this.themeMode,
    required this.backgroundStyle,
    required this.onChangePreset,
    required this.onChangeMode,
    required this.onChangeBackground,
    required this.foodService,
    required this.gymService,
    required this.studyService,
  });

  final ThemePreset preset;
  final ThemeMode themeMode;
  final BackgroundStyle backgroundStyle;
  final ValueChanged<ThemePreset> onChangePreset;
  final ValueChanged<ThemeMode> onChangeMode;
  final ValueChanged<BackgroundStyle> onChangeBackground;
  final FoodFirestoreService Function() foodService;
  final GymFirestoreService Function() gymService;
  final StudyFirestoreService Function() studyService;
}

Map<String, WidgetBuilder> buildAppRoutes(AppRouterDependencies deps) {
  return {
    AppRoutes.login: (_) => const LoginScreen(),
    AppRoutes.register: (_) => const RegisterScreen(),
    AppRoutes.home: (_) => AuthGate(
      authenticated: HomeScreen(
        toggleTheme: (isDark) {
          deps.onChangeMode(isDark ? ThemeMode.dark : ThemeMode.light);
        },
        themeMode: deps.themeMode,
      ),
      unauthenticated: const LoginScreen(),
    ),
    '/settings': (_) => SettingsScreen(
      currentPreset: deps.preset,
      currentMode: deps.themeMode,
      currentBackground: deps.backgroundStyle,
      onChangePreset: deps.onChangePreset,
      onChangeMode: deps.onChangeMode,
      onChangeBackground: deps.onChangeBackground,
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
    '/gym/goals': (_) {
      final service = deps.gymService();
      return GymGoalsScreen(svc: service);
    },
    '/gym/body/weight': (_) {
      final service = deps.gymService();
      return BodyweightScreen(svc: service);
    },
    '/gym/body/measurements': (_) {
      final service = deps.gymService();
      return MeasurementsScreen(svc: service);
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