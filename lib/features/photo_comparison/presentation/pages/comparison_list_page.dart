import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/observers/app_route_observer.dart';
import '../bloc/comparison_list_bloc.dart';
import 'photo_selection_page.dart';
import '../../domain/entities/comparison_session.dart';
import 'photo_comparison_page.dart';

class ComparisonListPage extends StatefulWidget {
  const ComparisonListPage({super.key});

  @override
  State<ComparisonListPage> createState() => _ComparisonListPageState();
}

class _ComparisonListPageState extends State<ComparisonListPage>
    with RouteAware {
  @override
  void initState() {
    super.initState();
    // Load sessions when the page is first created
    context.read<ComparisonListBloc>().add(LoadComparisonSessions());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // This is called when the user returns to this page.
    context.read<ComparisonListBloc>().add(LoadComparisonSessions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Comparisons')),
      body: BlocBuilder<ComparisonListBloc, ComparisonListState>(
        builder: (context, state) {
          if (state is ComparisonListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ComparisonListError) {
            return Center(child: Text('Error: ${state.message}'));
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
                return Dismissible(
                  key: Key(session.id),
                  onDismissed: (direction) {
                    context
                        .read<ComparisonListBloc>()
                        .add(DeleteComparisonSession(session));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '"${DateFormat.yMMMMd().format(session.createdAt)}" deleted',
                        ),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            context
                                .read<ComparisonListBloc>()
                                .add(UndoDeleteComparisonSession());
                          },
                        ),
                      ),
                    );
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ComparisonSessionCard(session: session),
                );
              },
            );
          }
          return const Center(child: Text('Welcome!'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PhotoSelectionPage()));
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
    final title =
        "Collection from ${DateFormat.yMMMMd().format(session.createdAt)}";
    final hasPhotos = session.allPhotos.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: SizedBox(
          width: 56,
          height: 56,
          child: hasPhotos && session.allPhotos.first.file != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                    session.allPhotos.first.file!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(Icons.image_not_supported),
                ),
        ),
        title: Text(title),
        subtitle: Text(
          '${session.remainingPhotos.length} of ${session.allPhotos.length} photos left',
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PhotoComparisonPage(sessionToResume: session),
            ),
          );
        },
      ),
    );
  }
}
