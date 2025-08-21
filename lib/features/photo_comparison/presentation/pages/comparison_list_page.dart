import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/dependency_injection.dart';
import '../bloc/comparison_list_bloc.dart';
import 'photo_selection_page.dart';
import '../../domain/entities/comparison_session.dart';
import 'photo_comparison_page.dart';

class ComparisonListPage extends StatelessWidget {
  const ComparisonListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Comparisons'),
      ),
      body: BlocBuilder<ComparisonListBloc, ComparisonListState>(
        builder: (context, state) {
          if (state is ComparisonListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ComparisonListError) {
            return Center(
              child: Text('Error: ${state.message}'),
            );
          }
          if (state is ComparisonListLoaded) {
            if (state.sessions.isEmpty) {
              return const Center(
                child: Text('No saved comparisons. Start a new one!'),
              );
            }
            return ListView.builder(
              itemCount: state.sessions.length,
              itemBuilder: (context, index) {
                final session = state.sessions[index];
                return ComparisonSessionCard(session: session);
              },
            );
          }
          return const Center(child: Text('Welcome!'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              // The selection page will need to be wrapped in its BLoC provider
              builder: (_) => const PhotoSelectionPage(),
            ),
          ).then((_) {
            // After returning from selection/comparison, refresh the list
            context.read<ComparisonListBloc>().add(LoadComparisonSessions());
          });
        },
        label: const Text('New Comparison'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class ComparisonSessionCard extends StatelessWidget {
  final ComparisonSession session;

  const ComparisonSessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement resume logic on tap
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        // TODO: Replace with StackedThumbnail widget
        leading: CircleAvatar(
          child: Text(session.remainingPhotos.length.toString()),
        ),
        title: Text('Comparison from ${session.createdAt.toLocal().toString().substring(0, 16)}'),
        subtitle: Text('${session.remainingPhotos.length} of ${session.allPhotos.length} photos left'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PhotoComparisonPage(sessionToResume: session),
            ),
          ).then((_) {
            // After returning, refresh the list
            context.read<ComparisonListBloc>().add(LoadComparisonSessions());
          });
        },
      ),
    );
  }
}
