import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bundled recitations catalog is available on iOS', (tester) async {
    final source = await rootBundle.loadString('assets/data/recitations_fallback.json');
    final catalog = jsonDecode(source) as Map<String, dynamic>;
    final surahs = catalog['surahs'] as List<dynamic>;
    expect(surahs, hasLength(114));
    expect(surahs.where((item) => item['available'] == true), isNotEmpty);
  });
}
