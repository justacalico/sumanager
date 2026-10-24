import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
import '../services/library.dart';
import '../services/runner.dart';
import '../services/settings.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String search = '';
  String? collection;

  @override
  Widget build(BuildContext context) {
    final lib = LibraryStore.instance;
    return AnimatedBuilder(
      animation: lib,
      builder: (_, __) {
        var list = lib.all.where((g) => search.isEmpty || g.title.toLowerCase().contains(search.toLowerCase())).toList();
        if (collection != null) {
          final c = lib.collections.firstWhere((x) => x.id == collection, orElse: () => GameCollection(id: '', name: ''));
          list = list.where((g) => c.gameKeys.contains(g.gameKey)).toList();
        }
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Search library…', isDense: true, prefixIcon: Icon(Icons.search, size: 20), border: OutlineInputBorder()),
                  onChanged: (v) => setState(() => search = v),
                ),
              ),
              FilledButton.tonalIcon(icon: const Icon(Icons.add, size: 18), label: const Text('Scan for Games'), onPressed: () => _scan(context)),
              FilledButton.tonalIcon(icon: const Icon(Icons.create_new_folder_outlined, size: 18), label: const Text('Add Game'), onPressed: () => _addCustom(context)),
              FilledButton.tonalIcon(icon: const Icon(Icons.collections_bookmark_outlined, size: 18), label: const Text('New Collection'), onPressed: () => _newCollection(context)),
              if (lib.collections.isNotEmpty)
                DropdownButton<String?>(
                  value: collection, hint: const Text('All games'), underline: const SizedBox(),
                  items: [const DropdownMenuItem(value: null, child: Text('All games')), ...lib.collections.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))],
                  onChanged: (v) => setState(() => collection = v),
                ),
              Text('${list.length} games', style: const TextStyle(fontSize: 12)),
            ]),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('Your library is empty. Download games or scan a folder.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (c, i) => _tile(context, lib, list[i]),
                  ),
          ),
        ]);
      },
    );
  }

  Widget _tile(BuildContext context, LibraryStore lib, LibraryGame g) {
    return Card(
      child: ListTile(
        leading: g.coverUrl != null && g.coverUrl!.isNotEmpty
            ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(g.coverUrl!, width: 44, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.videogame_asset)))
            : const Icon(Icons.videogame_asset, size: 36),
        title: Text(g.title),
        subtitle: Text(g.exePath == null ? 'No executable set' : g.exePath!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
        trailing: Wrap(spacing: 4, children: [
          IconButton(icon: const Icon(Icons.play_arrow), tooltip: 'Play', onPressed: () => _play(context, g)),
          IconButton(icon: Icon(lib.isFavorite(g.gameKey) ? Icons.favorite : Icons.favorite_border, size: 20), tooltip: 'Favorite', onPressed: () => lib.setFavorite(g.gameKey, !lib.isFavorite(g.gameKey))),
          PopupMenuButton<String>(
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'folder', child: Text('Open folder')),
              PopupMenuItem(value: 'exe', child: Text('Set executable')),
              PopupMenuItem(value: 'collections', child: Text('Collections')),
              PopupMenuItem(value: 'uninstall', child: Text('Uninstall')),
              PopupMenuItem(value: 'remove', child: Text('Remove from library')),
            ],
            onSelected: (v) => _menu(context, lib, g, v),
          ),
        ]),
      ),
    );
  }

  Future<void> _play(BuildContext context, LibraryGame g) async {
    if (g.exePath == null) {
      await _pickExe(context, g);
      if (g.exePath == null) return;
    }
    final p = await GameRunner.launch(g.exePath!, workDir: g.folderPath);
    if (p == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_runnerHint())));
      return;
    }
    g.lastPlayed = DateTime.now().millisecondsSinceEpoch;
  }

  String _runnerHint() {
    if (Theme.of(context).platform == TargetPlatform.linux) return 'No Proton/Wine found. Install Proton via Steam or configure a runner in Settings.';
    if (Theme.of(context).platform == TargetPlatform.macOS) return 'Install CrossOver or set a Wine/whisky binary in Settings to play Windows games.';
    return 'Could not launch the game.';
  }

  Future<void> _pickExe(BuildContext context, LibraryGame g) async {
    final r = await FilePicker.platform.pickFiles(dialogTitle: 'Choose the game executable');
    if (r != null && r.files.single.path != null) {
      g.exePath = r.files.single.path!;
      LibraryStore.instance.notifyListeners();
    }
  }

  Future<void> _menu(BuildContext context, LibraryStore lib, LibraryGame g, String v) async {
    switch (v) {
      case 'folder':
        await launchUrl(Uri.file(g.folderPath));
      case 'exe':
        await _pickExe(context, g);
      case 'collections':
        await showDialog(context: context, builder: (_) => _CollectionsDialog(game: g));
      case 'uninstall':
        try { await Directory(g.folderPath).delete(recursive: true); } catch (_) {}
        lib.removeGame(g.gameKey);
      case 'remove':
        lib.removeGame(g.gameKey);
    }
  }

  Future<void> _scan(BuildContext context) async {
    final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Choose a folder to scan for games');
    if (dir == null) return;
    final exes = await GameScanner.findExecutables(Directory(dir));
    if (!context.mounted) return;
    if (exes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No game executables found in that folder.')));
      return;
    }
    final lib = LibraryStore.instance;
    final name = dir.split(RegExp(r'[/\\]')).last;
    lib.addGame(LibraryGame(
      gameKey: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      title: GameScanner.normalizeTitle(name).isEmpty ? name : GameScanner.normalizeTitle(name),
      folderPath: dir,
      exePath: exes.first.path,
      isCustom: true,
    ));
  }

  Future<void> _addCustom(BuildContext context) => _scan(context);

  Future<void> _newCollection(BuildContext context) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New collection'),
        content: TextField(controller: ctrl, maxLength: 48, decoration: const InputDecoration(hintText: 'Collection name')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Create'))],
      ),
    );
    if (name != null && name.isNotEmpty && name != 'All games') {
      LibraryStore.instance.addCollection(name);
    }
  }
}

class _CollectionsDialog extends StatelessWidget {
  final LibraryGame game;
  const _CollectionsDialog({required this.game});
  @override
  Widget build(BuildContext context) {
    final lib = LibraryStore.instance;
    final selected = lib.collections.where((c) => c.gameKeys.contains(game.gameKey)).map((c) => c.id).toSet();
    return StatefulBuilder(builder: (context, setState) => AlertDialog(
          title: Text('Collections for ${game.title}'),
          content: SizedBox(
            width: 320,
            child: lib.collections.isEmpty
                ? const Text('No collections yet.')
                : ListView(shrinkWrap: true, children: [
                    for (final c in lib.collections)
                      CheckboxListTile(
                        title: Text(c.name),
                        value: selected.contains(c.id),
                        onChanged: (v) => setState(() => v == true ? selected.add(c.id) : selected.remove(c.id)),
                      ),
                  ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () { lib.setGameCollections(game.gameKey, selected.toList()); Navigator.pop(context); }, child: const Text('Save')),
          ],
        ));
  }
}
