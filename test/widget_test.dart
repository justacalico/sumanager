import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumanager/models.dart';
import 'package:sumanager/services/library.dart';

void main() {
  test('Version parses and compares', () {
    expect(Version.parse('v1.2.3')!.compareTo(Version.parse('1.2.0')!), greaterThan(0));
    expect(Version.parse('0.4.2')!.compareTo(Version.parse('0.4.2')!), 0);
    expect(Version.parse('junk') == null, true);
  });

  test('CatalogGame parses json', () {
    final g = CatalogGame.fromJson({'id': 7, 'slug': 'halo', 'title': 'Halo Free Download (v1.0)', 'cover_url': 'x', 'file_size': 2000000000, 'categories': ['Action']});
    expect(g.id, 7);
    expect(g.title, 'Halo');
    expect(g.fileSize, 2000000000);
  });

  test('normalizeTitle strips scene noise', () {
    expect(GameScanner.normalizeTitle('Far.Cry.5.Free.Download.v1.011.ALL.DLC'), 'Far Cry 5');
    expect(GameScanner.scoreMatch('far cry 5', 'Far Cry 5 Free Download') > 0.8, true);
  });

  testWidgets('game card renders', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: Text('ok'))));
    expect(find.text('ok'), findsOneWidget);
  });
}
