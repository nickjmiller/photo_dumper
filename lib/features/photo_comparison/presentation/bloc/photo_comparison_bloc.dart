import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/photo.dart';
import '../../domain/usecases/photo_usecases.dart';

// Events
abstract class PhotoComparisonEvent extends Equatable {
  const PhotoComparisonEvent();

  @override
  List<Object> get props => [];
}

class LoadPhotos extends PhotoComparisonEvent {}

class KeepPhoto extends PhotoComparisonEvent {
  final String photoId;
  final String photoName;

  const KeepPhoto({required this.photoId, required this.photoName});

  @override
  List<Object> get props => [photoId, photoName];
}

class DeletePhoto extends PhotoComparisonEvent {
  final String photoId;
  final String photoName;

  const DeletePhoto({required this.photoId, required this.photoName});

  @override
  List<Object> get props => [photoId, photoName];
}

class KeepBothPhotos extends PhotoComparisonEvent {}

class DeleteBothPhotos extends PhotoComparisonEvent {}

// States
abstract class PhotoComparisonState extends Equatable {
  const PhotoComparisonState();

  @override
  List<Object> get props => [];
}

class PhotoComparisonInitial extends PhotoComparisonState {}

class PhotoComparisonLoading extends PhotoComparisonState {}

class PhotoComparisonLoaded extends PhotoComparisonState {
  final List<Photo> photos;

  const PhotoComparisonLoaded({required this.photos});

  @override
  List<Object> get props => [photos];
}

class PhotoComparisonActionInProgress extends PhotoComparisonState {}

class PhotoComparisonActionSuccess extends PhotoComparisonState {
  final String message;
  final List<Photo> photos;

  const PhotoComparisonActionSuccess({
    required this.message,
    required this.photos,
  });

  @override
  List<Object> get props => [message, photos];
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

  PhotoComparisonBloc({required this.photoUseCases})
    : super(PhotoComparisonInitial()) {
    on<LoadPhotos>(_onLoadPhotos);
    on<KeepPhoto>(_onKeepPhoto);
    on<DeletePhoto>(_onDeletePhoto);
    on<KeepBothPhotos>(_onKeepBothPhotos);
    on<DeleteBothPhotos>(_onDeleteBothPhotos);
  }

  Future<void> _onLoadPhotos(
    LoadPhotos event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    emit(PhotoComparisonLoading());

    final result = await photoUseCases.getPhotos();

    result.fold(
      (failure) => emit(PhotoComparisonError(failure.message)),
      (photos) => emit(PhotoComparisonLoaded(photos: photos)),
    );
  }

  Future<void> _onKeepPhoto(
    KeepPhoto event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    final currentState = state;
    if (currentState is PhotoComparisonLoaded) {
      emit(PhotoComparisonActionInProgress());

      final result = await photoUseCases.keepPhoto(event.photoId);

      result.fold(
        (failure) => emit(PhotoComparisonError(failure.message)),
        (_) => emit(
          PhotoComparisonActionSuccess(
            message: '${event.photoName} kept successfully',
            photos: currentState.photos,
          ),
        ),
      );
    }
  }

  Future<void> _onDeletePhoto(
    DeletePhoto event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    final currentState = state;
    if (currentState is PhotoComparisonLoaded) {
      emit(PhotoComparisonActionInProgress());

      final result = await photoUseCases.deletePhoto(event.photoId);

      result.fold(
        (failure) => emit(PhotoComparisonError(failure.message)),
        (_) => emit(
          PhotoComparisonActionSuccess(
            message: '${event.photoName} deleted successfully',
            photos: currentState.photos,
          ),
        ),
      );
    }
  }

  Future<void> _onKeepBothPhotos(
    KeepBothPhotos event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    final currentState = state;
    if (currentState is PhotoComparisonLoaded) {
      emit(PhotoComparisonActionInProgress());

      final result = await photoUseCases.keepBothPhotos();

      result.fold(
        (failure) => emit(PhotoComparisonError(failure.message)),
        (_) => emit(
          PhotoComparisonActionSuccess(
            message: 'Both photos kept successfully',
            photos: currentState.photos,
          ),
        ),
      );
    }
  }

  Future<void> _onDeleteBothPhotos(
    DeleteBothPhotos event,
    Emitter<PhotoComparisonState> emit,
  ) async {
    final currentState = state;
    if (currentState is PhotoComparisonLoaded) {
      emit(PhotoComparisonActionInProgress());

      final result = await photoUseCases.deleteBothPhotos();

      result.fold(
        (failure) => emit(PhotoComparisonError(failure.message)),
        (_) => emit(
          PhotoComparisonActionSuccess(
            message: 'Both photos deleted successfully',
            photos: currentState.photos,
          ),
        ),
      );
    }
  }
}
