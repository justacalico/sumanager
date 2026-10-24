import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/painting.dart';

Directory? _tmp;
bool _max = false;

final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');

class FakeHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeReq();
  @override
  Future<HttpClientRequest> headUrl(Uri url) async => _FakeReq();
}

class _FakeReq extends Fake implements HttpClientRequest {
  final _headers = _FakeHeaders();
  @override
  HttpHeaders get headers => _headers;
  @override
  Future<HttpClientResponse> close() => Future.value(_FakeResp());
}

class _FakeHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _FakeResp extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _png.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream.value(_png).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
}

class FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => FakeHttpClient();
}

class FakeFilePicker extends FilePicker {
  static String? pickDir;
  static String? pickFile = '/tmp/picked/wine';
  @override
  Future<String?> getDirectoryPath({String? dialogTitle, bool lockParentWindow = false, String? initialDirectory}) async =>
      pickDir ?? '${_tmp!.path}/picked';
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async =>
      pickFile == null ? null : FilePickerResult([PlatformFile(name: 'wine', path: pickFile, size: 1)]);
}

class FakeUrlLauncher extends UrlLauncherPlatform {
  @override
  final LinkDelegate? linkDelegate = null;
  @override
  Future<bool> canLaunch(String url) async => true;
  @override
  Future<bool> launch(String url,
          {required bool useSafariVC,
          required bool useWebView,
          required bool enableJavaScript,
          required bool enableDomStorage,
          required bool universalLinksOnly,
          required Map<String, String> headers,
          String? webOnlyWindowName}) async =>
      true;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async => true;
  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;
  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async => true;
  @override
  Future<void> closeWebView() async {}
}

Future<void> setupTestEnv() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = FakeHttpOverrides();
  final loader = FontLoader('Noto Sans')
    ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/NotoSans-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
  await loader.load();
  SharedPreferences.setMockInitialValues({});
  UrlLauncherPlatform.instance = FakeUrlLauncher();
  FilePicker.platform = FakeFilePicker();
  _tmp ??= Directory.systemTemp.createTempSync('sumanager_test');
  File('${_tmp!.path}/picked/picked_game.exe').createSync(recursive: true);
  File('/tmp/picked/wine')
    ..createSync(recursive: true)
    ..writeAsStringSync('#!/bin/sh\nexit 0\n');
  Process.run('chmod', ['755', '/tmp/picked/wine']);
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => _tmp!.path,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/package_info'),
    (call) async => {'appName': 'sumanager', 'packageName': 'gitlab.httpanimations.sumanager', 'version': '0.4.2', 'buildNumber': '1'},
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('window_manager'),
    (call) async {
      switch (call.method) {
        case 'isMaximized':
          _max = !_max;
          return _max;
        case 'isVisible':
        case 'isFocused':
          return false;
        default:
          return null;
      }
    },
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/url_launcher'),
    (call) async => true,
  );
}
