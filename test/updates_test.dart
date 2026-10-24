import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sumanager/services/updates.dart';

void main() {
  test('check returns newer release', () async {
    final c = MockClient((req) async => http.Response(jsonEncode([
      {'tag_name': 'v9.9.9', 'name': 'r', 'description': 'notes', 'released_at': 'd'}
    ]), 200));
    final u = await UpdateChecker.check('0.4.2', client: c);
    expect(u!.version, '9.9.9');
  });

  test('check handles bad tags and throws', () async {
    final c = MockClient((req) async => http.Response(jsonEncode([
      {'tag_name': 'notaversion'},
      {'tag_name': 'v1.0.0', 'description': 'd'},
    ]), 200));
    expect((await UpdateChecker.check('0.0.1', client: c))!.tag, 'v1.0.0');
    final boom = MockClient((r) async => throw Exception('net'));
    expect(await UpdateChecker.check('0.0.1', client: boom), isNull);
  });

  test('check picks newest among several', () async {
    final c = MockClient((req) async => http.Response(jsonEncode([
      {'tag_name': 'v1.5.0'},
      {'tag_name': 'v1.9.0'},
      {'tag_name': 'v1.2.0'},
    ]), 200));
    expect((await UpdateChecker.check('0.0.1', client: c))!.tag, 'v1.9.0');
  });

  test('check returns null when current or error', () async {
    final c = MockClient((req) async => http.Response(jsonEncode([{'tag_name': 'v0.1.0'}]), 200));
    expect(await UpdateChecker.check('9.9.9', client: c), isNull);
    final bad = MockClient((req) async => http.Response('x', 500));
    expect(await UpdateChecker.check('0.0.1', client: bad), isNull);
  });
}
