import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/gym_firestore_service.dart';
import '../models/preset_routines_data.dart';
import '../models/gym_models.dart';

 class PresetRoutinesScreen extends StatefulWidget {
  final GymFirestoreService svc;

  const PresetRoutinesScreen({super.key, required this.svc});

  @override
  State<PresetRoutinesScreen> createState() => _PresetRoutinesScreenState();
}

class _PresetRoutinesScreenState extends State<PresetRoutinesScreen> {
  String _selectedGoal = 'all';
  String _selectedLevel = 'all';

  List<PresetRoutine> get filteredRoutines {
    return presetRoutines.where((r) {
      final matchGoal = _selectedGoal == 'all' || r.goal == _selectedGoal;
      final matchLevel = _selectedLevel == 'all' || r.level == _selectedLevel;
      return matchGoal && matchLevel;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
                     SliverAppBar.large(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.primaryContainer,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Rutinas Destacadas',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
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
                child: Center(
                  child: Icon(
                    Icons.auto_awesome,
                    size: 80,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),

                     SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtrar por objetivo',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildGoalChips(),
                  const SizedBox(height: 16),
                  Text(
                    'Nivel de experiencia',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLevelChips(),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey[300]),
                ],
              ),
            ),
          ),

                     SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final routine = filteredRoutines[index];
                  return _buildRoutineCard(routine, index);
                },
                childCount: filteredRoutines.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalChips() {
    final goals = [
      ('all', 'Todos', Icons.all_inclusive),
      ('strength', 'Fuerza', Icons.bolt),
      ('mass', 'Hipertrofia', Icons.fitness_center),
      ('endurance', 'Resistencia', Icons.directions_run),
      ('general', 'General', Icons.star),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: goals.map((goal) {
        final isSelected = _selectedGoal == goal.$1;
        return FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(goal.$3, size: 16),
              const SizedBox(width: 4),
              Text(goal.$2),
            ],
          ),
          onSelected: (selected) {
            setState(() => _selectedGoal = goal.$1);
          },
        );
      }).toList(),
    );
  }

  Widget _buildLevelChips() {
    final levels = [
      ('all', 'Todos', Icons.all_inclusive),
      ('beginner', 'Principiante', Icons.school),
      ('intermediate', 'Intermedio', Icons.trending_up),
      ('advanced', 'Avanzado', Icons.military_tech),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: levels.map((level) {
        final isSelected = _selectedLevel == level.$1;
        return FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(level.$3, size: 16),
              const SizedBox(width: 4),
              Text(level.$2),
            ],
          ),
          onSelected: (selected) {
            setState(() => _selectedLevel = level.$1);
          },
        );
      }).toList(),
    );
  }

  Widget _buildRoutineCard(PresetRoutine routine, int index) {
    Color goalColor = _getGoalColor(routine.goal);
    Color levelColor = _getLevelColor(routine.level);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _showRoutineDetails(routine),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                goalColor.withOpacity(0.05),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                                         Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: goalColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(routine.icon, color: goalColor, size: 32),
                    ),
                    const SizedBox(width: 16),
                    
                                         Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routine.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: [
                              _buildBadge(_getGoalLabel(routine.goal), goalColor),
                              _buildBadge(_getLevelLabel(routine.level), levelColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                                 Text(
                  routine.description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                                 Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      '${routine.days.length} días/semana',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Ver detalles',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: goalColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (100 * index).ms).fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showRoutineDetails(PresetRoutine routine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                                 Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                                 Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                                             Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _getGoalColor(routine.goal).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              routine.icon,
                              color: _getGoalColor(routine.goal),
                              size: 40,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  routine.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    _buildBadge(
                                      _getGoalLabel(routine.goal),
                                      _getGoalColor(routine.goal),
                                    ),
                                    _buildBadge(
                                      _getLevelLabel(routine.level),
                                      _getLevelColor(routine.level),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                                             Text(
                        routine.description,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                                             Text(
                        'Estructura (${routine.days.length} días)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      ...routine.days.asMap().entries.map((entry) {
                        final day = entry.value;
                        return _buildDayCard(day, entry.key + 1);
                      }),
                      
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) {
             _askToApplyRoutine(routine);
    });
  }

  Widget _buildDayCard(PresetDay day, int dayNumber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.2),
          child: Text(
            day.icon ?? '$dayNumber',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        title: Text(
          day.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${day.exercises.length} ejercicios',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        children: day.exercises.map((ex) {
          return ListTile(
            dense: true,
            leading: const Icon(Icons.fitness_center, size: 20),
            title: Text(ex.name, style: GoogleFonts.poppins(fontSize: 13)),
            subtitle: Text(
              '${ex.targetSets} × ${ex.targetReps}${ex.targetRPE != null ? ' @RPE ${ex.targetRPE}' : ''}',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _askToApplyRoutine(PresetRoutine routine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '¿Aplicar rutina?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '¿Quieres crear "${routine.name}" como tu nueva rutina? Podrás editarla después.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => _applyRoutine(routine),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyRoutine(PresetRoutine routine) async {
    Navigator.pop(context);      
         showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      await widget.svc.createRoutineFromPreset(
        routine.name,
        routine.description,
        _mapGoalToSplitType(routine.goal),
        routine.days,
      );
      
      if (mounted) {
        Navigator.pop(context);          Navigator.pop(context);          
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '✅ Rutina "${routine.name}" creada',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);          
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error al crear rutina: $e',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  String _getGoalLabel(String goal) {
    switch (goal) {
      case 'strength':
        return 'Fuerza';
      case 'mass':
        return 'Hipertrofia';
      case 'endurance':
        return 'Resistencia';
      case 'general':
        return 'General';
      default:
        return 'General';
    }
  }

  String _getLevelLabel(String level) {
    switch (level) {
      case 'beginner':
        return 'Principiante';
      case 'intermediate':
        return 'Intermedio';
      case 'advanced':
        return 'Avanzado';
      default:
        return 'Intermedio';
    }
  }

  Color _getGoalColor(String goal) {
    switch (goal) {
      case 'strength':
        return Colors.red;
      case 'mass':
        return Colors.blue;
      case 'endurance':
        return Colors.green;
      case 'general':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _mapGoalToSplitType(String goal) {
    switch (goal) {
      case 'strength':
        return 'UL';        case 'mass':
        return 'PPL';        default:
        return 'Custom';
    }
  }
}
