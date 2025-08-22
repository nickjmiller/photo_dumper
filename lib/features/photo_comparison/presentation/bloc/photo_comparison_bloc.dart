import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/comparison_session.dart';
import '../../domain/usecases/comparison_usecases.dart';
import '../../domain/entities/photo.dart';
import '../../domain/services/photo_manager_service.dart';
import '../../domain/usecases/photo_usecases.dart';
import '../../../../core/services/platform_service.dart';
import 'dart:math';

// Events
abstract class PhotoComparisonEvent extends Equatable {
  const PhotoComparisonEvent();

  @override
  List<Object?> get props => [];
}

class LoadSelectedPhotos extends PhotoComparisonEvent {
  final List<Photo> photos;

  const LoadSelectedPhotos({required this.photos});

  @override
  List<Object> get props => [photos];
}

class ResumeComparison extends PhotoComparisonEvent {
  final ComparisonSession session;

  const ResumeComparison({required this.session});

  @override
  List<Object> get props => [session];
}

class PauseComparison extends PhotoComparisonEvent {}

class SelectWinner extends PhotoComparisonEvent {
  final Photo winner;
  final Photo loser;

  const SelectWinner({required this.winner, required this.loser});

  @override
  List<Object> get props => [winner, loser];
}

class SkipPair extends PhotoComparisonEvent {
  final Photo photo1;
  final Photo photo2;

  const SkipPair({required this.photo1, required this.photo2});

  @override
  List<Object> get props => [photo1, photo2];
}

class RestartComparison extends PhotoComparisonEvent {}

class ConfirmDeletion extends PhotoComparisonEvent {}

class CancelComparison extends PhotoComparisonEvent {}

class KeepRemainingPhotos extends PhotoComparisonEvent {}

// States
abstract class PhotoComparisonState extends Equatable {
  const PhotoComparisonState();

  @override
  List<Object> get props => [];
}

class PhotoComparisonInitial extends PhotoComparisonState {}

class PhotoComparisonLoading extends PhotoComparisonState {}

class PhotoComparisonPaused extends PhotoComparisonState {}

class TournamentInProgress extends PhotoComparisonState {
  final Photo currentPhoto1;
  final Photo currentPhoto2;
  final int currentComparison;
  final int totalComparisons;
  final List<Photo> remainingPhotos;
  final List<Photo> eliminatedPhotos;

  const TournamentInProgress({
    required this.currentPhoto1,
    required this.currentPhoto2,
    required this.currentComparison,
    required this.totalComparisons,
    required this.remainingPhotos,
    required this.eliminatedPhotos,
  });

  @override
  List<Object> get props => [
    currentPhoto1,
    currentPhoto2,
    currentComparison,
    totalComparisons,
    remainingPhotos,
    eliminatedPhotos,
  ];
}

class DeletionConfirmation extends PhotoComparisonState {
  final List<Photo> eliminatedPhotos;
  final List<Photo> winner;

  const DeletionConfirmation({
    required this.eliminatedPhotos,
    required this.winner,
  });

  @override
  List<Object> get props => [eliminatedPhotos, winner];
}

class ComparisonComplete extends PhotoComparisonState {
  final List<Photo> winner;

  const ComparisonComplete({required this.winner});

  @override
  List<Object> get props => [winner];
}

class AllPairsSkipped extends PhotoComparisonState {
  final List<Photo> remainingPhotos;

  const AllPairsSkipped({required this.remainingPhotos});

  @override
  List<Object> get props => [remainingPhotos];
}

class PhotoComparisonError extends PhotoComparisonState {
  final String message;

  const PhotoComparisonError(this.message);

  @override
  List<Object> get props => [message];
}

class PhotoDeletionFailure extends PhotoComparisonState {
  final List<Photo> eliminatedPhotos;
  final List<Photo> winner;
  final String message;

  const PhotoDeletionFailure({
    required this.eliminatedPhotos,
    required this.winner,
    required this.message,
  });

  @override
  List<Object> get props => [eliminatedPhotos, winner, message];
}

class PhotoComparisonBloc
    extends Bloc<PhotoComparisonEvent, PhotoComparisonState> {
  final PhotoUseCases photoUseCases;
  final ComparisonUseCases comparisonUseCases;
  final PhotoManagerService photoManagerService;
  final PlatformService platformService;
  final Uuid uuid;
  final Random _random = Random();

  // Internal state tracking
  String? _sessionId;
  List<Photo> _allPhotos = [];
  List<Photo> _remainingPhotos = [];
  List<Photo> _eliminatedPhotos = [];
  int _totalComparisons = 0;
  Set<String> _skippedPairs = {};

  String _getPairKey(Photo p1, Photo p2) {
    final ids = [p1.id, p2.id]..sort();
    return ids.join('-');
  }

  PhotoComparisonBloc({
    required this.photoUseCases,
    required this.comparisonUseCases,
    this.uuid = const Uuid(),
    PhotoManagerService? photoManagerService,
    PlatformService? platformService,
  }) : photoManagerService = photoManagerService ?? PhotoManagerService(),
       platformService = platformService ?? PlatformService(),
       super(PhotoComparisonInitial()) {
    on<LoadSelectedPhotos>(_onLoadSelectedPhotos);
    on<ResumeComparison>(_onResumeComparison);
    on<PauseComparison>(_onPauseComparison);
    on<SelectWinner>(_onSelectWinner);
    on<SkipPair>(_onSkipPair);
    on<RestartComparison>(_onRestartComparison);
    on<ConfirmDeletion>(_onConfirmDeletion);
    on<CancelComparison>(_onCancelComparison);
    on<KeepRemainingPhotos>(_onKeepRemainingPhotos);
  }

  Future<void> _onLoadSelectedPhotos(
    LoadSelectedPhotos event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    emit(PhotoComparisonLoading());

    _sessionId = null;
    _allPhotos = List.from(event.photos);
    _allPhotos.shuffle(_random);
    _remainingPhotos = List.from(_allPhotos);
    _eliminatedPhotos = [];
    _totalComparisons = _allPhotos.length - 1;
    _skippedPairs = {};

    _emitCurrentState(emit);
  }

  Future<void> _onResumeComparison(
    ResumeComparison event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    emit(PhotoComparisonLoading());

    _sessionId = event.session.id;
    _allPhotos = List.from(event.session.allPhotos);
    _remainingPhotos = List.from(event.session.remainingPhotos);
    _eliminatedPhotos = List.from(event.session.eliminatedPhotos);
    _totalComparisons = _allPhotos.length - 1;
    _skippedPairs = {};

    _emitCurrentState(emit);
  }

  Future<void> _onPauseComparison(
    PauseComparison event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    _sessionId ??= uuid.v4();

    final session = ComparisonSession(
      id: _sessionId!,
      allPhotos: _allPhotos,
      remainingPhotos: _remainingPhotos,
      eliminatedPhotos: _eliminatedPhotos,
      createdAt: DateTime.now(),
    );

    final result = await comparisonUseCases.saveComparisonSession(session);

    result.fold(
      (failure) => emit(
        PhotoComparisonError('Failed to save session: ${failure.toString()}'),
      ),
      (_) => emit(PhotoComparisonPaused()),
    );
  }

  Future<void> _onSelectWinner(
    SelectWinner event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    _remainingPhotos.remove(event.loser);
    _eliminatedPhotos.add(event.loser);

    _emitCurrentState(emit);
  }

  Future<void> _onSkipPair(
    SkipPair event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    final pairKey = _getPairKey(event.photo1, event.photo2);
    _skippedPairs.add(pairKey);
    _emitCurrentState(emit);
  }

  Future<void> _onRestartComparison(
    RestartComparison event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    _allPhotos.shuffle(_random);
    _remainingPhotos = List.from(_allPhotos);
    _eliminatedPhotos = [];
    _totalComparisons = _allPhotos.length - 1;
    _skippedPairs = {};

    _emitCurrentState(emit);
  }

  Future<void> _onConfirmDeletion(
    ConfirmDeletion event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    if (_eliminatedPhotos.isEmpty) {
      emit(ComparisonComplete(winner: _remainingPhotos));
      return;
    }

    try {
      final List<String> photoIds = _eliminatedPhotos.map((p) => p.id).toList();

      bool deletionSucceeded = false;

      if (platformService.isAndroid) {
        try {
          final assetEntities = await Future.wait(
            photoIds.map((id) => photoManagerService.assetEntityFromId(id)),
          );
          final nonNullAssetEntities = assetEntities
              .whereType<AssetEntity>()
              .toList();

          if (nonNullAssetEntities.isNotEmpty) {
            await photoManagerService.moveToTrash(nonNullAssetEntities);
            deletionSucceeded = true;
          }
        } catch (e) {
          // Fallback to permanent delete
        }
      }

      if (!deletionSucceeded) {
        await photoManagerService.deleteWithIds(photoIds);
      }

      if (_sessionId != null) {
        await comparisonUseCases.deleteComparisonSession(_sessionId!);
      }

      emit(ComparisonComplete(winner: _remainingPhotos));
    } catch (e) {
      emit(
        PhotoDeletionFailure(
          eliminatedPhotos: _eliminatedPhotos,
          winner: _remainingPhotos,
          message: 'Failed to delete photos. Please try again.',
        ),
      );
    }
  }

  void _onCancelComparison(
    CancelComparison event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    if (_sessionId != null) {
      await comparisonUseCases.deleteComparisonSession(_sessionId!);
    }
    emit(PhotoComparisonInitial());
  }

  void _onKeepRemainingPhotos(
    KeepRemainingPhotos event,
    Emitter<PhotoComparisonState> emit,
  ) {
    emit(
      DeletionConfirmation(
        eliminatedPhotos: _eliminatedPhotos,
        winner: _remainingPhotos,
      ),
    );
  }

  void _emitCurrentState(Emitter<PhotoComparisonState> emit) {
    if (_remainingPhotos.length < 2) {
      emit(
        DeletionConfirmation(
          eliminatedPhotos: _eliminatedPhotos,
          winner: _remainingPhotos,
        ),
      );
      return;
    }

    List<Photo>? nextPair = _getNextPair();
    if (nextPair == null) {
      emit(AllPairsSkipped(remainingPhotos: _remainingPhotos));
      return;
    }

    emit(
      TournamentInProgress(
        currentPhoto1: nextPair[0],
        currentPhoto2: nextPair[1],
        currentComparison: _eliminatedPhotos.length + 1,
        totalComparisons: _totalComparisons,
        remainingPhotos: _remainingPhotos,
        eliminatedPhotos: _eliminatedPhotos,
      ),
    );
  }

  List<Photo>? _getNextPair() {
    for (int i = 0; i < _remainingPhotos.length; i++) {
      for (int j = i + 1; j < _remainingPhotos.length; j++) {
        final pairKey = _getPairKey(_remainingPhotos[i], _remainingPhotos[j]);
        if (!_skippedPairs.contains(pairKey)) {
          return [_remainingPhotos[i], _remainingPhotos[j]];
        }
      }
    }
    return null;
  }
}
