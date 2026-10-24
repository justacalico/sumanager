import 'dart:io';
import 'package:flutter/foundation.dart';
import 'settings.dart';

class GameRunner {
  @visibleForTesting
  static Future<String?> Function()? protonOverride;

  @visibleForTesting
  static Future<String?> Function(String)? whichOverride;

  static Future<Process?> launch(String exePath, {String? workDir, String? wineBinary, String? protonPath}) async {
    final file = File(exePath);
    if (!await file.exists()) return null;
    final cwd = workDir ?? file.parent.path;
    if (kIsWeb) return null;
    // coverage:ignore-start
    if (Platform.isWindows) {
      return Process.start(exePath, [], workingDirectory: cwd, mode: ProcessStartMode.detached);
    }
    // coverage:ignore-end
    if (Platform.isLinux) {
      final proton = protonPath ?? await (protonOverride?.call() ?? findProton());
      if (proton != null) {
        try {
          return await Process.start(proton, ['run', exePath], workingDirectory: cwd, mode: ProcessStartMode.detached);
        } catch (_) {}
      }
      final wine = wineBinary ?? await (whichOverride?.call('wine') ?? _which('wine'));
      if (wine != null) {
        try {
          return await Process.start(wine, [exePath], workingDirectory: cwd, mode: ProcessStartMode.detached);
        } catch (_) {}
      }
      if (!exePath.endsWith('.exe')) {
        try {
          return await Process.start(exePath, [], workingDirectory: cwd, mode: ProcessStartMode.detached);
        } catch (_) {}
      }
      return null;
    }
    // coverage:ignore-start
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
    // coverage:ignore-end
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

  static Future<String?> findProton({String? home}) async {
    home ??= Platform.environment['HOME'];
    final candidates = [
      '$home/.steam/steam/steamapps/common/Proton - Experimental/proton',
      '$home/.local/share/Steam/steamapps/common/Proton - Experimental/proton',
      '$home/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Proton - Experimental/proton',
    ];
    for (final c in candidates) {
      if (await File(c).exists()) return c;
    }
    final common = Directory('$home/.local/share/Steam/steamapps/common');
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
      // coverage:ignore-start
      if (Platform.isWindows) {
        await Process.run('taskkill', ['/IM', name, '/F']);
      } else {
        // coverage:ignore-end
        await Process.run('pkill', ['-f', name]);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<int> freeDiskBytes(String path) async {
    try {
      // coverage:ignore-start
      if (Platform.isWindows) {
        final r = await Process.run('powershell', ['-c', "(Get-PSDrive -Name '${path.substring(0, 1)}').Free"]);
        return int.tryParse((r.stdout as String).trim()) ?? -1;
      }
      // coverage:ignore-end
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
