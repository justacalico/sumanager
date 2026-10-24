import 'package:flutter/material.dart';
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
              Text(auth.pro.signedIn ? (auth.pro.isPro ? 'UploadHaven Pro' : 'Free account') : 'Not signed in', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              if (auth.pro.email != null) Text(auth.pro.email!, style: const TextStyle(fontSize: 12)),
            ]),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            if (!auth.pro.signedIn)
              FilledButton.icon(icon: const Icon(Icons.login), label: const Text('Sign in with UploadHaven'), onPressed: () => _signIn(context)),
            if (auth.pro.signedIn) ...[
              FilledButton.tonal(onPressed: () => auth.refreshProStatus(), child: const Text('Refresh status')),
              FilledButton.tonal(onPressed: () => launchUrl(Uri.parse('https://uploadhaven.com/account/subscription')), child: Text(auth.pro.isPro ? 'Manage subscription' : 'Upgrade to Pro')),
              OutlinedButton(onPressed: () => auth.logout(), child: const Text('Sign out')),
            ],
          ]),
        ]))),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Connection diagnostics', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_conn != null) ...[
            _row('DNS', _conn!.dnsOk), _row('TCP', _conn!.tcpOk), _row('TLS', _conn!.tlsOk), _row('API', _conn!.apiOk),
            Text('Latency: ${_conn!.latencyMs} ms', style: const TextStyle(fontSize: 12)),
            if (_conn!.errorDetail != null) Text(_conn!.errorDetail!, style: const TextStyle(fontSize: 12, color: Color(0xFFF87171))),
          ],
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _testing ? null : () async {
              setState(() => _testing = true);
              _conn = await Api.connectivityTest();
              setState(() => _testing = false);
            },
            child: Text(_testing ? 'Testing…' : 'Run connectivity test'),
          ),
        ]))),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Report a bug', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(maxLines: 3, decoration: const InputDecoration(hintText: 'Describe what went wrong…', border: OutlineInputBorder()), onChanged: (v) => _report = v),
          const SizedBox(height: 8),
          if (_reportMsg != null) Text(_reportMsg!, style: const TextStyle(fontSize: 12)),
          FilledButton.tonal(
            onPressed: () async {
              final ok = await Api.submitBugReport(_report);
              setState(() => _reportMsg = ok ? 'Report sent. Thank you!' : 'Could not send. You can only send one report per hour.');
            },
            child: const Text('Send report'),
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
        title: const Text('Finish sign-in'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Paste the auth code from your browser')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Sign in')),
        ],
      ),
    );
    if (code != null && code.isNotEmpty) {
      final ok = await Auth.instance.handleCallback(code);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Signed in' : 'Sign-in failed')));
      }
    }
  }
}
