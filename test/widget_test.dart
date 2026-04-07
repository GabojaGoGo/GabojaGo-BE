import 'package:flutter_test/flutter_test.dart';
import 'package:tripmate/main.dart';

void main() {
  testWidgets('TripMate smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TripMateApp());
    expect(find.text('TripMate'), findsWidgets);
  });
}
