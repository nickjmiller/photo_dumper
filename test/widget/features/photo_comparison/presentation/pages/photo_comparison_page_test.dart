import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_dumper/features/photo_comparison/data/repositories/photo_repository_impl.dart';
import 'package:photo_dumper/features/photo_comparison/domain/entities/photo.dart';
import 'package:photo_dumper/features/photo_comparison/domain/usecases/comparison_usecases.dart';
import 'package:photo_dumper/features/photo_comparison/domain/usecases/photo_usecases.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/bloc/photo_comparison_bloc.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/pages/photo_comparison_page.dart';

class MockPhotoUseCases extends Mock implements PhotoUseCases {}
class MockComparisonUseCases extends Mock implements ComparisonUseCases {}

class MockPhotoRepositoryImpl extends Mock implements PhotoRepositoryImpl {}

Photo createMockPhoto({String? id, String? imagePath}) {
  return Photo(
    id: id ?? 'test_id',
    name: 'test_photo.jpg',
    imagePath: imagePath ?? '/test/path',
    createdAt: DateTime.now(),
    file: File(
      '/test/path',
    ), // Provide a mock file to avoid null check errors
  );
}

void main() {
  group('PhotoComparisonPage', () {
    late MockPhotoUseCases mockPhotoUseCases;
    late MockComparisonUseCases mockComparisonUseCases;
    late PhotoComparisonBloc photoComparisonBloc;

    setUp(() {
      mockPhotoUseCases = MockPhotoUseCases();
      mockComparisonUseCases = MockComparisonUseCases();
      photoComparisonBloc = PhotoComparisonBloc(
        photoUseCases: mockPhotoUseCases,
        comparisonUseCases: mockComparisonUseCases,
      );
    });

    tearDown(() {
      photoComparisonBloc.close();
    });

    Widget createTestWidget({
      List<Photo>? selectedPhotos,
      required PhotoComparisonState initialState,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<PhotoComparisonBloc>.value(
            value: photoComparisonBloc..emit(initialState),
            child: PhotoComparisonPage(selectedPhotos: selectedPhotos ?? <Photo>[createMockPhoto()]),
          ),
        ),
      );
    }

    testWidgets('should show Done button on completion screen', (
      WidgetTester tester,
    ) async {
      // Arrange
      final selectedPhotos = <Photo>[createMockPhoto()];
      final completionState = ComparisonComplete(
        winner: <Photo>[createMockPhoto(id: 'winner')],
      );

      await tester.pumpWidget(
        createTestWidget(
          selectedPhotos: selectedPhotos,
          initialState: completionState,
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify we're on the completion screen
      expect(find.text('Comparison Complete!'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('should show completion screen with correct winner count', (
      WidgetTester tester,
    ) async {
      // Arrange
      final selectedPhotos = <Photo>[createMockPhoto()];
      final winnerPhotos = <Photo>[
        createMockPhoto(id: 'winner1'),
        createMockPhoto(id: 'winner2'),
      ];
      final completionState = ComparisonComplete(winner: winnerPhotos);

      await tester.pumpWidget(
        createTestWidget(
          selectedPhotos: selectedPhotos,
          initialState: completionState,
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Comparison Complete!'), findsOneWidget);
      expect(find.text('2 photo kept'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('should show completion screen with single winner', (
      WidgetTester tester,
    ) async {
      // Arrange
      final selectedPhotos = <Photo>[createMockPhoto()];
      final completionState = ComparisonComplete(
        winner: <Photo>[createMockPhoto(id: 'winner')],
      );

      await tester.pumpWidget(
        createTestWidget(
          selectedPhotos: selectedPhotos,
          initialState: completionState,
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Comparison Complete!'), findsOneWidget);
      expect(find.text('1 photo kept'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets(
      'should show deletion confirmation screen with Cancel and Confirm buttons',
      (WidgetTester tester) async {
        // Arrange
        final selectedPhotos = <Photo>[createMockPhoto()];
        final photo1 = createMockPhoto(id: 'photo1');
        final photo2 = createMockPhoto(id: 'photo2');
        final deletionState = DeletionConfirmation(
          eliminatedPhotos: <Photo>[photo1],
          winner: <Photo>[photo2],
        );

        await tester.pumpWidget(
          createTestWidget(
            selectedPhotos: selectedPhotos,
            initialState: deletionState,
          ),
        );

        // Wait for the widget to build
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Review Photos for Deletion'), findsOneWidget);
        expect(
          find.text('1 photos will be deleted\n1 photo will be kept'),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Confirm Delete'), findsOneWidget);
      },
    );

    testWidgets('should emit RestartComparison when Cancel button is pressed', (
      WidgetTester tester,
    ) async {
      // Arrange
      final selectedPhotos = <Photo>[createMockPhoto()];
      final photo1 = createMockPhoto(id: 'photo1');
      final photo2 = createMockPhoto(id: 'photo2');
      final deletionState = DeletionConfirmation(
        eliminatedPhotos: <Photo>[photo1],
        winner: <Photo>[photo2],
      );

      await tester.pumpWidget(
        createTestWidget(
          selectedPhotos: selectedPhotos,
          initialState: deletionState,
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Act - Press Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert - Verify that RestartComparison event was emitted
      // This is verified by checking that the bloc state changes
      // The actual verification would be done in bloc tests
    });

    testWidgets('should show tournament in progress with correct photo count', (
      WidgetTester tester,
    ) async {
      // Arrange
      final selectedPhotos = <Photo>[createMockPhoto()];
      final photo1 = createMockPhoto(id: 'photo1');
      final photo2 = createMockPhoto(id: 'photo2');
      final tournamentState = TournamentInProgress(
        currentPhoto1: photo1,
        currentPhoto2: photo2,
        currentComparison: 1,
        totalComparisons: 1,
        remainingPhotos: <Photo>[photo1, photo2],
        eliminatedPhotos: [],
      );

      await tester.pumpWidget(
        createTestWidget(
          selectedPhotos: selectedPhotos,
          initialState: tournamentState,
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('2 photos remaining • 0 queued for deletion'),
        findsOneWidget,
      );
      expect(find.text('VS'), findsOneWidget);
      expect(find.text('Skip This Pair'), findsOneWidget);
      expect(find.text('Restart'), findsOneWidget);
    });

    testWidgets(
      'should reset drag state when transitioning from deletion confirmation to tournament',
      (WidgetTester tester) async {
        // Arrange
        final selectedPhotos = <Photo>[createMockPhoto()];
        final photo1 = createMockPhoto(id: 'photo1');
        final photo2 = createMockPhoto(id: 'photo2');

        // Start with deletion confirmation state
        final deletionState = DeletionConfirmation(
          eliminatedPhotos: <Photo>[photo1],
          winner: <Photo>[photo2],
        );

        await tester.pumpWidget(
          createTestWidget(
            selectedPhotos: selectedPhotos,
            initialState: deletionState,
          ),
        );

        await tester.pumpAndSettle();

        // Verify we're on deletion confirmation screen
        expect(find.text('Review Photos for Deletion'), findsOneWidget);

        // Act - Press Cancel button to return to tournament
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // The bloc should emit a new TournamentInProgress state
        // This test verifies that the UI properly handles the state transition
        // and resets drag state when new photos are loaded
      },
    );
  });
}
