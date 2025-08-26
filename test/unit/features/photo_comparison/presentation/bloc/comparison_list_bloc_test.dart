import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:photo_dumper/features/photo_comparison/domain/entities/comparison_session.dart';
import 'package:photo_dumper/features/photo_comparison/domain/usecases/comparison_usecases.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/bloc/comparison_list_bloc.dart';

import 'comparison_list_bloc_test.mocks.dart';

@GenerateMocks([ComparisonUseCases])
void main() {
  late MockComparisonUseCases mockUseCases;
  late ComparisonListBloc bloc;

  setUp(() {
    mockUseCases = MockComparisonUseCases();
    bloc = ComparisonListBloc(useCases: mockUseCases);
  });

  tearDown(() {
    bloc.close();
  });

  group('ComparisonListBloc', () {
    final tSession = ComparisonSession(
      id: '1',
      allPhotos: [],
      remainingPhotos: [],
      eliminatedPhotos: [],
      createdAt: DateTime.now(),
    );

    test('initial state is ComparisonListInitial', () {
      expect(bloc.state, equals(ComparisonListInitial()));
    });

    blocTest<ComparisonListBloc, ComparisonListState>(
      'emits [ComparisonListLoading, ComparisonListLoaded] when LoadComparisonSessions is added.',
      build: () {
        when(
          mockUseCases.getComparisonSessions(),
        ).thenAnswer((_) async => Right([tSession]));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadComparisonSessions()),
      expect: () => [isA<ComparisonListLoading>(), isA<ComparisonListLoaded>()],
      verify: (_) {
        verify(mockUseCases.getComparisonSessions());
      },
    );

    blocTest<ComparisonListBloc, ComparisonListState>(
      'emits [ComparisonListLoaded] with updated list when DeleteComparisonSession is added.',
      build: () {
        when(
          mockUseCases.deleteComparisonSession(any),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => ComparisonListLoaded([tSession]),
      act: (bloc) => bloc.add(DeleteComparisonSession(tSession)),
      expect: () => [ComparisonListLoaded([], lastDeletedSession: tSession)],
      verify: (_) {
        verify(mockUseCases.deleteComparisonSession(tSession.id));
      },
    );

    blocTest<ComparisonListBloc, ComparisonListState>(
      'emits [ComparisonListLoaded] with restored list when UndoDeleteComparisonSession is added.',
      build: () {
        when(
          mockUseCases.saveComparisonSession(any),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => ComparisonListLoaded([], lastDeletedSession: tSession),
      act: (bloc) => bloc.add(UndoDeleteComparisonSession()),
      expect: () => [
        ComparisonListLoaded([tSession], lastDeletedSession: null),
      ],
      verify: (_) {
        verify(mockUseCases.saveComparisonSession(tSession));
      },
    );
  });
}
