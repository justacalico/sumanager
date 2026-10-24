import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sumanager/services/api.dart';
import 'package:sumanager/services/auth.dart';
import 'package:sumanager/services/settings.dart';
import 'helpers.dart';

void main() {
  setUpAll(() async {
    setupTestEnv();
    await Settings.instance.load();
  });

  test('buildLoginUrl has pkce params', () {
    final url = Auth.instance.buildLoginUrl();
    expect(url, contains('code_challenge='));
    expect(url, contains('code_challenge_method=S256'));
    expect(url, contains('client_id=launcher'));
  });

  test('handleCallback without verifier fails', () async {
    final a = Auth.instance;
    a.logout();
    expect(await a.handleCallback('code'), false);
  });

  test('token exchange then refresh then logout', () async {
    final a = Auth.instance;
    http.Client factory() => MockClient((req) async {
      if (req.url.path.contains('oauth/token')) {
        return http.Response(jsonEncode({'access_token': 'at', 'refresh_token': 'rt'}), 200);
      }
      if (req.url.path.contains('me')) {
        return http.Response(jsonEncode({'id': 'u', 'email': 'e@x', 'is_premium': true}), 200);
      }
      return http.Response('{}', 404);
    });
    a.httpFactory = factory;
    Api.clientFactory = factory;
    a.buildLoginUrl();
    expect(await a.handleCallback('code'), true);
    expect(a.accessToken, 'at');
    expect(a.pro.isPro, true);
    expect(await a.refresh(), true);
    await a.load();
    await a.logout();
    expect(a.accessToken, isNull);
    expect(a.pro.signedIn, false);
    a.httpFactory = null;
    Api.clientFactory = null;
  });

  test('openLogin launches url', () async {
    Auth.instance.buildLoginUrl();
    await Auth.instance.openLogin();
  });

  test('pro status retry after refresh', () async {
    final a = Auth.instance;
    var meCalls = 0;
    http.Client factory() => MockClient((req) async {
      if (req.url.path.contains('me')) {
        meCalls++;
        return meCalls == 1 ? http.Response('{}', 401) : http.Response(jsonEncode({'id': 'u', 'is_premium': true}), 200);
      }
      return http.Response(jsonEncode({'access_token': 'at2', 'refresh_token': 'rt2'}), 200);
    });
    a.httpFactory = factory;
    Api.clientFactory = factory;
    a.accessToken = 'old';
    a.refreshToken = 'rt';
    await a.refreshProStatus();
    expect(a.pro.isPro, true);
    expect(meCalls, 2);
    a.accessToken = null;
    await a.refreshProStatus();
    expect(a.pro.signedIn, false);
    a.httpFactory = null;
    Api.clientFactory = null;
  });

  test('token request failure returns false', () async {
    final a = Auth.instance;
    a.httpFactory = () => MockClient((req) async => http.Response('err', 500));
    Api.clientFactory = a.httpFactory;
    a.buildLoginUrl();
    expect(await a.handleCallback('code'), false);
    a.refreshToken = 'rt';
    expect(await a.refresh(), false);
    a.httpFactory = null;
    Api.clientFactory = null;
  });
}
