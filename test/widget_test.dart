import 'package:flutter_test/flutter_test.dart';
import 'package:knockknock_ai/app/knockknock_app.dart';

void main() {
  testWidgets('KnockKnockApp renders home prompt', (WidgetTester tester) async {
    await tester.pumpWidget(const KnockKnockApp());

    expect(find.text('Knock on your desk 👇'), findsOneWidget);
  });
}
