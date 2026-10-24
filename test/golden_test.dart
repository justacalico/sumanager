import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
import 'package:sumanager/services/downloads.dart';
import 'package:sumanager/services/library.dart';
import 'package:sumanager/services/settings.dart';
import 'package:sumanager/l10n/app_localizations.dart';
import 'helpers.dart';

ThemeData theme() => ThemeData(
      fontFamily: 'Noto Sans',
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B8DEF), brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF141419),
      useMaterial3: true,
      cardColor: const Color(0xFF1D1D26),
    );

Future<void> snap(WidgetTester t, Widget child, String name) async {
  await t.binding.setSurfaceSize(const Size(1280, 800));
  await t.pumpWidget(MaterialApp(theme: theme(), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: child)));
  await t.pumpAndSettle();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

void main() {
  setUpAll(() async {
    await setupTestEnv();
    await Settings.instance.load();
    Api.clientFactory = () => MockClient((req) async {
          if (req.url.path.contains('catalog')) {
            return http.Response(jsonEncode({'has_more': false, 'games': [
              {'id': 1, 'slug': 'alpha', 'title': 'Alpha Game', 'categories': ['RPG'], 'file_size': 1000000000, 'published_at': '2024-01-02'},
              {'id': 2, 'slug': 'beta', 'title': 'Beta Game', 'categories': ['FPS'], 'file_size': 2000000000},
            ]}), 200);
          }
          if (req.url.path.contains('popularity')) return http.Response(jsonEncode({'views': {'1': 500}}), 200);
          return http.Response('{}', 404);
        });
  });
  tearDownAll(() => Api.clientFactory = null);

  testWidgets('welcome', (t) => snap(t, WelcomeScreen(onDone: () {}), 'welcome'));
  testWidgets('browse', (t) => snap(t, const BrowseScreen(), 'browse'));

  testWidgets('downloads', (t) async {
    final dm = DownloadManager.instance;
    dm.items.addAll([
      DownloadItem(id: 'd1', catalogId: 1, slug: 'a', title: 'Downloading Game', totalSize: 100, downloadedBytes: 40, status: DownloadStatus.downloading, downloadUrl: 'x'),
      DownloadItem(id: 'd2', catalogId: 2, slug: 'b', title: 'Done Game', totalSize: 100, downloadedBytes: 100, status: DownloadStatus.done),
    ]);
    await snap(t, const DownloadsScreen(), 'downloads');
    dm.items.clear();
  });

  testWidgets('library', (t) async {
    LibraryStore.instance.addGame(LibraryGame(gameKey: 'g1', title: 'Library Game', folderPath: '/tmp/x', playSeconds: 3600));
    await snap(t, const LibraryScreen(), 'library');
  });

  testWidgets('favorites', (t) async {
    LibraryStore.instance.setFavorite('g1', true);
    await snap(t, const FavoritesScreen(), 'favorites');
  });

  testWidgets('account', (t) => snap(t, const AccountScreen(), 'account'));
  testWidgets('settings', (t) => snap(t, const SettingsScreen(), 'settings'));
  testWidgets('help', (t) => snap(t, const HelpScreen(), 'help'));
}
