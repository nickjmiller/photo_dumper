import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'dart:io';
import 'package:mockito/mockito.dart';
import 'package:photo_dumper/features/photo_comparison/domain/entities/photo.dart';
import 'package:photo_dumper/features/photo_comparison/domain/services/photo_manager_service.dart';
import 'package:photo_dumper/features/photo_comparison/domain/usecases/photo_usecases.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/bloc/photo_comparison_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:photo_dumper/features/photo_comparison/domain/repositories/photo_repository.dart';
import 'package:photo_dumper/core/services/platform_service.dart';
import 'package:photo_dumper/features/photo_comparison/domain/usecases/comparison_usecases.dart';
import 'photo_comparison_bloc_test.mocks.dart';

@GenerateMocks([
  PhotoUseCases,
  PhotoManagerService,
  PhotoRepository,
  PlatformService,
  ComparisonUseCases,
])
void main() {
  group('PhotoComparisonBloc', () {
    late PhotoComparisonBloc bloc;
    late MockPhotoUseCases mockPhotoUseCases;
    late MockComparisonUseCases mockComparisonUseCases;
    late MockPhotoManagerService mockPhotoManagerService;
    late MockPlatformService mockPlatformService;

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
      Photo(
        id: '3',
        name: 'photo3.jpg',
        createdAt: DateTime.now(),
        file: File('test/path/photo3.jpg'),
      ),
    ];

    setUp(() {
      mockPhotoUseCases = MockPhotoUseCases();
      mockComparisonUseCases = MockComparisonUseCases();
      mockPhotoManagerService = MockPhotoManagerService();
      mockPlatformService = MockPlatformService();
      bloc = PhotoComparisonBloc(
        photoUseCases: mockPhotoUseCases,
        comparisonUseCases: mockComparisonUseCases,
        photoManagerService: mockPhotoManagerService,
        platformService: mockPlatformService,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state should be PhotoComparisonInitial', () {
      expect(bloc.state, isA<PhotoComparisonInitial>());
    });

    group('LoadSelectedPhotos', () {
      blocTest<PhotoComparisonBloc, PhotoComparisonState>(
        'emits [PhotoComparisonLoading, TournamentInProgress] when LoadSelectedPhotos is added',
        build: () => bloc,
        act: (bloc) => bloc.add(LoadSelectedPhotos(photos: testPhotos)),
        expect: () => [
          isA<PhotoComparisonLoading>(),
          isA<TournamentInProgress>(),
        ],
      );
    });

    group('SelectWinner', () {
      final photo1 = testPhotos[0];
      final photo2 = testPhotos[1];

      blocTest<PhotoComparisonBloc, PhotoComparisonState>(
        'emits [DeletionConfirmation] when only one photo remains',
        build: () {
          bloc.add(LoadSelectedPhotos(photos: [photo1, photo2]));
          return bloc;
        },
        act: (bloc) => bloc.add(SelectWinner(winner: photo1, loser: photo2)),
        skip: 2, // Skip Loading and initial TournamentInProgress
        expect: () => [isA<DeletionConfirmation>()],
      );
    });

    group('SkipPair', () {
      final photo1 = testPhotos[0];
      final photo2 = testPhotos[1];

      blocTest<PhotoComparisonBloc, PhotoComparisonState>(
        'emits [AllPairsSkipped] when all pairs are skipped',
        build: () {
          bloc.add(LoadSelectedPhotos(photos: [photo1, photo2]));
          return bloc;
        },
        act: (bloc) => bloc.add(SkipPair(photo1: photo1, photo2: photo2)),
        skip: 2, // Skip Loading and initial TournamentInProgress
        expect: () => [isA<AllPairsSkipped>()],
      );
    });

    group('ConfirmDeletion', () {
      final photo1 = testPhotos[0];
      final photo2 = testPhotos[1];

      blocTest<PhotoComparisonBloc, PhotoComparisonState>(
        'emits [ComparisonComplete] when deletion is successful',
        build: () {
          when(mockPlatformService.isAndroid).thenReturn(false);
          when(mockPhotoManagerService.deleteWithIds(any)).thenAnswer(
            (invocation) async =>
                invocation.positionalArguments[0] as List<String>,
          );
          when(
            mockComparisonUseCases.deleteComparisonSession(any),
          ).thenAnswer((_) async => const Right(null));
          bloc.add(LoadSelectedPhotos(photos: [photo1, photo2]));
          bloc.add(SelectWinner(winner: photo1, loser: photo2));
          return bloc;
        },
        act: (bloc) => bloc.add(ConfirmDeletion()),
        skip: 3,
        expect: () => [isA<ComparisonComplete>()],
      );

      blocTest<PhotoComparisonBloc, PhotoComparisonState>(
        'emits [PhotoDeletionFailure] when deletion fails',
        build: () {
          when(mockPlatformService.isAndroid).thenReturn(false);
          when(
            mockPhotoManagerService.deleteWithIds(any),
          ).thenThrow(Exception('Deletion failed'));
          bloc.add(LoadSelectedPhotos(photos: [photo1, photo2]));
          bloc.add(SelectWinner(winner: photo1, loser: photo2));
          return bloc;
        },
        act: (bloc) => bloc.add(ConfirmDeletion()),
        skip: 3,
        expect: () => [isA<PhotoDeletionFailure>()],
      );
    });
  });
}
