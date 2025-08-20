import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:photo_dumper/features/photo_comparison/domain/entities/photo.dart';
import 'package:photo_dumper/features/photo_comparison/domain/usecases/photo_usecases.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/bloc/photo_selection_bloc.dart';
import 'package:photo_dumper/core/error/failures.dart';

import 'photo_selection_bloc_test.mocks.dart';

@GenerateMocks([PhotoUseCases])
void main() {
  group('PhotoSelectionBloc', () {
    late MockPhotoUseCases mockPhotoUseCases;
    late PhotoSelectionBloc bloc;

    setUp(() {
      mockPhotoUseCases = MockPhotoUseCases();
      bloc = PhotoSelectionBloc(photoUseCases: mockPhotoUseCases);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state should be PhotoSelectionInitial', () {
      expect(bloc.state, isA<PhotoSelectionInitial>());
    });

    group('PickPhotosAndCompare', () {
      final testPhotos = [
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
      ];

      blocTest<PhotoSelectionBloc, PhotoSelectionState>(
        'should emit [PhotoSelectionLoading, ComparisonReady] when photos are picked successfully and count >= 2',
        build: () {
          when(
            mockPhotoUseCases.getLibraryPhotos(),
          ).thenAnswer((_) async => Right(testPhotos));
          return bloc;
        },
        act: (bloc) => bloc.add(PickPhotosAndCompare()),
        expect: () => [isA<PhotoSelectionLoading>(), isA<ComparisonReady>()],
        verify: (_) {
          verify(mockPhotoUseCases.getLibraryPhotos()).called(1);
        },
      );

      blocTest<PhotoSelectionBloc, PhotoSelectionState>(
        'should emit [PhotoSelectionLoading, PhotoSelectionError] when only 1 photo is picked',
        build: () {
          when(
            mockPhotoUseCases.getLibraryPhotos(),
          ).thenAnswer((_) async => Right([testPhotos[0]]));
          return bloc;
        },
        act: (bloc) => bloc.add(PickPhotosAndCompare()),
        expect: () => [
          isA<PhotoSelectionLoading>(),
          isA<PhotoSelectionError>(),
        ],
        verify: (_) {
          verify(mockPhotoUseCases.getLibraryPhotos()).called(1);
        },
      );

      blocTest<PhotoSelectionBloc, PhotoSelectionState>(
        'should emit [PhotoSelectionLoading, PhotoSelectionError] when no photos are picked',
        build: () {
          when(
            mockPhotoUseCases.getLibraryPhotos(),
          ).thenAnswer((_) async => Right([]));
          return bloc;
        },
        act: (bloc) => bloc.add(PickPhotosAndCompare()),
        expect: () => [
          isA<PhotoSelectionLoading>(),
          isA<PhotoSelectionError>(),
        ],
        verify: (_) {
          verify(mockPhotoUseCases.getLibraryPhotos()).called(1);
        },
      );

      blocTest<PhotoSelectionBloc, PhotoSelectionState>(
        'should emit [PhotoSelectionLoading, PhotoSelectionError] when getLibraryPhotos fails',
        build: () {
          when(mockPhotoUseCases.getLibraryPhotos()).thenAnswer(
            (_) async => Left(ServerFailure('Failed to load photos')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(PickPhotosAndCompare()),
        expect: () => [
          isA<PhotoSelectionLoading>(),
          isA<PhotoSelectionError>(),
        ],
        verify: (_) {
          verify(mockPhotoUseCases.getLibraryPhotos()).called(1);
        },
      );
    });
  });
}
