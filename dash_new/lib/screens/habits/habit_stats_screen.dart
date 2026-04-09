import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:focuslane/screens/habits/habit_firestore_service.dart';
import 'package:focuslane/screens/habits/habit_model.dart';
import 'package:focuslane/screens/habits/habit_utils.dart';
import 'package:table_calendar/table_calendar.dart';

class HabitStatsScreen extends StatefulWidget {
  final Habit habit;

  const HabitStatsScreen({super.key, required this.habit});

  @override
  State<HabitStatsScreen> createState() => _HabitStatsScreenState();
}

class _HabitStatsScreenState extends State<HabitStatsScreen> {
  late Habit _habit;
  late DateTime _focusedDay;

  String _statsCacheSignature = '';
  late Map<String, dynamic> _dailyStatsCache;
  late Map<String, dynamic> _monthlyStatsCache;
  late List<MapEntry<DateTime, dynamic>> _historyEntriesCache;
  late List<MapEntry<DateTime, dynamic>> _loggedEntriesCache;
  late List<MapEntry<DateTime, dynamic>> _completedEntriesCache;
  late List<MapEntry<DateTime, dynamic>> _missedEntriesCache;
  late HabitStreakStats _streaksCache;
  late HabitGoalProgress _goalProgressCache;
  late double _totalCache;
  late double _completedCache;
  late double _completionPercentCache;
  late double _quantitativeTotalCache;
  late double _quantitativeAverageCache;

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
    _focusedDay = normalizeHabitDate(DateTime.now());
    _invalidateStatsCache();
  }

  void _invalidateStatsCache() {
    _statsCacheSignature = '';
  }

  String _buildStatsCacheSignature() {
    return '${_habit.id}|${identityHashCode(_habit.history)}|${_habit.history.length}|'
        '${_habit.currentStreak}|${_habit.bestStreak}|${_habit.goalValue}|'
        '${_habit.goalUnit}|${_habit.isQuantitative}';
  }

  void _ensureStatsCache() {
    final signature = _buildStatsCacheSignature();
    if (_statsCacheSignature == signature) {
      return;
    }

    _dailyStatsCache = _getDailyStats();
    _monthlyStatsCache = _getMonthlyStats();

    final normalizedHistory = normalizeHabitHistory(_habit.history);
    _historyEntriesCache = normalizedHistory.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    _loggedEntriesCache = _historyEntriesCache
        .where((entry) => isHabitLoggedValue(_habit, entry.value))
        .toList(growable: false);
    _completedEntriesCache = _loggedEntriesCache
        .where((entry) => isHabitCompletedValue(_habit, entry.value))
        .toList(growable: false);
    _missedEntriesCache = _loggedEntriesCache
        .where((entry) => isHabitMissedValue(entry.value))
        .toList(growable: false);
    _streaksCache = computeHabitStreakStats(_habit);
    _goalProgressCache = computeHabitGoalProgress(_habit);

    _totalCache = _loggedEntriesCache.length.toDouble();
    _completedCache = _completedEntriesCache.length.toDouble();
    _completionPercentCache =
        _totalCache == 0 ? 0.0 : (_completedCache / _totalCache) * 100;
    _quantitativeTotalCache = _habit.isQuantitative
        ? _loggedEntriesCache.fold<double>(
            0,
            (sum, entry) => sum + parseHabitNumericValue(entry.value),
          )
        : 0.0;
    _quantitativeAverageCache =
        _totalCache == 0 ? 0.0 : _quantitativeTotalCache / _totalCache;

    _statsCacheSignature = signature;
  }

  Map<String, dynamic> _getDailyStats() {
    final today = normalizeHabitDate(DateTime.now());
    final days = List<DateTime>.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
      growable: false,
    );

    final rawValues = days.map((day) {
      final value = habitHistoryValueForDate(_habit.history, day);
      if (_habit.isQuantitative) {
        return parseHabitNumericValue(value);
      }
      return isHabitCompletedValue(_habit, value) ? 100.0 : 0.0;
    }).toList(growable: false);

    final maxValue = _habit.isQuantitative
        ? math.max(
            1.0,
            rawValues.fold<double>(
              0,
              (currentMax, value) => value > currentMax ? value : currentMax,
            ),
          )
        : 100.0;

    return {
      'days': days,
      'rawValues': rawValues,
      'max': maxValue,
    };
  }

  Map<String, dynamic> _getMonthlyStats() {
    final now = normalizeHabitDate(DateTime.now());
    final months = List<DateTime>.generate(12, (index) {
      final date = DateTime(now.year, now.month - (11 - index), 1);
      return DateTime(date.year, date.month, 1);
    }, growable: false);

    final normalizedHistory = normalizeHabitHistory(_habit.history);
    final values = months.map((monthStart) {
      final nextMonth = DateTime(monthStart.year, monthStart.month + 1, 1);
      final entries = normalizedHistory.entries
          .where(
            (entry) =>
                !entry.key.isBefore(monthStart) && entry.key.isBefore(nextMonth),
          )
          .toList(growable: false);

      if (entries.isEmpty) {
        return 0.0;
      }

      if (_habit.isQuantitative) {
        return entries.fold<double>(
          0,
          (sum, entry) => sum + parseHabitNumericValue(entry.value),
        );
      }

      final loggedCount = entries
          .where((entry) => isHabitLoggedValue(_habit, entry.value))
          .length
          .toDouble();
      final completedCount = entries
          .where((entry) => isHabitCompletedValue(_habit, entry.value))
          .length
          .toDouble();

      return loggedCount == 0 ? 0.0 : (completedCount / loggedCount) * 100;
    }).toList(growable: false);

    return {
      'months': months,
      'values': values,
    };
  }

  Future<void> _saveDayValue({
    required DateTime day,
    required dynamic newValue,
  }) async {
    final key = habitDateKey(day);

    await HabitFirestoreService().updateHabitHistory(
      _habit.id,
      day,
      newValue ?? habitSkippedValue,
    );

    final updatedHistory = Map<String, dynamic>.from(_habit.history);
    if (newValue == null) {
      updatedHistory.remove(key);
    } else {
      updatedHistory[key] = newValue;
    }

    final refreshedHabit = _habit.copyWith(history: updatedHistory);
    final streaks = computeHabitStreakStats(refreshedHabit);

    if (streaks.current != _habit.currentStreak ||
        streaks.best != _habit.bestStreak) {
      await HabitFirestoreService.updateHabitFields(_habit.id, {
        'currentStreak': streaks.current,
        'bestStreak': streaks.best,
      });
    }

    setState(() {
      _habit = refreshedHabit.copyWith(
        currentStreak: streaks.current,
        bestStreak: streaks.best,
      );
      _invalidateStatsCache();
    });
  }

  DateTime get _calendarFirstDay {
    final dates = normalizeHabitHistory(_habit.history).keys.toList()..sort();
    if (dates.isEmpty) {
      final createdAt = normalizeHabitDate(_habit.createdAt);
      return DateTime(createdAt.year, createdAt.month, 1);
    }
    final firstDate = dates.first;
    return DateTime(firstDate.year, firstDate.month, 1);
  }

  DateTime get _calendarLastDay {
    final dates = normalizeHabitHistory(_habit.history).keys.toList()..sort();
    final today = normalizeHabitDate(DateTime.now());
    final lastDate = dates.isEmpty
        ? today
        : (dates.last.isAfter(today) ? dates.last : today);
    return DateTime(lastDate.year, lastDate.month + 1, 0);
  }

  double _axisInterval(double maxValue) {
    if (maxValue <= 0) {
      return 1;
    }

    final roughInterval = maxValue / 4;
    final magnitude = math.pow(
      10,
      (math.log(roughInterval) / math.ln10).floor(),
    ).toDouble();
    final scaled = roughInterval / magnitude;

    if (scaled <= 1) {
      return magnitude;
    }
    if (scaled <= 2) {
      return 2 * magnitude;
    }
    if (scaled <= 2.5) {
      return 2.5 * magnitude;
    }
    if (scaled <= 5) {
      return 5 * magnitude;
    }
    return 10 * magnitude;
  }

  String _formatChartAxisValue(double value, {required bool compact}) {
    return compact
        ? formatHabitCompactNumber(value)
        : formatHabitStatNumber(value);
  }

  Widget _buildCalendarDayCell(
    BuildContext context,
    DateTime day, {
    bool highlightToday = false,
  }) {
    final theme = Theme.of(context);
    final value = habitHistoryValueForDate(_habit.history, day);

    Color backgroundColor;
    Color foregroundColor;
    IconData? icon;

    if (isHabitCompletedValue(_habit, value)) {
      backgroundColor = theme.colorScheme.secondaryContainer;
      foregroundColor = theme.colorScheme.onSecondaryContainer;
      icon = Icons.check_rounded;
    } else if (isHabitMissedValue(value)) {
      backgroundColor = theme.colorScheme.errorContainer;
      foregroundColor = theme.colorScheme.onErrorContainer;
      icon = Icons.close_rounded;
    } else if (isHabitSkippedValue(value)) {
      backgroundColor = theme.colorScheme.tertiaryContainer;
      foregroundColor = theme.colorScheme.onTertiaryContainer;
      icon = Icons.remove_rounded;
    } else if (_habit.isQuantitative && value != null) {
      backgroundColor = theme.colorScheme.primaryContainer;
      foregroundColor = theme.colorScheme.onPrimaryContainer;
      icon = isHabitCompletedValue(_habit, value)
          ? Icons.check_rounded
          : Icons.show_chart_rounded;
    } else {
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      foregroundColor = theme.colorScheme.onSurfaceVariant;
      icon = null;
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => _EditHabitDayDialog(
            date: habitDateKey(day),
            value: value?.toString(),
            isQuantitative: _habit.isQuantitative,
            onSave: (newValue) async {
              Navigator.pop(context);
              await _saveDayValue(day: day, newValue: newValue);
            },
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: highlightToday
              ? Border.all(color: theme.colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 18, color: foregroundColor)
              : Text(
                  '${day.day}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 700;

    _ensureStatsCache();
    final daily = _dailyStatsCache;
    final monthly = _monthlyStatsCache;
    final historyEntries = _historyEntriesCache;
    final missedEntries = _missedEntriesCache;
    final streaks = _streaksCache;
    final total = _totalCache;
    final completed = _completedCache;
    final completionPercent = _completionPercentCache;
    final goalProgress = _goalProgressCache;
    final quantitativeTotal = _quantitativeTotalCache;
    final quantitativeAverage = _quantitativeAverageCache;
    final dailyValues = daily['rawValues'] as List<double>;
    final monthlyValues = monthly['values'] as List<double>;
    final dailyMax = _habit.isQuantitative
        ? ((daily['max'] as double) * 1.15)
        : 100.0;
    final monthlyBaseMax = monthlyValues.fold<double>(
      0,
      (currentMax, value) => value > currentMax ? value : currentMax,
    );
    final monthlyMax = _habit.isQuantitative
        ? math.max(1.0, monthlyBaseMax) * 1.15
        : 100.0;
    final dailyInterval = _habit.isQuantitative ? _axisInterval(dailyMax) : 25.0;
    final monthlyInterval = _habit.isQuantitative
        ? _axisInterval(monthlyMax)
        : 25.0;

    return Scaffold(
      appBar: AppBar(title: const Text('EstadÃ­sticas')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: cs.secondaryContainer,
                            foregroundColor: cs.onSecondaryContainer,
                            child: Icon(
                              _habit.isQuantitative
                                  ? Icons.stacked_line_chart_rounded
                                  : Icons.check_circle_rounded,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _habit.name,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (_habit.description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _habit.description,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Chip(
                                      avatar: const Icon(
                                        Icons.event_repeat_rounded,
                                        size: 16,
                                      ),
                                      label: Text(_habit.frequency),
                                    ),
                                    Chip(
                                      avatar: Icon(
                                        _habit.isQuantitative
                                            ? Icons.numbers_rounded
                                            : Icons.rule_folder_rounded,
                                        size: 16,
                                      ),
                                      label: Text(
                                        _habit.isQuantitative
                                            ? (_habit.goalDisplayUnit.isEmpty
                                                ? 'Cuantitativo'
                                                : _habit.goalDisplayUnit)
                                            : 'SÃ­/No',
                                      ),
                                    ),
                                    if (_habit.hasGoal)
                                      Chip(
                                        avatar: const Icon(
                                          Icons.flag_rounded,
                                          size: 16,
                                        ),
                                        label: Text(
                                          '${formatHabitStatNumber(_habit.goalValue)} ${_habit.goalDisplayUnit}'.trim(),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (goalProgress.hasGoal) ...[
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      color: cs.primaryContainer.withOpacity(0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meta actual',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${formatHabitStatNumber(goalProgress.current)} / ${formatHabitStatNumber(goalProgress.goal)} ${goalProgress.unit}'.trim(),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 12,
                                value: math.min(goalProgress.percent / 100, 1.0),
                                backgroundColor:
                                    cs.onPrimaryContainer.withOpacity(0.12),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                Text(
                                  '${formatHabitStatNumber(goalProgress.percent)}% completado',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: cs.onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Faltan ${formatHabitStatNumber(goalProgress.remaining)} ${goalProgress.unit}'.trim(),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final rawWidth = constraints.maxWidth < 720
                          ? (constraints.maxWidth - 12) / 2
                          : (constraints.maxWidth - 36) / 4;
                      final cardWidth = rawWidth.clamp(140.0, 320.0).toDouble();

                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _StatCard(
                              icon: Icons.check_circle_outline_rounded,
                              label: 'Completados',
                              value: formatHabitStatNumber(completed),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _StatCard(
                              icon: Icons.percent_rounded,
                              label: 'Cumplimiento',
                              value:
                                  '${formatHabitStatNumber(completionPercent)}%',
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _StatCard(
                              icon: Icons.local_fire_department_rounded,
                              label: 'Racha actual',
                              value: formatHabitStatNumber(streaks.current),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _StatCard(
                              icon: Icons.star_rounded,
                              label: 'Mejor racha',
                              value: formatHabitStatNumber(streaks.best),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (_habit.isQuantitative) ...[
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Analytics cuantitativos',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _QuantitativeAnalytics(habit: _habit),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ãšltimos 7 dÃ­as',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _habit.isQuantitative
                                ? 'Valores diarios reales del hÃ¡bito.'
                                : 'Porcentaje diario de cumplimiento.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: isMobile ? 240 : 290,
                            child: BarChart(
                              BarChartData(
                                minY: 0,
                                maxY: dailyMax,
                                alignment: BarChartAlignment.spaceAround,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: dailyInterval,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: cs.outlineVariant.withOpacity(0.35),
                                    strokeWidth: 1,
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      reservedSize: isMobile ? 30 : 36,
                                      getTitlesWidget: (value, meta) {
                                        if ((value - value.roundToDouble()).abs() >
                                            0.001) {
                                          return const SizedBox.shrink();
                                        }
                                        final index = value.round();
                                        final days = daily['days'] as List<DateTime>;
                                        if (index < 0 || index >= days.length) {
                                          return const SizedBox.shrink();
                                        }
                                        if (isMobile && index.isOdd) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            DateFormat(isMobile ? 'EE' : 'EEE')
                                                .format(days[index]),
                                            style: theme.textTheme.labelSmall,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: isMobile ? 46 : 56,
                                      interval: dailyInterval,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          _formatChartAxisValue(
                                            value,
                                            compact: _habit.isQuantitative,
                                          ),
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                          textAlign: TextAlign.center,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: List.generate(
                                  dailyValues.length,
                                  (index) => BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: dailyValues[index],
                                        width: isMobile ? 14 : 18,
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: LinearGradient(
                                          colors: [
                                            cs.secondary,
                                            cs.secondary.withOpacity(0.45),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    tooltipRoundedRadius: 12,
                                    getTooltipItem: (group, _, rod, __) {
                                      final day =
                                          (daily['days'] as List<DateTime>)[group.x.toInt()];
                                      final rawValue = dailyValues[group.x.toInt()];
                                      final valueLabel = _habit.isQuantitative
                                          ? '${formatHabitStatNumber(rawValue)} ${_habit.goalDisplayUnit}'.trim()
                                          : '${formatHabitStatNumber(rawValue)}%';
                                      return BarTooltipItem(
                                        '${DateFormat('EEE dd MMM').format(day)}\n$valueLabel',
                                        theme.textTheme.bodyMedium?.copyWith(
                                              color: cs.onInverseSurface,
                                              fontWeight: FontWeight.w700,
                                            ) ??
                                            TextStyle(
                                              color: cs.onInverseSurface,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _habit.isQuantitative
                                ? 'EvoluciÃ³n mensual'
                                : 'Ã‰xito mensual',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _habit.isQuantitative
                                ? 'Suma de valores registrados en los Ãºltimos 12 meses.'
                                : 'Porcentaje de dÃ­as cumplidos por mes.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: isMobile ? 240 : 290,
                            child: LineChart(
                              LineChartData(
                                minX: 0,
                                maxX: (monthlyValues.length - 1).toDouble(),
                                minY: 0,
                                maxY: monthlyMax,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: monthlyInterval,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: cs.outlineVariant.withOpacity(0.35),
                                    strokeWidth: 1,
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      reservedSize: 32,
                                      getTitlesWidget: (value, meta) {
                                        if ((value - value.roundToDouble()).abs() >
                                            0.001) {
                                          return const SizedBox.shrink();
                                        }
                                        final index = value.round();
                                        final months = monthly['months'] as List<DateTime>;
                                        if (index < 0 || index >= months.length) {
                                          return const SizedBox.shrink();
                                        }
                                        if (isMobile && index.isOdd) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            DateFormat('MMM').format(months[index]),
                                            style: theme.textTheme.labelSmall,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: isMobile ? 46 : 56,
                                      interval: monthlyInterval,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          _formatChartAxisValue(
                                            value,
                                            compact: _habit.isQuantitative,
                                          ),
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                          textAlign: TextAlign.center,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: List.generate(
                                      monthlyValues.length,
                                      (index) => FlSpot(
                                        index.toDouble(),
                                        monthlyValues[index],
                                      ),
                                    ),
                                    isCurved: true,
                                    color: cs.secondary,
                                    barWidth: 4,
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          cs.secondary.withOpacity(0.22),
                                          Colors.transparent,
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                    dotData: FlDotData(show: !isMobile),
                                  ),
                                ],
                                lineTouchData: LineTouchData(
                                  enabled: true,
                                  touchTooltipData: LineTouchTooltipData(
                                    tooltipRoundedRadius: 12,
                                    getTooltipItems: (spots) {
                                      final months = monthly['months'] as List<DateTime>;
                                      return spots.map((spot) {
                                        final month = months[spot.x.toInt()];
                                        final valueLabel = _habit.isQuantitative
                                            ? '${formatHabitStatNumber(spot.y)} ${_habit.goalDisplayUnit}'.trim()
                                            : '${formatHabitStatNumber(spot.y)}%';
                                        return LineTooltipItem(
                                          '${DateFormat('MMM yyyy').format(month)}\n$valueLabel',
                                          theme.textTheme.bodyMedium?.copyWith(
                                                color: cs.onInverseSurface,
                                                fontWeight: FontWeight.w700,
                                              ) ??
                                              TextStyle(
                                                color: cs.onInverseSurface,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calendario',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Todo el historial disponible del hÃ¡bito.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _CalendarLegendItem(
                                color: cs.secondaryContainer,
                                icon: Icons.check_rounded,
                                label: 'Completado',
                              ),
                              _CalendarLegendItem(
                                color: cs.errorContainer,
                                icon: Icons.close_rounded,
                                label: 'No completado',
                              ),
                              _CalendarLegendItem(
                                color: cs.tertiaryContainer,
                                icon: Icons.remove_rounded,
                                label: 'Saltado',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TableCalendar(
                            firstDay: _calendarFirstDay,
                            lastDay: _calendarLastDay,
                            focusedDay: _focusedDay,
                            onPageChanged: (day) => setState(() => _focusedDay = day),
                            calendarFormat: CalendarFormat.month,
                            availableCalendarFormats: const {
                              CalendarFormat.month: 'Mes',
                            },
                            availableGestures: AvailableGestures.horizontalSwipe,
                            startingDayOfWeek: StartingDayOfWeek.monday,
                            headerStyle: HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                                color: cs.onSecondaryContainer,
                                fontWeight: FontWeight.w800,
                              ),
                              leftChevronIcon: Icon(
                                Icons.chevron_left_rounded,
                                color: cs.onSecondaryContainer,
                              ),
                              rightChevronIcon: Icon(
                                Icons.chevron_right_rounded,
                                color: cs.onSecondaryContainer,
                              ),
                            ),
                            calendarStyle: const CalendarStyle(
                              outsideDaysVisible: false,
                              todayDecoration: BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            calendarBuilders: CalendarBuilders(
                              defaultBuilder: (context, day, _) =>
                                  _buildCalendarDayCell(context, day),
                              todayBuilder: (context, day, _) =>
                                  _buildCalendarDayCell(
                                    context,
                                    day,
                                    highlightToday: true,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Total registros: ${formatHabitStatNumber(total)}',
                            style: theme.textTheme.bodyLarge,
                          ),
                          if (_habit.isQuantitative) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Promedio por registro: ${formatHabitStatNumber(quantitativeAverage)} ${_habit.goalDisplayUnit}'.trim(),
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Total acumulado: ${formatHabitStatNumber(quantitativeTotal)} ${_habit.goalDisplayUnit}'.trim(),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ] else ...[
                            const SizedBox(height: 6),
                            Text(
                              'No completados: ${formatHabitStatNumber(missedEntries.length)}',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.history_rounded),
                            label: const Text('Ver historial completo'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Historial completo'),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: ListView(
                                      children: historyEntries.reversed.map((entry) {
                                        final trailingText = _habit.isQuantitative
                                            ? '${formatHabitStatNumber(parseHabitNumericValue(entry.value))} ${_habit.goalDisplayUnit}'.trim()
                                            : isHabitCompletedValue(_habit, entry.value)
                                                ? 'Completado'
                                                : isHabitMissedValue(entry.value)
                                                    ? 'No completado'
                                                    : isHabitSkippedValue(entry.value)
                                                        ? 'Saltado'
                                                        : '${entry.value}';
                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(DateFormat('dd/MM/yyyy').format(entry.key)),
                                          trailing: Text(trailingText),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cerrar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.secondary, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarLegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _CalendarLegendItem({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _EditHabitDayDialog extends StatefulWidget {
  final String date;
  final String? value;
  final bool isQuantitative;
  final Function(dynamic) onSave;

  const _EditHabitDayDialog({
    required this.date,
    required this.value,
    required this.isQuantitative,
    required this.onSave,
  });

  @override
  State<_EditHabitDayDialog> createState() => _EditHabitDayDialogState();
}

class _EditHabitDayDialogState extends State<_EditHabitDayDialog> {
  late dynamic _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value ?? (widget.isQuantitative ? '' : null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sec = theme.colorScheme.secondary;

    return AlertDialog(
      title: Text('Editar ${widget.date}'),
      content: widget.isQuantitative
          ? TextFormField(
              initialValue: _value?.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Cantidad'),
              onChanged: (value) => _value = value,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile(
                  value: habitCompletedValue,
                  groupValue: _value,
                  title: const Text('Completado'),
                  activeColor: sec,
                  onChanged: (value) => setState(() => _value = value),
                ),
                RadioListTile(
                  value: habitMissedValue,
                  groupValue: _value,
                  title: const Text('No completado'),
                  activeColor: sec,
                  onChanged: (value) => setState(() => _value = value),
                ),
                RadioListTile(
                  value: null,
                  groupValue: _value,
                  title: const Text('Sin registro'),
                  activeColor: sec,
                  onChanged: (value) => setState(() => _value = value),
                ),
              ],
            ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: sec),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: sec,
            foregroundColor: theme.colorScheme.onSecondary,
          ),
          onPressed: () => widget.onSave(_value),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _QuantitativeAnalytics extends StatelessWidget {
  final Habit habit;

  const _QuantitativeAnalytics({required this.habit});

  @override
  Widget build(BuildContext context) {
    final now = normalizeHabitDate(DateTime.now());
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(
      const Duration(days: 6, hours: 23, minutes: 59),
    );
    final weekData = _filterAndSum(habit.history, weekStart, weekEnd);

    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59);
    final monthData = _filterAndSum(habit.history, monthStart, monthEnd);

    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31, 23, 59);
    final yearData = _filterAndSum(habit.history, yearStart, yearEnd);

    final prevMonthStart = DateTime(now.year, now.month - 1, 1);
    final prevMonthEnd = DateTime(now.year, now.month, 0, 23, 59);
    final prevMonthData = _filterAndSum(
      habit.history,
      prevMonthStart,
      prevMonthEnd,
    );

    final monthChange = monthData.total - prevMonthData.total;
    final monthChangePercent = prevMonthData.total > 0
        ? formatHabitStatNumber((monthChange / prevMonthData.total) * 100)
        : (monthData.total > 0 ? '100.00' : '0.00');

    return Column(
      children: [
        _AnalyticsCard(
          title: 'Esta semana',
          value:
              '${formatHabitStatNumber(weekData.total)} ${habit.goalDisplayUnit}'.trim(),
          subtitle:
              'Promedio diario: ${formatHabitStatNumber(weekData.average)} ${habit.goalDisplayUnit}'.trim(),
          icon: Icons.calendar_view_week_rounded,
          color: Colors.blue,
        ),
        const SizedBox(height: 8),
        _AnalyticsCard(
          title: 'Este mes',
          value:
              '${formatHabitStatNumber(monthData.total)} ${habit.goalDisplayUnit}'.trim(),
          subtitle:
              'Promedio: ${formatHabitStatNumber(monthData.average)} ${habit.goalDisplayUnit} â€¢ ${monthChange >= 0 ? '+' : ''}${formatHabitStatNumber(monthChange)} ($monthChangePercent%)'.trim(),
          icon: Icons.calendar_today_rounded,
          color: Colors.green,
        ),
        const SizedBox(height: 8),
        _AnalyticsCard(
          title: 'Este aÃ±o',
          value:
              '${formatHabitStatNumber(yearData.total)} ${habit.goalDisplayUnit}'.trim(),
          subtitle:
              'Mejor mes: ${_bestMonth(habit.history, now.year)} ${habit.goalDisplayUnit}'.trim(),
          icon: Icons.calendar_month_rounded,
          color: Colors.orange,
        ),
      ],
    );
  }

  _PeriodData _filterAndSum(
    Map<String, dynamic> history,
    DateTime start,
    DateTime end,
  ) {
    final entries = normalizeHabitHistory(history).entries
        .where((entry) => !entry.key.isBefore(start) && !entry.key.isAfter(end))
        .toList(growable: false);

    if (entries.isEmpty) {
      return const _PeriodData(0, 0);
    }

    final sum = entries.fold<double>(
      0,
      (currentSum, entry) => currentSum + parseHabitNumericValue(entry.value),
    );
    final average = sum / entries.length;
    return _PeriodData(sum, average);
  }

  String _bestMonth(Map<String, dynamic> history, int year) {
    final monthTotals = <int, double>{};

    for (final entry in normalizeHabitHistory(history).entries) {
      if (entry.key.year != year) {
        continue;
      }
      monthTotals[entry.key.month] = (monthTotals[entry.key.month] ?? 0) +
          parseHabitNumericValue(entry.value);
    }

    if (monthTotals.isEmpty) {
      return formatHabitStatNumber(0);
    }

    final bestMonth = monthTotals.entries.reduce(
      (left, right) => left.value > right.value ? left : right,
    );
    return formatHabitStatNumber(bestMonth.value);
  }
}

class _PeriodData {
  final double total;
  final double average;

  const _PeriodData(this.total, this.average);
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
