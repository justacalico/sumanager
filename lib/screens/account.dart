import 'package:flutter/material.dart';
import '../l10n_ext.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth.dart';
import '../services/api.dart';
import '../models.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  ConnectivityResult? _conn;
  bool _testing = false;
  String? _reportMsg;
  String _report = '';

  @override
  Widget build(BuildContext context) {
    final auth = Auth.instance;
    return AnimatedBuilder(
      animation: auth,
      builder: (_, __) => ListView(padding: const EdgeInsets.all(24), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(auth.pro.isPro ? Icons.workspace_premium : Icons.person_outline, size: 32),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auth.pro.signedIn ? (auth.pro.isPro ? context.l.uploadhavenPro : context.l.freeAccount) : context.l.notSignedIn, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              if (auth.pro.email != null) Text(auth.pro.email!, style: const TextStyle(fontSize: 12)),
            ]),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            if (!auth.pro.signedIn)
              FilledButton.icon(icon: Icon(Icons.login), label: Text(context.l.signInWithUploadhaven), onPressed: () => _signIn(context)),
            if (auth.pro.signedIn) ...[
              FilledButton.tonal(onPressed: () => auth.refreshProStatus(), child: Text(context.l.refreshStatus)),
              FilledButton.tonal(onPressed: () => launchUrl(Uri.parse('https://uploadhaven.com/account/subscription')), child: Text(auth.pro.isPro ? context.l.manageSubscription : context.l.upgradeToPro)),
              OutlinedButton(onPressed: () => auth.logout(), child: Text(context.l.signOut)),
            ],
          ]),
        ]))),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.l.connectionDiagnostics, style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_conn != null) ...[
            _row(context.l.dns, _conn!.dnsOk), _row(context.l.tcp, _conn!.tcpOk), _row(context.l.tls, _conn!.tlsOk), _row(context.l.api, _conn!.apiOk),
            Text('${context.l.latency}${_conn!.latencyMs}${context.l.ms}', style: const TextStyle(fontSize: 12)),
            if (_conn!.errorDetail != null) Text(_conn!.errorDetail!, style: const TextStyle(fontSize: 12, color: Color(0xFFF87171))),
          ],
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _testing ? null : () async {
              setState(() => _testing = true);
              _conn = await Api.connectivityTest();
              setState(() => _testing = false);
            },
            child: Text(_testing ? context.l.testing : context.l.runConnectivityTest),
          ),
        ]))),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.l.reportABug, style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(maxLines: 3, decoration: InputDecoration(hintText: context.l.describeWhatWentWrong, border: OutlineInputBorder()), onChanged: (v) => _report = v),
          const SizedBox(height: 8),
          if (_reportMsg != null) Text(_reportMsg!, style: const TextStyle(fontSize: 12)),
          FilledButton.tonal(
            onPressed: () async {
              final ok = await Api.submitBugReport(_report);
              setState(() => _reportMsg = ok ? context.l.reportSentThankYou : context.l.couldNotSendYouCanOnlySendOneReportPerHour);
            },
            child: Text(context.l.sendReport),
          ),
        ]))),
      ]),
    );
  }

  Widget _row(String label, bool ok) => Row(children: [
        Icon(ok ? Icons.check_circle : Icons.error, size: 16, color: ok ? Colors.green : Colors.redAccent),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ]);

  Future<void> _signIn(BuildContext context) async {
    await Auth.instance.openLogin();
    if (!context.mounted) return;
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l.finishSignIn),
        content: TextField(controller: ctrl, decoration: InputDecoration(hintText: context.l.pasteTheAuthCodeFromYourBrowser)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: Text(context.l.signIn)),
        ],
      ),
    );
    if (code != null && code.isNotEmpty) {
      final ok = await Auth.instance.handleCallback(code);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? context.l.signedIn : context.l.signInFailed)));
      }
    }
  }
}
