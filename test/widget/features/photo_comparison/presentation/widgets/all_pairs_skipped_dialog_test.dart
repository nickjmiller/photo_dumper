import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_dumper/features/photo_comparison/domain/entities/photo.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/bloc/photo_comparison_bloc.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/widgets/all_pairs_skipped_dialog.dart';

class MockPhotoComparisonBloc extends Mock implements PhotoComparisonBloc {}
class FakePhotoComparisonEvent extends Fake implements PhotoComparisonEvent {}
class FakePhotoComparisonState extends Fake implements PhotoComparisonState {}

void main() {
  group('AllPairsSkippedDialog', () {
    late MockPhotoComparisonBloc mockBloc;

    final testPhotos = [
      Photo(id: '1', name: 'photo1.jpg', createdAt: DateTime.now(), file: File('test/path/photo1.jpg')),
      Photo(id: '2', name: 'photo2.jpg', createdAt: DateTime.now(), file: File('test/path/photo2.jpg')),
    ];

    setUp(() {
      mockBloc = MockPhotoComparisonBloc();
      registerFallbackValue(FakePhotoComparisonEvent());
      registerFallbackValue(FakePhotoComparisonState());

      // Stub the BLoC's stream and state
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockBloc.state).thenReturn(AllPairsSkipped(remainingPhotos: testPhotos));
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

      verify(() => mockBloc.add(any(that: isA<ContinueComparing>()
          .having((e) => e.dontAskAgain, 'dontAskAgain', false))));
    });

    testWidgets('tapping "No, Continue Comparing" dispatches ContinueComparing event with dontAskAgain=true when checked', (WidgetTester tester) async {
      await pumpDialog(tester);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.tap(find.text('No, Continue Comparing'));
      await tester.pump();

      verify(() => mockBloc.add(any(that: isA<ContinueComparing>()
          .having((e) => e.dontAskAgain, 'dontAskAgain', true))));
    });

    testWidgets('tapping "Yes, Keep Them" dispatches KeepRemainingPhotos event', (WidgetTester tester) async {
      when(() => mockBloc.add(any())).thenReturn(null);
      await pumpDialog(tester);

      await tester.tap(find.text('Yes, Keep Them'));
      await tester.pump();

      verify(() => mockBloc.add(any(that: isA<KeepRemainingPhotos>())));
    });
  });
}
