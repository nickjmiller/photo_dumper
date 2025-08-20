import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_constants.dart';
import 'core/di/dependency_injection.dart';
import 'core/theme/app_theme.dart';
import 'features/photo_comparison/presentation/bloc/photo_comparison_bloc.dart';
import 'features/photo_comparison/presentation/pages/photo_comparison_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const PhotoDumperApp());
}

class PhotoDumperApp extends StatelessWidget {
  const PhotoDumperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      theme: AppTheme.lightTheme,
      home: BlocProvider(
        create: (context) => PhotoComparisonBloc(photoUseCases: getIt()),
        child: const PhotoComparisonPage(),
      ),
    );
  }
}
