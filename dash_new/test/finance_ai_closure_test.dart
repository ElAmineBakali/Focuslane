import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_dashboard_personal/screens/finance/services/finance_ai_normalizer.dart';
import 'package:mi_dashboard_personal/screens/finance/services/finance_ai_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FinanceAiPreferences persists auto classify toggle', () async {
    SharedPreferences.setMockInitialValues({});

    final initial = await FinanceAiPreferences.getAutoClassifyEnabled(
      fallback: false,
    );
    expect(initial, isFalse);

    await FinanceAiPreferences.setAutoClassifyEnabled(true);
    final persisted = await FinanceAiPreferences.getAutoClassifyEnabled(
      fallback: false,
    );

    expect(persisted, isTrue);
  });

  test('FinanceAiNormalizer normalizes category/subCategory and trims noisy tags', () {
    final normalized = FinanceAiNormalizer.normalize({
      'category': 'Alimentación',
      'subCategory': 'Supermercado',
      'tags': ['42.50 EUR', 'Mercadona', '€', 'hogar', '123', 'Comida'],
    });

    expect(normalized.category, 'alimentacion');
    expect(normalized.subCategory, 'supermercado');
    expect(normalized.tags, contains('mercadona'));
    expect(normalized.tags, contains('hogar'));
    expect(normalized.tags, isNot(contains('42.50 eur')));
    expect(normalized.tags, isNot(contains('123')));
  });
}
