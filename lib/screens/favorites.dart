import 'package:flutter/material.dart';
import '../l10n_ext.dart';
import '../services/library.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final lib = LibraryStore.instance;
    return AnimatedBuilder(
      animation: lib,
      builder: (_, __) {
        final list = lib.all.where((g) => lib.isFavorite(g.gameKey)).toList();
        if (list.isEmpty) return Center(child: Text(context.l.noFavoritesYetTapTheHeartOnALibraryGame));
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
                  tooltip: context.l.removeFromFavorites,
                  onPressed: () {
                    lib.setFavorite(g.gameKey, false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(context.l.removedFromFavorites),
                      action: SnackBarAction(label: context.l.undo, onPressed: () => lib.setFavorite(g.gameKey, true)),
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
