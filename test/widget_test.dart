import 'package:flutter_test/flutter_test.dart';
import 'package:salon317_app/main.dart';

void main() {
  testWidgets('App renders and navigates past splash without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Salon317App());
    expect(find.text('SALÓN 317'), findsOneWidget);

    // Avanzar el timer dl splash screen
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
  });
}
