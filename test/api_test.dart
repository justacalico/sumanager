import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sumanager/services/api.dart';

http.Client mock(Map<String, http.Response Function(http.Request)> routes) =>
    MockClient((req) async {
      final key = '${req.url.host}${req.url.path}';
      for (final e in routes.entries) {
        if (key.contains(e.key)) return e.value(req);
      }
      return http.Response('not found', 404);
    });

Map<String, dynamic> game(int id) => {'id': id.toString(), 'slug': 'g$id', 'title': 'Game $id', 'cover_url': '', 'file_size': '10'};

void main() {
  test('fetchCatalogSync single page', () async {
    final c = mock({'/wp-json/launcher/v2/catalog': (r) {
      expect(r.url.queryParameters['run'], isNotNull);
      return http.Response(jsonEncode({'has_more': false, 'games': [game(1)]}), 200);
    }});
    final r = await Api.fetchCatalogSync(client: c);
    expect((r['games'] as List).length, 1);
  });

  test('fetchCatalogSync multi page with cursor', () async {
    var calls = 0;
    final c = mock({'catalog': (r) {
      calls++;
      if (calls == 1) {
        return http.Response(jsonEncode({'has_more': true, 'next_after': '7', 'games': [game(1)]}), 200);
      }
      expect(r.url.queryParameters['after'], '7');
      return http.Response(jsonEncode({'has_more': false, 'games': [game(2)]}), 200);
    }});
    final r = await Api.fetchCatalogSync(client: c);
    expect((r['games'] as List).length, 2);
    expect(calls, 2);
  });

  test('fetchCatalogSync keeps games when a page fails', () async {
    var calls = 0;
    final c = mock({'catalog': (r) {
      calls++;
      return calls == 1
          ? http.Response(jsonEncode({'has_more': true, 'next_after': '7', 'games': [game(1)]}), 200)
          : http.Response('err', 500);
    }});
    final r = await Api.fetchCatalogSync(client: c);
    expect((r['games'] as List).length, 1);
  });

  test('fetchCatalogSync throws when first page fails', () async {
    final c = mock({'catalog': (r) => http.Response('err', 400)});
    expect(() => Api.fetchCatalogSync(client: c), throwsException);
  });

  test('fetchCatalogSync passes since and returns sync_time', () async {
    final c = mock({'catalog': (r) {
      expect(r.url.queryParameters['since'], '123');
      return http.Response(jsonEncode({'has_more': false, 'games': [], 'sync_time': 999}), 200);
    }});
    final r = await Api.fetchCatalogSync(lastSync: 123, client: c);
    expect(r['sync_time'], 999);
  });

  test('fetchCatalog search filter', () async {
    final c = mock({'catalog': (r) => http.Response(jsonEncode({'has_more': false, 'games': [game(1), game(2)]}), 200)});
    final all = await Api.fetchCatalog(client: c);
    expect(all.length, 2);
    final f = await Api.fetchCatalog(search: 'game 1', client: c);
    expect(f.length, 1);
  });

  test('fetchPopularity', () async {
    final c = mock({'popularity': (r) => http.Response(jsonEncode({'views': {'5': 42}}), 200)});
    expect((await Api.fetchPopularity(client: c))[5], 42);
    final bad = mock({'popularity': (r) => http.Response('x', 500)});
    expect(await Api.fetchPopularity(client: bad), isEmpty);
  });

  test('resolveToken', () async {
    final c = mock({'resolve': (r) {
      expect(r.headers['Authorization'], 'Bearer tok');
      return http.Response(jsonEncode({'url': 'https://dl/x.zip'}), 200);
    }});
    expect(await Api.resolveToken(1, 's', bearer: 'tok', client: c), 'https://dl/x.zip');
    final bad = mock({'resolve': (r) => http.Response('{}', 403)});
    expect(await Api.resolveToken(1, 's', client: bad), isNull);
  });

  test('fetchAccount', () async {
    final c = mock({'me': (r) => http.Response(jsonEncode({'id': 'u1', 'email': 'a@b.c', 'is_premium': true, 'pro_expires_at': 'x'}), 200)});
    final s = await Api.fetchAccount('tok', client: c);
    expect(s.signedIn, true);
    expect(s.isPro, true);
    final bad = mock({'me': (r) => http.Response('{}', 401)});
    expect((await Api.fetchAccount('tok', client: bad)).signedIn, false);
  });

  test('connectivityTest', () async {
    final ok = mock({'health': (r) => http.Response('{}', 200)});
    final r = await Api.connectivityTest(client: ok);
    expect(r.apiOk, true);
    final fail = MockClient((req) async => throw Exception('down'));
    final r2 = await Api.connectivityTest(client: fail);
    expect(r2.apiOk, false);
  });

  test('popularity list form and errors', () async {
    final list = mock({'popularity': (r) => http.Response(jsonEncode({'games': [{'id': 7, 'views': 3}]}), 200)});
    expect((await Api.fetchPopularity(client: list))[7], 3);
    final boom = MockClient((r) async => throw Exception('x'));
    expect(await Api.fetchPopularity(client: boom), isEmpty);
    expect(await Api.resolveToken(1, 's', client: boom), isNull);
    expect((await Api.fetchAccount('t', client: boom)).signedIn, false);
    expect(await Api.submitBugReport('d', client: boom), false);
  });

  test('connectivityTest dns detail', () async {
    final boom = MockClient((r) async => throw Exception('Failed host lookup'));
    final r = await Api.connectivityTest(client: boom);
    expect(r.dnsOk, false);
    expect(r.errorDetail, contains('host'));
  });

  test('submitBugReport', () async {
    final c = mock({'bug': (r) => http.Response('{}', 200)});
    expect(await Api.submitBugReport('d', diagnostics: 'x', client: c), true);
    final bad = mock({'bug': (r) => http.Response('{}', 500)});
    expect(await Api.submitBugReport('d', client: bad), false);
  });
}
