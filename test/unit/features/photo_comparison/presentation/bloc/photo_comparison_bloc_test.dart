import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'dart:io';
import 'package:mockito/mockito.dart';
import 'package:photo_dumper/features/photo_comparison/domain/entities/photo.dart';
import 'package:photo_dumper/features/photo_comparison/domain/services/photo_manager_service.dart';
import 'package:photo_dumper/features/photo_comparison/domain/usecases/photo_usecases.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/bloc/photo_comparison_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:photo_dumper/features/photo_comparison/domain/repositories/photo_repository.dart';
import 'package:photo_dumper/core/services/platform_service.dart';
import 'photo_comparison_bloc_test.mocks.dart';

@GenerateMocks([PhotoUseCases, PhotoManagerService, PhotoRepository, PlatformService])
void main() {
  group('PhotoComparisonBloc', () {
    late PhotoComparisonBloc bloc;
    late MockPhotoUseCases mockPhotoUseCases;
    late MockPhotoManagerService mockPhotoManagerService;
    late MockPlatformService mockPlatformService;

    final testPhotos = [
      Photo(id: '1', name: 'photo1.jpg', createdAt: DateTime.now(), file: File('test/path/photo1.jpg')),
      Photo(id: '2', name: 'photo2.jpg', createdAt: DateTime.now(), file: File('test/path/photo2.jpg')),
      Photo(id: '3', name: 'photo3.jpg', createdAt: DateTime.now(), file: File('test/path/photo3.jpg')),
    ];

    setUp(() {
      mockPhotoUseCases = MockPhotoUseCases();
      mockPhotoManagerService = MockPhotoManagerService();
      mockPlatformService = MockPlatformService();
      bloc = PhotoComparisonBloc(
        photoUseCases: mockPhotoUseCases,
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
        'emits [TournamentInProgress, DeletionConfirmation] when only one photo remains',
        build: () => bloc,
        act: (bloc) {
          bloc.add(LoadSelectedPhotos(photos: [photo1, photo2]));
          return bloc.add(SelectWinner(winner: photo1, loser: photo2));
        },
        skip: 1, // Skip PhotoComparisonLoading state
        expect: () => [
          isA<TournamentInProgress>(), // The state from LoadSelectedPhotos
          isA<DeletionConfirmation>(), // The state from SelectWinner
        ],
      );
    });

    group('ConfirmDeletion', () {
       final photo1 = testPhotos[0];
       final photo2 = testPhotos[1];

       blocTest<PhotoComparisonBloc, PhotoComparisonState>(
        'emits [ComparisonComplete] when deletion is successful',
        build: () {
          when(mockPlatformService.isAndroid).thenReturn(false);
          when(mockPhotoManagerService.deleteWithIds(any)).thenAnswer((_) async => []);
          return bloc;
        },
        seed: () => DeletionConfirmation(eliminatedPhotos: [photo2], winner: [photo1]),
        act: (bloc) => bloc.add(ConfirmDeletion()),
        expect: () => [
          isA<ComparisonComplete>(),
        ],
       );

       blocTest<PhotoComparisonBloc, PhotoComparisonState>(
        'emits [PhotoComparisonError] when deletion fails on a non-Android platform',
        build: () {
          when(mockPlatformService.isAndroid).thenReturn(false);
          when(mockPhotoManagerService.deleteWithIds([photo2.id]))
              .thenAnswer((_) async => throw Exception('Deletion failed'));
          return bloc;
        },
        seed: () => DeletionConfirmation(eliminatedPhotos: [photo2], winner: [photo1]),
        act: (bloc) => bloc.add(ConfirmDeletion()),
        verify: (_) {
          verify(mockPhotoManagerService.deleteWithIds([photo2.id])).called(1);
        },
        expect: () => [
          isA<PhotoComparisonError>(),
        ],
       );
    });
  });
}
