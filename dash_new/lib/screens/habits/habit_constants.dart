import 'package:flutter/material.dart';

 class HabitIcons {
  static const Map<String, IconData> icons = {
         'fitness': Icons.fitness_center_rounded,
    'run': Icons.directions_run_rounded,
    'bike': Icons.directions_bike_rounded,
    'walk': Icons.directions_walk_rounded,
    'yoga': Icons.self_improvement_rounded,
    'meditation': Icons.spa_rounded,
    'sleep': Icons.bedtime_rounded,
    'water': Icons.local_drink_rounded,
    'nutrition': Icons.restaurant_rounded,
    'heart': Icons.favorite_rounded,

         'book': Icons.menu_book_rounded,
    'study': Icons.school_rounded,
    'write': Icons.edit_rounded,
    'laptop': Icons.laptop_rounded,
    'work': Icons.work_rounded,
    'language': Icons.translate_rounded,
    'code': Icons.code_rounded,
    'music': Icons.music_note_rounded,
    'art': Icons.palette_rounded,

         'calendar': Icons.calendar_today_rounded,
    'checklist': Icons.checklist_rounded,
    'alarm': Icons.alarm_rounded,
    'timer': Icons.timer_rounded,
    'clean': Icons.cleaning_services_rounded,
    'organize': Icons.folder_rounded,

         'people': Icons.people_rounded,
    'family': Icons.family_restroom_rounded,
    'phone': Icons.phone_rounded,
    'message': Icons.message_rounded,
    'smile': Icons.sentiment_satisfied_rounded,

         'money': Icons.attach_money_rounded,
    'savings': Icons.savings_rounded,
    'shopping': Icons.shopping_cart_rounded,

         'star': Icons.star_rounded,
    'trophy': Icons.emoji_events_rounded,
    'light': Icons.lightbulb_rounded,
    'target': Icons.track_changes_rounded,
    'home': Icons.home_rounded,
  };

  static IconData? getIcon(String? code) {
    if (code == null) return null;
    return icons[code];
  }
}

 class HabitTemplate {
  final String name;
  final String? emoji;
  final String? iconCode;
  final String description;
  final List<String> suggestedTags;
  final String frequency;
  final bool isQuantitative;
  final String unit;
  final String colorHex;

  const HabitTemplate({
    required this.name,
    this.emoji,
    this.iconCode,
    required this.description,
    required this.suggestedTags,
    this.frequency = 'Diario',
    this.isQuantitative = false,
    this.unit = '',
    required this.colorHex,
  });
}

 class HabitTemplates {
  static const List<HabitTemplate> templates = [
         HabitTemplate(
      name: 'Beber agua',
      emoji: '💧',
      iconCode: 'water',
      description: 'Mantente hidratado durante el día',
      suggestedTags: ['Salud', 'Mañana'],
      isQuantitative: true,
      unit: 'vasos',
      colorHex: '0xFF2196F3',
    ),
    HabitTemplate(
      name: 'Hacer ejercicio',
      emoji: '💪',
      iconCode: 'fitness',
      description: 'Mantén tu cuerpo activo',
      suggestedTags: ['Salud', 'Deporte'],
      isQuantitative: true,
      unit: 'min',
      colorHex: '0xFFFF5722',
    ),
    HabitTemplate(
      name: 'Meditar',
      emoji: '🧘',
      iconCode: 'meditation',
      description: 'Cuida tu mente con meditación',
      suggestedTags: ['Salud', 'Mental'],
      isQuantitative: true,
      unit: 'min',
      colorHex: '0xFF9C27B0',
    ),
    HabitTemplate(
      name: 'Dormir 8 horas',
      emoji: '😴',
      iconCode: 'sleep',
      description: 'Descansa adecuadamente',
      suggestedTags: ['Salud', 'Noche'],
      colorHex: '0xFF673AB7',
    ),
    HabitTemplate(
      name: 'Comer saludable',
      emoji: '🥗',
      iconCode: 'nutrition',
      description: 'Alimentación balanceada',
      suggestedTags: ['Salud', 'Nutrición'],
      colorHex: '0xFF4CAF50',
    ),

         HabitTemplate(
      name: 'Leer',
      emoji: '📚',
      iconCode: 'book',
      description: 'Dedica tiempo a la lectura',
      suggestedTags: ['Educación', 'Mañana'],
      isQuantitative: true,
      unit: 'páginas',
      colorHex: '0xFF795548',
    ),
    HabitTemplate(
      name: 'Estudiar',
      emoji: '📖',
      iconCode: 'study',
      description: 'Sesión de estudio',
      suggestedTags: ['Educación', 'Trabajo'],
      isQuantitative: true,
      unit: 'min',
      colorHex: '0xFF3F51B5',
    ),
    HabitTemplate(
      name: 'Aprender idiomas',
      emoji: '🗣️',
      iconCode: 'language',
      description: 'Practica un nuevo idioma',
      suggestedTags: ['Educación', 'Personal'],
      isQuantitative: true,
      unit: 'min',
      colorHex: '0xFF009688',
    ),
    HabitTemplate(
      name: 'Escribir',
      emoji: '✍️',
      iconCode: 'write',
      description: 'Diario personal o creativo',
      suggestedTags: ['Personal', 'Creatividad'],
      isQuantitative: true,
      unit: 'palabras',
      colorHex: '0xFFFF9800',
    ),
    HabitTemplate(
      name: 'Practicar música',
      emoji: '🎵',
      iconCode: 'music',
      description: 'Toca tu instrumento',
      suggestedTags: ['Creatividad', 'Arte'],
      isQuantitative: true,
      unit: 'min',
      colorHex: '0xFFE91E63',
    ),

         HabitTemplate(
      name: 'Levantarse temprano',
      emoji: '🌅',
      iconCode: 'alarm',
      description: 'Comienza el día temprano',
      suggestedTags: ['Mañana', 'Productividad'],
      colorHex: '0xFFFFC107',
    ),
    HabitTemplate(
      name: 'Organizar el día',
      emoji: '📋',
      iconCode: 'checklist',
      description: 'Planifica tus tareas',
      suggestedTags: ['Productividad', 'Mañana'],
      colorHex: '0xFF607D8B',
    ),
    HabitTemplate(
      name: 'Limpiar habitación',
      emoji: '🧹',
      iconCode: 'clean',
      description: 'Mantén el orden',
      suggestedTags: ['Casa', 'Organización'],
      colorHex: '0xFF00BCD4',
    ),

         HabitTemplate(
      name: 'Llamar a familia',
      emoji: '📞',
      iconCode: 'family',
      description: 'Mantén contacto familiar',
      suggestedTags: ['Social', 'Familia'],
      frequency: 'Semanal',
      colorHex: '0xFFFF5252',
    ),
    HabitTemplate(
      name: 'Agradecer',
      emoji: '🙏',
      iconCode: 'smile',
      description: 'Practica la gratitud',
      suggestedTags: ['Mental', 'Personal'],
      colorHex: '0xFFFFC107',
    ),

         HabitTemplate(
      name: 'Revisar gastos',
      emoji: '💰',
      iconCode: 'money',
      description: 'Control de finanzas',
      suggestedTags: ['Finanzas', 'Noche'],
      colorHex: '0xFF4CAF50',
    ),
    HabitTemplate(
      name: 'Ahorrar',
      emoji: '🪙',
      iconCode: 'savings',
      description: 'Guarda dinero regularmente',
      suggestedTags: ['Finanzas', 'Personal'],
      isQuantitative: true,
      unit: '€',
      colorHex: '0xFF8BC34A',
    ),
  ];
}

 class CommonTags {
  static const List<String> tags = [
    'Salud',
    'Deporte',
    'Mental',
    'Educación',
    'Trabajo',
    'Personal',
    'Mañana',
    'Tarde',
    'Noche',
    'Casa',
    'Social',
    'Familia',
    'Finanzas',
    'Creatividad',
    'Arte',
    'Nutrición',
    'Productividad',
    'Organización',
  ];
}
