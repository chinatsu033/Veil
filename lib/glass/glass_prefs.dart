import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'glass_widgets.dart';

/// Light is the default: dark only when the user picks it (or follows a dark system).
enum GlassAppearance { light, dark, system }

/// The two Veil icon designs: A (off-white plate) and B (grey plate).
enum GlassIcon { light, dark }

const _appearanceKey = 'glass.appearance';
const _iconKey = 'glass.icon';
const glassAppChannel = MethodChannel('com.follow.clash/app');

abstract final class GlassPrefs {
  static final appearance = ValueNotifier(GlassAppearance.light);
  static final icon = ValueNotifier(GlassIcon.light);
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      appearance.value =
          GlassAppearance.values.asNameMap()[prefs.getString(_appearanceKey)] ??
          GlassAppearance.light;
      icon.value =
          GlassIcon.values.asNameMap()[prefs.getString(_iconKey)] ??
          GlassIcon.light;
    } catch (_) {}
  }

  static ThemeMode get themeMode => switch (appearance.value) {
    GlassAppearance.light => ThemeMode.light,
    GlassAppearance.dark => ThemeMode.dark,
    GlassAppearance.system => ThemeMode.system,
  };

  static Future<void> setAppearance(GlassAppearance value) async {
    appearance.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_appearanceKey, value.name);
    } catch (_) {}
  }

  static Future<void> setIcon(GlassIcon value) async {
    icon.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_iconKey, value.name);
    } catch (_) {}
    await applyIcon();
  }

  static String get _suffix => icon.value == GlassIcon.dark ? '_dark' : '';

  /// Asset folder of the tray icons for the chosen design. The macOS menu
  /// bar only draws template images, so both designs share one set there.
  static String trayDir({required bool windows, bool macOS = false}) => macOS
      ? 'assets/images/tray/macos'
      : 'assets/images/tray/${windows ? 'windows' : 'unix'}$_suffix';

  static String get iconAsset => 'assets/images/icon$_suffix.png';

  /// Android swaps the launcher activity-alias; Windows swaps the window and
  /// taskbar icon and macOS the Dock icon (the installed exe/app bundle icon
  /// cannot change at runtime).
  static Future<void> applyIcon() async {
    try {
      if (Platform.isAndroid) {
        await glassAppChannel.invokeMethod<bool>('setLauncherIcon', {
          'icon': icon.value.name,
        });
      } else if (Platform.isWindows) {
        final assets = p.join(
          p.dirname(Platform.resolvedExecutable),
          'data',
          'flutter_assets',
        );
        await windowManager.setIcon(
          p.join(assets, 'assets', 'images', 'icon$_suffix.ico'),
        );
      } else if (Platform.isMacOS) {
        final assets = p.join(
          p.dirname(p.dirname(Platform.resolvedExecutable)),
          'Frameworks',
          'App.framework',
          'Resources',
          'flutter_assets',
        );
        await glassAppChannel.invokeMethod<bool>('setDockIcon', {
          'path': p.join(
            assets,
            'assets',
            'images',
            'macos',
            'dock$_suffix.png',
          ),
        });
      }
    } catch (_) {}
  }
}

/// Keeps [glassDark] in sync with the resolved theme and repaints the glass
/// widgets (which read colours imperatively) when it flips.
class GlassThemeScope extends StatelessWidget {
  const GlassThemeScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark != glassDark) {
      glassDark = dark;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        void rebuild(Element element) {
          element.markNeedsBuild();
          element.visitChildren(rebuild);
        }

        (context as Element).visitChildren(rebuild);
      });
    }
    return child;
  }
}
