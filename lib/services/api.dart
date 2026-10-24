import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models.dart';

class Api {
  static const suBase = 'https://steamunlocked.org';
  static const uhBase = 'https://api.uploadhaven.com';
  static const launcherKey = 'su-launcher-v1-8f3k9x2m7pqw4';
  static const launcherVersion = '0.4.2';

  static http.Client Function()? clientFactory;
  static http.Client newClient() => clientFactory?.call() ?? http.Client();

  static Map<String, String> get _headers => {
        'X-Launcher-Key': launcherKey,
        'X-Launcher-Version': launcherVersion,
        'User-Agent': 'SteamUnlocked-Launcher/$launcherVersion',
      };

  static String _uuid() {
    final r = Random.secure();
    String h(int n, int w) => r.nextInt(1 << (w * 4)).toRadixString(16).padLeft(w, '0');
    return '${h(0, 4)}${h(0, 4)}-${h(0, 4)}-4${h(0, 3)}-${(8 + r.nextInt(4)).toRadixString(16)}${h(0, 3)}-${h(0, 4)}${h(0, 4)}${h(0, 4)}';
  }

  static Future<Map<String, dynamic>> fetchCatalogSync({int? lastSync, http.Client? client}) async {
    final c = client ?? newClient();
    try {
      var url = '$suBase/wp-json/launcher/v2/catalog?run=${_uuid()}';
      if (lastSync != null && lastSync > 0) url += '&since=$lastSync';
      final games = <CatalogGame>[];
      var after = 0;
      var syncTime = 0;
      var hasMore = true;
      var guard = 0;
      while (hasMore && guard++ < 40) {
        final r = await c.get(Uri.parse('$url&after=$after'), headers: _headers).timeout(const Duration(seconds: 60));
        if (r.statusCode != 200) {
          if (games.isEmpty) throw Exception('HTTP ${r.statusCode}');
          break;
        }
        final j = jsonDecode(r.body);
        games.addAll((j['games'] as List? ?? []).map((g) => CatalogGame.fromJson(g)));
        hasMore = j['has_more'] == true;
        after = j['next_after'] is int ? j['next_after'] : int.tryParse('${j['next_after']}') ?? after;
        syncTime = j['sync_time'] is int ? j['sync_time'] : int.tryParse('${j['sync_time']}') ?? syncTime;
      }
      return {'games': games, 'sync_time': syncTime};
    } finally {
      if (client == null) c.close();
    }
  }

  static Future<List<CatalogGame>> fetchCatalog({String? search, http.Client? client}) async {
    final r = await fetchCatalogSync(client: client);
    var games = r['games'] as List<CatalogGame>;
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      games = games.where((g) => g.title.toLowerCase().contains(q)).toList();
    }
    return games;
  }

  static Future<Map<int, int>> fetchPopularity({http.Client? client}) async {
    final c = client ?? newClient();
    try {
      final r = await c.get(Uri.parse('$suBase/wp-json/launcher/v1/popularity'), headers: _headers).timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return {};
      final j = jsonDecode(r.body);
      final map = <int, int>{};
      if (j is Map) {
        final items = j['views'] ?? j['games'] ?? j;
        if (items is Map) items.forEach((k, v) => map[int.tryParse('$k') ?? 0] = v is int ? v : int.tryParse('$v') ?? 0);
        if (items is List) {
          for (final e in items) {
            if (e is Map) map[e['id'] ?? e['catalog_id'] ?? 0] = e['views'] ?? 0;
          }
        }
      }
      return map;
    } catch (_) {
      return {};
    } finally {
      if (client == null) c.close();
    }
  }

  static Future<String?> resolveToken(int catalogId, String slug, {String? bearer, http.Client? client}) async {
    final c = client ?? newClient();
    try {
      final h = {..._headers, 'Content-Type': 'application/json'};
      if (bearer != null) h['Authorization'] = 'Bearer $bearer';
      final r = await c.post(
        Uri.parse('$uhBase/api/launcher/resolve-token'),
        headers: h,
        body: jsonEncode({'catalog_id': catalogId, 'slug': slug}),
      ).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(r.body);
      return j['download_url'] ?? j['url'] ?? j['token'];
    } catch (_) {
      return null;
    } finally {
      if (client == null) c.close();
    }
  }

  static Future<ProStatus> fetchAccount(String bearer, {http.Client? client}) async {
    final c = client ?? newClient();
    try {
      final r = await c.get(Uri.parse('$uhBase/api/launcher/me'), headers: {..._headers, 'Authorization': 'Bearer $bearer'}).timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return const ProStatus();
      final j = jsonDecode(r.body);
      return ProStatus(
        signedIn: true,
        isPro: j['is_premium'] == true || j['premium'] == true || j['is_pro'] == true,
        email: j['email']?.toString(),
        userId: (j['user_id'] ?? j['id'])?.toString(),
        expiresAt: (j['expires_at'] ?? j['pro_expires_at'])?.toString(),
      );
    } catch (_) {
      return const ProStatus();
    } finally {
      if (client == null) c.close();
    }
  }

  static Future<ConnectivityResult> connectivityTest({http.Client? client}) async {
    final res = ConnectivityResult();
    final c = client ?? newClient();
    final sw = Stopwatch()..start();
    try {
      res.dnsOk = true;
      final sock = await c.get(Uri.parse('$uhBase/api/launcher/health'), headers: _headers).timeout(const Duration(seconds: 10));
      res.tcpOk = true;
      res.tlsOk = true;
      res.apiOk = sock.statusCode < 500;
      res.latencyMs = sw.elapsedMilliseconds;
    } catch (e) {
      res.errorDetail = e.toString();
      if (res.latencyMs == 0) res.latencyMs = sw.elapsedMilliseconds;
      if (!res.tcpOk) res.dnsOk = res.errorDetail!.contains('host') ? false : res.dnsOk;
    } finally {
      if (client == null) c.close();
    }
    return res;
  }

  static Future<bool> submitBugReport(String description, {String? diagnostics, http.Client? client}) async {
    final c = client ?? newClient();
    try {
      final r = await c.post(
        Uri.parse('$uhBase/api/launcher/bug-report'),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode({'description': description, 'diagnostics': diagnostics ?? '', 'version': launcherVersion}),
      ).timeout(const Duration(seconds: 20));
      return r.statusCode == 200 || r.statusCode == 201;
    } catch (_) {
      return false;
    } finally {
      if (client == null) c.close();
    }
  }
}
