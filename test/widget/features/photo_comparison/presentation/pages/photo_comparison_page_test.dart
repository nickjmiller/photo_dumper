import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_dumper/features/photo_comparison/data/repositories/photo_repository_impl.dart';
import 'package:photo_dumper/features/photo_comparison/domain/entities/photo.dart';
import 'package:photo_dumper/features/photo_comparison/domain/usecases/photo_usecases.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/bloc/photo_comparison_bloc.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/pages/photo_comparison_page.dart';

class MockPhotoUseCases extends Mock implements PhotoUseCases {}

class MockPhotoRepositoryImpl extends Mock implements PhotoRepositoryImpl {}

void main() {
  group('PhotoComparisonPage', () {
    late MockPhotoUseCases mockPhotoUseCases;
    late PhotoComparisonBloc photoComparisonBloc;

    setUp(() {
      mockPhotoUseCases = MockPhotoUseCases();
      photoComparisonBloc = PhotoComparisonBloc(
        photoUseCases: mockPhotoUseCases,
      );
    });

    tearDown(() {
      photoComparisonBloc.close();
    });

    Widget createTestWidget({
      required List<Photo> selectedPhotos,
      required PhotoComparisonState initialState,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<PhotoComparisonBloc>.value(
            value: photoComparisonBloc..emit(initialState),
            child: PhotoComparisonPage(selectedPhotos: selectedPhotos),
          ),
        ),
      );
    }

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

    testWidgets('should show Done button on completion screen', (
      WidgetTester tester,
    ) async {
      // Arrange
      final selectedPhotos = [createMockPhoto()];
      final completionState = ComparisonComplete(
        winner: [createMockPhoto(id: 'winner')],
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
      final selectedPhotos = [createMockPhoto()];
      final winnerPhotos = [
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
      final selectedPhotos = [createMockPhoto()];
      final completionState = ComparisonComplete(
        winner: [createMockPhoto(id: 'winner')],
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
  });
}
