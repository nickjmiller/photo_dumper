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
import 'package:photo_dumper/features/photo_comparison/presentation/bloc/comparison_list_bloc.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/pages/comparison_list_page.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/widgets/photo_card.dart';
import 'package:photo_dumper/features/photo_comparison/domain/usecases/comparison_usecases.dart';
import 'package:photo_dumper/core/services/permission_service.dart';
import 'package:photo_manager/photo_manager.dart';

import 'photo_comparison_flow_test.mocks.dart';

@GenerateMocks([
  PhotoUseCases,
  PhotoManagerService,
  PlatformService,
  ComparisonUseCases,
  PermissionService,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockPhotoUseCases mockPhotoUseCases;
  late MockComparisonUseCases mockComparisonUseCases;
  late MockPhotoManagerService mockPhotoManagerService;
  late MockPlatformService mockPlatformService;
  late MockPermissionService mockPermissionService;

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
    mockComparisonUseCases = MockComparisonUseCases();
    mockPhotoManagerService = MockPhotoManagerService();
    mockPlatformService = MockPlatformService();
    mockPermissionService = MockPermissionService();

    // Stub the successful photo fetch on the use cases
    when(
      mockPhotoUseCases.getPhotosFromGallery(),
    ).thenAnswer((_) async => Right(testPhotos));
    when(
      mockComparisonUseCases.getAllPhotoIdsInUse(),
    ).thenAnswer((_) async => const Right([]));

    // Stub the services needed by PhotoComparisonBloc
    when(mockPlatformService.isAndroid).thenReturn(false);
    when(mockPhotoManagerService.deleteWithIds(any)).thenAnswer(
      (invocation) async => invocation.positionalArguments[0] as List<String>,
    );

    // TODO: Integration tests are disabled because the UI flow has changed significantly
    when(
      mockComparisonUseCases.getComparisonSessions(),
    ).thenAnswer((_) async => const Right([]));
  });

  testWidgets('Full photo comparison and deletion flow', (
    WidgetTester tester,
  ) async {
    // Stub getComparisonSessions for this test to ensure a clean slate
    when(
      mockComparisonUseCases.getComparisonSessions(),
    ).thenAnswer((_) async => const Right([]));

    when(
      mockPermissionService.requestPhotoPermission(),
    ).thenAnswer((_) async => PermissionState.authorized);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<PhotoSelectionBloc>(
            create: (_) => PhotoSelectionBloc(
              photoUseCases: mockPhotoUseCases,
              comparisonUseCases: mockComparisonUseCases,
              permissionService: mockPermissionService,
            ),
          ),
          BlocProvider<PhotoComparisonBloc>(
            create: (_) => PhotoComparisonBloc(
              photoUseCases: mockPhotoUseCases,
              comparisonUseCases: mockComparisonUseCases,
              photoManagerService: mockPhotoManagerService,
              platformService: mockPlatformService,
            ),
          ),
          BlocProvider<ComparisonListBloc>(
            create: (_) =>
                ComparisonListBloc(useCases: mockComparisonUseCases)
                  ..add(LoadComparisonSessions()),
          ),
        ],
        child: const MaterialApp(
          home: ComparisonListPage(), // Start at the new home page
        ),
      ),
    );

    // 1. Start on the ComparisonListPage, should be empty
    await tester.pumpAndSettle();
    expect(find.text('No saved comparisons. Start a new one!'), findsOneWidget);

    // 2. Tap the 'New Comparison' FAB to navigate to PhotoSelectionPage
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoSelectionPage), findsOneWidget);

    // 3. Wait for photos to load and verify they are displayed
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byKey(const Key('photo_thumbnail_id_0')), findsOneWidget);

    // 4. Select all 3 photos
    await tester.tap(find.byKey(const Key('photo_thumbnail_id_0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('photo_thumbnail_id_1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('photo_thumbnail_id_2')));
    await tester.pump();

    // Verify selection count is updated on the button
    expect(find.text('Compare (3)'), findsOneWidget);

    // 5. Start comparison
    await tester.tap(find.text('Compare (3)'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 6. We are now on the PhotoComparisonPage. Verify it.
    expect(find.byType(PhotoComparisonPage), findsOneWidget);
    expect(find.byType(PhotoCard), findsNWidgets(2));

    // 7. Complete the tournament. With 3 photos, this takes 2 rounds.
    // Round 1: Tap the first PhotoCard to select it as the winner.
    await tester.tap(find.byType(PhotoCard).first);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Round 2: A new pair is shown. Tap the first PhotoCard again.
    await tester.tap(find.byType(PhotoCard).first);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 8. Deletion confirmation screen should be visible
    expect(find.text('Review Photos for Deletion'), findsOneWidget);
    expect(find.text('Confirm Delete'), findsOneWidget);

    // 9. Confirm deletion
    await tester.tap(find.text('Confirm Delete'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 10. Verify completion screen
    expect(find.text('Comparison Complete!'), findsOneWidget);

    // 11. Verify that the delete method was called on the service
    final verificationResult = verify(
      mockPhotoManagerService.deleteWithIds(captureAny),
    );
    verificationResult.called(1);
    final capturedIds = verificationResult.captured.single as List<String>;
    expect(capturedIds.length, 2);
  });

  testWidgets('Discarding a comparison navigates back to the home page',
      (WidgetTester tester) async {
    // Stub getComparisonSessions for this test to ensure a clean slate
    when(
      mockComparisonUseCases.getComparisonSessions(),
    ).thenAnswer((_) async => const Right([]));
    when(
      mockPermissionService.requestPhotoPermission(),
    ).thenAnswer((_) async => PermissionState.authorized);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<PhotoSelectionBloc>(
            create: (_) => PhotoSelectionBloc(
              photoUseCases: mockPhotoUseCases,
              comparisonUseCases: mockComparisonUseCases,
              permissionService: mockPermissionService,
            ),
          ),
          BlocProvider<PhotoComparisonBloc>(
            create: (_) => PhotoComparisonBloc(
              photoUseCases: mockPhotoUseCases,
              comparisonUseCases: mockComparisonUseCases,
              photoManagerService: mockPhotoManagerService,
              platformService: mockPlatformService,
            ),
          ),
          BlocProvider<ComparisonListBloc>(
            create: (_) =>
                ComparisonListBloc(useCases: mockComparisonUseCases)
                  ..add(LoadComparisonSessions()),
          ),
        ],
        child: const MaterialApp(
          home: ComparisonListPage(),
        ),
      ),
    );

    // 1. Start on the ComparisonListPage
    await tester.pumpAndSettle();
    expect(find.byType(ComparisonListPage), findsOneWidget);

    // 2. Tap the 'New Comparison' FAB to navigate to PhotoSelectionPage
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoSelectionPage), findsOneWidget);

    // 3. Wait for photos to load
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);

    // 4. Select 2 photos
    await tester.tap(find.byKey(const Key('photo_thumbnail_id_0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('photo_thumbnail_id_1')));
    await tester.pump();

    // 5. Start comparison
    await tester.tap(find.text('Compare (2)'));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoComparisonPage), findsOneWidget);

    // 6. Tap the close button to show the exit dialog
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    // 7. Tap the 'Discard' button
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    // 8. Verify that we are back on the ComparisonListPage
    expect(find.byType(ComparisonListPage), findsOneWidget);
    expect(find.text('No saved comparisons. Start a new one!'), findsOneWidget);

    // 9. Verify that the PhotoComparisonPage is gone
    expect(find.byType(PhotoComparisonPage), findsNothing);
  });
}
