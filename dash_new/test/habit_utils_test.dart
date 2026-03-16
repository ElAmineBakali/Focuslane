import 'package:flutter_test/flutter_test.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_model.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_utils.dart';

Habit _buildHabit({
  required Map<String, dynamic> history,
  bool isQuantitative = false,
  double? goalValue,
  String unit = '',
  String? goalUnit,
}) {
  final now = DateTime(2026, 3, 16);
  return Habit(
    id: 'habit-1',
    name: 'Habit test',
    description: '',
    frequency: 'Diario',
    reminderTime: '',
    unit: unit,
    isQuantitative: isQuantitative,
    history: history,
    isActive: true,
    createdAt: now,
    completedDates: const [],
    order: 0,
    daily: true,
    lastUpdated: now,
    colorHex: '0xFF000000',
    reminders: const <HabitReminder>[],
    goalValue: goalValue,
    goalUnit: goalUnit,
  );
}

void main() {
  test('normalizeHabitStatus soporta valores correctos y heredados', () {
    expect(normalizeHabitStatus(habitCompletedValue), habitCompletedValue);
    expect(normalizeHabitStatus('âœ”ï¸'), habitCompletedValue);
    expect(normalizeHabitStatus(habitMissedValue), habitMissedValue);
    expect(normalizeHabitStatus('âŒ'), habitMissedValue);
    expect(normalizeHabitStatus('skipped'), habitSkippedValue);
  });

  test('computeHabitGoalProgress calcula progreso y restante con meta', () {
    final habit = _buildHabit(
      isQuantitative: true,
      unit: 'ml',
      goalValue: 2000.0,
      goalUnit: 'ml',
      history: {'2026-03-16': '1500'},
    );

    final progress = computeHabitGoalProgress(
      habit,
      day: DateTime(2026, 3, 16),
    );

    expect(progress.hasGoal, isTrue);
    expect(progress.current, 1500);
    expect(progress.goal, 2000);
    expect(progress.remaining, 500);
    expect(progress.percent, 75);
    expect(progress.unit, 'ml');
  });

  test('computeHabitStreakStats usa fechas reales y corta por huecos', () {
    final habit = _buildHabit(
      history: {
        '2026-03-12': habitCompletedValue,
        '2026-03-13': habitCompletedValue,
        '2026-03-15': habitCompletedValue,
      },
    );

    final streaks = computeHabitStreakStats(
      habit,
      referenceDate: DateTime(2026, 3, 16),
    );

    expect(streaks.best, 2);
    expect(streaks.current, 1);
  });

  test('buildHabitTimeline alcanza el primer registro histórico disponible', () {
    final habit = _buildHabit(
      history: {'2025-12-31T10:30:00.000': habitCompletedValue},
    );

    final timeline = buildHabitTimeline([habit], extraPastDays: 0);

    expect(timeline.first, normalizeHabitDate(DateTime.now()));
    expect(timeline.last, DateTime(2025, 12, 31));
  });
}