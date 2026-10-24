import 'package:flutter_test/flutter_test.dart';
import 'package:sumanager/services/settings.dart';
import 'helpers.dart';

void main() {
  setUpAll(setupTestEnv);

  test('defaults and setters persist', () async {
    final s = Settings.instance;
    await s.load();
    expect(s.maxConcurrent, 1);
    expect(s.autoExtract, true);
    s.setDownloadPath('/tmp/dl');
    s.setMaxConcurrent(9);
    expect(s.maxConcurrent, 5);
    s.setAutoExtract(false);
    s.setRemoveWhenDone(true);
    s.setHideAdult(true);
    s.setWelcomeShown(true);
    s.setFpsEnabled(true);
    s.setFpsShortcut('alt+f');
    s.setLocale('zh');
    s.setMacOsWinePath('/opt/wine');
    await Future.delayed(const Duration(milliseconds: 20));
    await s.load();
    expect(s.downloadPath, '/tmp/dl');
    expect(s.maxConcurrent, 5);
    expect(s.hideAdult, true);
    expect(s.macOsWinePath, '/opt/wine');
  });

  test('writeJson/readJson roundtrip', () async {
    final s = Settings.instance;
    await s.load();
    await s.writeJson('t.json', {'a': 1});
    expect((await s.readJson('t.json'))['a'], 1);
    expect(await s.readJson('missing.json'), isEmpty);
    final bad = await s.file('bad.json');
    await bad.writeAsString('{nope');
    expect(await s.readJson('bad.json'), isEmpty);
    expect((await s.file('x')).path.contains('x'), true);
  });
}
