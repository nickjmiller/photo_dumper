import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/pages/photo_selection_page.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/bloc/photo_selection_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:photo_dumper/features/photo_comparison/domain/entities/photo.dart';
import 'dart:io';
import 'package:photo_dumper/features/photo_comparison/domain/usecases/photo_usecases.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/bloc/photo_comparison_bloc.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/pages/photo_comparison_page.dart';
import 'package:photo_dumper/core/services/platform_service.dart';
import 'package:photo_dumper/features/photo_comparison/domain/services/photo_manager_service.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/widgets/photo_card.dart';

import 'photo_comparison_flow_test.mocks.dart';

@GenerateMocks([PhotoUseCases, PhotoManagerService, PlatformService])
void main() {
  late MockPhotoUseCases mockPhotoUseCases;
  late MockPhotoManagerService mockPhotoManagerService;
  late MockPlatformService mockPlatformService;

  final testPhotos = List.generate(
    3, // Use 3 photos for a 2-round tournament
    (i) => Photo(
      id: 'id_$i',
      name: 'photo_$i.jpg',
      createdAt: DateTime.now(),
      file: File('test/path/photo_$i.jpg'),
    ),
  );

  setUp(() {
    mockPhotoUseCases = MockPhotoUseCases();
    mockPhotoManagerService = MockPhotoManagerService();
    mockPlatformService = MockPlatformService();

    // Stub the successful photo fetch on the use cases
    when(mockPhotoUseCases.getPhotosFromGallery())
        .thenAnswer((_) async => Right(testPhotos));

    // Stub the services needed by PhotoComparisonBloc
    when(mockPlatformService.isAndroid).thenReturn(false);
    when(mockPhotoManagerService.deleteWithIds(any))
        .thenAnswer((_) async => []);
  });

  testWidgets('Full photo comparison and deletion flow', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<PhotoSelectionBloc>(
            create: (_) => PhotoSelectionBloc(photoUseCases: mockPhotoUseCases),
          ),
          BlocProvider<PhotoComparisonBloc>(
            create: (_) => PhotoComparisonBloc(
              photoUseCases: mockPhotoUseCases,
              photoManagerService: mockPhotoManagerService,
              platformService: mockPlatformService,
            ),
          ),
        ],
        child: MaterialApp(
          home: const PhotoSelectionPage(),
          routes: {
            PhotoComparisonPage.routeName: (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
              final photos = args['photos'] as List<Photo>;

              context.read<PhotoComparisonBloc>().add(LoadSelectedPhotos(photos: photos));

              return PhotoComparisonPage(selectedPhotos: photos);
            }
          },
        ),
      ),
    );

    // 1. Wait for photos to load and verify they are displayed
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byKey(const Key('photo_thumbnail_id_0')), findsOneWidget);

    // 2. Select all 3 photos
    await tester.tap(find.byKey(const Key('photo_thumbnail_id_0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('photo_thumbnail_id_1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('photo_thumbnail_id_2')));
    await tester.pump();

    // Verify selection count is updated on the button
    expect(find.text('Compare (3)'), findsOneWidget);

    // 3. Start comparison
    await tester.tap(find.text('Compare (3)'));
    await tester.pumpAndSettle();

    // 4. We are now on the PhotoComparisonPage. Verify it.
    expect(find.byType(PhotoComparisonPage), findsOneWidget);
    expect(find.byType(PhotoCard), findsNWidgets(2));

    // 5. Complete the tournament. With 3 photos, this takes 2 rounds.
    // Round 1: Tap the first PhotoCard to select it as the winner.
    await tester.tap(find.byType(PhotoCard).first);
    await tester.pumpAndSettle();

    // Round 2: A new pair is shown. Tap the first PhotoCard again.
    await tester.tap(find.byType(PhotoCard).first);
    await tester.pumpAndSettle();

    // 6. Deletion confirmation screen should be visible
    expect(find.text('Review Photos for Deletion'), findsOneWidget);
    expect(find.text('Confirm Delete'), findsOneWidget);

    // 7. Confirm deletion
    await tester.tap(find.text('Confirm Delete'));
    await tester.pumpAndSettle();

    // 8. Verify completion screen
    expect(find.text('Comparison Complete!'), findsOneWidget);

    // 9. Verify that the delete method was called on the service
    final verificationResult = verify(mockPhotoManagerService.deleteWithIds(captureAny));
    verificationResult.called(1);
    final capturedIds = verificationResult.captured.single as List<String>;
    expect(capturedIds.length, 2);
  });

  testWidgets('Full photo comparison flow with skipping all pairs', (WidgetTester tester) async {
    final twoPhotos = testPhotos.sublist(0, 2);
    when(mockPhotoUseCases.getPhotosFromGallery())
        .thenAnswer((_) async => Right(twoPhotos));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<PhotoSelectionBloc>(
            create: (_) => PhotoSelectionBloc(photoUseCases: mockPhotoUseCases),
          ),
          BlocProvider<PhotoComparisonBloc>(
            create: (_) => PhotoComparisonBloc(
              photoUseCases: mockPhotoUseCases,
              photoManagerService: mockPhotoManagerService,
              platformService: mockPlatformService,
            ),
          ),
        ],
        child: MaterialApp(
          home: const PhotoSelectionPage(),
          routes: {
            PhotoComparisonPage.routeName: (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
              final photos = args['photos'] as List<Photo>;

              context.read<PhotoComparisonBloc>().add(LoadSelectedPhotos(photos: photos));

              return PhotoComparisonPage(selectedPhotos: photos);
            }
          },
        ),
      ),
    );

    // 1. Wait for photos to load
    await tester.pumpAndSettle();

    // 2. Select both photos
    await tester.tap(find.byKey(const Key('photo_thumbnail_id_0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('photo_thumbnail_id_1')));
    await tester.pump();

    // 3. Start comparison
    await tester.tap(find.text('Compare (2)'));
    await tester.pumpAndSettle();

    // 4. We are on the comparison page. Skip the pair.
    expect(find.text('Skip This Pair'), findsOneWidget);
    await tester.tap(find.text('Skip This Pair'));
    await tester.pumpAndSettle();

    // 5. The "All Pairs Skipped" dialog should appear
    expect(find.text('Keep all remaining photos?'), findsOneWidget);
    expect(find.text('Yes, Keep Them'), findsOneWidget);

    // 6. Tap "Yes, Keep Them"
    await tester.tap(find.text('Yes, Keep Them'));
    await tester.pumpAndSettle();

    // 7. Deletion confirmation screen should be visible
    expect(find.text('Review Photos for Deletion'), findsOneWidget);
    expect(find.textContaining('0 photos will be deleted'), findsOneWidget);
    expect(find.textContaining('2 photo will be kept'), findsOneWidget);

    // 8. Confirm (a no-op deletion)
    await tester.tap(find.text('Confirm Delete'));
    await tester.pumpAndSettle();

    // 9. Verify completion screen
    expect(find.text('Comparison Complete!'), findsOneWidget);
    expect(find.textContaining('2 photo kept'), findsOneWidget);

    // 10. Verify that delete was NOT called
    verifyNever(mockPhotoManagerService.deleteWithIds(any));
  });
}
