import 'dart:io';
import '../l10n_ext.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

class AppShell extends StatelessWidget {
  final int page;
  final ValueChanged<int> onNavigate;
  final Widget child;
  const AppShell({super.key, required this.page, required this.onNavigate, required this.child});

  static List<(IconData, String)> _dests(BuildContext context) => [
    (Icons.storefront_outlined, context.l.browse),
    (Icons.download_outlined, context.l.downloads),
    (Icons.videogame_asset_outlined, context.l.library),
    (Icons.favorite_border, context.l.favorites),
    (Icons.person_outline, context.l.account),
    (Icons.settings_outlined, context.l.settings),
    (Icons.help_outline, context.l.help),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (isDesktop) const TopBar(),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 232,
                  child: Material(
                    color: const Color(0xFF191921),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      children: [
                        for (var i = 0; i < _dests(context).length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Material(
                              type: MaterialType.transparency,
                              shape: const StadiumBorder(),
                              child: ListTile(
                                dense: true,
                                shape: const StadiumBorder(),
                                leading: Icon(_dests(context)[i].$1, size: 20),
                                title: Text(_dests(context)[i].$2),
                                selected: page == i,
                                selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
                                hoverColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                onTap: () => onNavigate(i),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Material(
        color: const Color(0xFF101015),
        child: Row(
          children: [
            const SizedBox(width: 12),
            _Light(color: const Color(0xFFFF5F57), icon: Icons.close, onTap: () => windowManager.close()),
            _Light(color: const Color(0xFFFEBC2E), icon: Icons.remove, onTap: () => windowManager.minimize()),
            _Light(color: const Color(0xFF28C840), icon: Icons.add, onTap: () async {
              if (await windowManager.isMaximized()) {
                windowManager.unmaximize();
              } else {
                windowManager.maximize();
              }
            }),
            const SizedBox(width: 12),
            Expanded(
              child: DragToMoveArea(
                child: GestureDetector(
                  onDoubleTap: () async {
                    if (await windowManager.isMaximized()) {
                      windowManager.unmaximize();
                    } else {
                      windowManager.maximize();
                    }
                  },
                  child: Center(
                    child: Text(context.l.steamunlockedLauncher, style: TextStyle(fontSize: 13, color: Color(0xFF9C9CAB))),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 96),
          ],
        ),
      ),
    );
  }
}

class _Light extends StatefulWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _Light({required this.color, required this.icon, required this.onTap});
  @override
  State<_Light> createState() => _LightState();
}

class _LightState extends State<_Light> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 12, height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
          child: hover ? Icon(widget.icon, size: 9, color: Colors.black87) : null,
        ),
      ),
    );
  }
}
