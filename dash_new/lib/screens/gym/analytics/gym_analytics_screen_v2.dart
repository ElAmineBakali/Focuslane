import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/navigation/app_routes.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/gym_firestore_service.dart';
import '../models/gym_models.dart';
import '../session/session_history_screen.dart';
import 'exercise_progress_screen.dart';
import 'package:intl/intl.dart';
import '../../../ui/components/focus_module_header.dart';

class GymAnalyticsScreenV2 extends StatefulWidget {
  final GymFirestoreService svc;

  const GymAnalyticsScreenV2({super.key, required this.svc});

  @override
  State<GymAnalyticsScreenV2> createState() => _GymAnalyticsScreenV2State();
}

class _GymAnalyticsScreenV2State extends State<GymAnalyticsScreenV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '7';
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime get _startDate {
    final days = int.parse(_selectedPeriod);
    return DateTime.now().subtract(Duration(days: days));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: colorScheme.primaryContainer,
            leading: FocusModuleHeader.buildLeading(
              context,
              mode: FocusModuleLeadingMode.backToModuleDashboard,
              backRouteName: AppRoutes.gymDashboard,
            ),
            leadingWidth: 96,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 60),
              title: Text(
                'Analíticas',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Icon(
                      Icons.analytics,
                      size: 80,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded),
                tooltip: 'Ver historial completo',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionHistoryScreen(svc: widget.svc),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                initialValue: _selectedPeriod,
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getPeriodLabel(),
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
                onSelected: (value) => setState(() => _selectedPeriod = value),
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: '7',
                        child: Text('Últimos 7 días'),
                      ),
                      const PopupMenuItem(
                        value: '30',
                        child: Text('Último mes'),
                      ),
                      const PopupMenuItem(
                        value: '90',
                        child: Text('Últimos 90 días'),
                      ),
                    ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.show_chart), text: 'Resumen'),
                Tab(icon: Icon(Icons.fitness_center), text: 'Entrenamiento'),
                Tab(icon: Icon(Icons.monitor_weight), text: 'Físico'),
                Tab(icon: Icon(Icons.psychology), text: 'Sensaciones'),
              ],
            ),
          ),

          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTrainingTab(),
                _buildPhysicalTab(),
                _buildFeelingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case '7':
        return '7d';
      case '30':
        return '30d';
      case '90':
        return '90d';
      default:
        return '7d';
    }
  }

  Widget _buildOverviewTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: widget.svc.getStatsForDateRange(_startDate, DateTime.now()),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snap.data!;
        final totalSessions = stats['totalSessions'] as int;
        final totalVolume = stats['totalVolume'] as double;
        final avgDuration = stats['avgDuration'] as double;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Métricas Principales'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      'Sesiones',
                      totalSessions.toString(),
                      Icons.calendar_today,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      'Volumen Total',
                      '${(totalVolume / 1000).toStringAsFixed(1)} ton',
                      Icons.fitness_center,
                      Colors.orange,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      'Duración Prom.',
                      '${avgDuration.toStringAsFixed(0)} min',
                      Icons.timer,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      'Adherencia',
                      '${((totalSessions / int.parse(_selectedPeriod)) * 7).toStringAsFixed(1)}/sem',
                      Icons.trending_up,
                      Colors.purple,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),

              _buildSectionTitle('Volumen Semanal'),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: _buildVolumeWeeklyChart(),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 24),

              _buildSectionTitle('Grupos Musculares'),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: _buildMuscleGroupDistribution(),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrainingTab() {
    return StreamBuilder<List<SessionDoc>>(
      stream: widget.svc.streamSessions(limit: 90),
      builder: (context, snap) {
        final sessions =
            (snap.data ?? []).where((s) => s.date.isAfter(_startDate)).toList();

        if (sessions.isEmpty) {
          return _buildEmptyState('No hay sesiones en este periodo');
        }

        final routineFreq = <String, int>{};
        for (final s in sessions) {
          routineFreq[s.routineName] = (routineFreq[s.routineName] ?? 0) + 1;
        }

        final exerciseVolume = <String, double>{};
        for (final s in sessions) {
          for (final ex in s.exercises) {
            exerciseVolume[ex.name] =
                (exerciseVolume[ex.name] ?? 0) + ex.volumeKg;
          }
        }
        final topExercises =
            exerciseVolume.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Frecuencia por Rutina'),
              const SizedBox(height: 12),
              ...routineFreq.entries.map((e) {
                final percentage = (e.value / sessions.length * 100)
                    .toStringAsFixed(0);
                return _buildProgressRow(
                  e.key,
                  e.value,
                  percentage,
                  Colors.blue,
                );
              }),

              const SizedBox(height: 24),

              _buildSectionTitle('Top Ejercicios (Volumen)'),
              const SizedBox(height: 12),
              ...topExercises.take(10).map((e) {
                return _buildExerciseVolumeCard(e.key, e.value);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhysicalTab() {
    return StreamBuilder<List<BodyWeightEntry>>(
      stream: widget.svc.streamBodyWeight(limit: 180),
      builder: (context, snap) {
        final weights =
            (snap.data ?? []).where((w) => w.date.isAfter(_startDate)).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (weights.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        'Peso Actual',
                        '${weights.last.weight.toStringAsFixed(1)} kg',
                        Icons.monitor_weight,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        'Cambio',
                        weights.length > 1
                            ? '${(weights.last.weight - weights.first.weight) >= 0 ? '+' : ''}${(weights.last.weight - weights.first.weight).toStringAsFixed(1)} kg'
                            : '0.0 kg',
                        Icons.trending_up,
                        (weights.length > 1 &&
                                weights.last.weight >= weights.first.weight)
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('Evolución de Peso'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 250,
                  child: _buildWeightChart(weights),
                ).animate().fadeIn(delay: 300.ms),
              ],

              const SizedBox(height: 24),

              _buildSectionTitle('Medidas Corporales'),
              const SizedBox(height: 12),
              StreamBuilder<List<MeasurementEntry>>(
                stream: widget.svc.streamMeasurements(limit: 90),
                builder: (context, mSnap) {
                  final measurements =
                      (mSnap.data ?? [])
                          .where((m) => m.date.isAfter(_startDate))
                          .toList();

                  if (measurements.isEmpty) {
                    return _buildEmptyState('No hay medidas registradas');
                  }

                  final byMuscle = <String, List<MeasurementEntry>>{};
                  for (final m in measurements) {
                    byMuscle.putIfAbsent(m.muscle, () => []).add(m);
                  }

                  return Column(
                    children:
                        byMuscle.entries.map((e) {
                          final latest = e.value.last.valueCm;
                          final first = e.value.first.valueCm;
                          final delta = latest - first;
                          return _buildMeasurementRow(
                            e.key,
                            latest,
                            delta,
                            delta >= 0 ? Colors.green : Colors.red,
                          );
                        }).toList(),
                  );
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _quickAddWeight(context),
                      icon: const Icon(Icons.monitor_weight, size: 20),
                      label: Text(
                        'Añadir Peso',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _quickAddMeasurement(context),
                      icon: const Icon(Icons.straighten, size: 20),
                      label: Text(
                        'Añadir Medida',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeelingsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: widget.svc.getStatsForDateRange(_startDate, DateTime.now()),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snap.data!;
        final avgEnergy = stats['avgEnergy'] as double;
        final avgFatigue = stats['avgFatigue'] as double;
        final avgMotivation = stats['avgMotivation'] as double;

        if (avgEnergy == 0 && avgFatigue == 0 && avgMotivation == 0) {
          return _buildEmptyState('No hay datos de sensaciones todavía');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Promedios del Periodo'),
              const SizedBox(height: 16),

              _buildFeelingMeter('Energía', avgEnergy, Colors.green),
              const SizedBox(height: 16),
              _buildFeelingMeter('Fatiga', avgFatigue, Colors.orange),
              const SizedBox(height: 16),
              _buildFeelingMeter('Motivación', avgMotivation, Colors.blue),

              const SizedBox(height: 24),

              _buildSectionTitle('Interpretación'),
              const SizedBox(height: 12),
              _buildInterpretationCard(avgEnergy, avgFatigue, avgMotivation),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(
    String label,
    int count,
    String percentage,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$count sesiones ($percentage%)',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: int.parse(percentage) / 100,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.2, end: 0);
  }

  Widget _buildExerciseVolumeCard(String exerciseName, double volume) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ExerciseProgressScreen(
                    svc: widget.svc,
                    exerciseName: exerciseName,
                  ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exerciseName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${volume.toStringAsFixed(0)} kg total',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.2, end: 0);
  }

  Widget _buildMeasurementRow(
    String muscle,
    double value,
    double delta,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              muscle.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} cm',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeelingMeter(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)}/5',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value / 5,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 12,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildInterpretationCard(
    double energy,
    double fatigue,
    double motivation,
  ) {
    String interpretation;
    IconData icon;
    Color color;

    if (energy >= 4 && fatigue <= 2 && motivation >= 4) {
      interpretation =
          '¡Excelente estado! Tu cuerpo está respondiendo muy bien al entrenamiento.';
      icon = Icons.sentiment_very_satisfied;
      color = Colors.green;
    } else if (fatigue >= 4) {
      interpretation =
          'Fatiga elevada detectada. Considera tomar un día de descanso o reducir volumen.';
      icon = Icons.warning_amber;
      color = Colors.orange;
    } else if (motivation <= 2) {
      interpretation =
          'Motivación baja. Intenta variar tu rutina o tomarte un descanso.';
      icon = Icons.sentiment_dissatisfied;
      color = Colors.red;
    } else {
      interpretation = 'Estado normal. Continúa con tu plan de entrenamiento.';
      icon = Icons.sentiment_satisfied;
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              interpretation,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeWeeklyChart() {
    return StreamBuilder<List<SessionDoc>>(
      stream: widget.svc.streamSessions(limit: 90),
      builder: (context, snap) {
        final sessions =
            (snap.data ?? []).where((s) => s.date.isAfter(_startDate)).toList();

        if (sessions.isEmpty) return const SizedBox();

        final weeklyVolume = <int, double>{};
        for (final s in sessions) {
          final weekNum = _getWeekNumber(s.date);
          weeklyVolume[weekNum] = (weeklyVolume[weekNum] ?? 0) + s.volumeKg;
        }

        final sorted =
            weeklyVolume.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));

        final maxY =
            sorted.isEmpty
                ? 100.0
                : sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b) *
                    1.1;

        final barGroups =
            sorted.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.value,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    width: 24,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: Colors.grey.withOpacity(0.1),
                    ),
                  ),
                ],
              );
            }).toList();

        return BarChart(
          BarChartData(
            maxY: maxY,
            barGroups: barGroups,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= sorted.length)
                      return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'S${sorted[index].key}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${(value / 1000).toStringAsFixed(0)}k',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipRoundedRadius: 12,
                tooltipPadding: const EdgeInsets.all(8),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    'Semana ${sorted[groupIndex].key}\n',
                    GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: '${rod.toY.toStringAsFixed(0)} kg',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMuscleGroupDistribution() {
    return StreamBuilder<List<SessionDoc>>(
      stream: widget.svc.streamSessions(limit: 90),
      builder: (context, snap) {
        final sessions =
            (snap.data ?? []).where((s) => s.date.isAfter(_startDate)).toList();

        if (sessions.isEmpty) return const SizedBox();

        final muscleVolume = <String, double>{};
        for (final s in sessions) {
          for (final ex in s.exercises) {
            final group = _inferMuscleGroup(ex.name);
            muscleVolume[group] = (muscleVolume[group] ?? 0) + ex.volumeKg;
          }
        }

        final sorted =
            muscleVolume.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

        final colors = [
          const Color(0xFF6366F1),
          const Color(0xFFEC4899),
          const Color(0xFF10B981),
          const Color(0xFFF59E0B),
          const Color(0xFF8B5CF6),
          const Color(0xFF14B8A6),
        ];

        int touchedIndex = -1;

        return Row(
          children: [
            Expanded(
              flex: 2,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return PieChart(
                    PieChartData(
                      sections:
                          sorted.take(6).toList().asMap().entries.map((e) {
                            final isTouched = e.key == touchedIndex;
                            final percentage =
                                (e.value.value /
                                    sorted.fold<double>(
                                      0,
                                      (sum, item) => sum + item.value,
                                    ) *
                                    100);
                            return PieChartSectionData(
                              value: e.value.value,
                              title: '${percentage.toStringAsFixed(0)}%',
                              color: colors[e.key % colors.length],
                              radius: isTouched ? 80 : 70,
                              titleStyle: GoogleFonts.poppins(
                                fontSize: isTouched ? 16 : 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                shadows: [
                                  const Shadow(
                                    color: Colors.black38,
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              borderSide:
                                  isTouched
                                      ? const BorderSide(
                                        color: Colors.white,
                                        width: 3,
                                      )
                                      : null,
                            );
                          }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (response != null &&
                                response.touchedSection != null) {
                              touchedIndex =
                                  response.touchedSection!.touchedSectionIndex;
                            } else {
                              touchedIndex = -1;
                            }
                          });
                        },
                        enabled: true,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    sorted.take(6).toList().asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[e.key % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.value.key,
                                style: GoogleFonts.poppins(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeightChart(List<BodyWeightEntry> weights) {
    if (weights.isEmpty) return const SizedBox();

    final spots =
        weights.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.weight);
        }).toList();

    final maxY =
        weights.map((w) => w.weight).reduce((a, b) => a > b ? a : b) * 1.05;
    final minY =
        weights.map((w) => w.weight).reduce((a, b) => a < b ? a : b) * 0.95;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (weights.length / 6).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= weights.length)
                  return const SizedBox();
                final date = weights[index].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('d/M').format(date),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1)} kg',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = spot.x.toInt();
                if (index < 0 || index >= weights.length) return null;
                final date = weights[index].date;
                return LineTooltipItem(
                  '${DateFormat('d/M/yy').format(date)}\n',
                  GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  children: [
                    TextSpan(
                      text: '${spot.y.toStringAsFixed(1)} kg',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.4,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: Theme.of(context).colorScheme.primary,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            shadow: Shadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ),
        ],
      ),
    );
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }

  String _inferMuscleGroup(String exerciseName) {
    final lower = exerciseName.toLowerCase();
    if (lower.contains('pecho') ||
        lower.contains('bench') ||
        lower.contains('press banca')) {
      return 'Pecho';
    } else if (lower.contains('espalda') ||
        lower.contains('remo') ||
        lower.contains('pull') ||
        lower.contains('dominada')) {
      return 'Espalda';
    } else if (lower.contains('pierna') ||
        lower.contains('squat') ||
        lower.contains('sentadilla') ||
        lower.contains('leg')) {
      return 'Piernas';
    } else if (lower.contains('hombro') ||
        lower.contains('shoulder') ||
        lower.contains('militar')) {
      return 'Hombros';
    } else if (lower.contains('brazo') ||
        lower.contains('curl') ||
        lower.contains('tríceps') ||
        lower.contains('bíceps')) {
      return 'Brazos';
    } else {
      return 'Otros';
    }
  }

  Future<void> _quickAddWeight(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.monitor_weight_rounded,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registrar Peso',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Añade tu peso actual',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: ctrl,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Peso corporal',
                        hintText: '72.4',
                        suffixText: 'kg',
                        suffixStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                        prefixIcon: Icon(
                          Icons.monitor_weight_outlined,
                          color: colorScheme.primary,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: colorScheme.error,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (s) {
                        final v = double.tryParse(
                          (s ?? '').replaceAll(',', '.'),
                        );
                        if (v == null) return 'Introduce un número válido';
                        if (v <= 0 || v > 300)
                          return 'Peso no válido (1-300 kg)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Registra tu peso por la mañana, antes de desayunar',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () {
                            if (formKey.currentState?.validate() == true) {
                              Navigator.pop(ctx, true);
                            }
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.check, size: 20),
                          label: Text(
                            'Guardar',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    if (ok == true && mounted) {
      final v = double.parse(ctrl.text.replaceAll(',', '.'));
      await widget.svc.addBodyWeight(v, DateTime.now(), computeTrend: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle),
                const SizedBox(width: 8),
                Text('Peso guardado ✅', style: GoogleFonts.poppins()),
              ],
            ),
          ),
        );
        setState(() {});
      }
    }
  }

  Future<void> _quickAddMeasurement(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final muscleCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    String site = 'avg';

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.straighten,
                            color: colorScheme.secondary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registrar Medida',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Medición corporal',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: muscleCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.poppins(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Grupo muscular',
                        hintText: 'Ej: Brazo, Pecho, Cintura...',
                        prefixIcon: Icon(
                          Icons.fitness_center_outlined,
                          color: colorScheme.secondary,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: colorScheme.secondary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: colorScheme.error,
                            width: 2,
                          ),
                        ),
                      ),
                      validator:
                          (s) =>
                              (s ?? '').trim().isEmpty
                                  ? 'Escribe el nombre del músculo'
                                  : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: valCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Medida',
                        hintText: '35.0',
                        suffixText: 'cm',
                        suffixStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.secondary,
                        ),
                        prefixIcon: Icon(
                          Icons.straighten,
                          color: colorScheme.secondary,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: colorScheme.secondary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: colorScheme.error,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (s) {
                        final v = double.tryParse(
                          (s ?? '').replaceAll(',', '.'),
                        );
                        if (v == null) return 'Introduce un número válido';
                        if (v <= 0 || v > 200)
                          return 'Medida no válida (1-200 cm)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      children:
                          [
                            'Biceps',
                            'Triceps',
                            'Pecho',
                            'Espalda',
                            'Pierna',
                          ].map((muscle) {
                            return ActionChip(
                              label: Text(
                                muscle,
                                style: GoogleFonts.poppins(fontSize: 11),
                              ),
                              onPressed: () {
                                muscleCtrl.text = muscle;
                              },
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              side: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () {
                            if (formKey.currentState?.validate() == true) {
                              Navigator.pop(ctx, true);
                            }
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.check, size: 20),
                          label: Text(
                            'Guardar',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    if (ok == true && mounted) {
      final cm = double.parse(valCtrl.text.replaceAll(',', '.'));
      final muscle = muscleCtrl.text.trim();
      await widget.svc.addMeasurement(muscle, cm, DateTime.now(), site: site);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle),
                const SizedBox(width: 8),
                Text('Medida guardada 📏', style: GoogleFonts.poppins()),
              ],
            ),
          ),
        );
        setState(() {});
      }
    }
  }
}
