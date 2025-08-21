import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:photo_dumper/features/photo_comparison/domain/entities/photo.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/bloc/photo_comparison_bloc.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/widgets/all_pairs_skipped_dialog.dart';
import 'package:bloc_test/bloc_test.dart';

class MockPhotoComparisonBloc extends MockBloc<PhotoComparisonEvent, PhotoComparisonState> implements PhotoComparisonBloc {}

void main() {
  group('AllPairsSkippedDialog', () {
    late PhotoComparisonBloc mockBloc;

    final testPhotos = [
      Photo(id: '1', name: 'photo1.jpg', createdAt: DateTime.now(), file: File('test/path/photo1.jpg')),
      Photo(id: '2', name: 'photo2.jpg', createdAt: DateTime.now(), file: File('test/path/photo2.jpg')),
    ];

    setUp(() {
      mockBloc = MockPhotoComparisonBloc();
    });

    Future<void> pumpDialog(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PhotoComparisonBloc>.value(
            value: mockBloc,
            child: Scaffold(
              body: AllPairsSkippedDialog(remainingPhotos: testPhotos),
            ),
          ),
        ),
      );
    }

    testWidgets('renders correctly', (WidgetTester tester) async {
      await pumpDialog(tester);

      expect(find.text('Keep all remaining photos?'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('No, Continue Comparing'), findsOneWidget);
      expect(find.text('Yes, Keep Them'), findsOneWidget);
    });

    testWidgets('tapping checkbox changes its value', (WidgetTester tester) async {
      await pumpDialog(tester);

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });

    testWidgets('tapping "No, Continue Comparing" dispatches ContinueComparing event with dontAskAgain=false', (WidgetTester tester) async {
      await pumpDialog(tester);

      await tester.tap(find.text('No, Continue Comparing'));
      await tester.pump();

      final captured = verify(mockBloc.add(captureAny)).captured;
      expect(captured.first, isA<ContinueComparing>());
      expect((captured.first as ContinueComparing).dontAskAgain, isFalse);
    });

    testWidgets('tapping "No, Continue Comparing" dispatches ContinueComparing event with dontAskAgain=true when checked', (WidgetTester tester) async {
      await pumpDialog(tester);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.tap(find.text('No, Continue Comparing'));
      await tester.pump();

      final captured = verify(mockBloc.add(captureAny)).captured;
      expect(captured.first, isA<ContinueComparing>());
      expect((captured.first as ContinueComparing).dontAskAgain, isTrue);
    });

    testWidgets('tapping "Yes, Keep Them" dispatches KeepRemainingPhotos event', (WidgetTester tester) async {
      await pumpDialog(tester);

      await tester.tap(find.text('Yes, Keep Them'));
      await tester.pump();

      verify(mockBloc.add(isA<KeepRemainingPhotos>())).called(1);
    });
  });
}
