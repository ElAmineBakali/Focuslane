import 'dart:math' as math;

import '../models/habit_model.dart';

const String habitCompletedValue = '\u2714\ufe0f';
const String habitMissedValue = '\u274c';
const String habitSkippedValue = '-';

String _twoDigits(int value) => value.toString().padLeft(2, '0');

DateTime normalizeHabitDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);

String habitDateKey(DateTime date) {
  final normalized = normalizeHabitDate(date);
  return '${normalized.year}-${_twoDigits(normalized.month)}-${_twoDigits(normalized.day)}';
}

DateTime? parseHabitHistoryDate(dynamic rawDate) {
  if (rawDate == null) {
    return null;
  }

  if (rawDate is DateTime) {
    return normalizeHabitDate(rawDate);
  }

  final parsed = DateTime.tryParse(rawDate.toString());
  if (parsed != null) {
    return normalizeHabitDate(parsed);
  }

  return null;
}

Map<DateTime, dynamic> normalizeHabitHistory(Map<String, dynamic> history) {
  final normalized = <DateTime, dynamic>{};

  for (final entry in history.entries) {
    final parsedDate = parseHabitHistoryDate(entry.key);
    if (parsedDate == null) {
      continue;
    }
    normalized[parsedDate] = entry.value;
  }

  return normalized;
}

Map<String, dynamic> buildHabitHistoryKeyIndex(Map<String, dynamic> history) {
  final index = <String, dynamic>{};

  for (final entry in history.entries) {
    final parsedDate = parseHabitHistoryDate(entry.key);
    if (parsedDate == null) {
      continue;
    }

    index[habitDateKey(parsedDate)] = entry.value;
  }

  return index;
}

dynamic habitHistoryIndexedValue(Map<String, dynamic> indexedHistory, DateTime date) {
  return indexedHistory[habitDateKey(date)];
}

dynamic habitHistoryValueForDate(Map<String, dynamic> history, DateTime date) {
  final normalizedDate = normalizeHabitDate(date);
  final directKey = habitDateKey(normalizedDate);
  if (history.containsKey(directKey)) {
    return history[directKey];
  }

  for (final entry in history.entries) {
    final parsedDate = parseHabitHistoryDate(entry.key);
    if (parsedDate == normalizedDate) {
      return entry.value;
    }
  }

  return null;
}

String? normalizeHabitStatus(dynamic value) {
  final status = value?.toString().trim();
  if (status == null || status.isEmpty) {
    return null;
  }

  switch (status) {
    case habitCompletedValue:
    case '✔':
    case 'done':
    case 'completed':
    case 'complete':
    case 'true':
    case 'âœ”ï¸':
      return habitCompletedValue;
    case habitMissedValue:
    case 'missed':
    case 'failed':
    case 'false':
    case 'âŒ':
      return habitMissedValue;
    case habitSkippedValue:
    case 'skip':
    case 'skipped':
    case 'saltar':
    case 'saltado':
      return habitSkippedValue;
    default:
      return null;
  }
}

double parseHabitNumericValue(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  final raw = value.toString().trim();
  if (raw.isEmpty) {
    return 0;
  }

  final sanitized = raw.replaceAll(',', '.').replaceAll(
    RegExp(r'[^0-9.\-]'),
    '',
  );

  return double.tryParse(sanitized) ?? 0;
}

bool isHabitLoggedValue(Habit habit, dynamic value) {
  if (value == null) {
    return false;
  }

  if (habit.isQuantitative) {
    final status = normalizeHabitStatus(value);
    if (status == habitSkippedValue) {
      return true;
    }

    return value.toString().trim().isNotEmpty;
  }

  return normalizeHabitStatus(value) != null;
}

bool isHabitCompletedValue(Habit habit, dynamic value) {
  if (habit.isQuantitative) {
    final amount = parseHabitNumericValue(value);
    if (habit.hasGoal) {
      return amount >= habit.goalValue!;
    }
    return amount > 0;
  }

  return normalizeHabitStatus(value) == habitCompletedValue;
}

bool isHabitMissedValue(dynamic value) =>
    normalizeHabitStatus(value) == habitMissedValue;

bool isHabitSkippedValue(dynamic value) =>
    normalizeHabitStatus(value) == habitSkippedValue;

String formatHabitStatNumber(num? value) {
  return (value ?? 0).toDouble().toStringAsFixed(2);
}

String formatHabitCompactNumber(num? value) {
  final number = (value ?? 0).toDouble();
  final absoluteValue = number.abs();
  final prefix = number < 0 ? '-' : '';

  if (absoluteValue >= 1000000) {
    return '$prefix${_formatCompactChunk(absoluteValue / 1000000)}M';
  }

  if (absoluteValue >= 1000) {
    return '$prefix${_formatCompactChunk(absoluteValue / 1000)}k';
  }

  return formatHabitStatNumber(number);
}

String _formatCompactChunk(double value) {
  if (value >= 100 || value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  final fixed = value >= 10
      ? value.toStringAsFixed(1)
      : value.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

List<DateTime> buildHabitTimeline(
  List<Habit> habits, {
  int extraPastDays = 3650,
}) {
  final today = normalizeHabitDate(DateTime.now());
  final earliestDate = resolveEarliestHabitDate(
    habits,
    extraPastDays: extraPastDays,
  );
  final days = today.difference(earliestDate).inDays + 1;

  return List<DateTime>.generate(
    days,
    (index) => today.subtract(Duration(days: index)),
    growable: false,
  );
}

DateTime resolveEarliestHabitDate(
  List<Habit> habits, {
  int extraPastDays = 3650,
}) {
  final today = normalizeHabitDate(DateTime.now());
  var earliestDate = today;

  for (final habit in habits) {
    final createdAt = normalizeHabitDate(habit.createdAt);
    if (createdAt.isBefore(earliestDate)) {
      earliestDate = createdAt;
    }

    for (final date in normalizeHabitHistory(habit.history).keys) {
      if (date.isBefore(earliestDate)) {
        earliestDate = date;
      }
    }
  }

  return earliestDate.subtract(Duration(days: extraPastDays));
}

class HabitGoalProgress {
  final bool hasGoal;
  final double current;
  final double goal;
  final double remaining;
  final double percent;
  final String unit;

  const HabitGoalProgress._({
    required this.hasGoal,
    required this.current,
    required this.goal,
    required this.remaining,
    required this.percent,
    required this.unit,
  });

  const HabitGoalProgress.empty()
    : hasGoal = false,
      current = 0,
      goal = 0,
      remaining = 0,
      percent = 0,
      unit = '';
}

HabitGoalProgress computeHabitGoalProgress(
  Habit habit, {
  DateTime? day,
  dynamic value,
}) {
  if (!habit.hasGoal) {
    return const HabitGoalProgress.empty();
  }

  final targetValue = habit.goalValue!;
  final currentValue = parseHabitNumericValue(
    value ?? habitHistoryValueForDate(habit.history, day ?? DateTime.now()),
  );
  final remainingValue = math.max(0.0, targetValue - currentValue);
  final percentValue = targetValue <= 0
      ? 0.0
      : ((currentValue / targetValue) * 100)
        .clamp(0.0, 999999.0)
        .toDouble();

  return HabitGoalProgress._(
    hasGoal: true,
    current: currentValue,
    goal: targetValue,
    remaining: remainingValue,
    percent: percentValue,
    unit: habit.goalDisplayUnit,
  );
}

class HabitStreakStats {
  final int current;
  final int best;

  const HabitStreakStats({required this.current, required this.best});
}

HabitStreakStats computeHabitStreakStats(
  Habit habit, {
  DateTime? referenceDate,
}) {
  final normalizedHistory = normalizeHabitHistory(habit.history);
  if (normalizedHistory.isEmpty) {
    return const HabitStreakStats(current: 0, best: 0);
  }

  final completedDates = normalizedHistory.entries
      .where((entry) => isHabitCompletedValue(habit, entry.value))
      .map((entry) => entry.key)
      .toList()
    ..sort();

  if (completedDates.isEmpty) {
    return const HabitStreakStats(current: 0, best: 0);
  }

  var bestStreak = 0;
  var runningBest = 0;
  DateTime? previousDate;
  for (final date in completedDates) {
    if (previousDate != null && date.difference(previousDate).inDays == 1) {
      runningBest += 1;
    } else {
      runningBest = 1;
    }
    if (runningBest > bestStreak) {
      bestStreak = runningBest;
    }
    previousDate = date;
  }

  final today = normalizeHabitDate(referenceDate ?? DateTime.now());
  final todayValue = habitHistoryValueForDate(habit.history, today);
  final hasLoggedToday = isHabitLoggedValue(habit, todayValue);
  final completedSet = completedDates.toSet();

  DateTime cursor;
  if (isHabitCompletedValue(habit, todayValue)) {
    cursor = today;
  } else if (hasLoggedToday) {
    return HabitStreakStats(current: 0, best: bestStreak);
  } else {
    cursor = today.subtract(const Duration(days: 1));
  }

  var currentStreak = 0;
  while (completedSet.contains(cursor)) {
    currentStreak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return HabitStreakStats(current: currentStreak, best: bestStreak);
}