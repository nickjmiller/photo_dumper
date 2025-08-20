import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/pages/photo_selection_page.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/bloc/photo_selection_bloc.dart';
import 'package:photo_dumper/features/photo_comparison/domain/usecases/photo_usecases.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:photo_dumper/features/photo_comparison/domain/entities/photo.dart';
import 'package:photo_dumper/core/error/failures.dart';

import 'photo_comparison_flow_test.mocks.dart';

@GenerateMocks([PhotoUseCases])
void main() {
  group('Photo Selection Flow Tests', () {
    late MockPhotoUseCases mockPhotoUseCases;

    setUp(() {
      mockPhotoUseCases = MockPhotoUseCases();
    });

    testWidgets('should display photo selection page with select button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) =>
                PhotoSelectionBloc(photoUseCases: mockPhotoUseCases),
            child: const PhotoSelectionPage(),
          ),
        ),
      );

      // Check for the body text specifically (not AppBar title)
      expect(
        find.text('Select photos to compare and organize'),
        findsOneWidget,
      );
      expect(find.text('Select Photos'), findsOneWidget);
      // Check for the button specifically
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('should show loading indicator when picking photos', (
      WidgetTester tester,
    ) async {
      // Setup mock to return a delayed response
      when(mockPhotoUseCases.getLibraryPhotos()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Right([
          Photo(
            id: '1',
            name: 'photo1.jpg',
            imagePath: '/path/to/photo1.jpg',
            thumbnailPath: '/path/to/photo1.jpg',
            createdAt: DateTime.now(),
          ),
          Photo(
            id: '2',
            name: 'photo2.jpg',
            imagePath: '/path/to/photo2.jpg',
            thumbnailPath: '/path/to/photo2.jpg',
            createdAt: DateTime.now(),
          ),
        ]);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) =>
                PhotoSelectionBloc(photoUseCases: mockPhotoUseCases),
            child: const PhotoSelectionPage(),
          ),
        ),
      );

      // Tap the select photos button
      await tester.tap(find.text('Select Photos'));
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for the async operation to complete
      await tester.pump(const Duration(milliseconds: 150));
    });

    testWidgets('should show error when photo picking fails', (
      WidgetTester tester,
    ) async {
      when(
        mockPhotoUseCases.getLibraryPhotos(),
      ).thenAnswer((_) async => Left(ServerFailure('Failed to load photos')));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) =>
                PhotoSelectionBloc(photoUseCases: mockPhotoUseCases),
            child: const PhotoSelectionPage(),
          ),
        ),
      );

      // Tap the select photos button
      await tester.tap(find.text('Select Photos'));
      await tester.pump();

      // Wait for the error to be shown
      await tester.pump(const Duration(milliseconds: 100));

      // Should show error snackbar
      expect(find.text('Failed to load photos'), findsOneWidget);
    });

    testWidgets('should show error when less than 2 photos are selected', (
      WidgetTester tester,
    ) async {
      when(mockPhotoUseCases.getLibraryPhotos()).thenAnswer(
        (_) async => Right([
          Photo(
            id: '1',
            name: 'photo1.jpg',
            imagePath: '/path/to/photo1.jpg',
            thumbnailPath: '/path/to/photo1.jpg',
            createdAt: DateTime.now(),
          ),
        ]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) =>
                PhotoSelectionBloc(photoUseCases: mockPhotoUseCases),
            child: const PhotoSelectionPage(),
          ),
        ),
      );

      // Tap the select photos button
      await tester.tap(find.text('Select Photos'));
      await tester.pump();

      // Wait for the error to be shown
      await tester.pump(const Duration(milliseconds: 100));

      // Should show error snackbar
      expect(find.text('Please select at least 2 photos'), findsOneWidget);
    });
  });
}
