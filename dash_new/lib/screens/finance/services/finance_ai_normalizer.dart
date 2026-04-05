class FinanceAiNormalizedResult {
  const FinanceAiNormalizedResult({
    required this.category,
    required this.subCategory,
    required this.tags,
    this.rawCategory,
    this.rawSubCategory,
  });

  final String category;
  final String subCategory;
  final List<String> tags;
  final String? rawCategory;
  final String? rawSubCategory;
}

class FinanceAiNormalizer {
  static const Set<String> _validCategories = {
    'salario',
    'freelance',
    'inversiones',
    'otros_ingresos',
    'alimentacion',
    'transporte',
    'vivienda',
    'ocio',
    'salud',
    'educacion',
    'compras',
    'otros_gastos',
    'otros',
  };

  static const Map<String, String> _categoryAliases = {
    'alimentacion': 'alimentacion',
    'comida': 'alimentacion',
    'supermercado': 'alimentacion',
    'restaurante': 'alimentacion',
    'restaurantes': 'alimentacion',
    'delivery': 'alimentacion',
    'transporte': 'transporte',
    'movilidad': 'transporte',
    'taxi': 'transporte',
    'uber': 'transporte',
    'combustible': 'transporte',
    'gasolina': 'transporte',
    'vivienda': 'vivienda',
    'hogar': 'vivienda',
    'alquiler': 'vivienda',
    'hipoteca': 'vivienda',
    'ocio': 'ocio',
    'entretenimiento': 'ocio',
    'salud': 'salud',
    'medico': 'salud',
    'farmacia': 'salud',
    'educacion': 'educacion',
    'cursos': 'educacion',
    'compras': 'compras',
    'shopping': 'compras',
    'vestimenta': 'compras',
    'tecnologia': 'compras',
    'salario': 'salario',
    'nomina': 'salario',
    'freelance': 'freelance',
    'inversiones': 'inversiones',
    'inversion': 'inversiones',
    'dividendos': 'inversiones',
    'otros ingresos': 'otros_ingresos',
    'otros_ingresos': 'otros_ingresos',
    'otros gastos': 'otros_gastos',
    'otros_gastos': 'otros_gastos',
    'otros': 'otros',
  };

  static FinanceAiNormalizedResult normalize(Map<String, dynamic> result) {
    final rawCategory = result['category']?.toString().trim();
    final rawSubCategory = result['subCategory']?.toString().trim();

    final category = _normalizeCategory(rawCategory);
    final subCategory = _normalizeSubCategory(rawSubCategory, fallbackCategory: category);
    final tags = _normalizeTags(result['tags']);

    return FinanceAiNormalizedResult(
      category: category,
      subCategory: subCategory,
      tags: tags,
      rawCategory: rawCategory,
      rawSubCategory: rawSubCategory,
    );
  }

  static String _normalizeCategory(String? raw) {
    final slug = _slug(raw);
    if (slug.isEmpty) return 'otros';

    if (_validCategories.contains(slug)) {
      return slug;
    }

    if (_categoryAliases.containsKey(slug)) {
      return _categoryAliases[slug]!;
    }

    for (final entry in _categoryAliases.entries) {
      if (slug.contains(entry.key)) return entry.value;
    }

    return 'otros';
  }

  static String _normalizeSubCategory(
    String? raw, {
    required String fallbackCategory,
  }) {
    final slug = _slug(raw);
    if (slug.isEmpty) {
      return fallbackCategory == 'otros' ? 'otros' : '${fallbackCategory}_otros';
    }
    return slug;
  }

  static List<String> _normalizeTags(dynamic raw) {
    if (raw is! List) return const <String>[];

    final out = <String>[];
    final seen = <String>{};

    for (final item in raw) {
      final normalized = _cleanTag(item?.toString() ?? '');
      if (normalized == null) continue;
      if (seen.add(normalized)) {
        out.add(normalized);
      }
      if (out.length >= 8) break;
    }

    return out;
  }

  static String? _cleanTag(String input) {
    final raw = input.trim().toLowerCase();
    if (raw.isEmpty) return null;

    final compact = raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true), '')
        .trim();

    if (compact.isEmpty) return null;

    if (RegExp(r'^[\d\s\.,:;\-_/+*€$£¥]+$').hasMatch(compact)) return null;

    if (RegExp(r'\b(eur|usd|gbp|jpy|chf|cad|aud)\b').hasMatch(compact) &&
        RegExp(r'\d').hasMatch(compact)) {
      return null;
    }

    if (RegExp(r'^\d+[\.,]?\d*$').hasMatch(compact)) return null;

    final slug = _slug(compact).replaceAll('_', '');
    if (slug.isEmpty || slug.length < 2) return null;

    return compact;
  }

  static String _slug(String? input) {
    if (input == null) return '';
    final lower = input.trim().toLowerCase();
    if (lower.isEmpty) return '';

    const replacements = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
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

    var normalized = lower;
    replacements.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });

    normalized = normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return normalized;
  }
}
