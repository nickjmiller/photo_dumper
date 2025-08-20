import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'dart:io';
import 'package:photo_dumper/features/photo_comparison/domain/entities/photo.dart';
import 'package:photo_dumper/features/photo_comparison/domain/usecases/photo_usecases.dart';
import 'package:photo_dumper/features/photo_comparison/domain/repositories/photo_repository.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/bloc/photo_comparison_bloc.dart';
import 'package:photo_dumper/core/error/failures.dart';

class MockPhotoRepository implements PhotoRepository {
  @override
  Future<Either<Failure, List<Photo>>> getLibraryPhotos() async {
    return Right([]);
  }
}

void main() {
  group('PhotoComparisonBloc', () {
    late PhotoComparisonBloc bloc;
    late PhotoUseCases photoUseCases;

    setUp(() {
      photoUseCases = PhotoUseCases(MockPhotoRepository());
      bloc = PhotoComparisonBloc(photoUseCases: photoUseCases);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state should be PhotoComparisonInitial', () {
      expect(bloc.state, isA<PhotoComparisonInitial>());
    });

    group('LoadSelectedPhotos', () {
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

      blocTest<PhotoComparisonBloc, PhotoComparisonState>(
        'emits [PhotoComparisonLoading, TournamentInProgress] when LoadSelectedPhotos is added',
        build: () => bloc,
        act: (bloc) => bloc.add(LoadSelectedPhotos(photos: testPhotos)),
        expect: () => [
          isA<PhotoComparisonLoading>(),
          isA<TournamentInProgress>(),
        ],
      );

      blocTest<PhotoComparisonBloc, PhotoComparisonState>(
        'emits correct TournamentInProgress state with first pair',
        build: () => bloc,
        act: (bloc) => bloc.add(LoadSelectedPhotos(photos: testPhotos)),
        expect: () => [
          isA<PhotoComparisonLoading>(),
          predicate<TournamentInProgress>((state) {
            return state.currentComparison == 1 &&
                state.totalComparisons == 1 &&
                state.remainingPhotos.length ==
                    3 && // All 3 photos in remaining
                state.eliminatedPhotos.isEmpty;
          }),
        ],
      );
    });

    group('SelectWinner', () {
      final photo1 = Photo(
        id: '1',
        name: 'photo1.jpg',
        createdAt: DateTime.now(),
        file: File('test/path/photo1.jpg'),
      );
      final photo2 = Photo(
        id: '2',
        name: 'photo2.jpg',
        createdAt: DateTime.now(),
        file: File('test/path/photo2.jpg'),
      );

      blocTest<PhotoComparisonBloc, PhotoComparisonState>(
        'emits DeletionConfirmation when selecting winner and only one photo remains',
        build: () {
          // Initialize with just 2 photos
          bloc.add(LoadSelectedPhotos(photos: [photo1, photo2]));
          return bloc;
        },
        act: (bloc) => bloc.add(SelectWinner(winner: photo1, loser: photo2)),
        expect: () => [
          isA<PhotoComparisonLoading>(),
          isA<TournamentInProgress>(),
          predicate<DeletionConfirmation>((state) {
            return state.eliminatedPhotos.length == 1 &&
                state.winner.length == 1;
          }),
        ],
      );
    });

    group('SkipPair', () {
      final photo1 = Photo(
        id: '1',
        name: 'photo1.jpg',
        createdAt: DateTime.now(),
        file: File('test/path/photo1.jpg'),
      );
      final photo2 = Photo(
        id: '2',
        name: 'photo2.jpg',
        createdAt: DateTime.now(),
        file: File('test/path/photo2.jpg'),
      );

      blocTest<PhotoComparisonBloc, PhotoComparisonState>(
        'emits TournamentInProgress when skipping pair (photos put back in queue)',
        build: () {
          bloc.add(LoadSelectedPhotos(photos: [photo1, photo2]));
          return bloc;
        },
        act: (bloc) => bloc.add(SkipPair(photo1: photo1, photo2: photo2)),
        expect: () => [
          isA<PhotoComparisonLoading>(),
          isA<TournamentInProgress>(),
          isA<PhotoComparisonLoading>(), // Loading state when skipping
          isA<TournamentInProgress>(), // After skipping, new pair is generated
        ],
        wait: const Duration(milliseconds: 10),
      );
    });

    group('RestartComparison', () {
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

      blocTest<PhotoComparisonBloc, PhotoComparisonState>(
        'emits TournamentInProgress when restarting comparison',
        build: () {
          bloc.add(LoadSelectedPhotos(photos: testPhotos));
          bloc.add(SelectWinner(winner: testPhotos[0], loser: testPhotos[1]));
          return bloc;
        },
        act: (bloc) => bloc.add(RestartComparison()),
        expect: () => [
          isA<PhotoComparisonLoading>(),
          isA<TournamentInProgress>(),
          predicate<DeletionConfirmation>((state) {
            return state.eliminatedPhotos.length == 1;
          }),
          isA<TournamentInProgress>(),
        ],
      );
    });

    group('ConfirmDeletion', () {
      final photo1 = Photo(
        id: '1',
        name: 'photo1.jpg',
        createdAt: DateTime.now(),
        file: File('test/path/photo1.jpg'),
      );
      final photo2 = Photo(
        id: '2',
        name: 'photo2.jpg',
        createdAt: DateTime.now(),
        file: File('test/path/photo2.jpg'),
      );

      blocTest<PhotoComparisonBloc, PhotoComparisonState>(
        'emits ComparisonComplete when confirming deletion',
        build: () {
          bloc.add(LoadSelectedPhotos(photos: [photo1, photo2]));
          bloc.add(SelectWinner(winner: photo1, loser: photo2));
          return bloc;
        },
        act: (bloc) => bloc.add(ConfirmDeletion()),
        expect: () => [
          isA<PhotoComparisonLoading>(),
          isA<TournamentInProgress>(),
          predicate<DeletionConfirmation>((state) {
            return state.eliminatedPhotos.length == 1;
          }),
          predicate<ComparisonComplete>((state) {
            return state.winner.length == 1;
          }),
        ],
      );
    });
  });
}
