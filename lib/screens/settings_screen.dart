import 'dart:io';
import '../l10n_ext.dart';
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
  String _version = '1.0.0';

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
      Text(context.l.downloads, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      ListTile(
        title: Text(context.l.downloadFolder),
        subtitle: Text(s.downloadPath.isEmpty ? context.l.notSet : s.downloadPath, style: const TextStyle(fontSize: 12)),
        trailing: FilledButton.tonal(onPressed: () async {
          final d = await FilePicker.platform.getDirectoryPath(dialogTitle: context.l.chooseDownloadFolder);
          if (d != null) { s.setDownloadPath(d); setState(() {}); }
        }, child: Text(context.l.choose)),
      ),
      ListTile(
        title: Text('${context.l.simultaneousDownloads}${s.maxConcurrent}'),
        subtitle: Text(context.l.proMembersCanRunUpTo5AtOnce, style: TextStyle(fontSize: 12)),
        trailing: SizedBox(width: 200, child: Slider(value: s.maxConcurrent.toDouble(), min: 1, max: 5, divisions: 4, onChanged: (v) { dm.setMaxConcurrent(v.round()); setState(() {}); })),
      ),
      SwitchListTile(title: Text(context.l.extractAutomatically), value: s.autoExtract, onChanged: (v) => s.setAutoExtract(v)),
      SwitchListTile(title: Text(context.l.deleteArchiveAfterExtraction), value: s.removeWhenDone, onChanged: (v) => s.setRemoveWhenDone(v)),
      SwitchListTile(title: Text(context.l.hideAdultGames), value: s.hideAdult, onChanged: (v) => s.setHideAdult(v)),
      const Divider(height: 32),
      const Text('Playing Windows games', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      // coverage:ignore-start
      if (!kIsWeb && Platform.isMacOS)
        ListTile(
          title: Text(context.l.windowsCompatibilityLayer),
          subtitle: Text(s.macOsWinePath ?? context.l.useCrossoverGamePortingToolkitOrWhiskySetTheWineBinaryPathHere, style: const TextStyle(fontSize: 12)),
          trailing: FilledButton.tonal(onPressed: () async {
            final r = await FilePicker.platform.pickFiles(dialogTitle: context.l.chooseWineCrossoverBinary);
            if (r != null && r.files.single.path != null) { s.setMacOsWinePath(r.files.single.path!); setState(() {}); }
          }, child: Text(context.l.choose)),
        ),
      // coverage:ignore-end
      if (!kIsWeb && Platform.isLinux)
        ListTile(
          title: Text(context.l.windowsCompatibility),
          subtitle: Text(context.l.gamesRunThroughSteamProtonOrWineWhenFoundOnThisSystem, style: TextStyle(fontSize: 12)),
        ),
      SwitchListTile(
        title: Text(context.l.fpsCounterWhilePlaying),
        subtitle: Text(context.l.experimentalNeedsACompatibleOverlayToolEGMangohudOnLinux, style: TextStyle(fontSize: 12)),
        value: s.fpsEnabled, onChanged: (v) => s.setFpsEnabled(v),
      ),
      ListTile(
        title: Text(context.l.showHideShortcut),
        subtitle: Text(s.fpsShortcut == 'ctrl_shift_f10' ? 'Ctrl + Shift + F10' : 'Alt + Shift + F11', style: const TextStyle(fontSize: 12)),
        trailing: DropdownButton<String>(
          value: s.fpsShortcut, underline: const SizedBox(),
          items: [DropdownMenuItem(value: 'ctrl_shift_f10', child: Text(context.l.ctrlShiftF10)), DropdownMenuItem(value: 'alt_shift_f11', child: Text(context.l.altShiftF11))],
          onChanged: (v) => s.setFpsShortcut(v!),
        ),
      ),
      const Divider(height: 32),
      Text(context.l.language, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      DropdownButton<String>(
        value: s.locale,
        items: [
          DropdownMenuItem(value: 'system', child: Text(context.l.system)),
          DropdownMenuItem(value: 'en', child: Text(context.l.traditionalEnglish)),
          DropdownMenuItem(value: 'zh', child: Text('简体中文')),
          DropdownMenuItem(value: 'ru', child: Text('Русский')),
          DropdownMenuItem(value: 'ga', child: Text('Gaeilge')),
        ],
        onChanged: (v) => s.setLocale(v!),
      ),
      const Divider(height: 32),
      Text(context.l.about, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      ListTile(
        title: Text('${context.l.version}$_version'),
        subtitle: _updateMsg != null ? Text(_updateMsg!, style: const TextStyle(fontSize: 12)) : null,
        trailing: FilledButton.tonal(
          onPressed: _checking ? null : () async {
            setState(() { _checking = true; _updateMsg = null; });
            final u = await UpdateChecker.check(_version);
            setState(() {
              _checking = false;
              _update = u;
              _updateMsg = u == null ? context.l.upToDate : 'New version ${u.version}${context.l.available}';
            });
          },
          child: _checking ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(context.l.checkForUpdates),
        ),
      ),
      if (_update != null)
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: TextButton(onPressed: () => launchUrl(Uri.parse(_update!.url)), child: Text('${context.l.open}${_update!.tag}${context.l.onGitlab}')),
        ),
    ]);
  }
}
