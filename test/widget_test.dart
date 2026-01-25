import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:synclife_app/src/app.dart';

void main() {
  testWidgets('SyncLife app smoke test', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: SyncLifeApp(),
      ),
    );

    // Verify that the app starts with the login page
    expect(find.text('SyncLife'), findsOneWidget);
    expect(find.text('Collaborative task management with gamification'), findsOneWidget);
  });
}
