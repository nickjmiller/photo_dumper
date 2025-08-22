import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_dumper/features/photo_comparison/domain/entities/photo.dart';
import 'package:photo_dumper/features/photo_comparison/presentation/bloc/photo_comparison_bloc.dart';

class AllPairsSkippedDialog extends StatefulWidget {
  final List<Photo> remainingPhotos;

  const AllPairsSkippedDialog({super.key, required this.remainingPhotos});

  @override
  State<AllPairsSkippedDialog> createState() => _AllPairsSkippedDialogState();
}

class _AllPairsSkippedDialogState extends State<AllPairsSkippedDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('All Pairs Skipped'),
      content: Text(
        'You have skipped all possible pairs with the remaining ${widget.remainingPhotos.length} photos. Do you want to keep them all?',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<PhotoComparisonBloc>().add(RestartComparison());
          },
          child: const Text('No, Restart'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<PhotoComparisonBloc>().add(KeepRemainingPhotos());
          },
          child: const Text('Yes, Keep Them'),
        ),
      ],
    );
  }
}
