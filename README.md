# sumanager

SteamUnlocked Launcher rewritten in Flutter for Windows, Linux and macOS.

## Features

- Browse the game catalog with search, sort (recent / views / name / size), category and file-size filters
- Resumable parallel downloads with chunk ranges, pause/resume, auto extraction
- Local library with scanning, collections, favorites, play tracking
- UploadHaven Pro account sign-in (PKCE OAuth)
- Platform runners: Windows runs games directly, Linux uses Steam Proton or Wine, macOS uses a Wine build you point at (CrossOver, GPTK, Whisky)
- Update check against GitLab releases, bug reports, connectivity test

## Development

```sh
flutter pub get
flutter gen-l10n   # regenerate l10n/app_localizations*.dart if ARB files change
flutter analyze
flutter test --coverage   # must stay at 100%
```

Releases are cut with [cocogitto](https://github.com/cocogitto/cocogitto): `cog bump --auto` bumps versions in `pubspec.yaml`, `lib/services/api.dart` and `lib/screens/settings_screen.dart`.

## Platforms

| OS | How games run |
|---|---|
| Windows | Direct |
| Linux | Proton, then Wine fallback |
| macOS | Wine binary set in Settings |

Flatpak packaging lives in `packaging/flatpak/`.
