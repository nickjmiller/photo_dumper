import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_constants.dart';
import 'core/di/dependency_injection.dart';
import 'core/theme/app_theme.dart';
import 'features/photo_comparison/presentation/bloc/photo_comparison_bloc.dart';
import 'features/photo_comparison/presentation/bloc/photo_selection_bloc.dart';
import 'features/photo_comparison/presentation/pages/photo_comparison_page.dart';
import 'features/photo_comparison/presentation/pages/photo_selection_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const PhotoDumperApp());
}

class PhotoDumperApp extends StatelessWidget {
  const PhotoDumperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PhotoSelectionBloc(photoUseCases: getIt()),
        ),
        BlocProvider(
          create: (context) => PhotoComparisonBloc(photoUseCases: getIt()),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appTitle,
        theme: AppTheme.lightTheme,
        home: const PhotoSelectionPage(),
        routes: {
          PhotoComparisonPage.routeName: (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            final photos = args['photos'];

            // The PhotoComparisonBloc is provided by MultiBlocProvider, so we just
            // need to build the page. The page's initState will handle loading
            // the photos into the BLoC.
            return PhotoComparisonPage(selectedPhotos: photos);
          }
        },
      ),
    );
  }
}
