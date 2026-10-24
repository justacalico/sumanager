import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart';

class Api {
  static const suBase = 'https://steamunlocked.org';
  static const uhBase = 'https://api.uploadhaven.com';
  static const launcherKey = 'su-launcher-v1-8f3k9x2m7pqw4';
  static const launcherVersion = '0.4.2';

  static Map<String, String> get _headers => {
        'X-Launcher-Key': launcherKey,
        'X-Launcher-Version': launcherVersion,
        'User-Agent': 'SteamUnlocked-Launcher/$launcherVersion',
      };

  static Future<List<CatalogGame>> fetchCatalogPage(int page, {String? search, http.Client? client}) async {
    final c = client ?? http.Client();
    try {
      var url = '$suBase/wp-json/launcher/v2/catalog?page=$page&per_page=100';
      if (search != null && search.isNotEmpty) url += '&search=${Uri.encodeComponent(search)}';
      final r = await c.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 30));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final j = jsonDecode(r.body);
      final list = (j is Map ? j['games'] : j) as List? ?? [];
      return list.map((g) => CatalogGame.fromJson(g)).toList();

    } finally {
      if (client == null) c.close();
    }
  }

  static Future<List<CatalogGame>> fetchCatalog({String? search, http.Client? client}) async {
    final all = <CatalogGame>[];
    for (var page = 1; page <= 12; page++) {
      final batch = await fetchCatalogPage(page, search: search, client: client);
      all.addAll(batch);
      if (batch.length < 100) break;
    }
    return all;
  }

  static Future<Map<int, int>> fetchPopularity({http.Client? client}) async {
    final c = client ?? http.Client();
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
    final c = client ?? http.Client();
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
    final c = client ?? http.Client();
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
    final c = client ?? http.Client();
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
    final c = client ?? http.Client();
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
