import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/gym_firestore_service.dart';
import '../models/gym_models.dart';
import 'exercise_progress_screen.dart';
import 'package:intl/intl.dart';

/// 📊 GymAnalyticsScreen rediseñado - Análisis profesional y comprehensivo
class GymAnalyticsScreenV2 extends StatefulWidget {
  final GymFirestoreService svc;

  const GymAnalyticsScreenV2({super.key, required this.svc});

  @override
  State<GymAnalyticsScreenV2> createState() => _GymAnalyticsScreenV2State();
}

class _GymAnalyticsScreenV2State extends State<GymAnalyticsScreenV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '7'; // '7', '30', '90'

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
          // AppBar moderno
          SliverAppBar.large(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Analíticas',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.analytics,
                    size: 80,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
            actions: [
              // Filtros de periodo
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
                itemBuilder: (context) => [
                  const PopupMenuItem(value: '7', child: Text('Últimos 7 días')),
                  const PopupMenuItem(value: '30', child: Text('Último mes')),
                  const PopupMenuItem(value: '90', child: Text('Últimos 90 días')),
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

          // Contenido según tab
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

  // ═══════════════════════════════════════════════════════════════════════
  // 1. TAB: RESUMEN GENERAL
  // ═══════════════════════════════════════════════════════════════════════
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
              // KPIs principales
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

              // Gráfico de volumen semanal
              _buildSectionTitle('Volumen Semanal'),
              const SizedBox(height: 12),
              SizedBox(
                height: 250,
                child: _buildVolumeWeeklyChart(),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 24),

              // Distribución por grupos musculares
              _buildSectionTitle('Grupos Musculares'),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: _buildMuscleGroupDistribution(),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 2. TAB: ENTRENAMIENTO
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildTrainingTab() {
    return StreamBuilder<List<SessionDoc>>(
      stream: widget.svc.streamSessions(limit: 90),
      builder: (context, snap) {
        final sessions =
            (snap.data ?? []).where((s) => s.date.isAfter(_startDate)).toList();

        if (sessions.isEmpty) {
          return _buildEmptyState('No hay sesiones en este periodo');
        }

        // Calcular frecuencia por rutina
        final routineFreq = <String, int>{};
        for (final s in sessions) {
          routineFreq[s.routineName] = (routineFreq[s.routineName] ?? 0) + 1;
        }

        // Top ejercicios por volumen
        final exerciseVolume = <String, double>{};
        for (final s in sessions) {
          for (final ex in s.exercises) {
            exerciseVolume[ex.name] = (exerciseVolume[ex.name] ?? 0) + ex.volumeKg;
          }
        }
        final topExercises = exerciseVolume.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Frecuencia por Rutina'),
              const SizedBox(height: 12),
              ...routineFreq.entries.map((e) {
                final percentage = (e.value / sessions.length * 100).toStringAsFixed(0);
                return _buildProgressRow(e.key, e.value, percentage, Colors.blue);
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

  // ═══════════════════════════════════════════════════════════════════════
  // 3. TAB: PROGRESO FÍSICO
  // ═══════════════════════════════════════════════════════════════════════
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
              // KPIs de peso
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
                        (weights.length > 1 && weights.last.weight >= weights.first.weight)
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

              // Medidas corporales
              _buildSectionTitle('Medidas Corporales'),
              const SizedBox(height: 12),
              StreamBuilder<List<MeasurementEntry>>(
                stream: widget.svc.streamMeasurements(limit: 90),
                builder: (context, mSnap) {
                  final measurements = (mSnap.data ?? [])
                      .where((m) => m.date.isAfter(_startDate))
                      .toList();

                  if (measurements.isEmpty) {
                    return _buildEmptyState('No hay medidas registradas');
                  }

                  // Agrupar por músculo
                  final byMuscle = <String, List<MeasurementEntry>>{};
                  for (final m in measurements) {
                    byMuscle.putIfAbsent(m.muscle, () => []).add(m);
                  }

                  return Column(
                    children: byMuscle.entries.map((e) {
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

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _quickAddWeight(context),
                      icon: const Icon(Icons.monitor_weight, size: 20),
                      label: Text('Añadir Peso', style: GoogleFonts.poppins(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _quickAddMeasurement(context),
                      icon: const Icon(Icons.straighten, size: 20),
                      label: Text('Añadir Medida', style: GoogleFonts.poppins(fontSize: 13)),
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

  // ═══════════════════════════════════════════════════════════════════════
  // 4. TAB: SENSACIONES
  // ═══════════════════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════════════════
  // WIDGETS COMPARTIDOS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
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
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, int count, String percentage, Color color) {
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
              builder: (_) => ExerciseProgressScreen(
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
                child: const Icon(Icons.fitness_center, color: Colors.blue, size: 20),
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

  Widget _buildMeasurementRow(String muscle, double value, double delta, Color color) {
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

  Widget _buildInterpretationCard(double energy, double fatigue, double motivation) {
    String interpretation;
    IconData icon;
    Color color;

    if (energy >= 4 && fatigue <= 2 && motivation >= 4) {
      interpretation = '¡Excelente estado! Tu cuerpo está respondiendo muy bien al entrenamiento.';
      icon = Icons.sentiment_very_satisfied;
      color = Colors.green;
    } else if (fatigue >= 4) {
      interpretation = 'Fatiga elevada detectada. Considera tomar un día de descanso o reducir volumen.';
      icon = Icons.warning_amber;
      color = Colors.orange;
    } else if (motivation <= 2) {
      interpretation = 'Motivación baja. Intenta variar tu rutina o tomarte un descanso.';
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
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GRÁFICOS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildVolumeWeeklyChart() {
    return StreamBuilder<List<SessionDoc>>(
      stream: widget.svc.streamSessions(limit: 90),
      builder: (context, snap) {
        final sessions =
            (snap.data ?? []).where((s) => s.date.isAfter(_startDate)).toList();

        if (sessions.isEmpty) return const SizedBox();

        // Agrupar por semana
        final weeklyVolume = <int, double>{};
        for (final s in sessions) {
          final weekNum = _getWeekNumber(s.date);
          weeklyVolume[weekNum] = (weeklyVolume[weekNum] ?? 0) + s.volumeKg;
        }

        final sorted = weeklyVolume.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        final barGroups = sorted.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value,
                color: Colors.blue,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList();

        final maxY = sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.1;

        return BarChart(
          BarChartData(
            maxY: maxY,
            barGroups: barGroups,
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= sorted.length) return const SizedBox();
                    return Text(
                      'S${sorted[index].key}',
                      style: GoogleFonts.poppins(fontSize: 10),
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
                      value.toStringAsFixed(0),
                      style: GoogleFonts.poppins(fontSize: 10),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
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

        // Calcular volumen por grupo muscular
        final muscleVolume = <String, double>{};
        for (final s in sessions) {
          for (final ex in s.exercises) {
            // Asumiendo que los ejercicios tienen muscleGroup en metadata
            // Por simplicidad, usar el nombre del ejercicio
            final group = _inferMuscleGroup(ex.name);
            muscleVolume[group] = (muscleVolume[group] ?? 0) + ex.volumeKg;
          }
        }

        final sorted = muscleVolume.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final colors = [
          Colors.blue,
          Colors.red,
          Colors.green,
          Colors.orange,
          Colors.purple,
          Colors.teal,
        ];

        return Row(
          children: [
            Expanded(
              flex: 2,
              child: PieChart(
                PieChartData(
                  sections: sorted.take(6).toList().asMap().entries.map((e) {
                    final percentage = (e.value.value / sorted.fold<double>(0, (sum, item) => sum + item.value) * 100);
                    return PieChartSectionData(
                      value: e.value.value,
                      title: '${percentage.toStringAsFixed(0)}%',
                      color: colors[e.key % colors.length],
                      radius: 80,
                      titleStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: sorted.take(6).toList().asMap().entries.map((e) {
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

    final spots = weights.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

    final maxY = weights.map((w) => w.weight).reduce((a, b) => a > b ? a : b) * 1.05;
    final minY = weights.map((w) => w.weight).reduce((a, b) => a < b ? a : b) * 0.95;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (weights.length / 6).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= weights.length) return const SizedBox();
                final date = weights[index].date;
                return Text(
                  DateFormat('d/M').format(date),
                  style: GoogleFonts.poppins(fontSize: 10),
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
                  value.toStringAsFixed(1),
                  style: GoogleFonts.poppins(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.3),
                  Colors.blue.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UTILIDADES
  // ═══════════════════════════════════════════════════════════════════════

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }

  String _inferMuscleGroup(String exerciseName) {
    final lower = exerciseName.toLowerCase();
    if (lower.contains('pecho') || lower.contains('bench') || lower.contains('press banca')) {
      return 'Pecho';
    } else if (lower.contains('espalda') || lower.contains('remo') || lower.contains('pull') ||
        lower.contains('dominada')) {
      return 'Espalda';
    } else if (lower.contains('pierna') || lower.contains('squat') || lower.contains('sentadilla') ||
        lower.contains('leg')) {
      return 'Piernas';
    } else if (lower.contains('hombro') || lower.contains('shoulder') || lower.contains('militar')) {
      return 'Hombros';
    } else if (lower.contains('brazo') || lower.contains('curl') || lower.contains('tríceps') ||
        lower.contains('bíceps')) {
      return 'Brazos';
    } else {
      return 'Otros';
    }
  }

  // Quick actions
  Future<void> _quickAddWeight(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Añadir peso (kg)', style: GoogleFonts.poppins()),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Ej: 72.4',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
              labelText: 'Peso (kg)',
            ),
            validator: (s) {
              final v = double.tryParse((s ?? '').replaceAll(',', '.'));
              if (v == null) return 'Introduce un número válido';
              if (v <= 0) return 'Debe ser mayor que 0';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
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
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Peso guardado ✅', style: GoogleFonts.poppins()),
              ],
            ),
          ),
        );
        setState(() {}); // Refrescar
      }
    }
  }

  Future<void> _quickAddMeasurement(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final muscleCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    String site = 'avg';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Añadir medida (cm)', style: GoogleFonts.poppins()),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: muscleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Músculo',
                  hintText: 'Ej: brazo',
                  prefixIcon: Icon(Icons.fitness_center_outlined),
                ),
                validator: (s) => (s ?? '').trim().isEmpty ? 'Escribe un músculo' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: valCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor (cm)',
                  prefixIcon: Icon(Icons.straighten),
                ),
                validator: (s) {
                  final v = double.tryParse((s ?? '').replaceAll(',', '.'));
                  if (v == null) return 'Número válido';
                  if (v <= 0) return 'Mayor que 0';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
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
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Medida guardada 📏', style: GoogleFonts.poppins()),
              ],
            ),
          ),
        );
        setState(() {}); // Refrescar
      }
    }
  }
}
