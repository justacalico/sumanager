import 'dart:io';
import '../l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
import '../services/library.dart';
import '../services/runner.dart';

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
                  decoration: InputDecoration(hintText: context.l.searchLibrary, isDense: true, prefixIcon: Icon(Icons.search, size: 20), border: OutlineInputBorder()),
                  onChanged: (v) => setState(() => search = v),
                ),
              ),
              FilledButton.tonalIcon(icon: Icon(Icons.add, size: 18), label: Text(context.l.scanForGames), onPressed: () => _scan(context)),
              FilledButton.tonalIcon(icon: Icon(Icons.create_new_folder_outlined, size: 18), label: Text(context.l.addGame), onPressed: () => _addCustom(context)),
              FilledButton.tonalIcon(icon: Icon(Icons.collections_bookmark_outlined, size: 18), label: Text(context.l.newCollection), onPressed: () => _newCollection(context)),
              if (lib.collections.isNotEmpty)
                DropdownButton<String?>(
                  value: collection, hint: Text(context.l.allGames), underline: const SizedBox(),
                  items: [DropdownMenuItem(value: null, child: Text(context.l.allGames)), ...lib.collections.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))],
                  onChanged: (v) => setState(() => collection = v),
                ),
              Text('${list.length} games', style: const TextStyle(fontSize: 12)),
            ]),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text(context.l.yourLibraryIsEmptyDownloadGamesOrScanAFolder))
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
        subtitle: Text(g.exePath == null ? context.l.noExecutableSet : g.exePath!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
        trailing: Wrap(spacing: 4, children: [
          IconButton(icon: const Icon(Icons.play_arrow), tooltip: context.l.play, onPressed: () => _play(context, g)),
          IconButton(icon: Icon(lib.isFavorite(g.gameKey) ? Icons.favorite : Icons.favorite_border, size: 20), tooltip: context.l.favorite, onPressed: () => lib.setFavorite(g.gameKey, !lib.isFavorite(g.gameKey))),
          PopupMenuButton<String>(
            itemBuilder: (_) => [
              PopupMenuItem(value: 'folder', child: Text(context.l.openFolder)),
              PopupMenuItem(value: 'exe', child: Text(context.l.setExecutable)),
              PopupMenuItem(value: 'collections', child: Text(context.l.collections)),
              PopupMenuItem(value: 'uninstall', child: Text(context.l.uninstall)),
              PopupMenuItem(value: 'remove', child: Text(context.l.removeFromLibrary)),
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
    if (Theme.of(context).platform == TargetPlatform.linux) return context.l.noProtonWineFoundInstallProtonViaSteamOrConfigureARunnerInSettings;
    if (Theme.of(context).platform == TargetPlatform.macOS) return context.l.installCrossoverOrSetAWineWhiskyBinaryInSettingsToPlayWindowsGames;
    return context.l.couldNotLaunchTheGame;
  }

  Future<void> _pickExe(BuildContext context, LibraryGame g) async {
    final r = await FilePicker.platform.pickFiles(dialogTitle: context.l.chooseTheGameExecutable);
    if (r != null && r.files.single.path != null) {
      g.exePath = r.files.single.path!;
      LibraryStore.instance.touch();
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
    final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: context.l.chooseAFolderToScanForGames);
    if (dir == null) return;
    final exes = await GameScanner.findExecutables(Directory(dir));
    if (!context.mounted) return;
    if (exes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l.noGameExecutablesFoundInThatFolder)));
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
    final allGames = context.l.allGames;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l.newCollection),
        content: TextField(controller: ctrl, maxLength: 48, decoration: InputDecoration(hintText: context.l.collectionName)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l.cancel)), FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: Text(context.l.create))],
      ),
    );
    if (name != null && name.isNotEmpty && name != allGames) {
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
          title: Text('${context.l.collectionsFor}${game.title}'),
          content: SizedBox(
            width: 320,
            child: lib.collections.isEmpty
                ? Text(context.l.noCollectionsYet)
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
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l.cancel)),
            FilledButton(onPressed: () { lib.setGameCollections(game.gameKey, selected.toList()); Navigator.pop(context); }, child: Text(context.l.save)),
          ],
        ));
  }
}
