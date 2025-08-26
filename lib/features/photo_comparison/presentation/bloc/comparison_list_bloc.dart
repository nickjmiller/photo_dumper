import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/comparison_session.dart';
import '../../domain/usecases/comparison_usecases.dart';

// --- EVENTS ---
abstract class ComparisonListEvent extends Equatable {
  const ComparisonListEvent();
  @override
  List<Object> get props => [];
}

class LoadComparisonSessions extends ComparisonListEvent {}

class DeleteComparisonSession extends ComparisonListEvent {
  final ComparisonSession session;
  const DeleteComparisonSession(this.session);
  @override
  List<Object> get props => [session];
}

class UndoDeleteComparisonSession extends ComparisonListEvent {}

// --- STATES ---
abstract class ComparisonListState extends Equatable {
  const ComparisonListState();
  @override
  List<Object> get props => [];
}

class ComparisonListInitial extends ComparisonListState {}

class ComparisonListLoading extends ComparisonListState {}

class ComparisonListLoaded extends ComparisonListState {
  final List<ComparisonSession> sessions;
  final ComparisonSession? lastDeletedSession;
  const ComparisonListLoaded(this.sessions, {this.lastDeletedSession});
  @override
  List<Object> get props =>
      [sessions, if (lastDeletedSession != null) lastDeletedSession!];

  ComparisonListLoaded copyWith({
    List<ComparisonSession>? sessions,
    ComparisonSession? lastDeletedSession,
  }) {
    return ComparisonListLoaded(
      sessions ?? this.sessions,
      lastDeletedSession: lastDeletedSession ?? this.lastDeletedSession,
    );
  }
}

class ComparisonListError extends ComparisonListState {
  final String message;
  const ComparisonListError(this.message);
  @override
  List<Object> get props => [message];
}

// --- BLOC ---
class ComparisonListBloc
    extends Bloc<ComparisonListEvent, ComparisonListState> {
  final ComparisonUseCases useCases;

  ComparisonListBloc({required this.useCases}) : super(ComparisonListInitial()) {
    on<LoadComparisonSessions>(_onLoadComparisonSessions);
    on<DeleteComparisonSession>(_onDeleteComparisonSession);
    on<UndoDeleteComparisonSession>(_onUndoDeleteComparisonSession);
  }

  Future<void> _onLoadComparisonSessions(
    LoadComparisonSessions event,
    Emitter<ComparisonListState> emit,
  ) async {
    emit(ComparisonListLoading());
    final failureOrSessions = await useCases.getComparisonSessions();
    emit(
      failureOrSessions.fold(
        (failure) => ComparisonListError(
          'Failed to load sessions',
        ), // Simplified error message
        (sessions) {
          final modifiableSessions = List<ComparisonSession>.from(sessions);
          modifiableSessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return ComparisonListLoaded(modifiableSessions);
        },
      ),
    );
  }

  Future<void> _onDeleteComparisonSession(
    DeleteComparisonSession event,
    Emitter<ComparisonListState> emit,
  ) async {
    if (state is ComparisonListLoaded) {
      final currentState = state as ComparisonListLoaded;
      final failureOrVoid =
          await useCases.deleteComparisonSession(event.session.id);
      if (failureOrVoid.isRight()) {
        final updatedSessions = List<ComparisonSession>.from(
          currentState.sessions,
        )..remove(event.session);
        emit(
          ComparisonListLoaded(
            updatedSessions,
            lastDeletedSession: event.session,
          ),
        );
      }
      // Optionally handle the failure case by emitting an error state
    }
  }

  Future<void> _onUndoDeleteComparisonSession(
    UndoDeleteComparisonSession event,
    Emitter<ComparisonListState> emit,
  ) async {
    if (state is ComparisonListLoaded) {
      final currentState = state as ComparisonListLoaded;
      if (currentState.lastDeletedSession != null) {
        final sessionToRestore = currentState.lastDeletedSession!;
        final failureOrVoid =
            await useCases.saveComparisonSession(sessionToRestore);
        if (failureOrVoid.isRight()) {
          final updatedSessions =
              List<ComparisonSession>.from(currentState.sessions)
                ..add(sessionToRestore);
          final modifiableSessions = List<ComparisonSession>.from(updatedSessions);
          modifiableSessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          emit(ComparisonListLoaded(modifiableSessions, lastDeletedSession: null));
        }
        // Optionally handle the failure case
      }
    }
  }
}
