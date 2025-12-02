// Archivo: habit_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_model.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class HabitStatsScreen extends StatefulWidget {
  final Habit habit;
  const HabitStatsScreen({super.key, required this.habit});

  @override
  State<HabitStatsScreen> createState() => _HabitStatsScreenState();
}

class _HabitStatsScreenState extends State<HabitStatsScreen> {
  late Habit _habit; // copia local para refrescar al vuelo
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
    _focusedDay = DateTime.now();
  }

  // -------------------- Métricas --------------------
  Map<String, dynamic> _getDailyStats() {
    final now = DateTime.now();
    final days = List.generate(
      7,
      (i) => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i)),
    );
    final labels = days.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList();

    // Valores crudos
    final raw = <double>[];
    for (final k in labels) {
      final v = _habit.history[k];
      if (v == null) {
        raw.add(0);
      } else if (_habit.isQuantitative) {
        raw.add(double.tryParse(v.toString()) ?? 0);
      } else {
        raw.add(v == '✔️' ? 1 : 0);
      }
    }

    // Normalizamos 0..1 para que el gráfico sea legible
    double maxVal = 1;
    if (_habit.isQuantitative) {
      maxVal = raw.fold<double>(0, (m, e) => e > m ? e : m);
      if (maxVal <= 0) maxVal = 1;
    }
    final norm = raw.map((e) => (e / maxVal)).toList();

    return {
      'days': days,
      'labels': labels,
      'rawValues': raw,
      'values': norm,
      'max': maxVal,
    };
  }

  Map<String, dynamic> _getMonthlyStats() {
    // últimos 12 meses (incluye mes actual)
    final now = DateTime.now();
    final months = List.generate(12, (i) {
      final d = DateTime(now.year, now.month - (11 - i), 1);
      return DateTime(d.year, d.month, 1);
    });

    final labels = months.map((m) => DateFormat('yyyy-MM').format(m)).toList();

    final vals = <double>[];
    for (final m in months) {
      final start = DateTime(m.year, m.month, 1);
      final end = DateTime(
        m.year,
        m.month + 1,
        1,
      ).subtract(const Duration(days: 1));
      // Filtramos claves de ese mes
      final entries =
          _habit.history.entries.where((e) {
            final dt = DateTime.tryParse(e.key);
            return dt != null && !dt.isBefore(start) && !dt.isAfter(end);
          }).toList();

      if (entries.isEmpty) {
        vals.add(0);
        continue;
      }

      if (_habit.isQuantitative) {
        final sum = entries.fold<double>(
          0,
          (a, e) => a + (double.tryParse(e.value.toString()) ?? 0),
        );
        vals.add(sum);
      } else {
        final total = entries.length.toDouble();
        final ok = entries.where((e) => e.value == '✔️').length.toDouble();
        vals.add(
          total == 0 ? 0 : (ok / total) * 100,
        ); // porcentaje de éxito del mes
      }
    }

    return {
      'months': months,
      'labels': labels,
      'values': vals,
      'isPercent': !_habit.isQuantitative,
    };
  }

  Future<void> _saveDayValue({
    required DateTime day,
    required dynamic newValue, // String | null
  }) async {
    final key = DateFormat('yyyy-MM-dd').format(day);

    await HabitFirestoreService().updateHabitHistory(
      _habit.id,
      day,
      newValue ?? '-',
    );

    setState(() {
      if (newValue == null) {
        _habit.history.remove(key);
      } else {
        _habit.history[key] = newValue;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daily = _getDailyStats();
    final monthly = _getMonthlyStats();

    // Rachas y métricas rápidas
    int currentStreak = 0, maxStreak = 0, tempStreak = 0;
    final sortedKeys = _habit.history.keys.toList()..sort();
    for (final k in sortedKeys) {
      final v = _habit.history[k];
      final success =
          _habit.isQuantitative
              ? (double.tryParse(v.toString()) ?? 0) > 0
              : v == '✔️';
      if (success) {
        tempStreak++;
        if (tempStreak > maxStreak) maxStreak = tempStreak;
      } else {
        tempStreak = 0;
      }
    }
    tempStreak = 0;
    for (final k in sortedKeys.reversed) {
      final v = _habit.history[k];
      final success =
          _habit.isQuantitative
              ? (double.tryParse(v.toString()) ?? 0) > 0
              : v == '✔️';
      if (success) {
        tempStreak++;
      } else {
        break;
      }
    }
    currentStreak = tempStreak;

    final total = _habit.history.length;
    final completados =
        _habit.isQuantitative
            ? _habit.history.values
                .where((v) => (double.tryParse(v.toString()) ?? 0) > 0)
                .length
            : _habit.history.values.where((v) => v == '✔️').length;
    final porcentaje = total == 0 ? 0 : (completados / total * 100).round();

    // Rango para calendario (permite moverse entre meses)
    //final firstDay = DateTime(_focusedDay.year - 5, 1, 1);
    //final lastDay = DateTime(_focusedDay.year + 1, 12, 31);

    return Scaffold(
      appBar: AppBar(title: Text('Estadísticas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado neutro
            ListTile(
              title: Text(
                _habit.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle:
                  _habit.description.isNotEmpty
                      ? Text(_habit.description)
                      : null,
              leading: CircleAvatar(
                child: Icon(
                  _habit.isQuantitative
                      ? Icons.stacked_line_chart
                      : Icons.check_circle,
                ),
              ),
            ),

            // Resumen (Wrap evita overflow en pantallas pequeñas)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _StatCard(
                    icon: Icons.check,
                    label: 'Completados',
                    value: '$completados',
                  ),
                  _StatCard(
                    icon: Icons.percent,
                    label: 'Éxito',
                    value: '$porcentaje%',
                  ),
                  _StatCard(
                    icon: Icons.local_fire_department,
                    label: 'Racha',
                    value: '$currentStreak',
                  ),
                  _StatCard(
                    icon: Icons.star,
                    label: 'Máx. racha',
                    value: '$maxStreak',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ========== ANALYTICS CUANTITATIVOS MEJORADOS ==========
            if (_habit.isQuantitative) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Analytics cuantitativos',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _QuantitativeAnalytics(habit: _habit),
              ),
              const SizedBox(height: 16),
            ],

            // ---------- Gráfico: Últimos 7 días ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Últimos 7 días', style: theme.textTheme.titleMedium),
                  const SizedBox(width: 8),
                  if (_habit.isQuantitative)
                    Text('(normalizado)', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: BarChart(
                  BarChartData(
                    barGroups: List.generate(
                      (daily['values'] as List).length,
                      (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: (daily['values'] as List<double>)[i],
                            width: 18,
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.secondary.withOpacity(.9),
                                theme.colorScheme.secondary.withOpacity(.5),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            final days = daily['days'] as List<DateTime>;
                            if (idx >= 0 && idx < days.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(DateFormat('E').format(days[idx])),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                    ),
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, _, rod, __) {
                          final raw =
                              (daily['rawValues'] as List<double>)[group.x
                                  .toInt()];
                          return BarTooltipItem(
                            _habit.isQuantitative
                                ? '${raw.toStringAsFixed(2)} ${_habit.unit}'
                                : (raw >= 0.5 ? '✔️' : '—'),
                            TextStyle(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---------- Gráfico: Últimos 12 meses ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _habit.isQuantitative
                    ? 'Suma mensual (12 meses)'
                    : 'Éxito mensual (12 meses)',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            final labels = monthly['labels'] as List<String>;
                            if (idx >= 0 && idx < labels.length) {
                              final m = labels[idx];
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(m.substring(2)), // yy-MM compacto
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          (monthly['values'] as List).length,
                          (i) => FlSpot(
                            i.toDouble(),
                            (monthly['values'] as List<double>)[i],
                          ),
                        ),
                        isCurved: true,
                        color: theme.colorScheme.secondary,
                        barWidth: 4,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.secondary.withOpacity(.25),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: true),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---------- Calendario ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Calendario', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TableCalendar(
                firstDay: DateTime(_focusedDay.year - 5, 1, 1),
                lastDay: DateTime(_focusedDay.year + 1, 12, 31),
                focusedDay: _focusedDay,
                onPageChanged: (d) => setState(() => _focusedDay = d),
                calendarFormat: CalendarFormat.month,
                availableGestures: AvailableGestures.horizontalSwipe,
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.secondary),
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, _) {
                    final key = DateFormat('yyyy-MM-dd').format(day);
                    final value = _habit.history[key];

                    Color? bg;
                    IconData? icon;
                    if (value == '✔️' ||
                        (_habit.isQuantitative &&
                            (double.tryParse((value ?? '0').toString()) ?? 0) >
                                0)) {
                      bg = theme.colorScheme.secondary;
                      icon = Icons.check;
                    } else if (value == '❌') {
                      bg = theme.colorScheme.error;
                      icon = Icons.close;
                    } else if (value == null) {
                      bg = theme.colorScheme.surfaceContainerHighest;
                      icon = null;
                    } else {
                      bg = theme.colorScheme.tertiary;
                      icon = Icons.remove;
                    }

                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (_) => _EditHabitDayDialog(
                                date: key,
                                value: value?.toString(),
                                isQuantitative: _habit.isQuantitative,
                                onSave: (newValue) async {
                                  Navigator.pop(context);
                                  await _saveDayValue(
                                    day: day,
                                    newValue: newValue,
                                  );
                                },
                              ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: bg,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child:
                              icon != null
                                  ? Icon(
                                    icon,
                                    size: 18,
                                    color: theme.colorScheme.onSecondary,
                                  )
                                  : Text(
                                    '${day.day}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---------- Detalles ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total registros: $total',
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (_habit.isQuantitative)
                    Text(
                      'Promedio por día: '
                      '${(_habit.history.values.map((v) => double.tryParse(v.toString()) ?? 0).fold(0.0, (a, b) => a + b) / (_habit.history.isEmpty ? 1 : _habit.history.length)).toStringAsFixed(2)} '
                      '${_habit.unit}',
                      style: theme.textTheme.bodyLarge,
                    ),
                  if (!_habit.isQuantitative)
                    Text(
                      '✔️: ${_habit.history.values.where((v) => v == '✔️').length}   '
                      '❌: ${_habit.history.values.where((v) => v == '❌').length}',
                      style: theme.textTheme.bodyLarge,
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.history),
                    label: const Text('Ver historial completo'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              title: const Text('Historial completo'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView(
                                  children:
                                      (_habit.history.entries.toList()..sort(
                                            (a, b) => b.key.compareTo(a.key),
                                          ))
                                          .map(
                                            (e) => ListTile(
                                              title: Text(e.key),
                                              trailing: Text('${e.value}'),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('Cerrar'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Tarjeta resumen (se adapta con Wrap)
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
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 150, // más estrecho que antes para móviles
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.secondary, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
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

// Diálogo edición rápida del día
class _EditHabitDayDialog extends StatefulWidget {
  final String date; // yyyy-MM-dd
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
      content:
          widget.isQuantitative
              ? TextFormField(
                initialValue: _value?.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                onChanged: (v) => _value = v,
              )
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile(
                    value: '✔️',
                    groupValue: _value,
                    title: const Text('Completado'),
                    activeColor: sec,
                    onChanged: (v) => setState(() => _value = v),
                  ),
                  RadioListTile(
                    value: '❌',
                    groupValue: _value,
                    title: const Text('No completado'),
                    activeColor: sec,
                    onChanged: (v) => setState(() => _value = v),
                  ),
                  RadioListTile(
                    value: null,
                    groupValue: _value,
                    title: const Text('Sin registro'),
                    activeColor: sec,
                    onChanged: (v) => setState(() => _value = v),
                  ),
                ],
              ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: sec),
          child: const Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: sec,
            foregroundColor: theme.colorScheme.onSecondary,
          ),
          child: const Text('Guardar'),
          onPressed: () => widget.onSave(_value),
        ),
      ],
    );
  }
}

// ========== ANALYTICS CUANTITATIVOS ==========
class _QuantitativeAnalytics extends StatelessWidget {
  final Habit habit;
  const _QuantitativeAnalytics({required this.habit});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Semana actual
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(
      const Duration(days: 6, hours: 23, minutes: 59),
    );
    final weekData = _filterAndSum(habit.history, weekStart, weekEnd);

    // Mes actual
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59);
    final monthData = _filterAndSum(habit.history, monthStart, monthEnd);

    // Año actual
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31, 23, 59);
    final yearData = _filterAndSum(habit.history, yearStart, yearEnd);

    // Mes anterior (para comparativa)
    final prevMonthStart = DateTime(now.year, now.month - 1, 1);
    final prevMonthEnd = DateTime(now.year, now.month, 0, 23, 59);
    final prevMonthData = _filterAndSum(
      habit.history,
      prevMonthStart,
      prevMonthEnd,
    );

    final monthChange = monthData.total - prevMonthData.total;
    final monthChangePercent =
        prevMonthData.total > 0
            ? ((monthChange / prevMonthData.total) * 100).toStringAsFixed(0)
            : '∞';

    return Column(
      children: [
        _AnalyticsCard(
          title: 'Esta semana',
          value: '${weekData.total.toStringAsFixed(1)} ${habit.unit}',
          subtitle:
              'Promedio diario: ${weekData.average.toStringAsFixed(1)} ${habit.unit}',
          icon: Icons.calendar_view_week,
          color: Colors.blue,
        ),
        const SizedBox(height: 8),
        _AnalyticsCard(
          title: 'Este mes',
          value: '${monthData.total.toStringAsFixed(1)} ${habit.unit}',
          subtitle:
              'Promedio: ${monthData.average.toStringAsFixed(1)} • ${monthChange >= 0 ? '+' : ''}${monthChange.toStringAsFixed(0)} ($monthChangePercent%)',
          icon: Icons.calendar_today,
          color: Colors.green,
        ),
        const SizedBox(height: 8),
        _AnalyticsCard(
          title: 'Este año',
          value: '${yearData.total.toStringAsFixed(1)} ${habit.unit}',
          subtitle:
              'Mejor mes: ${_bestMonth(habit.history, now.year)} ${habit.unit}',
          icon: Icons.calendar_month,
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
    final entries =
        history.entries.where((e) {
          final dt = DateTime.tryParse(e.key);
          return dt != null && !dt.isBefore(start) && !dt.isAfter(end);
        }).toList();

    if (entries.isEmpty) return _PeriodData(0, 0);

    final sum = entries.fold<double>(
      0,
      (a, e) => a + (double.tryParse(e.value.toString()) ?? 0),
    );
    final avg = sum / entries.length;
    return _PeriodData(sum, avg);
  }

  String _bestMonth(Map<String, dynamic> history, int year) {
    final monthTotals = <int, double>{};

    for (final e in history.entries) {
      final dt = DateTime.tryParse(e.key);
      if (dt == null || dt.year != year) continue;

      final val = double.tryParse(e.value.toString()) ?? 0;
      monthTotals[dt.month] = (monthTotals[dt.month] ?? 0) + val;
    }

    if (monthTotals.isEmpty) return '0';

    final best = monthTotals.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return best.value.toStringAsFixed(1);
  }
}

class _PeriodData {
  final double total;
  final double average;
  _PeriodData(this.total, this.average);
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
