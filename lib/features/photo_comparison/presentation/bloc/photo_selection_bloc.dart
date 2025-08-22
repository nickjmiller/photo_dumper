import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/photo.dart';
import '../../domain/usecases/comparison_usecases.dart';
import '../../domain/usecases/photo_usecases.dart';
import '../../../../core/services/permission_service.dart';

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
  }

  Future<void> _onLoadPhotos(
    LoadPhotos event,
    Emitter<PhotoSelectionState> emit,
  ) async {
    emit(PhotoSelectionLoading());

    final ps = await permissionService.requestPhotoPermission();
    if (!ps.hasAccess) {
      emit(PhotoSelectionPermissionError(ps));
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
            hasLimitedAccess: !ps.isAuth && ps.hasAccess,
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
