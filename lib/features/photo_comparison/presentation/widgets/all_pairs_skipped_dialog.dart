import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/photo.dart';
import '../bloc/photo_comparison_bloc.dart';

class AllPairsSkippedDialog extends StatefulWidget {
  final List<Photo> remainingPhotos;

  const AllPairsSkippedDialog({super.key, required this.remainingPhotos});

  @override
  State<AllPairsSkippedDialog> createState() => _AllPairsSkippedDialogState();
}

class _AllPairsSkippedDialogState extends State<AllPairsSkippedDialog> {
  bool _dontAskAgain = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Keep all remaining photos?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You have skipped all possible pairs of the remaining photos. Do you want to keep them all?',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              width: double.maxFinite,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: widget.remainingPhotos.length,
                itemBuilder: (context, index) {
                  final photo = widget.remainingPhotos[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(photo.file!, fit: BoxFit.cover),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _dontAskAgain,
                  onChanged: (bool? value) {
                    setState(() {
                      _dontAskAgain = value ?? false;
                    });
                  },
                ),
                const Flexible(child: Text("Don't ask again for this set")),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.read<PhotoComparisonBloc>().add(
              ContinueComparing(dontAskAgain: _dontAskAgain),
            );
            Navigator.of(context).pop();
          },
          child: const Text('No, Continue Comparing'),
        ),
        FilledButton(
          onPressed: () {
            context.read<PhotoComparisonBloc>().add(KeepRemainingPhotos());
            Navigator.of(context).pop();
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
          ),
          child: const Text('Yes, Keep Them'),
        ),
      ],
    );
  }
}
