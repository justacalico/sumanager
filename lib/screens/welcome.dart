import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/settings.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onDone;
  const WelcomeScreen({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.rocket_launch_outlined, size: 64),
            const SizedBox(height: 16),
            const Text('SteamUnlocked Launcher', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text(
              'Browse the catalog, download games with resumable parallel chunks, extract them automatically and organize everything in one library.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose a download folder'),
              onPressed: () async {
                final d = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Choose a download folder');
                if (d != null) Settings.instance.setDownloadPath(d);
                onDone();
              },
            ),
            TextButton(onPressed: onDone, child: const Text('Skip for now')),
          ]),
        ),
      ),
    );
  }
}
