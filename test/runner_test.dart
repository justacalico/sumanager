import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumanager/services/runner.dart';
import 'package:sumanager/services/settings.dart';
import 'helpers.dart';

void main() {
  setUpAll(() async {
    setupTestEnv();
    await Settings.instance.load();
  });

  test('launch nonexistent returns null', () async {
    expect(await GameRunner.launch('/no/such/file.exe'), isNull);
  });

  test('launch shell script on linux', () async {
    if (!Platform.isLinux) return;
    final d = Directory.systemTemp.createTempSync('run');
    final sh = File('${d.path}/g.sh')..writeAsStringSync('#!/bin/sh\nexit 0\n');
    File('${d.path}/g.exe').writeAsBytesSync([77, 90]);
    await Process.run('chmod', ['755', sh.path]);
    final p = await GameRunner.launch(sh.path);
    expect(p, isNotNull);
  });

  test('findProton finds injected proton', () async {
    final home = Directory.systemTemp.createTempSync('home');
    final p = '${home.path}/.steam/steam/steamapps/common/Proton - Experimental/proton';
    File(p).createSync(recursive: true);
    expect(await GameRunner.findProton(home: home.path), p);
    final home2 = Directory.systemTemp.createTempSync('home2');
    final p2 = '${home2.path}/.local/share/Steam/steamapps/common/Proton 9/proton';
    File(p2).createSync(recursive: true);
    expect(await GameRunner.findProton(home: home2.path), p2);
    final home3 = Directory.systemTemp.createTempSync('home3');
    await GameRunner.findProton(home: home3.path);
  });

  test('launch branches', () async {
    if (!Platform.isLinux) return;
    final d = Directory.systemTemp.createTempSync('run2');
    final sh = File('${d.path}/g.sh')..writeAsStringSync('#!/bin/sh\nexit 0\n');
    File('${d.path}/g.exe').writeAsBytesSync([77, 90]);
    await Process.run('chmod', ['755', sh.path]);
    GameRunner.protonOverride = () async => '/bin/true';
    expect(await GameRunner.launch('${d.path}/g.exe'), isNotNull);
    GameRunner.protonOverride = () async => null;
    expect(await GameRunner.launch('${d.path}/g.exe', wineBinary: '/bin/true'), isNotNull);
    GameRunner.protonOverride = () async => '/bad/missing';
    expect(await GameRunner.launch('${d.path}/g.exe', wineBinary: '/bad/missing2'), isNull);
    expect(await GameRunner.launch(sh.path, wineBinary: '/bad/missing2'), isNotNull);
    GameRunner.protonOverride = null;
  });

  test('findProton, closeGame, freeDiskBytes', () async {
    await GameRunner.findProton();
    if (!Platform.isWindows) {
      expect(await GameRunner.closeGame('definitely-not-running-xyz.exe'), true);
      expect(await GameRunner.freeDiskBytes('/tmp'), greaterThan(0));
      expect(await GameRunner.freeDiskBytes('/nonexistent-xyz'), -1);
    }
  });
}
