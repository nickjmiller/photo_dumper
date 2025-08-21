import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../domain/entities/photo.dart';
import '../../domain/services/photo_manager_service.dart';
import '../../domain/usecases/photo_usecases.dart';
import '../../../../core/services/platform_service.dart';
import 'dart:math';

// Events
abstract class PhotoComparisonEvent extends Equatable {
  const PhotoComparisonEvent();

  @override
  List<Object> get props => [];
}

class LoadSelectedPhotos extends PhotoComparisonEvent {
  final List<Photo> photos;

  const LoadSelectedPhotos({required this.photos});

  @override
  List<Object> get props => [photos];
}

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

class NextPair extends PhotoComparisonEvent {}

class RestartComparison extends PhotoComparisonEvent {}

class ConfirmDeletion extends PhotoComparisonEvent {}

class CancelComparison extends PhotoComparisonEvent {}

class KeepRemainingPhotos extends PhotoComparisonEvent {}

class ContinueComparing extends PhotoComparisonEvent {
  final bool dontAskAgain;

  const ContinueComparing({this.dontAskAgain = false});

  @override
  List<Object> get props => [dontAskAgain];
}

// States
abstract class PhotoComparisonState extends Equatable {
  const PhotoComparisonState();

  @override
  List<Object> get props => [];
}

class PhotoComparisonInitial extends PhotoComparisonState {}

class PhotoComparisonLoading extends PhotoComparisonState {}

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

class PhotoComparisonBloc
    extends Bloc<PhotoComparisonEvent, PhotoComparisonState> {
  final PhotoUseCases photoUseCases;
  final PhotoManagerService photoManagerService;
  final PlatformService platformService;
  final Random _random = Random();

  // Internal state tracking
  List<Photo> _allPhotos = [];
  List<Photo> _remainingPhotos = [];
  List<Photo> _eliminatedPhotos = [];
  List<List<Photo>> _currentRoundPairs = [];
  int _currentPairIndex = 0;
  Set<String> _skippedPairs = {};
  bool _dontAskAgain = false;

  String _getPairKey(Photo p1, Photo p2) {
    final ids = [p1.id, p2.id];
    ids.sort();
    return ids.join('-');
  }

  PhotoComparisonBloc({
    required this.photoUseCases,
    PhotoManagerService? photoManagerService,
    PlatformService? platformService,
  })  : photoManagerService = photoManagerService ?? PhotoManagerService(),
        platformService = platformService ?? PlatformService(),
        super(PhotoComparisonInitial()) {
    on<LoadSelectedPhotos>(_onLoadSelectedPhotos);
    on<SelectWinner>(_onSelectWinner);
    on<SkipPair>(_onSkipPair);
    on<NextPair>(_onNextPair);
    on<RestartComparison>(_onRestartComparison);
    on<ConfirmDeletion>(_onConfirmDeletion);
    on<CancelComparison>(_onCancelComparison);
    on<KeepRemainingPhotos>(_onKeepRemainingPhotos);
    on<ContinueComparing>(_onContinueComparing);
  }

  Future<void> _onLoadSelectedPhotos(
    LoadSelectedPhotos event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    emit(PhotoComparisonLoading());

    _allPhotos = List.from(event.photos);
    _remainingPhotos = List.from(event.photos);
    _eliminatedPhotos = [];
    _currentPairIndex = 0;
    _skippedPairs = {};
    _dontAskAgain = false;

    _generatePairs();
    _emitCurrentState(emit);
  }

  Future<void> _onSelectWinner(
    SelectWinner event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    // Remove both photos from remaining
    _remainingPhotos.remove(event.winner);
    _remainingPhotos.remove(event.loser);

    // Add winner back to remaining for next round
    _remainingPhotos.add(event.winner);

    // Add loser to eliminated
    _eliminatedPhotos.add(event.loser);

    _nextPair(emit);
  }

  Future<void> _onSkipPair(
    SkipPair event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    final pairKey = _getPairKey(event.photo1, event.photo2);
    _skippedPairs.add(pairKey);

    final n = _remainingPhotos.length;
    if (n > 1) {
      final totalPossiblePairs = (n * (n - 1)) / 2;
      if (!_dontAskAgain && _skippedPairs.length >= totalPossiblePairs) {
        emit(AllPairsSkipped(remainingPhotos: _remainingPhotos));
        return;
      }
    }

    _nextPair(emit);
  }

  Future<void> _onNextPair(
    NextPair event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    _nextPair(emit);
  }

  Future<void> _onRestartComparison(
    RestartComparison event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    _allPhotos = List.from(_allPhotos);
    _remainingPhotos = List.from(_allPhotos);
    _eliminatedPhotos = [];
    _currentPairIndex = 0;
    _skippedPairs = {};
    _dontAskAgain = false;

    _generatePairs();
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
      final List<String> photoIds =
          _eliminatedPhotos.map((p) => p.id).toList();

      bool deletionSucceeded = false;

      // Prefer moving to trash on Android if possible
      if (platformService.isAndroid) {
        try {
          final assetEntities = await Future.wait(
              photoIds.map((id) => photoManagerService.assetEntityFromId(id)));
          final nonNullAssetEntities = assetEntities.whereType<AssetEntity>().toList();

          if (nonNullAssetEntities.isNotEmpty) {
            await photoManagerService.moveToTrash(nonNullAssetEntities);
            deletionSucceeded = true;
          }
        } catch (e) {
          // Failed to move to trash, will fallback to permanent delete.
          // We don't rethrow here, because failure is expected on older Android.
        }
      }

      // If not Android, or if moving to trash failed, use permanent deletion.
      if (!deletionSucceeded) {
        await photoManagerService.deleteWithIds(photoIds);
      }

      emit(ComparisonComplete(winner: _remainingPhotos));
    } catch (e) {
      // This single catch block will now handle failures from both moveToTrash (if it's a real error)
      // and deleteWithIds, ensuring a PhotoComparisonError is always emitted on failure.
      emit(PhotoComparisonError('Failed to delete photos: $e'));
    }
  }

  void _onCancelComparison(
    CancelComparison event,
    Emitter<PhotoComparisonState> emit,
  ) {
    // Reset all internal state
    _allPhotos = [];
    _remainingPhotos = [];
    _eliminatedPhotos = [];
    _currentRoundPairs = [];
    _currentPairIndex = 0;

    // Emit initial state to clear everything
    emit(PhotoComparisonInitial());
  }

  void _onKeepRemainingPhotos(
    KeepRemainingPhotos event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    emit(PhotoComparisonLoading());
    await Future.delayed(const Duration(milliseconds: 50));
    emit(
      DeletionConfirmation(
        eliminatedPhotos: _eliminatedPhotos,
        winner: _remainingPhotos,
      ),
    );
  }

  void _onContinueComparing(
    ContinueComparing event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    _dontAskAgain = event.dontAskAgain;
    _skippedPairs.clear();
    emit(PhotoComparisonLoading());
    await Future.delayed(const Duration(milliseconds: 50));
    _generatePairs();
    _emitCurrentState(emit);
  }

  void _generatePairs() {
    _currentRoundPairs = [];
    final allPossiblePairs = <List<Photo>>[];
    for (int i = 0; i < _remainingPhotos.length; i++) {
      for (int j = i + 1; j < _remainingPhotos.length; j++) {
        allPossiblePairs.add([_remainingPhotos[i], _remainingPhotos[j]]);
      }
    }

    var validPairs = allPossiblePairs.where((pair) {
      final key = _getPairKey(pair[0], pair[1]);
      return !_skippedPairs.contains(key);
    }).toList();

    if (validPairs.isEmpty && _remainingPhotos.length > 1) {
      if (_dontAskAgain) {
        // User opted out and has skipped all pairs again.
        // Reset and let them loop.
        _skippedPairs.clear();
        validPairs = allPossiblePairs;
      }
    }

    validPairs.shuffle(_random);
    _currentRoundPairs = validPairs;
    _currentPairIndex = 0;
  }

  void _nextPair(Emitter<PhotoComparisonState> emit) {
    _currentPairIndex++;

    if (_currentPairIndex >= _currentRoundPairs.length) {
      // Round complete
      _generatePairs();
    }

    _emitCurrentState(emit);
  }

  void _emitCurrentState(Emitter<PhotoComparisonState> emit) {
    // Check if tournament is complete (only one photo remaining)
    if (_remainingPhotos.length == 1) {
      emit(
        DeletionConfirmation(
          eliminatedPhotos: _eliminatedPhotos,
          winner: _remainingPhotos,
        ),
      );
      return;
    }

    // Check if we have pairs to compare
    if (_currentRoundPairs.isEmpty ||
        _currentPairIndex >= _currentRoundPairs.length) {
      // If we are here, it means there are no more pairs to compare.
      // This can happen if all pairs have been skipped.
      if (_remainingPhotos.length > 1) {
        emit(AllPairsSkipped(remainingPhotos: _remainingPhotos));
      } else {
        // This should be handled by the check for `_remainingPhotos.length == 1`
        // but as a fallback, we go to the confirmation screen.
        emit(
          DeletionConfirmation(
            eliminatedPhotos: _eliminatedPhotos,
            winner: _remainingPhotos,
          ),
        );
      }
      return;
    }

    final currentPair = _currentRoundPairs[_currentPairIndex];
    final currentPhoto1 = currentPair[0];
    final currentPhoto2 = currentPair[1];

    emit(
      TournamentInProgress(
        currentPhoto1: currentPhoto1,
        currentPhoto2: currentPhoto2,
        currentComparison: _currentPairIndex + 1,
        totalComparisons: _currentRoundPairs.length,
        remainingPhotos: _remainingPhotos,
        eliminatedPhotos: _eliminatedPhotos,
      ),
    );
  }
}
