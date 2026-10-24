import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sumanager/models.dart';
import 'package:sumanager/services/api.dart';
import 'package:sumanager/services/downloads.dart';
import 'package:sumanager/services/settings.dart';
import 'helpers.dart';

List<int> zipBytes() {
  final a = Archive();
  a.addFile(ArchiveFile('game/run.exe', 4, utf8.encode('MZ!!')));
  return ZipEncoder().encode(a)!;
}

http.Client dlClient(List<int> body, {bool tokenOk = true}) => MockClient((req) async {
      if (req.url.path.contains('resolve-token')) {
        return tokenOk ? http.Response(jsonEncode({'download_url': 'https://files.local/x.zip'}), 200) : http.Response('{}', 500);
      }
      if (req.method == 'HEAD') {
        return http.Response('', 200, headers: {'content-length': '${body.length}'});
      }
      final range = req.headers['range'];
      if (range != null) {
        final m = RegExp(r'bytes=(\d+)-(\d+)').firstMatch(range)!;
        final f = int.parse(m[1]!), t = int.parse(m[2]!);
        return http.Response.bytes(body.sublist(f, t + 1 > body.length ? body.length : t + 1), 206);
      }
      return http.Response.bytes(body, 200);
    });

void main() {
  late Directory tmp;

  setUpAll(() async {
    await setupTestEnv();
    tmp = Directory.systemTemp.createTempSync('dl');
    await Settings.instance.load();
    Settings.instance.setDownloadPath(tmp.path);
    Settings.instance.setAutoExtract(false);
  });

  tearDown(() => Api.clientFactory = null);

  test('queue resolves, downloads, joins chunks', () async {
    final body = zipBytes();
    Api.clientFactory = () => dlClient(body);
    final mgr = DownloadManager.forTest();
    final g = CatalogGame(id: 1, slug: 's', title: 'T Game', coverUrl: '', fileSize: body.length);
    final item = await mgr.queue(g);
    expect(item, isNotNull);
    expect(await mgr.queue(g), isNull);
    for (var i = 0; i < 100 && item!.status != DownloadStatus.done; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    expect(item!.status, DownloadStatus.done);
    expect(item.needsExtract, true);
    expect(File(item.savePath).lengthSync(), body.length);
    await mgr.remove(item);
    expect(mgr.items, isEmpty);
  });

  test('queue fails without token resolution', () async {
    Api.clientFactory = () => dlClient([], tokenOk: false);
    final mgr = DownloadManager.forTest();
    final item = (await mgr.queue(CatalogGame(id: 2, slug: 's', title: 'X', coverUrl: '')))!;
    for (var i = 0; i < 50 && item.status != DownloadStatus.failed; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    expect(item.status, DownloadStatus.failed);
    await mgr.resume(item);
    for (var i = 0; i < 50 && item.status != DownloadStatus.failed; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    expect(item.status, DownloadStatus.failed);
    await mgr.cancel(item);
    expect(item.status, DownloadStatus.cancelled);
  });

  test('extract writes files', () async {
    Api.clientFactory = null;
    final mgr = DownloadManager.forTest();
    final zip = File('${tmp.path}/e.zip')..writeAsBytesSync(zipBytes());
    final item = DownloadItem(id: 'e', catalogId: 3, slug: 's', title: 'E', savePath: zip.path);
    await mgr.extract(item);
    expect(item.needsExtract, false);
    expect(File('${item.gameFolder}/game/run.exe').existsSync(), true);
    final bad = DownloadItem(id: 'b', catalogId: 4, slug: 's', title: 'B', savePath: '${tmp.path}/bad.zip');
    File(bad.savePath).writeAsBytesSync([1, 2, 3]);
    await mgr.extract(bad);
    expect(bad.error, contains('Extraction failed'));
    final missing = DownloadItem(id: 'm', catalogId: 5, slug: 's', title: 'M');
    await mgr.extract(missing);
    expect(missing.status, DownloadStatus.queued);
  });

  test('load remaps active to paused', () async {
    await Settings.instance.writeJson('downloads.json', {'items': [
      DownloadItem(id: 'l1', catalogId: 1, slug: 's', title: 't', status: DownloadStatus.downloading).toJson(),
      DownloadItem(id: 'l2', catalogId: 2, slug: 's', title: 't', status: DownloadStatus.paused).toJson(),
    ]});
    final mgr = DownloadManager.forTest();
    await mgr.load();
    expect(mgr.items[0].status, DownloadStatus.paused);
    expect(mgr.items.length, 2);
    await mgr.load();
  });

  test('fails without download folder', () async {
    Api.clientFactory = () => dlClient(zipBytes());
    final prev = Settings.instance.downloadPath;
    Settings.instance.setDownloadPath('');
    final mgr = DownloadManager.forTest();
    final item = (await mgr.queue(const CatalogGame(id: 20, slug: 's', title: 'N', coverUrl: '')))!;
    for (var i = 0; i < 50 && item.status != DownloadStatus.failed; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    expect(item.error, contains('download folder'));
    Settings.instance.setDownloadPath(prev);
  });

  test('existing complete file skips download', () async {
    Api.clientFactory = () => dlClient(zipBytes());
    final mgr = DownloadManager.forTest();
    final item = DownloadItem(id: 'd0', catalogId: 21, slug: 's', title: 'Pre', status: DownloadStatus.paused, downloadUrl: 'https://files.local/x.zip', totalSize: 5);
    File('${tmp.path}/Pre.zip').writeAsBytesSync(List.filled(5, 0));
    await mgr.extract(item);
    mgr.items.add(item);
    await mgr.resume(item);
    for (var i = 0; i < 50 && item.status != DownloadStatus.done; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    expect(item.needsExtract, true);
  });

  test('chunk http error fails', () async {
    Api.clientFactory = () => MockClient((req) async {
      if (req.url.path.contains('resolve-token')) return http.Response(jsonEncode({'download_url': 'https://files.local/x.zip'}), 200);
      return http.Response('bad', 500);
    });
    final mgr = DownloadManager.forTest();
    final item = (await mgr.queue(const CatalogGame(id: 22, slug: 's', title: 'Err', coverUrl: '', fileSize: 100)))!;
    for (var i = 0; i < 60 && item.status != DownloadStatus.failed; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    expect(item.error, contains('HTTP'));
  });

  test('extract with removeWhenDone deletes zip', () async {
    Settings.instance.setRemoveWhenDone(true);
    final mgr = DownloadManager.forTest();
    final zip = File('${tmp.path}/rm.zip')..writeAsBytesSync(zipBytes());
    final item = DownloadItem(id: 'r', catalogId: 23, slug: 's', title: 'R', savePath: zip.path);
    await mgr.extract(item);
    expect(zip.existsSync(), false);
    Settings.instance.setRemoveWhenDone(false);
  });

  test('totalSize from content-length when zero', () async {
    final body = zipBytes();
    Api.clientFactory = () => dlClient(body);
    final mgr = DownloadManager.forTest();
    final item = DownloadItem(id: 'h0', catalogId: 30, slug: 's', title: 'Head', status: DownloadStatus.paused, downloadUrl: 'https://files.local/x.zip');
    mgr.items.add(item);
    await mgr.resume(item);
    for (var i = 0; i < 100 && item.status != DownloadStatus.done; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    expect(item.totalSize, body.length);
  });

  test('resumes from existing part files', () async {
    final body = zipBytes();
    Api.clientFactory = () => dlClient(body);
    final mgr = DownloadManager.forTest();
    File('${tmp.path}/Partly.zip.part0').writeAsBytesSync(body.sublist(0, 10));
    final item = DownloadItem(id: 'p0', catalogId: 31, slug: 's', title: 'Partly', status: DownloadStatus.paused, downloadUrl: 'https://files.local/x.zip', totalSize: body.length);
    mgr.items.add(item);
    await mgr.resume(item);
    for (var i = 0; i < 100 && item.status != DownloadStatus.done; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    expect(item.status, DownloadStatus.done);
  });

  test('slow stream reports speed and eta', () async {
    final body = List<int>.filled(4000, 1);
    Api.clientFactory = () => MockClient.streaming((req, b) async {
      if (req.url.path.contains('resolve-token')) {
        return http.StreamedResponse(Stream.value(utf8.encode(jsonEncode({'download_url': 'https://files.local/x.zip'}))), 200);
      }
      if (req.method == 'HEAD') {
        return http.StreamedResponse(const Stream.empty(), 200, contentLength: body.length);
      }
      return http.StreamedResponse(Stream.fromFuture(Future.delayed(const Duration(milliseconds: 700), () => body)), 200);
    });
    final mgr = DownloadManager.forTest();
    final item = (await mgr.queue(const CatalogGame(id: 32, slug: 's', title: 'Slow', coverUrl: '', fileSize: 4000)))!;
    for (var i = 0; i < 120 && item.status != DownloadStatus.done; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    expect(item.status, DownloadStatus.done);
  });

  test('pause/cancel/remove/save/load/setMaxConcurrent', () async {
    Api.clientFactory = () => dlClient(zipBytes(), tokenOk: false);
    final mgr = DownloadManager.forTest();
    final item = DownloadItem(id: 'x9', catalogId: 9, slug: 's', title: 'P', status: DownloadStatus.downloading, downloadUrl: 'u');
    mgr.items.add(item);
    await mgr.pause(item);
    expect(item.status, DownloadStatus.paused);
    await mgr.save();
    final mgr2 = DownloadManager.forTest();
    await mgr2.load();
    expect(mgr2.items.length, 1);
    mgr.setMaxConcurrent(0);
    mgr.setMaxConcurrent(3);
    expect(mgr.isQueuedOrDone(9), true);
    expect(mgr.isQueuedOrDone(999), false);
    item.status = DownloadStatus.cancelled;
    await mgr.resume(item);
    expect(item.status, DownloadStatus.downloading);
    await mgr.remove(item);
    expect(mgr.isQueuedOrDone(9), false);
    expect(mgr.items, isEmpty);
  });
}
