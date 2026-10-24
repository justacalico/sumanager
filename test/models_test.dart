import 'package:flutter_test/flutter_test.dart';
import 'package:sumanager/models.dart';

void main() {
  test('CatalogGame full json roundtrip', () {
    final g = CatalogGame.fromJson({
      'id': '7', 'slug': 's', 'title': 'X Free Download (v2.0)', 'cover_url': 'c',
      'categories': ['A'], 'file_size': '100', 'uncensored': true,
      'published_at': 1, 'updated_at': 2, 'recently_updated': true,
    });
    expect(g.title, 'X');
    expect(g.uncensored, true);
    expect(g.recentlyUpdated, true);
    final j = g.toJson();
    expect(CatalogGame.fromJson(j).id, 7);
  });

  test('DownloadItem json roundtrip and progress', () {
    final d = DownloadItem(id: 'a', catalogId: 1, slug: 's', title: 't', totalSize: 200, downloadedBytes: 50,
        status: DownloadStatus.downloading, error: 'e', chunksTotal: 2, chunksDone: 1, needsExtract: true,
        extractDone: 3, extractTotal: 9, gameFolder: 'f', downloadUrl: 'u', addedAt: 9);
    expect(d.progress, 0.25);
    final d2 = DownloadItem.fromJson(d.toJson());
    expect(d2.status, DownloadStatus.downloading);
    expect(d2.needsExtract, true);
    expect(DownloadItem.fromJson({'id': 'x', 'status': 'bogus'}).status, DownloadStatus.paused);
    expect(DownloadItem(id: 'z', catalogId: 0, slug: '', title: '', totalSize: 0).progress, 0);
  });

  test('LibraryGame/Collection/ProStatus/UpdateInfo/ConnectivityResult', () {
    final g = LibraryGame(gameKey: 'k', title: 't', folderPath: 'p', exePath: 'e', catalogId: 2,
        coverUrl: 'c', lastPlayed: 1, playSeconds: 5, isCustom: true, collectionIds: ['a']);
    final g2 = LibraryGame.fromJson(g.toJson());
    expect(g2.isCustom, true);
    expect(g2.collectionIds, ['a']);
    final c = GameCollection(id: 'i', name: 'n', gameKeys: ['k']);
    expect(GameCollection.fromJson(c.toJson()).name, 'n');
    expect(const ProStatus(signedIn: true, isPro: true, email: 'e', userId: 'u', expiresAt: 'x').isPro, true);
    const u = UpdateInfo(version: '1', tag: 'v1', url: 'u', notes: 'n', pubDate: 'p');
    expect(u.tag, 'v1');
    final cr = ConnectivityResult(dnsOk: true, tcpOk: true, tlsOk: true, apiOk: true, latencyMs: 5, errorDetail: 'x');
    expect(cr.apiOk, true);
  });

  test('Version edge cases', () {
    expect(Version.parse('1.0.0')!.compareTo(Version.parse('1.0.1')!), lessThan(0));
    expect(Version.parse('2')!.compareTo(Version.parse('1.9.9')!), greaterThan(0));
    expect(const Version([1]).compareTo(const Version([1, 0])), 0);
    expect(Version.parse('  v3.4.5  ')!.parts, [3, 4, 5]);
  });
}
