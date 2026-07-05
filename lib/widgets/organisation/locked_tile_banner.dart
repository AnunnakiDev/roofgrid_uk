import 'package:flutter/material.dart';

class LockedTileBanner extends StatelessWidget {
  final String tileName;

  const LockedTileBanner({super.key, required this.tileName});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer.withValues(
            alpha: 0.45,
          ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project tile locked',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    tileName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}