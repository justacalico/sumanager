import 'package:flutter_test/flutter_test.dart';
import 'package:sumanager/l10n/app_localizations.dart';

void main() {
  test('all locales load and expose strings', () async {
    for (final loc in AppLocalizations.supportedLocales) {
      final l = await AppLocalizations.delegate.load(loc);
      expect(l.browse.isNotEmpty, isTrue);
      expect(l.settings.isNotEmpty, isTrue);
      expect(l.downloading.isNotEmpty, isTrue);
    }
  });
}
