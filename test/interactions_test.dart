import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sumanager/app.dart';
import 'package:sumanager/models.dart';
import 'package:sumanager/screens/browse.dart';
import 'package:sumanager/screens/downloads.dart';
import 'package:sumanager/screens/favorites.dart';
import 'package:sumanager/screens/help.dart';
import 'package:sumanager/screens/library.dart';
import 'package:sumanager/screens/settings_screen.dart';
import 'package:sumanager/screens/welcome.dart';
import 'package:sumanager/screens/account.dart';
import 'package:sumanager/services/api.dart';
import 'package:sumanager/services/auth.dart';
import 'package:sumanager/services/downloads.dart';
import 'package:sumanager/services/library.dart';
import 'package:sumanager/services/runner.dart';
import 'package:sumanager/services/settings.dart';
import 'package:flutter/gestures.dart';
import 'package:sumanager/widgets/shell.dart';
import 'package:sumanager/l10n/app_localizations.dart';
import 'helpers.dart';

Future<void> settle(WidgetTester t) async {
  await t.runAsync(() => Future.delayed(const Duration(milliseconds: 150)));
  await t.pumpAndSettle();
}

Future<void> tapAsync(WidgetTester t, Finder f) async {
  await t.runAsync(() async {
    await t.tap(f);
    await Future.delayed(const Duration(milliseconds: 150));
  });
  await t.pumpAndSettle();
}

void _noop(int _) {}

Widget wrap(Widget child) => MaterialApp(
      theme: ThemeData(fontFamily: 'Noto Sans', brightness: Brightness.dark, useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  setUpAll(() async {
    await setupTestEnv();
    await Settings.instance.load();
    Api.clientFactory = () => MockClient((req) async {
          if (req.url.path.contains('catalog')) {
            final games = [
              {'id': 1, 'slug': 'alpha', 'title': 'Alpha Game', 'cover_url': 'https://x/alpha.png', 'categories': ['RPG'], 'file_size': 1000000000, 'published_at': '2024-01-02'},
              {'id': 2, 'slug': 'beta', 'title': 'Beta Game', 'categories': ['FPS'], 'file_size': 2000000000},
              {'id': 3, 'slug': 'nsfw', 'title': 'Adult Game', 'categories': ['Adult'], 'file_size': 500000000, 'uncensored': true},
              for (var i = 10; i < 90; i++) {'id': i, 'slug': 'g$i', 'title': 'Filler $i', 'categories': ['RPG'], 'file_size': 1000},
            ];
            return http.Response(jsonEncode({'has_more': false, 'games': games}), 200);
          }
          if (req.url.path.contains('popularity')) return http.Response(jsonEncode({'views': {'1': 500, '2': 900}}), 200);
          if (req.url.path.contains('resolve-token')) return http.Response('{}', 500);
          if (req.url.path.contains('releases')) return http.Response(jsonEncode([{'tag_name': 'v9.9.9'}]), 200);
          if (req.url.path.contains('bug-report')) return http.Response('{}', 200);
          if (req.url.path.contains('health')) return http.Response('{}', 200);
          if (req.url.path.contains('me')) return http.Response(jsonEncode({'id': 'u', 'is_premium': false}), 200);
          return http.Response('{}', 404);
        });
  });
  tearDownAll(() => Api.clientFactory = null);

  testWidgets('welcome choose folder', (t) async {
    var done = false;
    await t.pumpWidget(wrap(WelcomeScreen(onDone: () => done = true)));
    await tapAsync(t, find.text('Choose a download folder'));
    expect(done, true);
    expect(Settings.instance.downloadPath.isNotEmpty, true);
  });

  testWidgets('app navigates all pages', (t) async {
    Settings.instance.welcomeShown = true;
    await t.pumpWidget(const SuManagerApp());
    await t.pumpAndSettle();
    for (final label in ['Downloads', 'Library', 'Favorites', 'Account', 'Settings', 'Help', 'Browse']) {
      await t.tap(find.text(label).first);
      await t.pumpAndSettle();
    }
    expect(find.byType(BrowseScreen), findsOneWidget);
  });

  testWidgets('browse sort, category, adult filter, dialog download', (t) async {
    DownloadManager.instance.items.clear();
    DownloadManager.instance.items.add(DownloadItem(id: 'q1', catalogId: 10, slug: 'f10', title: 'Filler 10', status: DownloadStatus.done));
    await t.binding.setSurfaceSize(const Size(1400, 900));
    await t.pumpWidget(wrap(const BrowseScreen()));
    await t.pumpAndSettle();
    await t.tap(find.text('Recently added'));
    await t.pumpAndSettle();
    await t.tap(find.text('Most viewed').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Most viewed'));
    await t.pumpAndSettle();
    await t.tap(find.text('Name A–Z').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Name A–Z'));
    await t.pumpAndSettle();
    await t.tap(find.text('Size').last);
    await t.pumpAndSettle();
    await t.tap(find.text('All categories'));
    await t.pumpAndSettle();
    await t.tap(find.text('RPG').last);
    await t.pumpAndSettle();
    expect(find.text('Beta Game'), findsNothing);
    await t.tap(find.text('Clear filters'), warnIfMissed: false);
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, 'beta');
    await t.pumpAndSettle();
    expect(find.text('Beta Game'), findsOneWidget);
    await t.enterText(find.byType(TextField).first, '');
    await t.pumpAndSettle();
    await t.drag(find.byType(GridView), const Offset(0, -3000));
    await t.pumpAndSettle();
    Settings.instance.setHideAdult(true);
    await t.enterText(find.byType(TextField).first, ' ');
    await t.pumpAndSettle();
    expect(find.text('Adult Game'), findsNothing);
    Settings.instance.setHideAdult(false);
    await t.enterText(find.byType(TextField).first, 'alpha');
    await t.pumpAndSettle();
    await t.tap(find.text('Alpha Game'));
    await t.pumpAndSettle();
    await t.tap(find.text('Download'));
    await t.pumpAndSettle();
    expect(DownloadManager.instance.items.any((i) => i.catalogId != 0), true);
  });

  testWidgets('downloads extract, dismiss, cancel, resume', (t) async {
    final dm = DownloadManager.instance;
    dm.items.clear();
    final zip = File('${Directory.systemTemp.createTempSync('x').path}/g.zip');
    zip.writeAsBytesSync(base64Decode('UEsDBAoAAAAAAGx+LlYWcGmlBAAAAAQAAAAJABwAZ2FtZS9ydW4uZXhlVVQJAAP7K7VpeFKuaXV4CwABBOgDAAAE6AMAAE1aISFQSwECHgMKAAAAAABsfi5WFnBppQQAAAAEAAAACQAYAAAAAAABAAAApIEAAAAAZ2FtZS9ydW4uZXhlVVQFAAP7K7VpdXgLAAEE6AMAAAToAwAAUEsFBgAAAAABAAEATwAAAEcAAAAAAA=='));
    dm.items.addAll([
      DownloadItem(id: 'e1', catalogId: 11, slug: 'a', title: 'Extract Me', totalSize: 10, downloadedBytes: 10, status: DownloadStatus.done, needsExtract: true, savePath: zip.path),
      DownloadItem(id: 'd1', catalogId: 12, slug: 'b', title: 'Done Game', totalSize: 10, downloadedBytes: 10, status: DownloadStatus.done),
      DownloadItem(id: 'f1', catalogId: 13, slug: 'c', title: 'Failed Game', totalSize: 10, status: DownloadStatus.failed, error: 'x'),
      DownloadItem(id: 'e2', catalogId: 14, slug: 'd', title: 'Slow Game', totalSize: 1000, downloadedBytes: 10, status: DownloadStatus.downloading, downloadUrl: 'x', speed: 5, etaSecs: 4000),
    ]);
    await t.pumpWidget(wrap(const DownloadsScreen()));
    await t.pump();
    await tapAsync(t, find.text('Extract'));
    await t.tap(find.byIcon(Icons.check_circle_outline).first);
    await t.pump();
    await tapAsync(t, find.byIcon(Icons.play_arrow).first);
    await t.tap(find.byIcon(Icons.close).first);
    await t.pump();
    dm.items.clear();
  });

  testWidgets('library full flow', (t) async {
    final lib = LibraryStore.instance;
    lib.games.clear();
    lib.collections.clear();
    final g = LibraryGame(gameKey: 'k1', title: 'Lib Game', folderPath: Directory.systemTemp.createTempSync('sacrificial').path);
    lib.addGame(g);
    await t.pumpWidget(wrap(const LibraryScreen()));
    await t.pumpAndSettle();
    final before = lib.games.length;
    await tapAsync(t, find.text('Scan for Games'));
    expect(lib.games.length + lib.customGames.length, before + 1);
    await t.tap(find.text('New Collection'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).last, 'RPGs');
    await t.tap(find.text('Create'));
    await t.pumpAndSettle();
    expect(lib.collections.any((c) => c.name == 'RPGs'), true);
    await t.tap(find.byIcon(Icons.favorite_border).first);
    await t.pump();
    expect(lib.isFavorite('k1'), true);
    lib.collections.clear();
    await t.tap(find.byType(PopupMenuButton<String>).first);
    await t.pumpAndSettle();
    await t.tap(find.text('Collections'));
    await t.pumpAndSettle();
    expect(find.text('No collections yet.'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    lib.addCollection('RPGs');
    await t.tap(find.byType(PopupMenuButton<String>).first);
    await t.pumpAndSettle();
    await t.tap(find.text('Collections'));
    await t.pumpAndSettle();
    await t.tap(find.text('RPGs'));
    await t.pump();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    await t.tap(find.byType(PopupMenuButton<String>).first);
    await t.pumpAndSettle();
    await tapAsync(t, find.text('Set executable'));
    expect(g.exePath, isNotNull);
    await tapAsync(t, find.byIcon(Icons.play_arrow).first);
    await t.tap(find.byType(PopupMenuButton<String>).first);
    await t.pumpAndSettle();
    await tapAsync(t, find.text('Open folder'));
    await t.tap(find.byType(PopupMenuButton<String>).first);
    await t.pumpAndSettle();
    await tapAsync(t, find.text('Uninstall'));
    lib.games.clear();
    lib.collections.clear();
  });

  testWidgets('library search, filter, empty scan, play without exe', (t) async {
    final lib = LibraryStore.instance;
    lib.games.clear();
    lib.addGame(LibraryGame(gameKey: 'a', title: 'Alpha Lib', folderPath: '/tmp/picked', coverUrl: 'https://x/c.png'));
    lib.addGame(LibraryGame(gameKey: 'b', title: 'Beta Lib', folderPath: '/tmp/picked', exePath: '/tmp/picked/wine'));
    final cid = lib.addCollection('Col');
    lib.setGameCollections('a', [cid]);
    await t.pumpWidget(wrap(const LibraryScreen()));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, 'alpha');
    await t.pumpAndSettle();
    expect(find.text('Beta Lib'), findsNothing);
    await t.enterText(find.byType(TextField).first, '');
    await t.pumpAndSettle();
    await t.tap(find.text('All games'));
    await t.pumpAndSettle();
    await t.tap(find.text('Col').last);
    await t.pumpAndSettle();
    expect(find.text('Beta Lib'), findsNothing);
    expect(find.text('Alpha Lib'), findsOneWidget);
    await t.tap(find.text('Col'));
    await t.pumpAndSettle();
    await t.tap(find.text('All games').last);
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.play_arrow).first);
    await settle(t);
    FakeFilePicker.pickDir = Directory.systemTemp.createTempSync('emptydir').path;
    await tapAsync(t, find.text('Add Game'));
    await t.pumpAndSettle();
    expect(find.textContaining('No game executables'), findsOneWidget);
    FakeFilePicker.pickDir = null;
    await t.pumpAndSettle();
    GameRunner.protonOverride = () async => null;
    GameRunner.whichOverride = (n) async => null;
    final exe = File('${Directory.systemTemp.createTempSync('pe').path}/game.exe')..writeAsBytesSync([77, 90]);
    lib.addGame(LibraryGame(gameKey: 'c', title: 'Fail Game', folderPath: exe.parent.path, exePath: exe.path));
    await t.pumpAndSettle();
    final failTile = find.ancestor(of: find.text('Fail Game'), matching: find.byType(ListTile));
    await t.runAsync(() async {
      await t.tap(find.descendant(of: failTile, matching: find.byIcon(Icons.play_arrow)));
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await t.pump();
    expect(find.byType(SnackBar).evaluate().isNotEmpty || lib.byKey('c')!.lastPlayed == null, true);
    GameRunner.protonOverride = null;
    GameRunner.whichOverride = null;
    await t.pumpAndSettle();
    await t.tap(find.byType(PopupMenuButton<String>).first);
    await t.pumpAndSettle();
    await t.tap(find.text('Remove from library'));
    await t.pumpAndSettle();
    if (lib.games.isNotEmpty) {
      await t.tap(find.byType(PopupMenuButton<String>).first);
      await t.pumpAndSettle();
      await tapAsync(t, find.text('Uninstall'));
    }
    lib.games.clear();
    lib.collections.clear();
  });

  testWidgets('library uninstall removes game and folder', (t) async {
    final lib = LibraryStore.instance;
    lib.games.clear();
    final dir = Directory.systemTemp.createTempSync('uninstallme');
    lib.addGame(LibraryGame(gameKey: 'u1', title: 'U Game', folderPath: dir.path));
    await t.pumpWidget(wrap(const LibraryScreen()));
    await t.pumpAndSettle();
    await t.tap(find.byType(PopupMenuButton<String>).first);
    await t.pumpAndSettle();
    await t.tap(find.text('Uninstall'));
    await settle(t);
    expect(lib.byKey('u1'), isNull);
    expect(dir.existsSync(), false);
  });

  testWidgets('favorites remove with undo', (t) async {
    final lib = LibraryStore.instance;
    lib.addGame(LibraryGame(gameKey: 'f9', title: 'Undo Game', folderPath: '/x'));
    lib.setFavorite('f9', true);
    await t.pumpWidget(wrap(const FavoritesScreen()));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.heart_broken_outlined).first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.text('Undo'));
    await t.pump();
    await t.pumpAndSettle();
    expect(lib.isFavorite('f9'), true);
    lib.removeGame('f9');
  });

  testWidgets('settings all controls', (t) async {
    Settings.instance.setDownloadPath('/tmp/dl');
    await t.binding.setSurfaceSize(const Size(1400, 3000));
    await t.pumpWidget(wrap(const SettingsScreen()));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Choose').first);
    await tapAsync(t, find.text('Choose').first);
    await t.ensureVisible(find.byType(SwitchListTile).first);
    for (final sw in find.byType(SwitchListTile).evaluate().toList()) {
      await t.ensureVisible(find.byWidget(sw.widget));
      await t.tap(find.byWidget(sw.widget));
      await t.pump();
    }
    final dds = find.byType(DropdownButton<String>);
    for (var i = 0; i < dds.evaluate().length; i++) {
      await t.ensureVisible(dds.at(i));
      await t.pump();
      await t.tap(dds.at(i), warnIfMissed: false);
      await t.pumpAndSettle();
      await t.tap(find.byType(DropdownMenuItem<String>).last);
      await t.pumpAndSettle();
    }
    await t.ensureVisible(find.text('Check for updates'));
    await tapAsync(t, find.text('Check for updates'));
    final openUpdate = find.textContaining('on GitLab');
    if (openUpdate.evaluate().isNotEmpty) {
      await t.tap(openUpdate);
      await t.pumpAndSettle();
    }
    await tapAsync(t, find.text('Choose').last);
  });

  testWidgets('account sign in, refresh, test, report, logout', (t) async {
    Auth.instance.logout();
    Auth.instance.httpFactory = () => MockClient((req) async => http.Response(jsonEncode({'access_token': 'at', 'refresh_token': 'rt'}), 200));
    await t.binding.setSurfaceSize(const Size(1400, 2000));
    await t.pumpWidget(wrap(const AccountScreen()));
    await t.pumpAndSettle();
    await tapAsync(t, find.text('Sign in with UploadHaven'));
    await t.enterText(find.byType(TextField).last, 'authcode');
    await tapAsync(t, find.text('Sign in').last);
    await t.runAsync(() => Auth.instance.refreshProStatus());
    await t.pumpAndSettle();
    expect(Auth.instance.accessToken, 'at');
    expect(Auth.instance.pro.signedIn, true);
    await t.ensureVisible(find.text('Refresh status'));
    await tapAsync(t, find.text('Refresh status'));
    await tapAsync(t, find.text('Upgrade to Pro'));
    await t.ensureVisible(find.text('Run connectivity test'));
    await tapAsync(t, find.text('Run connectivity test'));
    expect(find.textContaining('Latency'), findsOneWidget);
    await t.ensureVisible(find.text('Send report'));
    await t.enterText(find.byType(TextField).last, 'bug text here');
    await tapAsync(t, find.text('Send report'));
    expect(find.textContaining('Report sent'), findsOneWidget);
    await tapAsync(t, find.text('Sign out'));
    expect(Auth.instance.accessToken, isNull);
    Auth.instance.httpFactory = null;
  });

  testWidgets('topbar window controls and hover', (t) async {
    await t.pumpWidget(wrap(const AppShell(page: 0, onNavigate: _noop, child: SizedBox())));
    await t.pumpAndSettle();
    final circles = find.descendant(
      of: find.byType(TopBar),
      matching: find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).shape == BoxShape.circle),
    );
    final gesture = await t.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    for (var i = 0; i < circles.evaluate().length; i++) {
      final c = t.getCenter(circles.at(i));
      await gesture.moveTo(c);
      await t.pump();
      await t.tapAt(c);
      await t.pump();
      await t.tapAt(c);
      await t.pump();
    }
    await gesture.moveTo(Offset.zero);
    await t.pump();
    await t.tap(find.text('SteamUnlocked Launcher'));
    await t.pump(const Duration(milliseconds: 50));
    await t.tap(find.text('SteamUnlocked Launcher'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.text('SteamUnlocked Launcher'));
    await t.pump(const Duration(milliseconds: 50));
    await t.tap(find.text('SteamUnlocked Launcher'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
  });

  testWidgets('help links and runtimes', (t) async {
    await t.pumpWidget(wrap(const HelpScreen()));
    await t.pumpAndSettle();
    for (final label in ['steamunlocked.org', 'uploadhaven.com']) {
      await t.tap(find.text(label));
      await t.pumpAndSettle();
    }
    expect(find.byType(HelpScreen), findsOneWidget);
  });
}
