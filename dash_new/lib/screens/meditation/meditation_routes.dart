import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/meditation/presets/breath_presets_screen.dartbreath_presets_screen.dart';
import 'dashboard/meditation_home_screen.dart';
import 'timer/timer_session_screen.dart';
import 'breathing/breathing_coach_screen.dart';
import 'sessions/sessions_log_screen.dart';
import 'sessions/session_edit_screen.dart';
import 'programs/programs_screen.dart';
import 'programs/program_detail_screen.dart';
import 'programs/program_day_screen.dart';
import 'programs/program_day_edit_screen.dart';
import 'analytics/meditation_analytics_screen.dart';
import 'presets/breath_preset_edit_screen.dart';
import 'reminders/reminders_screen.dart';
import 'reminders/reminder_edit_screen.dart';
import 'tags/tags_screen.dart';
import 'guided/guided_library_screen.dart';
import 'guided/guided_player_screen.dart';
import 'guided/guided_edit_screen.dart';

Map<String, WidgetBuilder> meditationRoutes = {
  MeditationHomeScreen.route: (_) => const MeditationHomeScreen(),
  TimerSessionScreen.route: (_) => const TimerSessionScreen(),
  BreathingCoachScreen.route: (_) => const BreathingCoachScreen(),
  SessionsLogScreen.route: (_) => const SessionsLogScreen(),
  SessionEditScreen.route: (_) => const SessionEditScreen(),
  ProgramsScreen.route: (_) => const ProgramsScreen(),
  ProgramDetailScreen.route: (_) => const ProgramDetailScreen(),
  ProgramDayScreen.route: (_) => const ProgramDayScreen(),
  ProgramDayEditScreen.route: (_) => const ProgramDayEditScreen(),
  MeditationAnalyticsScreen.route: (_) => const MeditationAnalyticsScreen(),
  BreathPresetsScreen.route: (_) => const BreathPresetsScreen(),
  BreathPresetEditScreen.route: (_) => const BreathPresetEditScreen(),
  RemindersScreen.route: (_) => const RemindersScreen(),
  ReminderEditScreen.route: (_) => const ReminderEditScreen(),
  TagsScreen.route: (_) => const TagsScreen(),
  GuidedLibraryScreen.route: (_) => const GuidedLibraryScreen(),
  GuidedPlayerScreen.route: (_) => const GuidedPlayerScreen(),
  GuidedEditScreen.route: (_) => const GuidedEditScreen(),
};
