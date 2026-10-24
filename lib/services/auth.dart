import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
import 'api.dart';
import 'settings.dart';

class Auth extends ChangeNotifier {
  static final Auth instance = Auth._();
  Auth._();

  ProStatus pro = const ProStatus();
  String? accessToken;
  String? refreshToken;
  String? _codeVerifier;
  http.Client Function()? httpFactory;

  static const clientId = 'launcher';
  static const redirectUri = 'steamunlocked-launcher://auth-success';
  static const authorizeUrl = 'https://uploadhaven.com/oauth/authorize';
  static const tokenUrl = 'https://uploadhaven.com/oauth/token';

  Future<void> load() async {
    final j = await Settings.instance.readJson('auth.json');
    accessToken = j['access_token'];
    refreshToken = j['refresh_token'];
    if (accessToken != null) await refreshProStatus();
  }

  String buildLoginUrl() {
    final rnd = Random.secure();
    _codeVerifier = base64UrlEncode(List.generate(64, (_) => rnd.nextInt(256))).replaceAll('=', '');
    final challenge = base64UrlEncode(sha256.convert(utf8.encode(_codeVerifier!)).bytes).replaceAll('=', '');
    final state = base64UrlEncode(List.generate(16, (_) => rnd.nextInt(256))).replaceAll('=', '');
    return '$authorizeUrl?response_type=code&client_id=$clientId&redirect_uri=${Uri.encodeComponent(redirectUri)}&code_challenge=$challenge&code_challenge_method=S256&state=$state';
  }

  Future<void> openLogin() async {
    final u = Uri.parse(buildLoginUrl());
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  Future<bool> handleCallback(String code) async {
    final v = _codeVerifier;
    if (v == null) return false;
    final resp = await _tokenRequest({
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': redirectUri,
      'client_id': clientId,
      'code_verifier': v,
    });
    if (resp == null) return false;
    accessToken = resp['access_token'];
    refreshToken = resp['refresh_token'];
    await _persist();
    await refreshProStatus();
    return true;
  }

  Future<Map<String, dynamic>?> _tokenRequest(Map<String, String> body) async {
    try {
      final c = httpFactory?.call() ?? http.Client();
      final r = await c.post(Uri.parse(tokenUrl),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: body)
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return null;
      return jsonDecode(r.body);
    } catch (_) {
      return null;
    }
  }

  Future<bool> refresh() async {
    if (refreshToken == null) return false;
    final resp = await _tokenRequest({'grant_type': 'refresh_token', 'refresh_token': refreshToken!, 'client_id': clientId});
    if (resp == null) return false;
    accessToken = resp['access_token'] ?? accessToken;
    refreshToken = resp['refresh_token'] ?? refreshToken;
    await _persist();
    return true;
  }

  Future<void> refreshProStatus() async {
    if (accessToken == null) {
      pro = const ProStatus();
      notifyListeners();
      return;
    }
    var s = await Api.fetchAccount(accessToken!);
    if (!s.signedIn && refreshToken != null && await refresh()) {
      s = await Api.fetchAccount(accessToken!);
    }
    pro = s;
    notifyListeners();
  }

  Future<void> _persist() async {
    await Settings.instance.writeJson('auth.json', {'access_token': accessToken, 'refresh_token': refreshToken});
  }

  Future<void> logout() async {
    accessToken = null;
    refreshToken = null;
    pro = const ProStatus();
    await _persist();
    notifyListeners();
  }
}
