import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends ChangeNotifier {
  static final Settings instance = Settings._();
  Settings._();

  String downloadPath = '';
  int maxConcurrent = 1;
  bool autoExtract = true;
  bool removeWhenDone = false;
  bool hideAdult = false;
  bool welcomeShown = false;
  bool fpsEnabled = false;
  String fpsShortcut = 'ctrl_shift_f10';
  String locale = 'system';
  String? macOsWinePath;

  SharedPreferences? _prefs;

  Future<Directory> dataDir() async {
    if (kIsWeb) return Directory.systemTemp; // coverage:ignore-line
    final d = await getApplicationSupportDirectory();
    await d.create(recursive: true);
    return d;
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    downloadPath = _prefs!.getString('download_path') ?? '';
    maxConcurrent = _prefs!.getInt('max_concurrent') ?? 1;
    autoExtract = _prefs!.getBool('auto_extract') ?? true;
    removeWhenDone = _prefs!.getBool('remove_when_done') ?? false;
    hideAdult = _prefs!.getBool('hide_adult') ?? false;
    welcomeShown = _prefs!.getBool('welcome_shown') ?? false;
    fpsEnabled = _prefs!.getBool('fps_enabled') ?? false;
    fpsShortcut = _prefs!.getString('fps_shortcut') ?? 'ctrl_shift_f10';
    locale = _prefs!.getString('locale') ?? 'system';
    macOsWinePath = _prefs!.getString('macos_wine_path');
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    _prefs = p;
    await p.setString('download_path', downloadPath);
    await p.setInt('max_concurrent', maxConcurrent);
    await p.setBool('auto_extract', autoExtract);
    await p.setBool('remove_when_done', removeWhenDone);
    await p.setBool('hide_adult', hideAdult);
    await p.setBool('welcome_shown', welcomeShown);
    await p.setBool('fps_enabled', fpsEnabled);
    await p.setString('fps_shortcut', fpsShortcut);
    await p.setString('locale', locale);
    if (macOsWinePath != null) await p.setString('macos_wine_path', macOsWinePath!);
    notifyListeners();
  }

  void setDownloadPath(String v) { downloadPath = v; _save(); }
  void setMaxConcurrent(int v) { maxConcurrent = v.clamp(1, 5); _save(); }
  void setAutoExtract(bool v) { autoExtract = v; _save(); }
  void setRemoveWhenDone(bool v) { removeWhenDone = v; _save(); }
  void setHideAdult(bool v) { hideAdult = v; _save(); }
  void setWelcomeShown(bool v) { welcomeShown = v; _save(); }
  void setFpsEnabled(bool v) { fpsEnabled = v; _save(); }
  void setFpsShortcut(String v) { fpsShortcut = v; _save(); }
  void setLocale(String v) { locale = v; _save(); }
  void setMacOsWinePath(String v) { macOsWinePath = v; _save(); }

  Future<File> file(String name) async => File('${(await dataDir()).path}${Platform.pathSeparator}$name');
  Future<Map<String, dynamic>> readJson(String name) async {
    try {
      final f = await file(name);
      if (!await f.exists()) return {};
      return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
  var _writeSeq = 0;
  Future<void> writeJson(String name, Object data) async {
    final f = await file(name);
    final tmp = File('${f.path}.${_writeSeq++}.tmp');
    await tmp.writeAsString(jsonEncode(data));
    await tmp.rename(f.path);
  }
}
