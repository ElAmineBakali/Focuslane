import 'package:flutter/material.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';
import 'package:focuslane/screens/study/models/study_models.dart';
import 'schedule_widgets.dart';
import 'package:focuslane/design/ui/components/focus_module_header.dart';

class ScheduleScreen extends StatelessWidget {
  final StudyFirestoreService svc;
  const ScheduleScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horario académico'),
        leading: FocusModuleHeader.buildLeading(
          context,
          mode: FocusModuleLeadingMode.backToModuleDashboard,
          backRouteName: AppRoutes.studyDashboard,
        ),
        leadingWidth: 96,
      ),
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
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final blocks = snap.data!;

              if (isMobile) {
                return _MobileDayByDaySchedule(
                  blocks: blocks,
                  courseById: byId,
                  svc: svc,
                );
              }

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
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      ...List.generate(7, (dowIdx) {
                        final dow = dowIdx + 1;
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                here.map((b) {
                                  final c = courseById[b.courseId];
                                  final name = (c?.name ?? b.courseId).trim();
                                  final label =
                                      '$name • ${b.start.format(context)}-${b.end.format(context)}${b.room != null ? ' • ${b.room}' : ''}';
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(8),
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
                                      final ok = await showDialog<bool>(
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
                                                      () => Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Cancelar'),
                                                ),
                                                FilledButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text('Eliminar'),
                                                ),
                                              ],
                                            ),
                                      );
                                      if (ok == true) {
                                        await svc.deleteScheduleBlock(b.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Bloque eliminado'),
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
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                            top: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                c?.color ??
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
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
  State<_MobileDayByDaySchedule> createState() =>
      _MobileDayByDayScheduleState();
}

class _MobileDayByDayScheduleState extends State<_MobileDayByDaySchedule> {
  final PageController _pageController = PageController(
    initialPage: DateTime.now().weekday - 1,
  );
  late int _currentDay;

  @override
  void initState() {
    super.initState();
    _currentDay = DateTime.now().weekday;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayNames = const [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final dayNamesShort = const ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primaryContainer, colorScheme.surface],
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
                    onPressed:
                        _currentDay > 1
                            ? () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                            : null,
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
                    onPressed:
                        _currentDay < 7
                            ? () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                            : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                        color:
                            isSelected
                                ? colorScheme.primary
                                : isToday
                                ? colorScheme.primaryContainer
                                : Colors.transparent,
                        border:
                            isToday && !isSelected
                                ? Border.all(
                                  color: colorScheme.primary,
                                  width: 2,
                                )
                                : null,
                      ),
                      child: Center(
                        child: Text(
                          dayNamesShort[index],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                isSelected
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
              final dayOfWeek = pageIndex + 1;
              final dayBlocks =
                  widget.blocks
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
                        builder:
                            (_) => _EditBlockSheet(
                              svc: widget.svc,
                              initial: block,
                            ),
                      );
                    },
                    onLongPress: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              title: const Text('Eliminar clase'),
                              content: Text(
                                '¿Eliminar "${course?.name ?? block.courseId}"?',
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
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
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle),
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
  void dispose() {
    _room.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.15),
                          Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.initial == null
                          ? Icons.add_rounded
                          : Icons.edit_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.initial == null ? 'Nuevo bloque' : 'Editar bloque',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                'Curso',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Course>>(
                stream: widget.svc.streamCourses(includeArchived: false),
                builder: (context, snap) {
                  final courses = snap.data ?? const <Course>[];
                  if (courses.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No hay cursos disponibles',
                        style: GoogleFonts.plusJakartaSans(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        courses.map((course) {
                          final isSelected = _courseId == course.id;
                          return GestureDetector(
                            onTap: () => setState(() => _courseId = course.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient:
                                    isSelected
                                        ? LinearGradient(
                                          colors: [
                                            course.color?.withOpacity(0.3) ??
                                                Colors.grey.withOpacity(0.3),
                                            course.color?.withOpacity(0.15) ??
                                                Colors.grey.withOpacity(0.15),
                                          ],
                                        )
                                        : null,
                                color:
                                    !isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withOpacity(0.5)
                                        : null,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: course.color ?? Colors.grey,
                                          width: 2,
                                        )
                                        : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: course.color ?? Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    course.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),

              const SizedBox(height: 28),

              Text(
                'Días de la semana',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (i) {
                  final labels = const [
                    'Lun',
                    'Mar',
                    'Mié',
                    'Jue',
                    'Vie',
                    'Sáb',
                    'Dom',
                  ];
                  final label = labels[i];
                  final sel = _days.contains(i + 1);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (sel) {
                          _days.remove(i + 1);
                        } else {
                          _days.add(i + 1);
                        }
                      });
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient:
                            sel
                                ? LinearGradient(
                                  colors: [
                                    Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.3),
                                    Theme.of(
                                      context,
                                    ).colorScheme.secondary.withOpacity(0.3),
                                  ],
                                )
                                : null,
                        color:
                            !sel
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.5)
                                : null,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            sel
                                ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                                : null,
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: _TimePickerButton(
                      label: 'Inicio',
                      time: _start,
                      icon: Icons.access_time_rounded,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _start,
                        );
                        if (t != null) setState(() => _start = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TimePickerButton(
                      label: 'Fin',
                      time: _end,
                      icon: Icons.access_time_filled_rounded,
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

              const SizedBox(height: 28),

              Text(
                'Aula (opcional)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _room,
                decoration: InputDecoration(
                  hintText: 'Ej: Aula 201, Lab A',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: GoogleFonts.plusJakartaSans(),
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  if (widget.initial != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text(
                                    'Eliminar bloque',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  content: Text(
                                    '¿Estás seguro de que deseas eliminar este bloque del horario?',
                                    style: GoogleFonts.plusJakartaSans(),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red.shade600,
                                      ),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                          );

                          if (confirm == true && mounted) {
                            try {
                              await widget.svc.deleteScheduleBlock(
                                widget.initial!.id,
                              );
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Bloque eliminado',
                                      style: GoogleFonts.plusJakartaSans(),
                                    ),
                                    backgroundColor: Colors.green.shade600,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error al eliminar: $e',
                                      style: GoogleFonts.plusJakartaSans(),
                                    ),
                                    backgroundColor: Colors.red.shade600,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade600),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(
                          'Eliminar',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (widget.initial != null) const SizedBox(width: 12),

                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () async {
                        if ((_courseId == null || _courseId!.trim().isEmpty) ||
                            _days.isEmpty) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Completa curso y días de la semana',
                                  style: GoogleFonts.plusJakartaSans(),
                                ),
                                backgroundColor: Colors.orange.shade600,
                                behavior: SnackBarBehavior.floating,
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
                              SnackBar(
                                content: Text(
                                  'La hora de fin debe ser posterior al inicio',
                                  style: GoogleFonts.plusJakartaSans(),
                                ),
                                backgroundColor: Colors.orange.shade600,
                                behavior: SnackBarBehavior.floating,
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
                          if (mounted) Navigator.pop(context);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Bloque guardado correctamente',
                                  style: GoogleFonts.plusJakartaSans(),
                                ),
                                backgroundColor: Colors.green.shade600,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error guardando: $e',
                                  style: GoogleFonts.plusJakartaSans(),
                                ),
                                backgroundColor: Colors.red.shade600,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Guardar bloque',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final IconData icon;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              time.format(context),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
