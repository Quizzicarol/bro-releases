// Basic Flutter widget test for Bro App
import 'package:flutter_test/flutter_test.dart';

import 'package:bro_app/main.dart';
import 'package:bro_app/providers/locale_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final localeProvider = LocaleProvider();
    await localeProvider.initialize();
    // Build our app and trigger a frame.
    await tester.pumpWidget(BroApp(
      isLoggedIn: false,
      hasSeenOnboarding: true,
      localeProvider: localeProvider,
    ));

    // Verify that the app loads without crashing
    await tester.pump();
  });
}