import 'dart:io';
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
      const Text('Most Windows games need Visual C++, DirectX or .NET runtimes. Install them once and every game benefits.', style: TextStyle(fontSize: 13)),
      const SizedBox(height: 12),
      if (!kIsWeb && Platform.isWindows)
        FilledButton.icon(icon: const Icon(Icons.build), label: const Text('Install all runtimes'), onPressed: () => _runtimes(context))
      else
        const Text('Runtime installers are a Windows-only feature.', style: TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 24),
      if (!kIsWeb && Platform.isWindows) ...[
        const Text('Windows Defender', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Defender can slow down or break downloads. Exclude your download folder from scanning.', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(icon: const Icon(Icons.shield_outlined), label: const Text('Exclude download folder'), onPressed: () => _defender(context)),
        const SizedBox(height: 24),
      ],
      const Text('Running Windows games here', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      if (!kIsWeb && Platform.isLinux)
        const Text('Games launch through Steam Proton when installed, or Wine as a fallback. Install Proton from Steam for the best results.', style: TextStyle(fontSize: 13)),
      if (!kIsWeb && Platform.isMacOS)
        const Text('macOS has no native .exe support. Point Settings to a Wine build from CrossOver, the Game Porting Toolkit or Whisky, and games will launch through it.', style: TextStyle(fontSize: 13)),
      if (!kIsWeb && Platform.isWindows)
        const Text('You are on Windows — games just run. Nothing extra needed.', style: TextStyle(fontSize: 13)),
      const SizedBox(height: 24),
      const Text('Links', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        TextButton(onPressed: () => launchUrl(Uri.parse('https://steamunlocked.org')), child: const Text('steamunlocked.org')),
        TextButton(onPressed: () => launchUrl(Uri.parse('https://uploadhaven.com')), child: const Text('uploadhaven.com')),
      ]),
    ]);
  }

  Future<void> _runtimes(BuildContext context) async {
    final scripts = [
      'https://aka.ms/vs/17/release/vc_redist.x64.exe',
      'https://aka.ms/vs/17/release/vc_redist.x86.exe',
      'https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe',
    ];
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Install runtimes'),
        content: const Text('This downloads the official Microsoft installers for Visual C++ and DirectX and opens them for you. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Install')),
        ],
      ),
    );
    if (ok != true) return;
    for (final u in scripts) {
      await launchUrl(Uri.parse(u));
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opened the official installers in your browser.')));
    }
  }

  Future<void> _defender(BuildContext context) async {
    if (!Platform.isWindows) return;
    try {
      await Process.run('powershell', ['-Command', 'Add-MpPreference -ExclusionPath (Get-Content "\$env:APPDATA\\sumanager\\download_path.txt" -ErrorAction SilentlyContinue)']);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exclusion request sent to Windows Defender.')));
      }
    } catch (_) {}
  }
}
