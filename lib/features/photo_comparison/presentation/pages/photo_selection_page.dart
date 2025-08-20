import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/dependency_injection.dart';
import '../bloc/photo_selection_bloc.dart';
import '../bloc/photo_comparison_bloc.dart';
import 'photo_comparison_page.dart';

class PhotoSelectionPage extends StatefulWidget {
  const PhotoSelectionPage({super.key});

  @override
  State<PhotoSelectionPage> createState() => _PhotoSelectionPageState();
}

class _PhotoSelectionPageState extends State<PhotoSelectionPage> {
  void _pickPhotosAndCompare() {
    context.read<PhotoSelectionBloc>().add(PickPhotosAndCompare());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Dumper'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocListener<PhotoSelectionBloc, PhotoSelectionState>(
        listener: (context, state) {
          if (state is ComparisonReady) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) =>
                      PhotoComparisonBloc(photoUseCases: getIt()),
                  child: PhotoComparisonPage(
                    selectedPhotos: state.selectedPhotos,
                  ),
                ),
              ),
            );
          } else if (state is PhotoSelectionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: BlocBuilder<PhotoSelectionBloc, PhotoSelectionState>(
          builder: (context, state) {
            if (state is PhotoSelectionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Photo Dumper',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select photos to compare and organize',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _pickPhotosAndCompare,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Select Photos'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
