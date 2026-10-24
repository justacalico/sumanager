import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'services/settings.dart';
import 'services/auth.dart';
import 'services/downloads.dart';
import 'services/library.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  if (isDesktop) {
    await windowManager.ensureInitialized();
    const opts = WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(980, 640),
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    windowManager.waitUntilReadyToShow(opts, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  await Settings.instance.load();
  await Future.wait([
    Auth.instance.load(),
    DownloadManager.instance.load(),
    LibraryStore.instance.load(),
  ]);
  runApp(const SuManagerApp());
}
