import 'package:flutter/material.dart';
import '../../domain/entities/photo.dart';

class SelectablePhotoCard extends StatelessWidget {
  final Photo photo;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectablePhotoCard({
    super.key,
    required this.photo,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GridTile(
        footer: isSelected
            ? Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(4.0),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                ),
              )
            : null,
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  )
                : null,
            image: DecorationImage(
              image: FileImage(photo.file!),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
