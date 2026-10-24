import 'dart:convert';
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
import 'package:sumanager/services/downloads.dart';
import 'package:sumanager/services/library.dart';
import 'package:sumanager/services/settings.dart';
import 'package:sumanager/widgets/shell.dart';
import 'helpers.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: ThemeData(fontFamily: 'Noto Sans', brightness: Brightness.dark, useMaterial3: true),
      home: Scaffold(body: child),
    );

void main() {
  setUpAll(() async {
    await setupTestEnv();
    await Settings.instance.load();
    Api.clientFactory = () => MockClient((req) async {
          if (req.url.path.contains('catalog')) {
            return http.Response(jsonEncode({'has_more': false, 'games': [
              {'id': 1, 'slug': 'alpha', 'title': 'Alpha Game', 'cover_url': '', 'categories': ['RPG'], 'file_size': 1000000000, 'published_at': '2024-01-02'},
              {'id': 2, 'slug': 'beta', 'title': 'Beta Game', 'cover_url': '', 'categories': ['FPS'], 'file_size': 2000000000},
            ]}), 200);
          }
          if (req.url.path.contains('popularity')) {
            return http.Response(jsonEncode({'views': {'1': 500, '2': 900}}), 200);
          }
          return http.Response('{}', 404);
        });
  });
  tearDownAll(() => Api.clientFactory = null);

  testWidgets('full app shows welcome then shell', (t) async {
    Settings.instance.welcomeShown = false;
    await t.pumpWidget(const SuManagerApp());
    expect(find.byType(WelcomeScreen), findsOneWidget);
    await t.tap(find.text('Skip for now'));
    await t.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(BrowseScreen), findsOneWidget);
  });

  testWidgets('shell navigates to each page', (t) async {
    Settings.instance.welcomeShown = true;
    var page = 0;
    await t.pumpWidget(wrap(AppShell(
      title: 'Browse', page: page, onNavigate: (i) => page = i,
      child: const SizedBox(),
    )));
    for (final label in ['Downloads', 'Library', 'Favorites', 'Account', 'Settings', 'Help']) {
      await t.tap(find.text(label));
      await t.pump();
    }
    expect(page, 6);
  });

  testWidgets('browse loads, searches, sorts, opens dialog', (t) async {
    await t.pumpWidget(wrap(const BrowseScreen()));
    await t.pumpAndSettle();
    expect(find.text('Alpha Game'), findsOneWidget);
    expect(find.text('Beta Game'), findsOneWidget);
    await t.enterText(find.byType(TextField).first, 'alpha');
    await t.pumpAndSettle();
    expect(find.text('Beta Game'), findsNothing);
    await t.tap(find.text('Alpha Game'));
    await t.pumpAndSettle();
    expect(find.byType(GameDialog), findsOneWidget);
    expect(find.text('Size: 1.0 GB'), findsOneWidget);
    await t.tap(find.text('Close'));
    await t.pumpAndSettle();
  });

  testWidgets('browse error state', (t) async {
    Api.clientFactory = () => MockClient((req) async => http.Response('err', 500));
    await t.pumpWidget(wrap(const BrowseScreen()));
    await t.pumpAndSettle();
    expect(find.textContaining('Could not load'), findsOneWidget);
    await t.tap(find.text('Retry'));
    await t.pumpAndSettle();
  });

  testWidgets('downloads renders items', (t) async {
    final dm = DownloadManager.instance;
    dm.items.add(DownloadItem(id: 'w1', catalogId: 1, slug: 's', title: 'Widget Game', totalSize: 100, downloadedBytes: 40, status: DownloadStatus.downloading, downloadUrl: 'u'));
    await t.pumpWidget(wrap(const DownloadsScreen()));
    await t.pump();
    expect(find.text('Widget Game'), findsOneWidget);
    await t.tap(find.byIcon(Icons.pause));
    await t.pump();
    expect(dm.items.first.status, DownloadStatus.paused);
    dm.items.clear();
  });

  testWidgets('library renders and dialogs', (t) async {
    LibraryStore.instance.addGame(LibraryGame(gameKey: 'k', title: 'Lib Game', folderPath: '/tmp/x'));
    await t.pumpWidget(wrap(const LibraryScreen()));
    await t.pumpAndSettle();
    expect(find.text('Lib Game'), findsOneWidget);
    await t.tap(find.byType(PopupMenuButton<String>).first);
    await t.pumpAndSettle();
    await t.tap(find.text('Remove from library').last);
    await t.pumpAndSettle();
  });

  testWidgets('favorites empty and populated', (t) async {
    LibraryStore.instance.addGame(LibraryGame(gameKey: 'f1', title: 'Fav Game', folderPath: '/x'));
    LibraryStore.instance.setFavorite('f1', true);
    await t.pumpWidget(wrap(const FavoritesScreen()));
    await t.pumpAndSettle();
    expect(find.text('Fav Game'), findsOneWidget);
    LibraryStore.instance.removeGame('f1');
  });

  testWidgets('settings toggles', (t) async {
    await t.pumpWidget(wrap(const SettingsScreen()));
    await t.pumpAndSettle();
    expect(find.textContaining('Download'), findsWidgets);
    await t.tap(find.byType(SwitchListTile).first);
    await t.pump();
  });

  testWidgets('help renders', (t) async {
    await t.pumpWidget(wrap(const HelpScreen()));
    await t.pumpAndSettle();
    expect(find.byType(HelpScreen), findsOneWidget);
  });

  testWidgets('account renders', (t) async {
    await t.pumpWidget(wrap(const AccountScreen()));
    await t.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);
  });

  test('fmtBytes', () {
    expect(GameCard.fmtBytes(2000000000), '2.0 GB');
    expect(GameCard.fmtBytes(2000000), '2 MB');
    expect(GameCard.fmtBytes(2000), '2 KB');
  });
}
