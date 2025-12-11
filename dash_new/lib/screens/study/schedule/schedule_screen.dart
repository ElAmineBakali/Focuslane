import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../services/study_firestore_service.dart';
import '../models/study_models.dart';
import '../services/study_notifications.dart';
import 'schedule_widgets.dart';

class ScheduleScreen extends StatelessWidget {
  final StudyFirestoreService svc;
  const ScheduleScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Horario académico')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => _EditBlockSheet(svc: svc),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Course>>(
        stream: svc.streamCourses(includeArchived: false),
        builder: (context, courseSnap) {
          final courses = courseSnap.data ?? const <Course>[];
          final byId = {for (final c in courses) c.id: c};
          return StreamBuilder<List<StudyClassBlock>>(
            stream: svc.streamSchedule(),
            builder: (context, snap) {
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());
              final blocks = snap.data!;
              
              // Vista móvil: día por día con PageView
              if (isMobile) {
                return _MobileDayByDaySchedule(
                  blocks: blocks,
                  courseById: byId,
                  svc: svc,
                );
              }
              
              // Vista web/tablet: semanal completa
              return _WeeklyScheduleView(
                blocks: blocks,
                courseById: byId,
                svc: svc,
              );
            },
          );
        },
      ),
    );
  }
}

/// Vista semanal completa para web/tablet
class _WeeklyScheduleView extends StatelessWidget {
  final List<StudyClassBlock> blocks;
  final Map<String, Course> courseById;
  final StudyFirestoreService svc;

  const _WeeklyScheduleView({
    required this.blocks,
    required this.courseById,
    required this.svc,
  });

  @override
  Widget build(BuildContext context) {
    final days = const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    
    return CustomScrollView(
      slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Vista semanal',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Table(
                        border: const TableBorder(
                          horizontalInside: BorderSide(color: Colors.black12),
                        ),
                        columnWidths: const {0: FixedColumnWidth(60)},
                        children: [
                          TableRow(
                            children: [
                              const SizedBox(),
                              ...days.map(
                                (d) => Center(
                                  child: Text(
                                    d,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ...List.generate(12, (h) {
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    '${8 + h}:00',
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                  ),
                                ),
                                ...List.generate(7, (dowIdx) {
                                  final dow = dowIdx + 1; // 1..7
                                  final here =
                                      blocks
                                          .where(
                                            (b) =>
                                                b.daysOfWeek.contains(dow) &&
                                                b.start.hour == (8 + h),
                                          )
                                          .toList();
                                  return Container(
                                    margin: const EdgeInsets.all(4),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children:
                                          here.map((b) {
                                            final c = courseById[b.courseId];
                                            final name =
                                                (c?.name ?? b.courseId).trim();
                                            final label =
                                                '$name • ${b.start.format(context)}-${b.end.format(context)}${b.room != null ? ' • ${b.room}' : ''}';
                                            return InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              onTap: () async {
                                                await showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  builder:
                                                      (_) => _EditBlockSheet(
                                                        svc: svc,
                                                        initial: b,
                                                      ),
                                                );
                                              },
                                              onLongPress: () async {
                                                final ok = await showDialog<
                                                  bool
                                                >(
                                                  context: context,
                                                  builder:
                                                      (_) => AlertDialog(
                                                        title: const Text(
                                                          'Eliminar bloque',
                                                        ),
                                                        content: Text(
                                                          '¿Eliminar "$label"?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      false,
                                                                    ),
                                                            child: const Text(
                                                              'Cancelar',
                                                            ),
                                                          ),
                                                          FilledButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      true,
                                                                    ),
                                                            child: const Text(
                                                              'Eliminar',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                );
                                                if (ok == true) {
                                                  await svc.deleteScheduleBlock(
                                                    b.id,
                                                  );
                                                  // Reprogramar recordatorios de clases del día
                                                  await StudyNotifications(
                                                    svc,
                                                  ).scheduleTodayClasses();
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Bloque eliminado',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 4,
                                                    height: 24,
                                                    margin:
                                                        const EdgeInsets.only(
                                                          right: 8,
                                                          top: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          c?.color ??
                                                          Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            2,
                                                          ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 4,
                                                            horizontal: 6,
                                                          ),
                                                      child: Text(label),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  );
                                }),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
    );
  }
}

/// Vista móvil día por día con PageView
class _MobileDayByDaySchedule extends StatefulWidget {
  final List<StudyClassBlock> blocks;
  final Map<String, Course> courseById;
  final StudyFirestoreService svc;

  const _MobileDayByDaySchedule({
    required this.blocks,
    required this.courseById,
    required this.svc,
  });

  @override
  State<_MobileDayByDaySchedule> createState() => _MobileDayByDayScheduleState();
}

class _MobileDayByDayScheduleState extends State<_MobileDayByDaySchedule> {
  final PageController _pageController = PageController(initialPage: DateTime.now().weekday - 1);
  late int _currentDay;

  @override
  void initState() {
    super.initState();
    _currentDay = DateTime.now().weekday; // 1=Lun, 7=Dom
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayNames = const ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final dayNamesShort = const ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        // Header con gradient
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                colorScheme.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filled(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _currentDay > 1 ? () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } : null,
                  ),
                  Text(
                    dayNames[_currentDay - 1],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ).animate(key: ValueKey(_currentDay)).fadeIn().slideX(),
                  IconButton.filled(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _currentDay < 7 ? () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Indicador de días con letras
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  final dayIndex = index + 1;
                  final isSelected = dayIndex == _currentDay;
                  final isToday = dayIndex == DateTime.now().weekday;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected 
                            ? colorScheme.primary
                            : isToday
                                ? colorScheme.primaryContainer
                                : Colors.transparent,
                        border: isToday && !isSelected
                            ? Border.all(color: colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          dayNamesShort[index],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected 
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        
        // PageView con scroll horizontal
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentDay = index + 1;
              });
            },
            itemCount: 7,
            itemBuilder: (context, pageIndex) {
              final dayOfWeek = pageIndex + 1; // 1=Lun, 7=Dom
              
              // Filtrar bloques para este día
              final dayBlocks = widget.blocks
                  .where((b) => b.daysOfWeek.contains(dayOfWeek))
                  .toList()
                ..sort((a, b) {
                  final aMinutes = a.start.hour * 60 + a.start.minute;
                  final bMinutes = b.start.hour * 60 + b.start.minute;
                  return aMinutes.compareTo(bMinutes);
                });
              
              if (dayBlocks.isEmpty) {
                return EmptyScheduleState(
                  onAddClass: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _EditBlockSheet(svc: widget.svc),
                    );
                  },
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: dayBlocks.length,
                itemBuilder: (context, index) {
                  final block = dayBlocks[index];
                  final course = widget.courseById[block.courseId];
                  
                  return ModernClassBlock(
                    block: block,
                    course: course,
                    onTap: () async {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _EditBlockSheet(
                          svc: widget.svc,
                          initial: block,
                        ),
                      );
                    },
                    onLongPress: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Eliminar clase'),
                          content: Text(
                            '¿Eliminar "${course?.name ?? block.courseId}"?',
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.error,
                              ),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        await widget.svc.deleteScheduleBlock(block.id);
                        await StudyNotifications(widget.svc).scheduleTodayClasses();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text('Clase eliminada'),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EditBlockSheet extends StatefulWidget {
  final StudyFirestoreService svc;
  final StudyClassBlock? initial;
  const _EditBlockSheet({required this.svc, this.initial});
  @override
  State<_EditBlockSheet> createState() => _EditBlockSheetState();
}

class _EditBlockSheetState extends State<_EditBlockSheet> {
  String? _courseId;
  final List<int> _days = [];
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 9, minute: 0);
  final _room = TextEditingController();

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _courseId = init.courseId;
      _days.clear();
      _days.addAll(init.daysOfWeek);
      _start = init.start;
      _end = init.end;
      if (init.room != null) _room.text = init.room!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.initial == null ? 'Nuevo bloque' : 'Editar bloque',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<Course>>(
              stream: widget.svc.streamCourses(includeArchived: false),
              builder: (context, snap) {
                final courses = snap.data ?? const <Course>[];
                final valid = courses.any((c) => c.id == _courseId);
                final value = valid ? _courseId : null;
                return DropdownButtonFormField<String>(
                  initialValue: value,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Curso'),
                  items: [
                    ...courses.map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: c.color ?? Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(c.name),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _courseId = v),
                );
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: List.generate(7, (i) {
                final label = const ['L', 'M', 'X', 'J', 'V', 'S', 'D'][i];
                final sel = _days.contains(i + 1);
                return FilterChip(
                  label: Text(label),
                  selected: sel,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _days.add(i + 1);
                      } else {
                        _days.remove(i + 1);
                      }
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Inicio'),
                    subtitle: Text(_start.format(context)),
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _start,
                      );
                      if (t != null) setState(() => _start = t);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Fin'),
                    subtitle: Text(_end.format(context)),
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _end,
                      );
                      if (t != null) setState(() => _end = t);
                    },
                  ),
                ),
              ],
            ),
            TextField(
              controller: _room,
              decoration: const InputDecoration(labelText: 'Aula (opcional)'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    // Validaciones básicas
                    if ((_courseId == null || _courseId!.trim().isEmpty) ||
                        _days.isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Completa curso y días de la semana'),
                          ),
                        );
                      }
                      return;
                    }
                    final startMinutes = _start.hour * 60 + _start.minute;
                    final endMinutes = _end.hour * 60 + _end.minute;
                    if (endMinutes <= startMinutes) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'La hora de fin debe ser posterior al inicio',
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    final newMap =
                        StudyClassBlock(
                          id: widget.initial?.id ?? '',
                          courseId: _courseId!.trim(),
                          daysOfWeek: List<int>.from(_days)..sort(),
                          start: _start,
                          end: _end,
                          room:
                              _room.text.trim().isEmpty
                                  ? null
                                  : _room.text.trim(),
                        ).toMap();

                    try {
                      if (widget.initial == null) {
                        await widget.svc.addScheduleBlock(
                          StudyClassBlock(
                            id: '',
                            courseId: newMap['courseId'] as String,
                            daysOfWeek: List<int>.from(
                              newMap['daysOfWeek'] as List,
                            ),
                            start: _start,
                            end: _end,
                            room: newMap['room'] as String?,
                          ),
                        );
                      } else {
                        await widget.svc.updateScheduleBlock(
                          widget.initial!.id,
                          newMap,
                        );
                      }
                      // Reprogramar recordatorios de clases del día
                      await StudyNotifications(
                        widget.svc,
                      ).scheduleTodayClasses();
                      if (mounted) Navigator.pop(context);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bloque guardado')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error guardando: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
