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

    group('LoadPhotos', () {
      blocTest<PhotoSelectionBloc, PhotoSelectionState>(
        'should emit [PhotoSelectionLoading, PhotoSelectionLoaded] when photos are loaded successfully',
        build: () {
          when(mockPhotoUseCases.getPhotosFromGallery())
              .thenAnswer((_) async => Right(testPhotos));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadPhotos()),
        expect: () => [
          isA<PhotoSelectionLoading>(),
          isA<PhotoSelectionLoaded>().having(
            (state) => state.allPhotos,
            'allPhotos',
            testPhotos,
          ),
        ],
      );

      blocTest<PhotoSelectionBloc, PhotoSelectionState>(
        'should emit [PhotoSelectionLoading, PhotoSelectionError] when loading photos fails',
        build: () {
          when(mockPhotoUseCases.getPhotosFromGallery())
              .thenAnswer((_) async => Left(ServerFailure('Failed')));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadPhotos()),
        expect: () => [
          isA<PhotoSelectionLoading>(),
          isA<PhotoSelectionError>(),
        ],
      );
    });

    group('TogglePhotoSelection', () {
      blocTest<PhotoSelectionBloc, PhotoSelectionState>(
        'should add photo to selection if not already selected',
        build: () => bloc,
        seed: () => PhotoSelectionLoaded(allPhotos: testPhotos, selectedPhotos: []),
        act: (bloc) => bloc.add(TogglePhotoSelection(photo: testPhotos.first)),
        expect: () => [
          isA<PhotoSelectionLoaded>().having(
            (state) => state.selectedPhotos,
            'selectedPhotos',
            [testPhotos.first],
          )
        ],
      );

      blocTest<PhotoSelectionBloc, PhotoSelectionState>(
        'should remove photo from selection if already selected',
        build: () => bloc,
        seed: () => PhotoSelectionLoaded(allPhotos: testPhotos, selectedPhotos: [testPhotos.first]),
        act: (bloc) => bloc.add(TogglePhotoSelection(photo: testPhotos.first)),
        expect: () => [
          isA<PhotoSelectionLoaded>().having(
            (state) => state.selectedPhotos,
            'selectedPhotos',
            [],
          )
        ],
      );
    });

    group('StartComparison', () {
      blocTest<PhotoSelectionBloc, PhotoSelectionState>(
        'should emit [ComparisonReady] when 2 or more photos are selected',
        build: () => bloc,
        seed: () => PhotoSelectionLoaded(allPhotos: testPhotos, selectedPhotos: testPhotos),
        act: (bloc) => bloc.add(StartComparison()),
        expect: () => [isA<ComparisonReady>()],
      );

      blocTest<PhotoSelectionBloc, PhotoSelectionState>(
        'should emit [PhotoSelectionError] when less than 2 photos are selected',
        build: () => bloc,
        seed: () => PhotoSelectionLoaded(allPhotos: testPhotos, selectedPhotos: [testPhotos.first]),
        act: (bloc) => bloc.add(StartComparison()),
        expect: () => [isA<PhotoSelectionError>()],
      );
    });
  });
}
