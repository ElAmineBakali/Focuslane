import 'package:flutter/material.dart';

String labelForCategory(String? key, {String locale = 'es'}) {
  final normalized = _normalizeKey(key);
  if (normalized.isEmpty) return _defaultCategoryLabel(locale);

  const labelsEs = <String, String>{
    'alimentacion': 'Alimentación',
    'transporte': 'Transporte',
    'hogar': 'Hogar',
    'vivienda': 'Hogar',
    'suscripciones': 'Suscripciones',
    'salud': 'Salud',
    'ocio': 'Ocio',
    'educacion': 'Educación',
    'trabajo': 'Trabajo',
    'salario': 'Trabajo',
    'freelance': 'Trabajo',
    'ahorro': 'Ahorro',
    'inversiones': 'Ahorro',
    'compras': 'Compras',
    'otros': 'Otros',
    'otros_gastos': 'Otros',
    'otros_ingresos': 'Otros',
    'general': 'Otros',
  };

  if (locale == 'es') {
    return labelsEs[normalized] ?? _humanize(normalized);
  }
  return _humanize(normalized);
}

String labelForSubCategory(String? key, {String locale = 'es'}) {
  final normalized = _normalizeKey(key);
  if (normalized.isEmpty) return locale == 'es' ? 'Otros' : 'Other';

  const labelsEs = <String, String>{
    'supermercado': 'Supermercado',
    'restaurantes': 'Restaurantes',
    'delivery': 'Delivery',
    'gasolina': 'Gasolina',
    'transporte_publico': 'Transporte público',
    'taxi_uber': 'Taxi/Uber',
    'mantenimiento': 'Mantenimiento',
    'alquiler': 'Alquiler',
    'hipoteca': 'Hipoteca',
    'electricidad': 'Electricidad',
    'agua': 'Agua',
    'internet': 'Internet',
    'reparaciones': 'Reparaciones',
    'cine': 'Cine',
    'conciertos': 'Conciertos',
    'viajes': 'Viajes',
    'hobbies': 'Hobbies',
    'streaming': 'Streaming',
    'membresia': 'Membresía',
    'medico': 'Médico',
    'farmacia': 'Farmacia',
    'gimnasio': 'Gimnasio',
    'seguros': 'Seguros',
    'cursos': 'Cursos',
    'libros': 'Libros',
    'material': 'Material',
    'comestibles': 'Comestibles',
    'otros': 'Otros',
  };

  if (locale == 'es') {
    return labelsEs[normalized] ?? _humanize(normalized);
  }
  return _humanize(normalized);
}

IconData? iconForCategory(String? key) {
  switch (_normalizeKey(key)) {
    case 'alimentacion':
      return Icons.restaurant;
    case 'transporte':
      return Icons.directions_car;
    case 'hogar':
    case 'vivienda':
      return Icons.home;
    case 'suscripciones':
      return Icons.subscriptions;
    case 'salud':
      return Icons.health_and_safety;
    case 'ocio':
      return Icons.movie;
    case 'educacion':
      return Icons.school;
    case 'trabajo':
    case 'salario':
    case 'freelance':
      return Icons.work;
    case 'ahorro':
    case 'inversiones':
      return Icons.savings;
    case 'otros':
    case 'otros_gastos':
    case 'otros_ingresos':
      return Icons.category;
    default:
      return Icons.category;
  }
}

String _defaultCategoryLabel(String locale) =>
    locale == 'es' ? 'Otros' : 'Other';

String _normalizeKey(String? raw) {
  if (raw == null) return '';
  var value = raw.trim().toLowerCase();
  if (value.isEmpty) return '';

  const replacements = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    '\u00e2': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
    'ç': 'c',
  };

  replacements.forEach((from, to) {
    value = value.replaceAll(from, to);
  });

  value = value
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  return value;
}

String _humanize(String key) {
  if (key.isEmpty) return 'Otros';
  return key
      .split('_')
      .where((e) => e.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}
