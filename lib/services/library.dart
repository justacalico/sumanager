import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models.dart';
import 'settings.dart';

class LibraryStore extends ChangeNotifier {
  static final LibraryStore instance = LibraryStore._();
  LibraryStore._();

  final List<LibraryGame> games = [];
  final List<GameCollection> collections = [];
  final Set<String> favorites = {};
  final List<LibraryGame> customGames = [];
  bool _loaded = false;

  void touch() => notifyListeners();

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final lj = await Settings.instance.readJson('library.json');
    for (final g in (lj['games'] as List? ?? [])) {
      games.add(LibraryGame.fromJson(Map<String, dynamic>.from(g)));
    }
    final cj = await Settings.instance.readJson('collections.json');
    for (final c in (cj['collections'] as List? ?? [])) {
      collections.add(GameCollection.fromJson(Map<String, dynamic>.from(c)));
    }
    final fj = await Settings.instance.readJson('favorites.json');
    favorites.addAll((fj['keys'] as List? ?? []).map((e) => '$e'));
    final gj = await Settings.instance.readJson('custom_games.json');
    for (final g in (gj['games'] as List? ?? [])) {
      customGames.add(LibraryGame.fromJson(Map<String, dynamic>.from(g))..isCustom = true);
    }
    notifyListeners();
  }

  Future<void> _save() async {
    await Settings.instance.writeJson('library.json', {'games': games.map((g) => g.toJson()).toList()});
    await Settings.instance.writeJson('collections.json', {'collections': collections.map((c) => c.toJson()).toList(), 'revision': 1});
    await Settings.instance.writeJson('favorites.json', {'keys': favorites.toList()});
    await Settings.instance.writeJson('custom_games.json', {'games': customGames.map((g) => g.toJson()).toList()});
  }

  void addGame(LibraryGame g) {
    games.removeWhere((x) => x.gameKey == g.gameKey);
    games.add(g);
    notifyListeners();
    _save();
  }

  void removeGame(String gameKey) {
    games.removeWhere((g) => g.gameKey == gameKey);
    customGames.removeWhere((g) => g.gameKey == gameKey);
    favorites.remove(gameKey);
    for (final c in collections) {
      c.gameKeys = c.gameKeys.where((k) => k != gameKey).toList();
    }
    notifyListeners();
    _save();
  }

  void setFavorite(String key, bool on) {
    if (on) { favorites.add(key); } else { favorites.remove(key); }
    notifyListeners();
    _save();
  }

  bool isFavorite(String key) => favorites.contains(key);

  String addCollection(String name) {
    final id = 'c${DateTime.now().millisecondsSinceEpoch}';
    collections.add(GameCollection(id: id, name: name));
    notifyListeners();
    _save();
    return id;
  }

  void deleteCollection(String id) {
    collections.removeWhere((c) => c.id == id);
    notifyListeners();
    _save();
  }

  void saveCollectionGameKeys(String id, List<String> keys) {
    final c = collections.firstWhere((x) => x.id == id, orElse: () => GameCollection(id: id, name: 'Collection'));
    if (!collections.contains(c)) collections.add(c);
    c.gameKeys = keys;
    notifyListeners();
    _save();
  }

  void setGameCollections(String gameKey, List<String> ids) {
    for (final c in collections) {
      final has = c.gameKeys.contains(gameKey);
      if (ids.contains(c.id) && !has) c.gameKeys = [...c.gameKeys, gameKey];
      if (!ids.contains(c.id) && has) c.gameKeys = c.gameKeys.where((k) => k != gameKey).toList();
    }
    notifyListeners();
    _save();
  }

  LibraryGame? byKey(String key) {
    for (final g in [...games, ...customGames]) {
      if (g.gameKey == key) return g;
    }
    return null;
  }

  List<LibraryGame> get all => [...games, ...customGames];
}

class GameScanner {
  static const skipNames = [
    'battleyelauncher', 'easyanticheat', 'crashhandler', 'crashreporter',
    'crashsender', 'reportclient', 'reqsetup', 'ueprereqsetup', 'ue4prereqsetup',
    'notification_helper', 'unitycrashhandler', 'unins', 'setup', 'redist',
    'dxsetup', 'vcredist', 'dotnetfx', 'oalinst', 'directx',
  ];

  static String normalizeTitle(String folder) {
    var t = folder.replaceAll(RegExp(r'[._]+'), ' ').trim();
    t = t.replaceAll(RegExp(r'\b(free download|repack|fitgirl|dodi|full version|all dlc|incl\.?.*|v[\d.]+.*|digital deluxe edition|game of the year edition|deluxe edition|complete edition|definitive edition|ultimate edition|gold edition|special edition|standard edition|goty edition|update.*|multi\d+|prophet|codex|skidrow|reloaded|plaza|elamigos|gog|steamrip|crack.*)\b', caseSensitive: false), ' ');
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool isGameExe(String name) {
    final n = name.toLowerCase();
    if (!n.endsWith('.exe') && !n.endsWith('.bat') && !n.endsWith('.sh') && !n.endsWith('')) return false;
    return !skipNames.any((s) => n.contains(s));
  }

  static Future<List<FileSystemEntity>> findExecutables(Directory dir, {int depth = 3}) async {
    final out = <FileSystemEntity>[];
    await for (final e in dir.list(recursive: true, followLinks: false)) {
      if (e is! File) continue;
      final rel = e.path.substring(dir.path.length).split(Platform.pathSeparator).length - 1;
      if (rel > depth) continue;
      final name = e.path.split(Platform.pathSeparator).last;
      if (isGameExe(name)) out.add(e);
    }
    return out;
  }

  static double scoreMatch(String folderName, String catalogTitle) {
    final a = normalizeTitle(folderName).toLowerCase();
    final b = normalizeTitle(catalogTitle).toLowerCase();
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0;
    if (a.contains(b) || b.contains(a)) return 0.85;
    final aw = a.split(' ').toSet();
    final bw = b.split(' ').toSet();
    if (aw.isEmpty || bw.isEmpty) return 0;
    final inter = aw.intersection(bw).length;
    return inter / (aw.length > bw.length ? aw.length : bw.length);
  }

  static Map<String, dynamic> matchFolder(String folderName, List<CatalogGame> catalog) {
    var best = 0.0;
    CatalogGame? hit;
    for (final g in catalog) {
      final s = scoreMatch(folderName, g.title);
      if (s > best) { best = s; hit = g; }
    }
    return {
      'normalized_title': normalizeTitle(folderName),
      'score': best,
      'confidence': best > 0.8 ? 'exact' : best > 0.5 ? 'strong' : 'weak',
      'suggested_catalog_id': hit?.id,
      'suggested_name': hit?.title,
      'suggested_cover': hit?.coverUrl,
    };
  }
}
