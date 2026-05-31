import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/main.dart';
import 'package:myapp/core/database/database_service.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    // Initialize standard mock offline DB boxes
    final db = DatabaseService.instance;
    await db.init();

    // Pump app with required ProviderScope for Riverpod
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Verify it builds without throwing exceptions
    expect(tester.takeException(), isNull);
  });
}
