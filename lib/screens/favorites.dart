import 'package:flutter/material.dart';
import '../services/library.dart';
import 'library.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final lib = LibraryStore.instance;
    return AnimatedBuilder(
      animation: lib,
      builder: (_, __) {
        final list = lib.all.where((g) => lib.isFavorite(g.gameKey)).toList();
        if (list.isEmpty) return const Center(child: Text('No favorites yet. Tap the heart on a library game.'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (c, i) {
            final g = list[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.favorite, color: Colors.redAccent),
                title: Text(g.title),
                subtitle: Text(g.folderPath, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.heart_broken_outlined),
                  tooltip: 'Remove from favorites',
                  onPressed: () {
                    lib.setFavorite(g.gameKey, false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Removed from favorites'),
                      action: SnackBarAction(label: 'Undo', onPressed: () => lib.setFavorite(g.gameKey, true)),
                    ));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
