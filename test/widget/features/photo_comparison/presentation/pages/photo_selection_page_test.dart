import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/bloc/photo_selection_bloc.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/pages/photo_selection_page.dart';
import 'package:photo_manager/photo_manager.dart';

class MockPhotoSelectionBloc
    extends MockBloc<PhotoSelectionEvent, PhotoSelectionState>
    implements PhotoSelectionBloc {}

void main() {
  group('PhotoSelectionPage', () {
    late PhotoSelectionBloc mockPhotoSelectionBloc;

    setUp(() {
      mockPhotoSelectionBloc = MockPhotoSelectionBloc();
    });

    testWidgets(
        'should display centered add photos button when permission is denied',
        (WidgetTester tester) async {
      whenListen(
        mockPhotoSelectionBloc,
        Stream.fromIterable([
          const PhotoSelectionPermissionError(PermissionState.denied),
        ]),
        initialState: const PhotoSelectionPermissionError(PermissionState.denied),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PhotoSelectionBloc>.value(
            value: mockPhotoSelectionBloc,
            child: const PhotoSelectionPage(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Add photos'), findsOneWidget);
    });

    testWidgets('should display centered add photos button when no photos are loaded',
        (WidgetTester tester) async {
      whenListen(
        mockPhotoSelectionBloc,
        Stream.fromIterable([
          const PhotoSelectionLoaded(allPhotos: []),
        ]),
        initialState: const PhotoSelectionLoaded(allPhotos: []),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PhotoSelectionBloc>.value(
            value: mockPhotoSelectionBloc,
            child: const PhotoSelectionPage(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Add photos'), findsOneWidget);
    });

    testWidgets(
        'should display add more photos button when hasLimitedAccess is true',
        (WidgetTester tester) async {
      whenListen(
        mockPhotoSelectionBloc,
        Stream.fromIterable([
          const PhotoSelectionLoaded(allPhotos: [], hasLimitedAccess: true),
        ]),
        initialState:
            const PhotoSelectionLoaded(allPhotos: [], hasLimitedAccess: true),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PhotoSelectionBloc>.value(
            value: mockPhotoSelectionBloc,
            child: const PhotoSelectionPage(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Add more photos'), findsOneWidget);
    });
  });
}
