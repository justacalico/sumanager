import 'dart:io';
import '../l10n_ext.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(24), children: [
      const Text('Missing DLL or game won\'t launch?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      Text(context.l.mostWindowsGamesNeedVisualCDirectxOrNetRuntimesInstallThemOnceAndEveryGameBenefits, style: TextStyle(fontSize: 13)),
      const SizedBox(height: 12),
      // coverage:ignore-start
      if (!kIsWeb && Platform.isWindows)
        FilledButton.icon(icon: Icon(Icons.build), label: Text(context.l.installAllRuntimes), onPressed: () => _runtimes(context))
      // coverage:ignore-end
      else
        Text(context.l.runtimeInstallersAreAWindowsOnlyFeature, style: TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 24),
      // coverage:ignore-start
      if (!kIsWeb && Platform.isWindows) ...[
        Text(context.l.windowsDefender, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        Text(context.l.defenderCanSlowDownOrBreakDownloadsExcludeYourDownloadFolderFromScanning, style: TextStyle(fontSize: 13)),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(icon: Icon(Icons.shield_outlined), label: Text(context.l.excludeDownloadFolder), onPressed: () => _defender(context)),
        const SizedBox(height: 24),
      ],
      // coverage:ignore-end
      Text(context.l.runningWindowsGamesHere, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      if (!kIsWeb && Platform.isLinux)
        Text(context.l.gamesLaunchThroughSteamProtonWhenInstalledOrWineAsAFallbackInstallProtonFromSteamForTheBestResults, style: TextStyle(fontSize: 13)),
      // coverage:ignore-start
      if (!kIsWeb && Platform.isMacOS)
        Text(context.l.macosHasNoNativeExeSupportPointSettingsToAWineBuildFromCrossoverTheGamePortingToolkitOrWhiskyAndGamesWillLaunchThroughIt, style: TextStyle(fontSize: 13)),
      if (!kIsWeb && Platform.isWindows)
        Text(context.l.youAreOnWindowsGamesJustRunNothingExtraNeeded, style: TextStyle(fontSize: 13)),
      // coverage:ignore-end
      const SizedBox(height: 24),
      Text(context.l.links, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        TextButton(onPressed: () => launchUrl(Uri.parse('https://steamunlocked.org')), child: Text(context.l.steamunlockedOrg)),
        TextButton(onPressed: () => launchUrl(Uri.parse('https://uploadhaven.com')), child: Text(context.l.uploadhavenCom)),
      ]),
    ]);
  }

  // coverage:ignore-start
  Future<void> _runtimes(BuildContext context) async {
    final scripts = [
      'https://aka.ms/vs/17/release/vc_redist.x64.exe',
      'https://aka.ms/vs/17/release/vc_redist.x86.exe',
      'https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe',
    ];
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l.installRuntimes),
        content: Text(context.l.thisDownloadsTheOfficialMicrosoftInstallersForVisualCAndDirectxAndOpensThemForYouContinue),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l.install)),
        ],
      ),
    );
    if (ok != true) return;
    for (final u in scripts) {
      await launchUrl(Uri.parse(u));
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l.openedTheOfficialInstallersInYourBrowser)));
    }
  }
  // coverage:ignore-end

  // coverage:ignore-start
  Future<void> _defender(BuildContext context) async {
    if (!Platform.isWindows) return;
    try {
      await Process.run('powershell', ['-Command', 'Add-MpPreference -ExclusionPath (Get-Content "\$env:APPDATA\\sumanager\\download_path.txt" -ErrorAction SilentlyContinue)']);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l.exclusionRequestSentToWindowsDefender)));
      }
    } catch (_) {}
  }
  // coverage:ignore-end
}
