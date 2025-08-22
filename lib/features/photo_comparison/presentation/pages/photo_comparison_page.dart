import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/dependency_injection.dart';
import '../bloc/photo_comparison_bloc.dart';
import '../bloc/photo_selection_bloc.dart';
import '../widgets/all_pairs_skipped_dialog.dart';
import '../widgets/photo_card.dart';
import '../../domain/entities/comparison_session.dart';
import '../../domain/entities/photo.dart';
import 'photo_selection_page.dart';

class PhotoComparisonPage extends StatefulWidget {
  static const routeName = '/photo-comparison';
  final List<Photo>? selectedPhotos;
  final ComparisonSession? sessionToResume;

  const PhotoComparisonPage({
    super.key,
    this.selectedPhotos,
    this.sessionToResume,
  }) : assert(selectedPhotos != null || sessionToResume != null);

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

  Photo? _currentPhoto1;
  Photo? _currentPhoto2;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.sessionToResume != null) {
      context.read<PhotoComparisonBloc>().add(
        ResumeComparison(session: widget.sessionToResume!),
      );
    } else {
      context.read<PhotoComparisonBloc>().add(
        LoadSelectedPhotos(photos: widget.selectedPhotos!),
      );
    }
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

    _resetAnimations();
  }

  void _resetAnimations() {
    _photo1Controller.reset();
    _photo2Controller.reset();

    _photo1Animation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _photo1Controller, curve: Curves.easeOut),
        );

    _photo2Animation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _photo2Controller, curve: Curves.easeOut),
        );
  }

  void _resetDragState() {
    _photo1DragOffset = 0.0;
    _photo2DragOffset = 0.0;
    _photo1TotalDrag = 0.0;
    _photo2TotalDrag = 0.0;
    _isDraggingPhoto1 = false;
    _isDraggingPhoto2 = false;
  }

  @override
  void dispose() {
    _photo1Controller.dispose();
    _photo2Controller.dispose();
    super.dispose();
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

    if (_currentPhoto1 != null && _currentPhoto2 != null) {
      if (velocity > velocityThreshold) {
        // Swipe right - choose left photo
        _photo1Animation =
            Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(1.0, 0.0),
            ).animate(
              CurvedAnimation(parent: _photo1Controller, curve: Curves.easeOut),
            );
        _photo1Controller.forward();
        _selectWinner(_currentPhoto1!, _currentPhoto2!);
      } else if (velocity < -velocityThreshold) {
        // Swipe left - choose right photo
        _photo1Animation =
            Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-1.0, 0.0),
            ).animate(
              CurvedAnimation(parent: _photo1Controller, curve: Curves.easeOut),
            );
        _photo1Controller.forward();
        _selectWinner(_currentPhoto2!, _currentPhoto1!);
      }
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

    if (_currentPhoto1 != null && _currentPhoto2 != null) {
      if (velocity > velocityThreshold) {
        // Swipe right - choose right photo
        _photo2Animation =
            Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(1.0, 0.0),
            ).animate(
              CurvedAnimation(parent: _photo2Controller, curve: Curves.easeOut),
            );
        _photo2Controller.forward();
        _selectWinner(_currentPhoto2!, _currentPhoto1!);
      } else if (velocity < -velocityThreshold) {
        // Swipe left - choose left photo
        _photo2Animation =
            Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-1.0, 0.0),
            ).animate(
              CurvedAnimation(parent: _photo2Controller, curve: Curves.easeOut),
            );
        _photo2Controller.forward();
        _selectWinner(_currentPhoto1!, _currentPhoto2!);
      }
    }

    setState(() {
      _photo2DragOffset = 0.0;
      _photo2TotalDrag = 0.0;
    });
  }

  void _selectWinner(Photo winner, Photo loser) {
    context.read<PhotoComparisonBloc>().add(
      SelectWinner(winner: winner, loser: loser),
    );
  }

  void _skipPair() {
    if (_currentPhoto1 != null && _currentPhoto2 != null) {
      context.read<PhotoComparisonBloc>().add(
        SkipPair(photo1: _currentPhoto1!, photo2: _currentPhoto2!),
      );
    }
  }

  void _restartComparison() {
    context.read<PhotoComparisonBloc>().add(RestartComparison());
  }

  void _confirmDeletion() {
    context.read<PhotoComparisonBloc>().add(ConfirmDeletion());
  }

  void _cancelComparison() {
    // Clear all photo state from memory
    context.read<PhotoComparisonBloc>().add(CancelComparison());

    // Navigate back to photo selection page and clear all routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => PhotoSelectionBloc(
            photoUseCases: getIt(),
            comparisonUseCases: getIt(),
            permissionService: getIt(),
          ),
          child: const PhotoSelectionPage(),
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _showExitDialog() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exit Comparison'),
        content: const Text('Do you want to save your progress?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _cancelComparison();
            },
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Dismiss dialog
              context.read<PhotoComparisonBloc>().add(PauseComparison());
            },
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.photoComparisonTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _showExitDialog,
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
          ),
        ],
      ),
      body: BlocListener<PhotoComparisonBloc, PhotoComparisonState>(
        listener: (context, state) {
          if (state is PhotoComparisonPaused) {
            Navigator.of(context).pop();
            return;
          }
          if (state is PhotoDeletionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Unable to delete the photos, please grant access to delete the photos when prompted.',
                ),
                duration: AppConstants.snackbarDuration,
                backgroundColor: Theme.of(context).colorScheme.error,
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
          if (state is AllPairsSkipped) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => BlocProvider.value(
                value: context.read<PhotoComparisonBloc>(),
                child: AllPairsSkippedDialog(
                  remainingPhotos: state.remainingPhotos,
                ),
              ),
            );
          }
        },
        child: BlocBuilder<PhotoComparisonBloc, PhotoComparisonState>(
          builder: (context, state) {
            if (state is PhotoComparisonLoading ||
                state is PhotoComparisonPaused) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TournamentInProgress) {
              final currentPhoto1 = state.currentPhoto1;
              final currentPhoto2 = state.currentPhoto2;
              final currentComparison = state.currentComparison;
              final totalComparisons = state.totalComparisons;
              final remainingPhotos = state.remainingPhotos;
              final eliminatedPhotos = state.eliminatedPhotos;

              // Reset animations and drag state when new photos are loaded
              if (_currentPhoto1 != currentPhoto1 ||
                  _currentPhoto2 != currentPhoto2) {
                _resetAnimations();
                _resetDragState();
              }

              _currentPhoto1 = currentPhoto1;
              _currentPhoto2 = currentPhoto2;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Round indicator and progress
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${remainingPhotos.length} photos remaining • ${eliminatedPhotos.length} queued for deletion',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Progress indicator
                    LinearProgressIndicator(
                      value: totalComparisons > 0
                          ? currentComparison / totalComparisons
                          : 0.0,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Photos comparison area
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            flex: 1,
                            child: PhotoCard(
                              key: Key(
                                'comparison_photo_1_${currentPhoto1.id}',
                              ),
                              photo: currentPhoto1,
                              animation: _photo1Animation,
                              dragOffset: _photo1DragOffset,
                              onHorizontalDragStart: (_) =>
                                  _handlePhoto1DragStart(),
                              onHorizontalDragUpdate: _handlePhoto1DragUpdate,
                              onHorizontalDragEnd: _handlePhoto1DragEnd,
                              onTap: () =>
                                  _selectWinner(currentPhoto1, currentPhoto2),
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
                                ).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'VS',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: PhotoCard(
                              key: Key(
                                'comparison_photo_2_${currentPhoto2.id}',
                              ),
                              photo: currentPhoto2,
                              animation: _photo2Animation,
                              dragOffset: _photo2DragOffset,
                              onHorizontalDragStart: (_) =>
                                  _handlePhoto2DragStart(),
                              onHorizontalDragUpdate: _handlePhoto2DragUpdate,
                              onHorizontalDragEnd: _handlePhoto2DragEnd,
                              onTap: () =>
                                  _selectWinner(currentPhoto2, currentPhoto1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _skipPair,
                          child: const Text('Skip This Pair'),
                        ),
                        ElevatedButton(
                          onPressed: _restartComparison,
                          child: const Text('Restart'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            if (state is DeletionConfirmation) {
              return _buildDeletionConfirmationScreen(
                state.eliminatedPhotos,
                state.winner,
              );
            }

            if (state is PhotoDeletionFailure) {
              return _buildDeletionConfirmationScreen(
                state.eliminatedPhotos,
                state.winner,
              );
            }

            if (state is ComparisonComplete) {
              return _buildCompletionScreen(state);
            }

            return const Center(
              child: Text('Something went wrong. Please try again.'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeletionConfirmationScreen(
    List<Photo> eliminatedPhotos,
    List<Photo> winner,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.warning_amber_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Review Photos for Deletion',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${eliminatedPhotos.length} photos will be deleted\n${winner.length} photo will be kept',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          Expanded(
            child: Column(
              children: [
                Text(
                  'Photos to be deleted:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: eliminatedPhotos.length,
                    itemBuilder: (context, index) {
                      final photo = eliminatedPhotos[index];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.error,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(photo.file!, fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.read<PhotoComparisonBloc>().add(
                      RestartComparison(),
                    );
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _confirmDeletion,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Confirm Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen(ComparisonComplete state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Comparison Complete!',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${state.winner.length} photo kept',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: state.winner.length,
              itemBuilder: (context, index) {
                final photo = state.winner[index];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(photo.file!, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              // Navigate back to photo selection page
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
