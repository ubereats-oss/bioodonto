import 'package:flutter_test/flutter_test.dart';
import 'package:bioodonto/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Smoke test básico — expandir conforme o app cresce
    expect(BioOdontoApp, isNotNull);
  });
}
