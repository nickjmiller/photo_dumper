import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../domain/entities/photo.dart';
import '../bloc/photo_selection_bloc.dart';
import '../widgets/selectable_photo_card.dart';
import 'photo_comparison_page.dart';

class PhotoSelectionPage extends StatefulWidget {
  const PhotoSelectionPage({super.key});

  @override
  State<PhotoSelectionPage> createState() => _PhotoSelectionPageState();
}

class _PhotoSelectionPageState extends State<PhotoSelectionPage> {
  @override
  void initState() {
    super.initState();
    // Load photos when the page is initialized
    context.read<PhotoSelectionBloc>().add(LoadPhotos());
  }

  void _toggleSelection(photo) {
    context.read<PhotoSelectionBloc>().add(TogglePhotoSelection(photo: photo));
  }

  void _startComparison(List<Photo> selectedPhotos) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => PhotoComparisonPage(selectedPhotos: selectedPhotos),
          ),
        )
        .then((_) {
          if (!mounted) return;
          context.read<PhotoSelectionBloc>().add(LoadPhotos());
        });
  }

  Widget _buildAddPhotosCenteredButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No photos found or permission denied.',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<PhotoSelectionBloc>().add(LoadPhotos());
            },
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Add photos'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Select Photos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocListener<PhotoSelectionBloc, PhotoSelectionState>(
        listener: (context, state) {
          if (state is PhotoSelectionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            // Reset to initial state after showing error
            Future.delayed(const Duration(milliseconds: 100), () {
              if (context.mounted) {
                context.read<PhotoSelectionBloc>().add(ResetSelection());
              }
            });
          }
        },
        child: BlocBuilder<PhotoSelectionBloc, PhotoSelectionState>(
          builder: (context, state) {
            if (state is PhotoSelectionLoading ||
                state is PhotoSelectionInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PhotoSelectionLoaded) {
              if (state.allPhotos.isEmpty) {
                return _buildAddPhotosCenteredButton();
              }
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: state.allPhotos.length,
                itemBuilder: (context, index) {
                  final photo = state.allPhotos[index];
                  final isSelected = state.selectedPhotos.contains(photo);
                  final isLocked = state.lockedPhotoIds.contains(photo.id);
                  return SelectablePhotoCard(
                    key: Key('photo_thumbnail_${photo.id}'),
                    photo: photo,
                    isSelected: isSelected,
                    isLocked: isLocked,
                    onTap: () => _toggleSelection(photo),
                  );
                },
              );
            }
            if (state is PhotoSelectionPermissionError) {
              return _buildAddPhotosCenteredButton();
            }
            if (state is PhotoSelectionError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(state.message, textAlign: TextAlign.center),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.read<PhotoSelectionBloc>().add(LoadPhotos());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return const Center(
              child: Text('Something went wrong. Please restart the app.'),
            );
          },
        ),
      ),
      floatingActionButton: BlocBuilder<PhotoSelectionBloc, PhotoSelectionState>(
        builder: (context, state) {
          if (state is PhotoSelectionLoaded) {
            final showCompareButton = state.selectedPhotos.length >= 2;
            final showAddPhotosButton = state.hasLimitedAccess;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showAddPhotosButton)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: FloatingActionButton.extended(
                        onPressed: () async {
                          final bloc = context.read<PhotoSelectionBloc>();
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          try {
                            await PhotoManager.presentLimited();
                            if (!mounted) return;
                            bloc.add(LoadPhotos());
                          } catch (e) {
                            if (!mounted) return;
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error presenting limited photo picker: $e',
                                ),
                              ),
                            );
                          }
                        },
                        label: const Text('Add more photos'),
                        icon: const Icon(Icons.add_a_photo),
                        heroTag: 'add_photos',
                      ),
                    ),
                  if (showCompareButton)
                    FloatingActionButton.extended(
                      onPressed: () => _startComparison(state.selectedPhotos),
                      label: Text('Compare (${state.selectedPhotos.length})'),
                      icon: const Icon(Icons.compare_arrows),
                      heroTag: 'compare',
                    ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
