import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/photo.dart';
import '../../domain/usecases/photo_usecases.dart';

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

  const PhotoSelectionLoaded({
    required this.allPhotos,
    this.selectedPhotos = const [],
  });

  @override
  List<Object> get props => [allPhotos, selectedPhotos];

  PhotoSelectionLoaded copyWith({
    List<Photo>? allPhotos,
    List<Photo>? selectedPhotos,
  }) {
    return PhotoSelectionLoaded(
      allPhotos: allPhotos ?? this.allPhotos,
      selectedPhotos: selectedPhotos ?? this.selectedPhotos,
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

class PhotoSelectionBloc
    extends Bloc<PhotoSelectionEvent, PhotoSelectionState> {
  final PhotoUseCases photoUseCases;

  PhotoSelectionBloc({required this.photoUseCases})
      : super(PhotoSelectionInitial()) {
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
    final result = await photoUseCases.getPhotosFromGallery();
    result.fold(
      (failure) => emit(PhotoSelectionError(failure.message)),
      (photos) => emit(PhotoSelectionLoaded(allPhotos: photos)),
    );
  }

  void _onTogglePhotoSelection(
    TogglePhotoSelection event,
    Emitter<PhotoSelectionState> emit,
  ) {
    if (state is PhotoSelectionLoaded) {
      final currentState = state as PhotoSelectionLoaded;
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
