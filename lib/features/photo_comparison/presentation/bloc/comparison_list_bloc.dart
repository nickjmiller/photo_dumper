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
  final String sessionId;
  const DeleteComparisonSession(this.sessionId);
  @override
  List<Object> get props => [sessionId];
}

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
  const ComparisonListLoaded(this.sessions);
  @override
  List<Object> get props => [sessions];
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

  ComparisonListBloc({required this.useCases})
    : super(ComparisonListInitial()) {
    on<LoadComparisonSessions>(_onLoadComparisonSessions);
    on<DeleteComparisonSession>(_onDeleteComparisonSession);
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
        (sessions) => ComparisonListLoaded(sessions),
      ),
    );
  }

  Future<void> _onDeleteComparisonSession(
    DeleteComparisonSession event,
    Emitter<ComparisonListState> emit,
  ) async {
    final failureOrVoid = await useCases.deleteComparisonSession(
      event.sessionId,
    );
    if (failureOrVoid.isLeft()) {
      // Optionally emit an error state or handle it silently.
      // For now, reloading the list will show the user it wasn't deleted.
    }
    // Reload the list from the database to ensure consistency.
    add(LoadComparisonSessions());
  }
}
