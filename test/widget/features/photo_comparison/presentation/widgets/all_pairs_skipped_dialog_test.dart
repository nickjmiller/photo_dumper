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
      Photo(
        id: '1',
        name: 'photo1.jpg',
        createdAt: DateTime.now(),
        file: File('test/path/photo1.jpg'),
      ),
      Photo(
        id: '2',
        name: 'photo2.jpg',
        createdAt: DateTime.now(),
        file: File('test/path/photo2.jpg'),
      ),
    ];

    setUp(() {
      mockBloc = MockPhotoComparisonBloc();
      registerFallbackValue(FakePhotoComparisonEvent());
      registerFallbackValue(FakePhotoComparisonState());

      // Stub the BLoC's stream and state
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
      when(
        () => mockBloc.state,
      ).thenReturn(AllPairsSkipped(remainingPhotos: testPhotos));
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

      expect(find.text('All Pairs Skipped'), findsOneWidget);
      expect(
        find.text(
          'You have skipped all possible pairs with the remaining 2 photos. Do you want to keep them all?',
        ),
        findsOneWidget,
      );
      expect(find.text('No, Restart'), findsOneWidget);
      expect(find.text('Yes, Keep Them'), findsOneWidget);
    });

    testWidgets(
      'tapping "Yes, Keep Them" dispatches KeepRemainingPhotos event',
      (WidgetTester tester) async {
        when(() => mockBloc.add(any())).thenReturn(null);
        await pumpDialog(tester);

        await tester.tap(find.text('Yes, Keep Them'));
        await tester.pump();

        verify(() => mockBloc.add(any(that: isA<KeepRemainingPhotos>())));
      },
    );

    testWidgets('tapping "No, Restart" dispatches RestartComparison event', (
      WidgetTester tester,
    ) async {
      when(() => mockBloc.add(any())).thenReturn(null);
      await pumpDialog(tester);

      await tester.tap(find.text('No, Restart'));
      await tester.pump();

      verify(() => mockBloc.add(any(that: isA<RestartComparison>())));
    });
  });
}
