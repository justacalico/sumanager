import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/settings.dart';
import '../services/downloads.dart';
import '../services/updates.dart';
import '../models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _checking = false;
  String? _updateMsg;
  UpdateInfo? _update;
  String _version = '0.4.2';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) => setState(() => _version = p.version));
  }

  @override
  Widget build(BuildContext context) {
    final s = Settings.instance;
    final dm = DownloadManager.instance;
    return ListView(padding: const EdgeInsets.all(24), children: [
      const Text('Downloads', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      ListTile(
        title: const Text('Download folder'),
        subtitle: Text(s.downloadPath.isEmpty ? 'Not set' : s.downloadPath, style: const TextStyle(fontSize: 12)),
        trailing: FilledButton.tonal(onPressed: () async {
          final d = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Choose download folder');
          if (d != null) { s.setDownloadPath(d); setState(() {}); }
        }, child: const Text('Choose')),
      ),
      ListTile(
        title: Text('Simultaneous downloads: ${s.maxConcurrent}'),
        subtitle: const Text('Pro members can run up to 5 at once', style: TextStyle(fontSize: 12)),
        trailing: SizedBox(width: 200, child: Slider(value: s.maxConcurrent.toDouble(), min: 1, max: 5, divisions: 4, onChanged: (v) { dm.setMaxConcurrent(v.round()); setState(() {}); })),
      ),
      SwitchListTile(title: const Text('Extract automatically'), value: s.autoExtract, onChanged: (v) => s.setAutoExtract(v)),
      SwitchListTile(title: const Text('Delete archive after extraction'), value: s.removeWhenDone, onChanged: (v) => s.setRemoveWhenDone(v)),
      SwitchListTile(title: const Text('Hide adult games'), value: s.hideAdult, onChanged: (v) => s.setHideAdult(v)),
      const Divider(height: 32),
      const Text('Playing Windows games', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      if (!kIsWeb && Platform.isMacOS)
        ListTile(
          title: const Text('Windows compatibility layer'),
          subtitle: Text(s.macOsWinePath ?? 'Use CrossOver, Game Porting Toolkit or Whisky — set the wine binary path here', style: const TextStyle(fontSize: 12)),
          trailing: FilledButton.tonal(onPressed: () async {
            final r = await FilePicker.platform.pickFiles(dialogTitle: 'Choose wine/crossover binary');
            if (r != null && r.files.single.path != null) { s.setMacOsWinePath(r.files.single.path!); setState(() {}); }
          }, child: const Text('Choose')),
        ),
      if (!kIsWeb && Platform.isLinux)
        const ListTile(
          title: Text('Windows compatibility'),
          subtitle: Text('Games run through Steam Proton or Wine when found on this system.', style: TextStyle(fontSize: 12)),
        ),
      SwitchListTile(
        title: const Text('FPS counter while playing'),
        subtitle: const Text('Experimental — needs a compatible overlay tool (e.g. MangoHud on Linux)', style: TextStyle(fontSize: 12)),
        value: s.fpsEnabled, onChanged: (v) => s.setFpsEnabled(v),
      ),
      ListTile(
        title: const Text('Show / hide shortcut'),
        subtitle: Text(s.fpsShortcut == 'ctrl_shift_f10' ? 'Ctrl + Shift + F10' : 'Alt + Shift + F11', style: const TextStyle(fontSize: 12)),
        trailing: DropdownButton<String>(
          value: s.fpsShortcut, underline: const SizedBox(),
          items: const [DropdownMenuItem(value: 'ctrl_shift_f10', child: Text('Ctrl+Shift+F10')), DropdownMenuItem(value: 'alt_shift_f11', child: Text('Alt+Shift+F11'))],
          onChanged: (v) => s.setFpsShortcut(v!),
        ),
      ),
      const Divider(height: 32),
      const Text('Language', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      DropdownButton<String>(
        value: s.locale,
        items: const [
          DropdownMenuItem(value: 'system', child: Text('System')),
          DropdownMenuItem(value: 'en', child: Text('Traditional English')),
          DropdownMenuItem(value: 'zh', child: Text('简体中文')),
          DropdownMenuItem(value: 'ru', child: Text('Русский')),
          DropdownMenuItem(value: 'ga', child: Text('Gaeilge')),
        ],
        onChanged: (v) => s.setLocale(v!),
      ),
      const Divider(height: 32),
      const Text('About', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      ListTile(
        title: Text('Version $_version'),
        subtitle: _updateMsg != null ? Text(_updateMsg!, style: const TextStyle(fontSize: 12)) : null,
        trailing: FilledButton.tonal(
          onPressed: _checking ? null : () async {
            setState(() { _checking = true; _updateMsg = null; });
            final u = await UpdateChecker.check(_version);
            setState(() {
              _checking = false;
              _update = u;
              _updateMsg = u == null ? 'Up to date' : 'New version ${u.version} available';
            });
          },
          child: _checking ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Check for updates'),
        ),
      ),
      if (_update != null)
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: TextButton(onPressed: () => launchUrl(Uri.parse(_update!.url)), child: Text('Open ${_update!.tag} on GitLab')),
        ),
    ]);
  }
}
