import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knockknock_ai/ui/knock_animation_widget.dart';

void main() {
  group('KnockAnimationWidget', () {
    Future<void> pumpWidgetUnderTest(
      WidgetTester tester,
      GlobalKey<KnockAnimationWidgetState> key,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KnockAnimationWidget(key: key),
          ),
        ),
      );
    }

    Future<void> advanceAnimation(WidgetTester tester) async {
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('Door emoji 🚪 renders by default', (WidgetTester tester) async {
      final key = GlobalKey<KnockAnimationWidgetState>();
      await pumpWidgetUnderTest(tester, key);

      expect(find.text('🚪'), findsOneWidget);
    });

    testWidgets('Speech bubble appears after triggerKnock()', (
      WidgetTester tester,
    ) async {
      final key = GlobalKey<KnockAnimationWidgetState>();
      await pumpWidgetUnderTest(tester, key);

      key.currentState!.triggerKnock('Come in 😳');
      await advanceAnimation(tester);

      expect(key.currentState!.currentBubbleText, 'Come in 😳');
      expect(find.text('Come in 😳'), findsOneWidget);
    });

    testWidgets('Speech bubble text matches responseText passed in', (
      WidgetTester tester,
    ) async {
      final key = GlobalKey<KnockAnimationWidgetState>();
      await pumpWidgetUnderTest(tester, key);

      key.currentState!.triggerKnock('Custom response');
      await advanceAnimation(tester);

      expect(key.currentState!.currentBubbleText, 'Custom response');
      expect(find.text('Custom response'), findsOneWidget);
    });

    testWidgets('triggerDoubleKnock() shows "SERIOUSLY?! 😤"', (
      WidgetTester tester,
    ) async {
      final key = GlobalKey<KnockAnimationWidgetState>();
      await pumpWidgetUnderTest(tester, key);

      key.currentState!.triggerDoubleKnock();
      await advanceAnimation(tester);

      expect(key.currentState!.currentBubbleText, 'SERIOUSLY?! 😤');
      expect(find.text('SERIOUSLY?! 😤'), findsOneWidget);
    });
  });
}
