import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_dashboard_personal/theme/global_ui_theme.dart';
import 'package:mi_dashboard_personal/widgets/external_link_picker_widget.dart';
import 'package:mi_dashboard_personal/widgets/global_color_picker_widget.dart';
import '../models/study_models.dart';
import '../services/study_firestore_service.dart';

class CourseEditSheet extends StatefulWidget {
  final StudyFirestoreService svc;
  final Course? initial;

  const CourseEditSheet({super.key, required this.svc, this.initial});

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
        teacher:
            _teacherController.text.trim().isEmpty
                ? null
                : _teacherController.text.trim(),
        credits: int.tryParse(_creditsController.text.trim())?.toDouble(),
        colorHex: '#${_selectedColor.value.toRadixString(16).substring(2)}',
        goalHours: int.tryParse(_goalHoursController.text.trim())?.toDouble(),
        attendanceRequired: double.tryParse(
          _attendancePctController.text.trim(),
        ),
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
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: _selectedColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: _selectedColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
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
                            const SizedBox(height: 4),
                            Text(
                              'Configura tu materia',
                              style: AppTypography.caption(context),
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

                  const SizedBox(height: AppSpacing.xl),

                  ModernTextField(
                    controller: _nameController,
                    label: 'Nombre del curso*',
                    hint: 'Ej: Álgebra lineal',
                    prefixIcon: Icons.book_rounded,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'El nombre es obligatorio';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  ModernTextField(
                    controller: _teacherController,
                    label: 'Profesor',
                    hint: 'Opcional',
                    prefixIcon: Icons.person_rounded,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  Row(
                    children: [
                      Expanded(
                        child: ModernTextField(
                          controller: _creditsController,
                          label: 'Créditos',
                          hint: 'Ej: 4',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.star_rounded,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ModernTextField(
                          controller: _goalHoursController,
                          label: 'Horas meta',
                          hint: 'Ej: 40',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.access_time_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  ModernTextField(
                    controller: _attendancePctController,
                    label: 'Asistencia requerida (%)',
                    hint: 'Ej: 80',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.how_to_reg_rounded,
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

                  const SizedBox(height: AppSpacing.xl),

                  GlobalColorPickerWidget(
                    initialColor: _selectedColor,
                    onColorSelected: (color) {
                      setState(() => _selectedColor = color);
                    },
                    label: 'Color del curso',
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  ExternalLinkPickerWidget(
                    initialLink: _externalLink,
                    onLinkSelected: (link) {
                      setState(() => _externalLink = link);
                    },
                    label: 'Enlaces rápidos',
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _isSaving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ModernPrimaryButton(
                          label: isEdit ? 'Guardar cambios' : 'Crear curso',
                          icon: Icons.check,
                          fullWidth: true,
                          color: _selectedColor,
                          isLoading: _isSaving,
                          onPressed: _isSaving ? null : _saveCourse,
                        ),
                      ),
                    ],
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
