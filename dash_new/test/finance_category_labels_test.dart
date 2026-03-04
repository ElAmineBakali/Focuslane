import 'package:flutter_test/flutter_test.dart';
import 'package:mi_dashboard_personal/screens/finance/services/finance_category_labels.dart';

void main() {
  test("labelForCategory('alimentacion') == 'Alimentación'", () {
    expect(labelForCategory('alimentacion'), 'Alimentación');
  });
}
