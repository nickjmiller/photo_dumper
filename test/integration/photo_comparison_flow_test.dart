import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/widgets/action_buttons.dart';

void main() {
  group('Photo Comparison Widget Tests', () {
    testWidgets('should display action buttons correctly', (
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

    testWidgets('should handle keep both action', (WidgetTester tester) async {
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

    testWidgets('should handle discard both action', (
      WidgetTester tester,
    ) async {
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
    });
  });
}
