import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onKeepBoth;
  final VoidCallback onDiscardBoth;

  const ActionButtons({
    super.key,
    required this.onKeepBoth,
    required this.onDiscardBoth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onKeepBoth,
            icon: const Icon(Icons.check),
            label: const Text('Keep Both'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton.icon(
            onPressed: onDiscardBoth,
            icon: const Icon(Icons.delete),
            label: const Text('Discard Both'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
