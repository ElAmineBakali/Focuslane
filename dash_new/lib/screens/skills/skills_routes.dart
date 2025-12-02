import 'package:flutter/material.dart';

import 'dashboard/skills_home_screen.dart';
import 'skills/skill_edit_screen.dart';
import 'skills/skill_detail_screen.dart';
import 'skills/session_timer_screen.dart';

import 'projects/project_board_screen.dart';

import 'reviews/review_weekly_screen.dart';
import 'reviews/review_monthly_screen.dart';

import 'analytics/skills_analytics_screen.dart';

Map<String, WidgetBuilder> skillsRoutes = {
  SkillsHomeScreen.route: (_) => const SkillsHomeScreen(),

  SkillEditScreen.route: (_) => const SkillEditScreen(),
  SkillDetailScreen.route: (_) => const SkillDetailScreen(),
  SessionTimerScreen.route: (_) => const SessionTimerScreen(),

  ProjectBoardScreen.route: (_) => const ProjectBoardScreen(),

  ReviewWeeklyScreen.route: (_) => const ReviewWeeklyScreen(),
  ReviewMonthlyScreen.route: (_) => const ReviewMonthlyScreen(),

  SkillsAnalyticsScreen.route: (_) => const SkillsAnalyticsScreen(),
};
