import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'widgets/shell.dart';
import 'screens/browse.dart';
import 'screens/downloads.dart';
import 'screens/library.dart';
import 'screens/favorites.dart';
import 'screens/settings_screen.dart';
import 'screens/help.dart';
import 'screens/account.dart';
import 'screens/welcome.dart';
import 'services/settings.dart';

class SuManagerApp extends StatefulWidget {
  const SuManagerApp({super.key});
  @override
  State<SuManagerApp> createState() => _SuManagerAppState();
}

class _SuManagerAppState extends State<SuManagerApp> {
  int _page = 0;
  static const titles = ['Browse', 'Downloads', 'Library', 'Favorites', 'Account', 'Settings', 'Help'];

  @override
  void initState() {
    super.initState();
    Settings.instance.addListener(_onSettings);
  }

  void _onSettings() => setState(() {});

  @override
  void dispose() {
    Settings.instance.removeListener(_onSettings);
    super.dispose();
  }

  Locale? get _locale {
    switch (Settings.instance.locale) {
      case 'en': return const Locale('en', 'GB');
      case 'zh': return const Locale('zh');
      case 'ru': return const Locale('ru');
      case 'ga': return const Locale('ga');
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B8DEF), brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF141419),
      useMaterial3: true,
      cardColor: const Color(0xFF1D1D26),
    );
    return MaterialApp(
      title: 'SteamUnlocked Launcher',
      debugShowCheckedModeBanner: false,
      theme: dark,
      locale: _locale,
      supportedLocales: const [Locale('en'), Locale('en', 'GB'), Locale('zh'), Locale('ru'), Locale('ga')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: !Settings.instance.welcomeShown
          ? WelcomeScreen(onDone: () {
              Settings.instance.setWelcomeShown(true);
              setState(() {});
            })
          : AppShell(
              title: titles[_page],
              page: _page,
              onNavigate: (i) => setState(() => _page = i),
              child: switch (_page) {
                0 => const BrowseScreen(),
                1 => const DownloadsScreen(),
                2 => const LibraryScreen(),
                3 => const FavoritesScreen(),
                4 => const AccountScreen(),
                5 => const SettingsScreen(),
                _ => const HelpScreen(),
              },
            ),
    );
  }
}
