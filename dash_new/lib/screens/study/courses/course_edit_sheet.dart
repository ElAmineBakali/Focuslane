import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/study_firestore_service.dart';
import '../models/study_models.dart';
import 'package:mi_dashboard_personal/widgets/global_color_picker_widget.dart';
import 'package:mi_dashboard_personal/widgets/external_link_picker_widget.dart';

 class CourseEditSheet extends StatefulWidget {
  final StudyFirestoreService svc;
  final Course? initial;
  
  const CourseEditSheet({
    super.key,
    required this.svc,
    this.initial,
  });

  @override
  State<CourseEditSheet> createState() => _CourseEditSheetState();
}

class _CourseEditSheetState extends State<CourseEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _teacherController;
  late TextEditingController _creditsController;
  late TextEditingController _goalHoursController;
  late TextEditingController _attendancePctController;

  Color _selectedColor = Colors.blue;
  String? _externalLink;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final course = widget.initial;
    
    _nameController = TextEditingController(text: course?.name ?? '');
    _teacherController = TextEditingController(text: course?.teacher ?? '');
    _creditsController = TextEditingController(
      text: course?.credits?.toString() ?? '',
    );
    _goalHoursController = TextEditingController(
      text: course?.goalHours?.toString() ?? '',
    );
    _attendancePctController = TextEditingController(
      text: course?.attendanceRequired?.toStringAsFixed(0) ?? '',
    );
    
    if (course?.color != null) {
      _selectedColor = course!.color!;
    }
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final course = Course(
        id: widget.initial?.id ?? '',
        name: _nameController.text.trim(),
        teacher: _teacherController.text.trim().isEmpty
            ? null
            : _teacherController.text.trim(),
        credits: int.tryParse(_creditsController.text.trim())?.toDouble(),
        colorHex: '#${_selectedColor.value.toRadixString(16).substring(2)}',
        goalHours: int.tryParse(_goalHoursController.text.trim())?.toDouble(),
        attendanceRequired: double.tryParse(_attendancePctController.text.trim()),
      );

      Course? result;
      if (widget.initial == null) {
        final id = await widget.svc.createCourse(course);
        result = Course(
          id: id,
          name: course.name,
          teacher: course.teacher,
          credits: course.credits,
          colorHex: course.colorHex,
          goalHours: course.goalHours,
          attendanceRequired: course.attendanceRequired,
        );
      } else {
        await widget.svc.updateCourse(widget.initial!.id, {
          'name': course.name,
          'teacher': course.teacher,
          'credits': course.credits,
          'goalHours': course.goalHours,
          'colorHex': course.colorHex,
          'attendanceRequired': course.attendanceRequired,
        });
        result = course;
      }

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEdit = widget.initial != null;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                     Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: _selectedColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'Editar curso' : 'Nuevo curso',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Configura tu materia',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                                     _TaskFormTextField(
                    controller: _nameController,
                    label: 'Nombre del curso',
                    icon: Icons.book_rounded,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'El nombre es obligatorio';
                      }
                      return null;
                    },
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
                    validator: (value) {
                      if (value?.trim().isNotEmpty ?? false) {
                        final pct = double.tryParse(value!.trim());
                        if (pct == null || pct < 0 || pct > 100) {
                          return 'Debe ser entre 0 y 100';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                                     GlobalColorPickerWidget(
                    initialColor: _selectedColor,
                    onColorSelected: (color) {
                      setState(() => _selectedColor = color);
                    },
                    label: 'Color del curso',
                  ),
                  const SizedBox(height: 24),

                                     ExternalLinkPickerWidget(
                    initialLink: _externalLink,
                    onLinkSelected: (link) {
                      setState(() => _externalLink = link);
                    },
                    label: 'Enlaces rápidos',
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
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEdit ? 'Guardar cambios' : 'Crear curso',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

 class _TaskFormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _TaskFormTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
      ),
    );
  }
}
