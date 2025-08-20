import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/widgets/action_buttons.dart';

void main() {
  group('ActionButtons Widget', () {
    testWidgets('should display both buttons with correct labels', (
      WidgetTester tester,
    ) async {
      bool keepBothCalled = false;
      bool discardBothCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButtons(
              onKeepBoth: () => keepBothCalled = true,
              onDiscardBoth: () => discardBothCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Keep Both'), findsOneWidget);
      expect(find.text('Discard Both'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('should call onKeepBoth when Keep Both button is pressed', (
      WidgetTester tester,
    ) async {
      bool keepBothCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButtons(
              onKeepBoth: () => keepBothCalled = true,
              onDiscardBoth: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Keep Both'));
      await tester.pump();

      expect(keepBothCalled, isTrue);
    });

    testWidgets(
      'should call onDiscardBoth when Discard Both button is pressed',
      (WidgetTester tester) async {
        bool discardBothCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActionButtons(
                onKeepBoth: () {},
                onDiscardBoth: () => discardBothCalled = true,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Discard Both'));
        await tester.pump();

        expect(discardBothCalled, isTrue);
      },
    );

    testWidgets('should have proper button styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButtons(onKeepBoth: () {}, onDiscardBoth: () {}),
          ),
        ),
      );

      expect(find.text('Keep Both'), findsOneWidget);
      expect(find.text('Discard Both'), findsOneWidget);
    });

    testWidgets('should be arranged in a row with proper spacing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButtons(onKeepBoth: () {}, onDiscardBoth: () {}),
          ),
        ),
      );

      expect(find.text('Keep Both'), findsOneWidget);
      expect(find.text('Discard Both'), findsOneWidget);
    });
  });
}
