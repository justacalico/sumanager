import 'dart:async';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models.dart';
import 'api.dart';
import 'settings.dart';
import 'auth.dart';

class DownloadManager extends ChangeNotifier {
  static final DownloadManager instance = DownloadManager._();
  DownloadManager._();

  final List<DownloadItem> items = [];
  final Map<String, http.Client> _clients = {};
  final Map<String, bool> _cancel = {};
  Timer? _ticker;
  bool _loaded = false;

  int get activeCount => items.where((i) => i.status == DownloadStatus.downloading || i.status == DownloadStatus.extracting).length;
  int get maxConcurrent => Auth.instance.pro.isPro ? Settings.instance.maxConcurrent : 1;
  int get chunkCount => Auth.instance.pro.isPro ? 8 : 2;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final j = await Settings.instance.readJson('downloads.json');
    for (final d in (j['items'] as List? ?? [])) {
      final item = DownloadItem.fromJson(Map<String, dynamic>.from(d));
      if (item.status == DownloadStatus.downloading || item.status == DownloadStatus.resolving) {
        item.status = DownloadStatus.paused;
      }
      items.add(item);
    }
    notifyListeners();
    _pump();
  }

  Future<void> save() async {
    await Settings.instance.writeJson('downloads.json', {'items': items.map((i) => i.toJson()).toList()});
  }

  void _pump() {
    for (final q in items.where((i) => i.status == DownloadStatus.queued)) {
      if (activeCount >= maxConcurrent) break;
      _start(q);
    }
    _ticker ??= Timer.periodic(const Duration(seconds: 2), (_) { notifyListeners(); save(); });
  }

  bool isQueuedOrDone(int catalogId) => items.any((i) => i.catalogId == catalogId && i.status != DownloadStatus.cancelled && i.status != DownloadStatus.failed);

  Future<DownloadItem?> queue(CatalogGame g) async {
    if (isQueuedOrDone(g.id)) return null;
    final item = DownloadItem(
      id: '${g.id}-${DateTime.now().millisecondsSinceEpoch}',
      catalogId: g.id,
      slug: g.slug,
      title: g.title,
      coverUrl: g.coverUrl,
      totalSize: g.fileSize,
      status: DownloadStatus.queued,
      addedAt: DateTime.now().millisecondsSinceEpoch,
    );
    items.add(item);
    notifyListeners();
    _pump();
    save();
    return item;
  }

  Future<void> _start(DownloadItem item) async {
    item.status = DownloadStatus.resolving;
    notifyListeners();
    final url = item.downloadUrl ?? await Api.resolveToken(item.catalogId, item.slug, bearer: Auth.instance.accessToken);
    if (url == null) {
      item.status = DownloadStatus.failed;
      item.error = 'Could not resolve a download link';
      notifyListeners();
      _pump();
      return;
    }
    item.downloadUrl = url;
    item.status = DownloadStatus.downloading;
    _cancel[item.id] = false;
    notifyListeners();
    unawaited(_download(item, url));
  }

  Future<void> _download(DownloadItem item, String url) async {
    final dir = Settings.instance.downloadPath.isEmpty ? null : Directory(Settings.instance.downloadPath);
    if (dir == null) {
      item.status = DownloadStatus.failed;
      item.error = 'Choose a download folder in Settings first';
      notifyListeners();
      return;
    }
    await dir.create(recursive: true);
    final safe = item.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final zipPath = '${dir.path}${Platform.pathSeparator}$safe.zip';
    item.savePath = zipPath;
    try {
      final head = await http.head(Uri.parse(url));
      if (item.totalSize <= 0) {
        item.totalSize = int.tryParse(head.headers['content-length'] ?? '') ?? 0;
      }
      final f = File(zipPath);
      final existed = await f.exists() ? await f.length() : 0;
      item.downloadedBytes = existed;
      if (item.totalSize > 0 && existed >= item.totalSize) {
        item.downloadedBytes = item.totalSize;
        item.status = DownloadStatus.done;
        item.needsExtract = true;
        notifyListeners();
        _pump();
        return;
      }
      final chunks = chunkCount;
      final chunkSize = item.totalSize > 0 ? (item.totalSize / chunks).ceil() : 0;
      final start = item.downloadedBytes;
      final client = http.Client();
      _clients[item.id] = client;
      final sw = Stopwatch()..start();
      var lastBytes = start;

      Future<void> fetchChunk(int idx) async {
        var from = start + idx * chunkSize;
        var to = chunkSize > 0 ? (idx == chunks - 1 ? item.totalSize - 1 : from + chunkSize - 1) : -1;
        if (item.totalSize > 0 && from > to) return;
        final part = File('$zipPath.part$idx');
        if (await part.exists()) {
          final plen = await part.length();
          from += plen;
          item.downloadedBytes += 0; // already counted via existed
        }
        while (from <= to || to < 0) {
          if (_cancel[item.id] == true) return;
          final req = http.Request('GET', Uri.parse(url));
          if (to >= 0) req.headers['Range'] = 'bytes=$from-$to';
          final res = await client.send(req).timeout(const Duration(seconds: 30));
          if (res.statusCode != 200 && res.statusCode != 206) {
            throw Exception('Chunk $idx got HTTP ${res.statusCode}');
          }
          final sink = part.openWrite(mode: FileMode.append);
          await for (final b in res.stream) {
            if (_cancel[item.id] == true) { await sink.close(); return; }
            sink.add(b);
            from += b.length;
            item.downloadedBytes += b.length;
            if (sw.elapsedMilliseconds > 500) {
              item.speed = (item.downloadedBytes - lastBytes) / (sw.elapsedMilliseconds / 1000);
              lastBytes = item.downloadedBytes;
              sw.reset();
              if (item.totalSize > 0 && item.speed > 0) item.etaSecs = ((item.totalSize - item.downloadedBytes) / item.speed).round();
            }
          }
          await sink.close();
          if (to < 0) break;
        }
        item.chunksDone++;
        notifyListeners();
      }

      item.chunksTotal = chunkSize > 0 ? chunks : 1;
      await Future.wait(List.generate(item.chunksTotal, fetchChunk));

      if (_cancel[item.id] == true) return;
      // join parts
      final out = f.openWrite();
      for (var i = 0; i < item.chunksTotal; i++) {
        final p = File('$zipPath.part$i');
        if (await p.exists()) {
          await out.addStream(p.openRead());
          await p.delete();
        }
      }
      await out.close();
      item.downloadedBytes = await f.length();
      item.status = DownloadStatus.done;
      item.needsExtract = true;
      notifyListeners();
      save();
      if (Settings.instance.autoExtract) await extract(item);
      _pump();
    } catch (e) {
      if (_cancel[item.id] == true) return;
      item.status = DownloadStatus.failed;
      item.error = '$e';
      notifyListeners();
      _pump();
    } finally {
      _clients.remove(item.id)?.close();
    }
  }

  Future<void> extract(DownloadItem item) async {
    if (item.savePath.isEmpty || !await File(item.savePath).exists()) return;
    item.status = DownloadStatus.extracting;
    notifyListeners();
    try {
      final dest = item.savePath.replaceAll(RegExp(r'\.zip$'), '');
      final bytes = await File(item.savePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      item.extractTotal = archive.length;
      for (final file in archive) {
        item.extractDone++;
        if (item.extractDone % 20 == 0) notifyListeners();
        if (!file.isFile) continue;
        final out = File('$dest${Platform.pathSeparator}${file.name}');
        await out.parent.create(recursive: true);
        await out.writeAsBytes(file.content as List<int>);
      }
      item.gameFolder = dest;
      item.status = DownloadStatus.done;
      item.needsExtract = false;
      if (Settings.instance.removeWhenDone) await File(item.savePath).delete();
      notifyListeners();
      save();
    } catch (e) {
      item.status = DownloadStatus.done;
      item.needsExtract = true;
      item.error = 'Extraction failed: $e';
      notifyListeners();
    }
    _pump();
  }

  Future<void> pause(DownloadItem i) async {
    _cancel[i.id] = true;
    _clients[i.id]?.close();
    if (i.status == DownloadStatus.downloading || i.status == DownloadStatus.resolving) {
      i.status = DownloadStatus.paused;
    }
    notifyListeners();
    save();
  }

  Future<void> resume(DownloadItem i) async {
    if (i.status != DownloadStatus.paused && i.status != DownloadStatus.failed && i.status != DownloadStatus.cancelled) return;
    _cancel[i.id] = false;
    if (i.status == DownloadStatus.failed && i.downloadUrl == null) {
      i.status = DownloadStatus.queued;
      notifyListeners();
      _pump();
      return;
    }
    i.error = null;
    i.status = DownloadStatus.downloading;
    notifyListeners();
    if (i.downloadUrl != null) unawaited(_download(i, i.downloadUrl!));
  }

  Future<void> cancel(DownloadItem i) async {
    _cancel[i.id] = true;
    _clients[i.id]?.close();
    i.status = DownloadStatus.cancelled;
    notifyListeners();
    save();
    _pump();
  }

  Future<void> remove(DownloadItem i) async {
    await cancel(i);
    items.remove(i);
    notifyListeners();
    save();
  }

  void setMaxConcurrent(int v) {
    Settings.instance.setMaxConcurrent(v);
    notifyListeners();
    _pump();
  }
}
