// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/widgets/action_buttons.dart';

void main() {
  testWidgets('Action buttons widget test', (WidgetTester tester) async {
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
}
