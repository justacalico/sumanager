import 'package:flutter/material.dart';
import '../models.dart';
import '../services/downloads.dart';
import 'browse.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final dm = DownloadManager.instance;
    return AnimatedBuilder(
      animation: dm,
      builder: (_, __) {
        if (dm.items.isEmpty) {
          return const Center(child: Text('No downloads yet. Browse the catalog and pick a game.'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Text('${dm.items.length} download(s) · ${dm.activeCount} active', style: const TextStyle(fontSize: 13)),
                const Spacer(),
                Text('Concurrent: ${dm.maxConcurrent}', style: const TextStyle(fontSize: 13)),
              ]),
            ),
            for (final i in dm.items) _tile(context, dm, i),
          ],
        );
      },
    );
  }

  Widget _tile(BuildContext context, DownloadManager dm, DownloadItem i) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(i.title, style: const TextStyle(fontWeight: FontWeight.w600))),
            _statusChip(i),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: i.status == DownloadStatus.extracting && i.extractTotal > 0 ? i.extractDone / i.extractTotal : i.progress),
          const SizedBox(height: 6),
          Row(children: [
            Text('${GameCard.fmtBytes(i.downloadedBytes)} / ${GameCard.fmtBytes(i.totalSize)}', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 12),
            if (i.speed > 0) Text('${GameCard.fmtBytes(i.speed.round())}/s', style: const TextStyle(fontSize: 12)),
            if (i.etaSecs != null && i.etaSecs! > 0) Text(' · ${_fmtEta(i.etaSecs!)}', style: const TextStyle(fontSize: 12)),
            if (i.status == DownloadStatus.extracting) Text(' · extracting ${i.extractDone}/${i.extractTotal}', style: const TextStyle(fontSize: 12)),
            const Spacer(),
            _actions(context, dm, i),
          ]),
          if (i.error != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(i.error!, style: const TextStyle(fontSize: 12, color: Color(0xFFF87171)))),
        ]),
      ),
    );
  }

  Widget _statusChip(DownloadItem i) {
    final s = switch (i.status) {
      DownloadStatus.queued => 'Queued',
      DownloadStatus.resolving => 'Resolving…',
      DownloadStatus.downloading => 'Downloading',
      DownloadStatus.paused => 'Paused',
      DownloadStatus.extracting => 'Extracting',
      DownloadStatus.done => i.needsExtract ? 'Ready to extract' : 'Done',
      DownloadStatus.failed => 'Failed',
      DownloadStatus.cancelled => 'Cancelled',
    };
    return Text(s, style: const TextStyle(fontSize: 12, color: Colors.grey));
  }

  Widget _actions(BuildContext context, DownloadManager dm, DownloadItem i) {
    return Wrap(spacing: 4, children: [
      if (i.status == DownloadStatus.downloading || i.status == DownloadStatus.resolving)
        IconButton(icon: const Icon(Icons.pause, size: 20), tooltip: 'Pause', onPressed: () => dm.pause(i)),
      if (i.status == DownloadStatus.paused || i.status == DownloadStatus.failed)
        IconButton(icon: const Icon(Icons.play_arrow, size: 20), tooltip: 'Resume', onPressed: () => dm.resume(i)),
      if (i.status == DownloadStatus.done && i.needsExtract)
        TextButton(onPressed: () => dm.extract(i), child: const Text('Extract')),
      if (i.status == DownloadStatus.done)
        IconButton(icon: const Icon(Icons.check_circle_outline, size: 20), tooltip: 'Dismiss', onPressed: () => dm.remove(i)),
      if (i.status != DownloadStatus.done)
        IconButton(icon: const Icon(Icons.close, size: 20), tooltip: 'Cancel', onPressed: () => dm.cancel(i)),
    ]);
  }

  static String _fmtEta(int s) => s >= 3600 ? '${s ~/ 3600}h ${(s % 3600) ~/ 60}m' : s >= 60 ? '${s ~/ 60}m ${s % 60}s' : '${s}s';
}
