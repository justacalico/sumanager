import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumanager/models.dart';
import 'package:sumanager/services/library.dart';
import 'package:sumanager/services/settings.dart';
import 'helpers.dart';

void main() {
  setUpAll(setupTestEnv);

  test('store add/remove/favorite/collections', () async {
    final s = LibraryStore.forTest();
    await s.load();
    s.addGame(LibraryGame(gameKey: 'g1', title: 'A', folderPath: '/x'));
    s.addGame(LibraryGame(gameKey: 'g1', title: 'A2', folderPath: '/x'));
    expect(s.games.length, 1);
    s.setFavorite('g1', true);
    expect(s.isFavorite('g1'), true);
    final cid = s.addCollection('RPG');
    s.saveCollectionGameKeys(cid, ['g1']);
    s.setGameCollections('g1', [cid]);
    expect(s.collections.firstWhere((c) => c.id == cid).gameKeys, ['g1']);
    expect(s.all.length, 1);
    s.deleteCollection(cid);
    s.removeGame('g1');
    expect(s.byKey('g1'), isNull);
    expect(s.isFavorite('g1'), false);
    await s.load();
  });

  test('scanner normalize/isGameExe/score/match', () {
    expect(GameScanner.normalizeTitle('Hades_v1.2_free_download-CODEX'), 'Hades');
    expect(GameScanner.isGameExe('game.exe'), true);
    expect(GameScanner.isGameExe('unins000.exe'), false);
    expect(GameScanner.isGameExe('readme.txt'), false);
    expect(GameScanner.isGameExe('run.sh'), true);
    expect(GameScanner.isGameExe('linuxbinary'), true);
    expect(GameScanner.scoreMatch('hades', 'Hades'), 1.0);
    expect(GameScanner.scoreMatch('hades ii', 'Hades'), 0.85);
    expect(GameScanner.scoreMatch('', 'x'), 0);
    expect(GameScanner.scoreMatch('a b', 'a c'), greaterThan(0));
    final catalog = [const CatalogGame(id: 1, slug: 'h', title: 'Hades', coverUrl: '')];
    expect(GameScanner.matchFolder('Hades Free Download', catalog)['suggested_catalog_id'], 1);
  });

  test('load reads saved files', () async {
    await Settings.instance.writeJson('library.json', {'games': [{'game_key': 'a', 'title': 'T', 'folder_path': '/p'}]});
    await Settings.instance.writeJson('collections.json', {'collections': [{'id': 'c1', 'name': 'C', 'game_keys': ['a']}]});
    await Settings.instance.writeJson('favorites.json', {'keys': ['a']});
    await Settings.instance.writeJson('custom_games.json', {'games': [{'game_key': 'cu', 'title': 'CU', 'folder_path': '/q'}]});
    final s = LibraryStore.forTest();
    await s.load();
    expect(s.games.length, 1);
    expect(s.collections.length, 1);
    expect(s.isFavorite('a'), true);
    expect(s.customGames.length, 1);
    expect(s.byKey('cu')!.isCustom, true);
    s.setGameCollections('a', ['c1']);
    s.removeGame('a');
    expect(s.collections.first.gameKeys, isEmpty);
  });

  test('findExecutables walks dirs', () async {
    final d = Directory.systemTemp.createTempSync('scan');
    File('${d.path}/game.exe').createSync();
    File('${d.path}/unins.exe').createSync();
    Directory('${d.path}/deep/nested/x').createSync(recursive: true);
    File('${d.path}/deep/nested/x/tool.exe').createSync();
    final found = await GameScanner.findExecutables(d);
    expect(found.any((f) => f.path.endsWith('game.exe')), true);
    expect(found.any((f) => f.path.endsWith('unins.exe')), false);
    expect(found.any((f) => f.path.endsWith('tool.exe')), false);
  });
}
