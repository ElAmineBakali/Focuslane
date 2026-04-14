import 'package:flutter/material.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focuslane/screens/study/models/study_models.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';
import '../attendance/attendance_screen.dart';
import 'package:focuslane/design/widgets/global_color_picker_widget.dart';
import 'package:focuslane/design/ui/components/focus_module_header.dart';

class CourseDetailEditableScreen extends StatefulWidget {
  final StudyFirestoreService svc;
  final Course course;

  const CourseDetailEditableScreen({
    super.key,
    required this.svc,
    required this.course,
  });

  @override
  State<CourseDetailEditableScreen> createState() =>
      _CourseDetailEditableScreenState();
}

class _CourseDetailEditableScreenState
    extends State<CourseDetailEditableScreen> {
  late TextEditingController _nameController;
  late TextEditingController _teacherController;
  late TextEditingController _creditsController;
  late TextEditingController _goalHoursController;
  late TextEditingController _attendancePctController;

  Color _selectedColor = Colors.blue;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.course.name);
    _teacherController = TextEditingController(
      text: widget.course.teacher ?? '',
    );
    _creditsController = TextEditingController(
      text: widget.course.credits?.toString() ?? '',
    );
    _goalHoursController = TextEditingController(
      text: widget.course.goalHours?.toString() ?? '',
    );
    _attendancePctController = TextEditingController(
      text: widget.course.attendanceRequired?.toStringAsFixed(0) ?? '',
    );
    _selectedColor = widget.course.color ?? Colors.blue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _creditsController.dispose();
    _goalHoursController.dispose();
    _attendancePctController.dispose();
    super.dispose();
  }

  Future<void> _saveCourse() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del curso es obligatorio')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.svc.updateCourse(widget.course.id, {
        'name': _nameController.text.trim(),
        'teacher':
            _teacherController.text.trim().isEmpty
                ? null
                : _teacherController.text.trim(),
        'credits': double.tryParse(_creditsController.text.trim()),
        'colorHex': '#${_selectedColor.value.toRadixString(16).substring(2)}',
        'goalHours': double.tryParse(_goalHoursController.text.trim()),
        'attendanceRequired': double.tryParse(
          _attendancePctController.text.trim(),
        ),
      });

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Curso actualizado correctamente'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _archiveCourse() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Archivar curso',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            content: Text(
              '¿Estás seguro de que deseas archivar este curso? Podrás restaurarlo más tarde.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                ),
                child: const Text('Archivar'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteCourse() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Eliminar curso',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            content: Text(
              '¿Estás seguro de que deseas eliminar este curso? Esta acción no se puede deshacer.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
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
        await widget.svc.deleteCourse(widget.course.id);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 200,
            pinned: true,
                leading: FocusModuleHeader.buildLeading(
                  context,
                  mode: FocusModuleLeadingMode.backToModuleDashboard,
                  backRouteName: AppRoutes.studyDashboard,
                ),
                leadingWidth: 96,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.course.name,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 8),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_selectedColor, _selectedColor.withOpacity(0.7)],
                  ),
                ),
              ),
            ),
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => setState(() => _isEditing = true),
                  tooltip: 'Editar',
                )
              else
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() => _isEditing = false),
                  tooltip: 'Cancelar',
                ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert_rounded),
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(
                              Icons.archive_rounded,
                              color: Colors.orange.shade600,
                            ),
                            const SizedBox(width: 12),
                            const Text('Archivar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_rounded,
                              color: Colors.red.shade600,
                            ),
                            const SizedBox(width: 12),
                            const Text('Eliminar'),
                          ],
                        ),
                      ),
                    ],
                onSelected: (value) {
                  if (value == 'archive') _archiveCourse();
                  if (value == 'delete') _deleteCourse();
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditing) ...[
                      Text(
                        'Información del curso',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _TaskFormTextField(
                        controller: _nameController,
                        label: 'Nombre del curso',
                        icon: Icons.book_rounded,
                      ),
                      const SizedBox(height: 16),

                      _TaskFormTextField(
                        controller: _teacherController,
                        label: 'Profesor',
                        icon: Icons.person_rounded,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _TaskFormTextField(
                              controller: _creditsController,
                              label: 'Créditos',
                              icon: Icons.star_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TaskFormTextField(
                              controller: _goalHoursController,
                              label: 'Horas meta',
                              icon: Icons.access_time_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _TaskFormTextField(
                        controller: _attendancePctController,
                        label: 'Asistencia requerida (%)',
                        icon: Icons.how_to_reg_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),

                      GlobalColorPickerWidget(
                        initialColor: _selectedColor,
                        onColorSelected: (color) {
                          setState(() => _selectedColor = color);
                        },
                        label: 'Color del curso',
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _saveCourse,
                          style: FilledButton.styleFrom(
                            backgroundColor: _selectedColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child:
                              _isSaving
                                  ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                  : Text(
                                    'Guardar cambios',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                    ] else ...[
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.event_available),
                          title: const Text('Asistencia'),
                          subtitle: const Text('Abrir registro de asistencia'),
                          onTap: () {
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (_) => AttendanceScreen(
                                  svc: widget.svc,
                                  course: widget.course,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.grading),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Calificaciones',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () async {
                                      await _showAddGradeDialog(context);
                                    },
                                    icon: const Icon(Icons.add_circle_outline),
                                    tooltip: 'Agregar calificacion',
                                  ),
                                ],
                              ),
                              StreamBuilder<List<GradeEntry>>(
                                stream: widget.svc.streamGrades(
                                  courseId: widget.course.id,
                                ),
                                builder: (context, snapshot) {
                                  final grades = snapshot.data ?? const <GradeEntry>[];
                                  if (grades.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text('Aun no hay calificaciones registradas'),
                                    );
                                  }

                                  final average =
                                      grades.map((grade) => grade.grade).reduce((a, b) => a + b) /
                                      grades.length;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          'Promedio: ${average.toStringAsFixed(2)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      ...grades.take(6).map(
                                        (grade) => ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          leading: const Icon(Icons.assignment_outlined),
                                          title: Text(
                                            grade.taskId,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${grade.assessmentType ?? 'Evaluacion'} • Nota ${grade.grade.toStringAsFixed(2)} • ${_formatGradeDate(grade.date)}',
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete_outline),
                                            onPressed: () => widget.svc.deleteGrade(grade.id),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StatCard(
                        icon: Icons.school_rounded,
                        label: 'Profesor',
                        value: widget.course.teacher ?? 'No asignado',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.star_rounded,
                              label: 'Créditos',
                              value: widget.course.credits?.toString() ?? '-',
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.access_time_rounded,
                              label: 'Horas meta',
                              value: widget.course.goalHours?.toString() ?? '-',
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      if (widget.course.attendanceRequired != null) ...[
                        const SizedBox(height: 12),
                        _StatCard(
                          icon: Icons.how_to_reg_rounded,
                          label: 'Asistencia requerida',
                          value:
                              '${widget.course.attendanceRequired!.toStringAsFixed(0)}%',
                          color: Colors.purple,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddGradeDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'Examen');
    final gradeCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final commentCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return AlertDialog(
              title: const Text('Registrar calificacion'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la prueba',
                      ),
                    ),
                    TextField(
                      controller: typeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tipo (examen, practica, parcial)',
                      ),
                    ),
                    TextField(
                      controller: gradeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Nota'),
                    ),
                    TextField(
                      controller: weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Peso (%) opcional',
                      ),
                    ),
                    TextField(
                      controller: commentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Comentario opcional',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.event_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Fecha: ${_formatGradeDate(selectedDate)}'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              initialDate: selectedDate,
                            );
                            if (picked != null) {
                              setLocalState(() => selectedDate = picked);
                            }
                          },
                          child: const Text('Cambiar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;
    final grade = double.tryParse(gradeCtrl.text.trim().replaceAll(',', '.'));
    final assessmentName = nameCtrl.text.trim();
    if (grade == null || assessmentName.isEmpty) return;

    await widget.svc.addGrade(
      GradeEntry(
        id: '',
        taskId: assessmentName,
        courseId: widget.course.id,
        assessmentType:
            typeCtrl.text.trim().isEmpty ? null : typeCtrl.text.trim(),
        grade: grade,
        weight: double.tryParse(weightCtrl.text.trim().replaceAll(',', '.')),
        date: selectedDate,
        notes: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
      ),
    );
  }

  static String _formatGradeDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }
}

class _TaskFormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  const _TaskFormTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
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
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}




