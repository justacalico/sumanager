import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart';

class UpdateChecker {
  static const releasesApi = 'https://gitlab.com/api/v4/projects/HttpAnimations%2Fsumanager/releases?per_page=100&order_by=released_at&sort=desc';
  static const releasesPage = 'https://gitlab.com/HttpAnimations/sumanager/-/releases';

  static UpdateInfo? _cached;
  static Future<UpdateInfo?>? _pending;

  static Future<UpdateInfo?> check(String currentVersion, {http.Client? client}) {
    _pending ??= _doCheck(currentVersion, client).whenComplete(() => _pending = null);
    return _pending!;
  }

  static Future<UpdateInfo?> _doCheck(String currentVersion, http.Client? client) async {
    final c = client ?? http.Client();
    try {
      final r = await c.get(Uri.parse(releasesApi)).timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return null;
      final list = jsonDecode(r.body) as List;
      UpdateInfo? best;
      Version? bestV;
      for (final rel in list) {
        final tag = rel['tag_name'] ?? '';
        final v = Version.parse(tag);
        if (v == null) continue;
        if (bestV == null || v.compareTo(bestV) > 0) {
          bestV = v;
          best = UpdateInfo(version: tag.replaceFirst('v', ''), tag: tag, url: '$releasesPage/$tag', notes: rel['description']?.toString(), pubDate: rel['released_at']?.toString());
        }
      }
      final cur = Version.parse(currentVersion);
      if (best == null || cur == null) return null;
      _cached = bestV!.compareTo(cur) > 0 ? best : null;
      return _cached;
    } catch (_) {
      return null;
    } finally {
      if (client == null) c.close();
    }
  }
}
