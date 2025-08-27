import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/photo.dart';
import '../../domain/usecases/comparison_usecases.dart';
import '../../domain/usecases/photo_usecases.dart';
import '../../../../core/services/permission_service.dart';
import '../../domain/entities/comparison_session.dart';
import '../../domain/services/photo_clustering_service.dart';
import '../../domain/services/image_hashing_service.dart';

// Events
abstract class PhotoSelectionEvent extends Equatable {
  const PhotoSelectionEvent();

  @override
  List<Object> get props => [];
}

class LoadPhotos extends PhotoSelectionEvent {}

class TogglePhotoSelection extends PhotoSelectionEvent {
  final Photo photo;

  const TogglePhotoSelection({required this.photo});

  @override
  List<Object> get props => [photo];
}

class StartComparison extends PhotoSelectionEvent {}

class ResetSelection extends PhotoSelectionEvent {}

class FindSimilarPhotos extends PhotoSelectionEvent {}

// States
abstract class PhotoSelectionState extends Equatable {
  const PhotoSelectionState();

  @override
  List<Object> get props => [];
}

class PhotoSelectionInitial extends PhotoSelectionState {}

class PhotoSelectionLoading extends PhotoSelectionState {}

class PhotoSelectionLoaded extends PhotoSelectionState {
  final List<Photo> allPhotos;
  final List<Photo> selectedPhotos;
  final Set<String> lockedPhotoIds;
  final bool hasLimitedAccess;

  const PhotoSelectionLoaded({
    required this.allPhotos,
    this.selectedPhotos = const [],
    this.lockedPhotoIds = const {},
    this.hasLimitedAccess = false,
  });

  @override
  List<Object> get props => [
    allPhotos,
    selectedPhotos,
    lockedPhotoIds,
    hasLimitedAccess,
  ];

  PhotoSelectionLoaded copyWith({
    List<Photo>? allPhotos,
    List<Photo>? selectedPhotos,
    Set<String>? lockedPhotoIds,
    bool? hasLimitedAccess,
  }) {
    return PhotoSelectionLoaded(
      allPhotos: allPhotos ?? this.allPhotos,
      selectedPhotos: selectedPhotos ?? this.selectedPhotos,
      lockedPhotoIds: lockedPhotoIds ?? this.lockedPhotoIds,
      hasLimitedAccess: hasLimitedAccess ?? this.hasLimitedAccess,
    );
  }
}

class ComparisonReady extends PhotoSelectionState {
  final List<Photo> selectedPhotos;

  const ComparisonReady({required this.selectedPhotos});

  @override
  List<Object> get props => [selectedPhotos];
}

class PhotoSelectionError extends PhotoSelectionState {
  final String message;

  const PhotoSelectionError(this.message);

  @override
  List<Object> get props => [message];
}

class PhotoSelectionPermissionError extends PhotoSelectionState {
  final PermissionState permissionState;

  const PhotoSelectionPermissionError(this.permissionState);

  @override
  List<Object> get props => [permissionState];
}

class FindingSimilarPhotos extends PhotoSelectionState {}

class FindSimilarPhotosSuccess extends PhotoSelectionState {
  final int comparisonCount;

  const FindSimilarPhotosSuccess(this.comparisonCount);

  @override
  List<Object> get props => [comparisonCount];
}

class PhotoSelectionBloc
    extends Bloc<PhotoSelectionEvent, PhotoSelectionState> {
  final PhotoUseCases photoUseCases;
  final ComparisonUseCases comparisonUseCases;
  final PermissionService permissionService;

  PhotoSelectionBloc({
    required this.photoUseCases,
    required this.comparisonUseCases,
    required this.permissionService,
  }) : super(PhotoSelectionInitial()) {
    on<LoadPhotos>(_onLoadPhotos);
    on<TogglePhotoSelection>(_onTogglePhotoSelection);
    on<StartComparison>(_onStartComparison);
    on<ResetSelection>(_onResetSelection);
    on<FindSimilarPhotos>(_onFindSimilarPhotos);
  }

  Future<void> _onFindSimilarPhotos(
    FindSimilarPhotos event,
    Emitter<PhotoSelectionState> emit,
  ) async {
    if (state is! PhotoSelectionLoaded) return;

    final currentState = state as PhotoSelectionLoaded;
    emit(FindingSimilarPhotos());

    try {
      final clusteringService = PhotoClusteringService(
        imageHashingService: ImageHashingService(),
      );
      final clusters = await clusteringService.findClusters(
        currentState.allPhotos,
      );

      if (clusters.isEmpty) {
        emit(const FindSimilarPhotosSuccess(0));
        // Restore the previous state
        emit(currentState);
        return;
      }

      int createdCount = 0;
      for (final cluster in clusters) {
        if (cluster.length < 2) continue;

        final session = ComparisonSession(
          id: const Uuid().v4(),
          allPhotos: cluster,
          remainingPhotos: cluster,
          eliminatedPhotos: [],
          createdAt: DateTime.now(),
        );

        final result = await comparisonUseCases.saveComparisonSession(session);
        result.fold(
          (l) => null, // Silently ignore failed saves for now
          (r) => createdCount++,
        );
      }

      emit(FindSimilarPhotosSuccess(createdCount));
      // Restore the previous state
      emit(currentState);
    } catch (e) {
      emit(PhotoSelectionError(e.toString()));
    }
  }

  Future<void> _onLoadPhotos(
    LoadPhotos event,
    Emitter<PhotoSelectionState> emit,
  ) async {
    emit(PhotoSelectionLoading());

    final permissionState = await permissionService.requestPhotoPermission();
    if (permissionState != PermissionState.authorized &&
        permissionState != PermissionState.limited) {
      emit(PhotoSelectionPermissionError(permissionState));
      return;
    }

    final lockedIdsResult = await comparisonUseCases.getAllPhotoIdsInUse();
    if (lockedIdsResult.isLeft()) {
      emit(const PhotoSelectionError('Could not load session data.'));
      return;
    }
    final lockedIds = lockedIdsResult.getOrElse(() => []);

    final photosResult = await photoUseCases.getPhotosFromGallery();
    photosResult.fold(
      (failure) {
        if (failure is PhotoPermissionFailure) {
          emit(PhotoSelectionPermissionError(failure.permissionState));
        } else {
          emit(PhotoSelectionError(failure.message));
        }
      },
      (photos) {
        emit(
          PhotoSelectionLoaded(
            allPhotos: photos,
            lockedPhotoIds: lockedIds.toSet(),
            hasLimitedAccess: permissionState == PermissionState.limited,
          ),
        );
      },
    );
  }

  void _onTogglePhotoSelection(
    TogglePhotoSelection event,
    Emitter<PhotoSelectionState> emit,
  ) {
    if (state is PhotoSelectionLoaded) {
      final currentState = state as PhotoSelectionLoaded;

      if (currentState.lockedPhotoIds.contains(event.photo.id)) {
        return; // Do not allow selecting locked photos
      }

      final newSelectedPhotos = List<Photo>.from(currentState.selectedPhotos);

      if (newSelectedPhotos.contains(event.photo)) {
        newSelectedPhotos.remove(event.photo);
      } else {
        newSelectedPhotos.add(event.photo);
      }

      emit(currentState.copyWith(selectedPhotos: newSelectedPhotos));
    }
  }

  void _onStartComparison(
    StartComparison event,
    Emitter<PhotoSelectionState> emit,
  ) {
    if (state is PhotoSelectionLoaded) {
      final currentState = state as PhotoSelectionLoaded;
      if (currentState.selectedPhotos.length >= 2) {
        emit(ComparisonReady(selectedPhotos: currentState.selectedPhotos));
      } else {
        emit(const PhotoSelectionError('Please select at least 2 photos'));
      }
    }
  }

  void _onResetSelection(
    ResetSelection event,
    Emitter<PhotoSelectionState> emit,
  ) {
    emit(PhotoSelectionInitial());
  }
}
