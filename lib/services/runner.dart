import 'dart:io';
import 'package:flutter/foundation.dart';
import 'settings.dart';

class GameRunner {
  static Future<Process?> launch(String exePath, {String? workDir, String? wineBinary}) async {
    final file = File(exePath);
    if (!await file.exists()) return null;
    final cwd = workDir ?? file.parent.path;
    if (kIsWeb) return null;
    if (Platform.isWindows) {
      return Process.start(exePath, [], workingDirectory: cwd, mode: ProcessStartMode.detached);
    }
    if (Platform.isLinux) {
      final proton = await findProton();
      if (proton != null) {
        return Process.start(proton, ['run', exePath], workingDirectory: cwd, mode: ProcessStartMode.detached);
      }
      final wine = await _which('wine');
      if (wine != null) {
        return Process.start(wine, [exePath], workingDirectory: cwd, mode: ProcessStartMode.detached);
      }
      if (!exePath.endsWith('.exe')) {
        return Process.start(exePath, [], workingDirectory: cwd, mode: ProcessStartMode.detached);
      }
      return null;
    }
    if (Platform.isMacOS) {
      final wine = wineBinary ?? Settings.instance.macOsWinePath ?? await _which('wine');
      if (wine != null) {
        return Process.start(wine, [exePath], workingDirectory: cwd, mode: ProcessStartMode.detached);
      }
      final crossover = '/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine';
      if (await File(crossover).exists()) {
        return Process.start(crossover, [exePath], workingDirectory: cwd, mode: ProcessStartMode.detached);
      }
      return null;
    }
    return null;
  }

  static Future<String?> _which(String name) async {
    try {
      final r = await Process.run('which', [name]);
      final p = (r.stdout as String).trim();
      return p.isEmpty ? null : p;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> findProton() async {
    final candidates = [
      '${Platform.environment['HOME']}/.steam/steam/steamapps/common/Proton - Experimental/proton',
      '${Platform.environment['HOME']}/.local/share/Steam/steamapps/common/Proton - Experimental/proton',
      '${Platform.environment['HOME']}/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Proton - Experimental/proton',
    ];
    for (final c in candidates) {
      if (await File(c).exists()) return c;
    }
    final common = Directory('${Platform.environment['HOME']}/.local/share/Steam/steamapps/common');
    if (await common.exists()) {
      await for (final e in common.list()) {
        if (e is Directory && e.path.contains('Proton')) {
          final p = '${e.path}/proton';
          if (await File(p).exists()) return p;
        }
      }
    }
    final umu = await _which('umu-run');
    if (umu != null) return umu;
    return null;
  }

  static Future<bool> closeGame(String exePath) async {
    try {
      final name = exePath.split(Platform.pathSeparator).last;
      if (Platform.isWindows) {
        await Process.run('taskkill', ['/IM', name, '/F']);
      } else {
        await Process.run('pkill', ['-f', name]);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<int> freeDiskBytes(String path) async {
    try {
      if (Platform.isWindows) {
        final r = await Process.run('powershell', ['-c', "(Get-PSDrive -Name '${path.substring(0, 1)}').Free"]);
        return int.tryParse((r.stdout as String).trim()) ?? -1;
      }
      final r = await Process.run('df', ['-B1', path]);
      final lines = (r.stdout as String).trim().split('\n');
      if (lines.length > 1) {
        final parts = lines.last.split(RegExp(r'\s+'));
        return int.tryParse(parts.length > 3 ? parts[3] : '') ?? -1;
      }
    } catch (_) {}
    return -1;
  }
}
