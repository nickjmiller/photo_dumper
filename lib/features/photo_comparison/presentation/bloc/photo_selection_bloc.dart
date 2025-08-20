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
      if (photos.length >= 2) {
        // All picked photos are automatically selected for comparison
        emit(ComparisonReady(selectedPhotos: photos));
      } else {
        emit(const PhotoSelectionError('Please select at least 2 photos'));
      }
    });
  }
}
