import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/navigation/app_routes.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/gym_firestore_service.dart';
import 'package:intl/intl.dart';
import '../../../design/ui/components/focus_module_header.dart';

class ExerciseProgressScreen extends StatefulWidget {
  final GymFirestoreService svc;
  final String exerciseName;
  final String? exerciseId;

  const ExerciseProgressScreen({
    super.key,
    required this.svc,
    required this.exerciseName,
    this.exerciseId,
  });

  @override
  State<ExerciseProgressScreen> createState() => _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState extends State<ExerciseProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<({DateTime date, double e1rm})> _e1rmHistory = [];
  List<({DateTime date, double volume})> _volumeHistory = [];
  List<({DateTime date, double weight, int reps, double e1rm})> _prs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      widget.svc.getExerciseE1rmHistory(widget.exerciseName, lookback: 90),
      widget.svc.getExerciseVolumeHistory(widget.exerciseName, lookback: 90),
      widget.svc.getExercisePRs(widget.exerciseName, limit: 5),
    ]);

    setState(() {
      _e1rmHistory = results[0] as List<({DateTime date, double e1rm})>;
      _volumeHistory = results[1] as List<({DateTime date, double volume})>;
      _prs =
          results[2]
              as List<({DateTime date, double weight, int reps, double e1rm})>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 160,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.primaryContainer.withOpacity(0.8),
            leading: FocusModuleHeader.buildLeading(
              context,
              mode: FocusModuleLeadingMode.backToModuleDashboard,
              backRouteName: AppRoutes.gymDashboard,
            ),
            leadingWidth: 96,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.exerciseName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: colorScheme.primary.withOpacity(0.2),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.show_chart), text: 'e1RM'),
                Tab(icon: Icon(Icons.bar_chart), text: 'Volumen'),
                Tab(icon: Icon(Icons.emoji_events), text: 'PRs'),
              ],
            ),
          ),

          SliverFillRemaining(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildE1rmTab(),
                        _buildVolumeTab(),
                        _buildPRsTab(),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildE1rmTab() {
    if (_e1rmHistory.isEmpty) {
      return _buildEmptyState('No hay datos de e1RM todavÃ­a');
    }

    final maxE1rm = _e1rmHistory
        .map((e) => e.e1rm)
        .reduce((a, b) => a > b ? a : b);
    final avgE1rm =
        _e1rmHistory.map((e) => e.e1rm).reduce((a, b) => a + b) /
        _e1rmHistory.length;
    final latestE1rm = _e1rmHistory.last.e1rm;
    final improvement =
        _e1rmHistory.length > 1
            ? ((latestE1rm - _e1rmHistory.first.e1rm) /
                _e1rmHistory.first.e1rm *
                100)
            : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKpiRow([
            (
              'Actual',
              '${latestE1rm.toStringAsFixed(1)} kg',
              Icons.fitness_center,
              Colors.blue,
            ),
            (
              'MÃ¡ximo',
              '${maxE1rm.toStringAsFixed(1)} kg',
              Icons.trending_up,
              Colors.green,
            ),
            (
              'Mejora',
              '${improvement >= 0 ? '+' : ''}${improvement.toStringAsFixed(1)}%',
              improvement >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
              improvement >= 0 ? Colors.green : Colors.red,
            ),
          ]),
          const SizedBox(height: 24),

          Text(
            'EvoluciÃ³n e1RM',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: _buildE1rmChart(),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 24),

          _buildStatCard(
            'Promedio General',
            '${avgE1rm.toStringAsFixed(1)} kg',
            Icons.analytics_outlined,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeTab() {
    if (_volumeHistory.isEmpty) {
      return _buildEmptyState('No hay datos de volumen todavÃ­a');
    }

    final totalVolume = _volumeHistory
        .map((e) => e.volume)
        .reduce((a, b) => a + b);
    final avgVolume = totalVolume / _volumeHistory.length;
    final maxVolume = _volumeHistory
        .map((e) => e.volume)
        .reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKpiRow([
            (
              'Total',
              '${(totalVolume / 1000).toStringAsFixed(1)} ton',
              Icons.scale,
              Colors.orange,
            ),
            (
              'Promedio',
              '${avgVolume.toStringAsFixed(0)} kg',
              Icons.analytics,
              Colors.blue,
            ),
            (
              'MÃ¡ximo',
              '${maxVolume.toStringAsFixed(0)} kg',
              Icons.trending_up,
              Colors.green,
            ),
          ]),
          const SizedBox(height: 24),

          Text(
            'Volumen por SesiÃ³n',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: _buildVolumeChart(),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildPRsTab() {
    if (_prs.isEmpty) {
      return _buildEmptyState('Â¡Entrena para lograr tu primer PR!');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _prs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Top ${_prs.length} PRs',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn().slideX(begin: -0.2, end: 0),
          );
        }

        final pr = _prs[index - 1];
        final rank = index;

        return _buildPRCard(pr, rank)
            .animate(delay: (100 * index).ms)
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildKpiRow(List<(String, String, IconData, Color)> kpis) {
    return Row(
      children:
          kpis.asMap().entries.map((entry) {
            final (label, value, icon, color) = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: entry.key < kpis.length - 1 ? 8 : 0,
                ),
                child: _buildKpiCard(label, value, icon, color),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    ).animate().scale(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPRCard(
    ({DateTime date, double weight, int reps, double e1rm}) pr,
    int rank,
  ) {
    Color rankColor =
        rank == 1
            ? Colors.amber
            : rank == 2
            ? Colors.grey[400]!
            : rank == 3
            ? Colors.brown[300]!
            : Colors.blue;

    IconData rankIcon = rank <= 3 ? Icons.emoji_events : Icons.military_tech;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient:
              rank <= 3
                  ? LinearGradient(
                    colors: [rankColor.withOpacity(0.1), Colors.transparent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(rankIcon, color: rankColor, size: 24),
                  Text(
                    '#$rank',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: rankColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${pr.weight.toStringAsFixed(1)} kg',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ' Ã— ${pr.reps}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'e1RM: ${pr.e1rm.toStringAsFixed(1)} kg',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    DateFormat('d MMM yyyy', 'es').format(pr.date),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildE1rmChart() {
    if (_e1rmHistory.isEmpty) return const SizedBox();

    final spots =
        _e1rmHistory.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.e1rm);
        }).toList();

    final maxY =
        _e1rmHistory.map((e) => e.e1rm).reduce((a, b) => a > b ? a : b) * 1.1;
    final minY =
        _e1rmHistory.map((e) => e.e1rm).reduce((a, b) => a < b ? a : b) * 0.9;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
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
              reservedSize: 30,
              interval: (_e1rmHistory.length / 6).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _e1rmHistory.length) {
                  return const SizedBox();
                }
                final date = _e1rmHistory[index].date;
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
              interval: (maxY - minY) / 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
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
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: Colors.blue,
                );
              },
            ),
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

  Widget _buildVolumeChart() {
    if (_volumeHistory.isEmpty) return const SizedBox();

    final barGroups =
        _volumeHistory.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.volume,
                color: Colors.orange,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          );
        }).toList();

    final maxY =
        _volumeHistory.map((e) => e.volume).reduce((a, b) => a > b ? a : b) *
        1.1;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
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
              reservedSize: 30,
              interval: (_volumeHistory.length / 6).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _volumeHistory.length) {
                  return const SizedBox();
                }
                final date = _volumeHistory[index].date;
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
              interval: maxY / 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
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
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(0)} kg',
                GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
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
}

