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

class PickPhotosAndCompare extends PhotoSelectionEvent {}

class ResetSelection extends PhotoSelectionEvent {}

// States
abstract class PhotoSelectionState extends Equatable {
  const PhotoSelectionState();

  @override
  List<Object> get props => [];
}

class PhotoSelectionInitial extends PhotoSelectionState {}

class PhotoSelectionLoading extends PhotoSelectionState {}

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
    on<PickPhotosAndCompare>(_onPickPhotosAndCompare);
    on<ResetSelection>(_onResetSelection);
  }

  Future<void> _onPickPhotosAndCompare(
    PickPhotosAndCompare event,
    Emitter<PhotoSelectionState> emit,
  ) async {
    emit(PhotoSelectionLoading());

    final result = await photoUseCases.getLibraryPhotos();

    result.fold((failure) => emit(PhotoSelectionError(failure.message)), (
      photos,
    ) {
      if (photos.isEmpty) {
        // No photos selected or invalid selection (less than 2 photos)
        emit(const PhotoSelectionError('Please select at least 2 photos'));
      } else if (photos.length >= 2) {
        // Valid selection - proceed to comparison
        emit(ComparisonReady(selectedPhotos: photos));
      } else {
        // This should not happen due to repository logic, but handle just in case
        emit(const PhotoSelectionError('Please select at least 2 photos'));
      }
    });
  }

  void _onResetSelection(
    ResetSelection event,
    Emitter<PhotoSelectionState> emit,
  ) {
    emit(PhotoSelectionInitial());
  }
}
