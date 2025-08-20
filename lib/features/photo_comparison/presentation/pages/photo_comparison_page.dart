import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/photo_comparison_bloc.dart';
import '../widgets/photo_card.dart';
import '../widgets/action_buttons.dart';
import '../../domain/entities/photo.dart';

class PhotoComparisonPage extends StatefulWidget {
  final List<Photo> selectedPhotos;

  const PhotoComparisonPage({super.key, required this.selectedPhotos});

  @override
  State<PhotoComparisonPage> createState() => _PhotoComparisonPageState();
}

class _PhotoComparisonPageState extends State<PhotoComparisonPage>
    with TickerProviderStateMixin {
  late AnimationController _photo1Controller;
  late AnimationController _photo2Controller;
  late Animation<Offset> _photo1Animation;
  late Animation<Offset> _photo2Animation;

  bool _isDraggingPhoto1 = false;
  bool _isDraggingPhoto2 = false;
  double _photo1DragOffset = 0.0;
  double _photo2DragOffset = 0.0;
  double _photo1TotalDrag = 0.0;
  double _photo2TotalDrag = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Initialize the bloc with the selected photos directly
    context.read<PhotoComparisonBloc>().add(
      InitializeWithPhotos(photos: widget.selectedPhotos),
    );
  }

  void _initializeAnimations() {
    _photo1Controller = AnimationController(
      duration: AppConstants.photoAnimationDuration,
      vsync: this,
    );
    _photo2Controller = AnimationController(
      duration: AppConstants.photoAnimationDuration,
      vsync: this,
    );

    _photo1Animation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _photo1Controller, curve: Curves.easeOut),
        );

    _photo2Animation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _photo2Controller, curve: Curves.easeOut),
        );
  }

  @override
  void dispose() {
    _photo1Controller.dispose();
    _photo2Controller.dispose();
    super.dispose();
  }

  void _showConfirmationDialog(String photoName, bool isKeep) {
    final otherPhotoName = photoName == AppConstants.photo1Name
        ? AppConstants.photo2Name
        : AppConstants.photo1Name;
    final title = isKeep ? 'Keep Photo' : 'Delete Photo';
    final message = isKeep
        ? 'Are you sure you want to keep $photoName and delete $otherPhotoName?'
        : 'Are you sure you want to delete $photoName?';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetPhotoPosition(photoName);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmAction(photoName, isKeep);
              },
              style: FilledButton.styleFrom(
                backgroundColor: isKeep
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
              child: Text(isKeep ? 'Keep' : 'Delete'),
            ),
          ],
        );
      },
    );
  }

  void _resetPhotoPosition(String photoName) {
    if (photoName == AppConstants.photo1Name) {
      _photo1Controller.reverse();
    } else {
      _photo2Controller.reverse();
    }
  }

  void _confirmAction(String photoName, bool isKeep) {
    final photoId = photoName == AppConstants.photo1Name ? '1' : '2';

    if (isKeep) {
      context.read<PhotoComparisonBloc>().add(
        KeepPhoto(photoId: photoId, photoName: photoName),
      );
    } else {
      context.read<PhotoComparisonBloc>().add(
        DeletePhoto(photoId: photoId, photoName: photoName),
      );
    }

    _resetPhotoPosition(photoName);
  }

  void _handlePhoto1DragStart() {
    _isDraggingPhoto1 = true;
    _photo1TotalDrag = 0.0;
  }

  void _handlePhoto1DragUpdate(DragUpdateDetails details) {
    if (_isDraggingPhoto1) {
      setState(() {
        _photo1TotalDrag += details.delta.dx;
        _photo1DragOffset = _photo1TotalDrag;
      });
    }
  }

  void _handlePhoto1DragEnd(DragEndDetails details) {
    _isDraggingPhoto1 = false;
    final velocity = details.primaryVelocity ?? 0.0;
    final velocityThreshold = 100.0;

    if (velocity > velocityThreshold) {
      _photo1Animation =
          Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(1.0, 0.0),
          ).animate(
            CurvedAnimation(parent: _photo1Controller, curve: Curves.easeOut),
          );
      _photo1Controller.forward();
      _showConfirmationDialog(AppConstants.photo1Name, true);
    } else if (velocity < -velocityThreshold) {
      _photo1Animation =
          Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-1.0, 0.0),
          ).animate(
            CurvedAnimation(parent: _photo1Controller, curve: Curves.easeOut),
          );
      _photo1Controller.forward();
      _showConfirmationDialog(AppConstants.photo1Name, false);
    }
    setState(() {
      _photo1DragOffset = 0.0;
      _photo1TotalDrag = 0.0;
    });
  }

  void _handlePhoto2DragStart() {
    _isDraggingPhoto2 = true;
    _photo2TotalDrag = 0.0;
  }

  void _handlePhoto2DragUpdate(DragUpdateDetails details) {
    if (_isDraggingPhoto2) {
      setState(() {
        _photo2TotalDrag += details.delta.dx;
        _photo2DragOffset = _photo2TotalDrag;
      });
    }
  }

  void _handlePhoto2DragEnd(DragEndDetails details) {
    _isDraggingPhoto2 = false;
    final velocity = details.primaryVelocity ?? 0.0;
    final velocityThreshold = 100.0;

    if (velocity > velocityThreshold) {
      _photo2Animation =
          Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(1.0, 0.0),
          ).animate(
            CurvedAnimation(parent: _photo2Controller, curve: Curves.easeOut),
          );
      _photo2Controller.forward();
      _showConfirmationDialog(AppConstants.photo2Name, true);
    } else if (velocity < -velocityThreshold) {
      _photo2Animation =
          Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-1.0, 0.0),
          ).animate(
            CurvedAnimation(parent: _photo2Controller, curve: Curves.easeOut),
          );
      _photo2Controller.forward();
      _showConfirmationDialog(AppConstants.photo2Name, false);
    }
    setState(() {
      _photo2DragOffset = 0.0;
      _photo2TotalDrag = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.photoComparisonTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocListener<PhotoComparisonBloc, PhotoComparisonState>(
        listener: (context, state) {
          if (state is PhotoComparisonActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: AppConstants.snackbarDuration,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          } else if (state is PhotoComparisonError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: AppConstants.snackbarDuration,
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: BlocBuilder<PhotoComparisonBloc, PhotoComparisonState>(
          builder: (context, state) {
            if (state is PhotoComparisonLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          flex: 1,
                          child: PhotoCard(
                            photoName: AppConstants.photo1Name,
                            animation: _photo1Animation,
                            dragOffset: _photo1DragOffset,
                            onHorizontalDragStart: (_) =>
                                _handlePhoto1DragStart(),
                            onHorizontalDragUpdate: _handlePhoto1DragUpdate,
                            onHorizontalDragEnd: _handlePhoto1DragEnd,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'VS',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: PhotoCard(
                            photoName: AppConstants.photo2Name,
                            animation: _photo2Animation,
                            dragOffset: _photo2DragOffset,
                            onHorizontalDragStart: (_) =>
                                _handlePhoto2DragStart(),
                            onHorizontalDragUpdate: _handlePhoto2DragUpdate,
                            onHorizontalDragEnd: _handlePhoto2DragEnd,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ActionButtons(
                    onKeepBoth: () {
                      context.read<PhotoComparisonBloc>().add(KeepBothPhotos());
                    },
                    onDiscardBoth: () {
                      context.read<PhotoComparisonBloc>().add(
                        DeleteBothPhotos(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
