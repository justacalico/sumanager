import 'package:flutter/material.dart';
import '../models.dart';
import '../services/api.dart';
import '../services/downloads.dart';
import '../services/settings.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});
  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  List<CatalogGame> games = [];
  Map<int, int> views = {};
  bool loading = true;
  String? error;
  String search = '';
  String sort = 'recent';
  String? category;
  RangeValues sizeRange = const RangeValues(0, 200);
  int shown = 60;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() { loading = true; error = null; });
    try {
      games = await Api.fetchCatalog();
      views = await Api.fetchPopularity();
    } catch (e) {
      error = 'Could not load the catalog. Check your connection and retry.';
    }
    if (mounted) setState(() => loading = false);
  }

  List<CatalogGame> get filtered {
    var out = games.where((g) {
      if (Settings.instance.hideAdult && g.uncensored) return false;
      if (search.isNotEmpty && !g.title.toLowerCase().contains(search.toLowerCase())) return false;
      if (category != null && !g.categories.contains(category)) return false;
      final gb = g.fileSize / 1e9;
      if (gb < sizeRange.start || (sizeRange.end < 200 && gb > sizeRange.end)) return false;
      return true;
    }).toList();
    switch (sort) {
      case 'views': out.sort((a, b) => (views[b.id] ?? 0).compareTo(views[a.id] ?? 0)); break;
      case 'name': out.sort((a, b) => a.title.compareTo(b.title)); break;
      case 'size': out.sort((a, b) => b.fileSize.compareTo(a.fileSize)); break;
      default: out.sort((a, b) => (b.publishedAt ?? '').compareTo(a.publishedAt ?? ''));
    }
    return out;
  }

  List<String> get categories => games.expand((g) => g.categories).toSet().toList()..sort();

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(error!, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton(onPressed: _load, child: const Text('Retry')),
      ]));
    }
    final list = filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            SizedBox(
              width: 340,
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: 'Search games…', isDense: true, prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: search.isEmpty ? null : IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _ctrl.clear(); setState(() => search = ''); }),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() { search = v; shown = 60; }),
              ),
            ),
            DropdownButton<String>(
              value: sort, underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'recent', child: Text('Recently added')),
                DropdownMenuItem(value: 'views', child: Text('Most viewed')),
                DropdownMenuItem(value: 'name', child: Text('Name A–Z')),
                DropdownMenuItem(value: 'size', child: Text('Size')),
              ],
              onChanged: (v) => setState(() => sort = v!),
            ),
            if (categories.isNotEmpty)
              DropdownButton<String?>(
                value: category, hint: const Text('Category'), underline: const SizedBox(),
                items: [const DropdownMenuItem(value: null, child: Text('All categories')),
                  ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c)))],
                onChanged: (v) => setState(() => category = v),
              ),
            TextButton.icon(icon: const Icon(Icons.clear_all, size: 18), label: const Text('Clear filters'),
              onPressed: () { _ctrl.clear(); setState(() { search = ''; category = null; sort = 'recent'; sizeRange = const RangeValues(0, 200); }); }),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Text('Size: ${_fmt(sizeRange.start * 1e9)} – ${sizeRange.end >= 200 ? '∞' : _fmt(sizeRange.end * 1e9)}', style: const TextStyle(fontSize: 12)),
            Expanded(child: RangeSlider(values: sizeRange, min: 0, max: 200, onChanged: (v) => setState(() => sizeRange = v))),
            Text('${list.length} games', style: const TextStyle(fontSize: 12)),
          ]),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels > n.metrics.maxScrollExtent - 400 && shown < list.length) {
                setState(() => shown += 60);
              }
              return false;
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, childAspectRatio: 0.68, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: list.length.clamp(0, shown),
              itemBuilder: (c, i) => GameCard(game: list[i], views: views[list[i].id]),
            ),
          ),
        ),
      ],
    );
  }

  static String _fmt(double b) => b >= 1e9 ? '${(b / 1e9).toStringAsFixed(0)} GB' : '${(b / 1e6).toStringAsFixed(0)} MB';
}

class GameCard extends StatelessWidget {
  final CatalogGame game;
  final int? views;
  const GameCard({super.key, required this.game, this.views});

  @override
  Widget build(BuildContext context) {
    final dm = DownloadManager.instance;
    final inLibrary = dm.isQueuedOrDone(game.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showDialog(context: context, builder: (_) => GameDialog(game: game)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFF23232E),
                child: game.coverUrl.isNotEmpty
                    ? Image.network(game.coverUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.videogame_asset, size: 48))
                    : const Icon(Icons.videogame_asset, size: 48),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(game.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  Text(fmtBytes(game.fileSize), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const Spacer(),
                  if (inLibrary) const Icon(Icons.check_circle, size: 14, color: Colors.green),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  static String fmtBytes(int b) =>
      b >= 1e9 ? '${(b / 1e9).toStringAsFixed(1)} GB' : b >= 1e6 ? '${(b / 1e6).toStringAsFixed(0)} MB' : '${(b / 1e3).toStringAsFixed(0)} KB';
}

class GameDialog extends StatelessWidget {
  final CatalogGame game;
  const GameDialog({super.key, required this.game});
  @override
  Widget build(BuildContext context) {
    final dm = DownloadManager.instance;
    return AlertDialog(
      title: Text(game.title),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (game.coverUrl.isNotEmpty)
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(game.coverUrl, height: 180, width: 320, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())),
        const SizedBox(height: 12),
        Text('Size: ${GameCard.fmtBytes(game.fileSize)}'),
        if (game.categories.isNotEmpty) Text('Categories: ${game.categories.join(', ')}'),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        AnimatedBuilder(
          animation: dm,
          builder: (_, __) => FilledButton.icon(
            icon: const Icon(Icons.download),
            label: Text(dm.isQueuedOrDone(game.id) ? 'In Downloads' : 'Download'),
            onPressed: dm.isQueuedOrDone(game.id)
                ? null
                : () async {
                    await dm.queue(game);
                    if (context.mounted) Navigator.pop(context);
                  },
          ),
        ),
      ],
    );
  }
}
