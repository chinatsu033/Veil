import 'package:fl_clash/common/common.dart';
import 'package:material_ui/material_ui.dart';

import 'desktop_home.dart';
import 'glass_widgets.dart';
import 'mobile_home.dart';

class GlassHome extends StatelessWidget {
  const GlassHome({super.key});

  @override
  Widget build(BuildContext context) {
    if (system.isDesktop) configureGlassForDesktop();
    return system.isDesktop
        ? const DesktopGlassHome()
        : const MobileGlassHome();
  }
}

ThemeData glassTheme(ThemeData base, {bool dark = false}) {
  final scheme = dark ? _darkScheme : _lightScheme;
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    cardTheme: base.cardTheme.copyWith(
      color: dark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: dark
          ? scheme.surfaceContainerHigh
          : scheme.surfaceContainerLowest,
      // A light haze instead of a dark scrim: on the transparent desktop
      // window the barrier would otherwise tint the wallpaper grey.
      barrierColor: dark ? const Color(0x80000000) : const Color(0x66EEF2FA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

const _lightScheme = ColorScheme.light(
  primary: Color(0xFF2F7CF6),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFDCE8FF),
  onPrimaryContainer: Color(0xFF0B2A5C),
  secondary: Color(0xFF55627E),
  secondaryContainer: Color(0xFFE3E8F4),
  onSecondaryContainer: Color(0xFF1B2233),
  tertiary: Color(0xFF1FB57F),
  tertiaryContainer: Color(0xFFD5F5E8),
  surface: Color(0xFFF5F7FC),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF9FAFE),
  surfaceContainer: Color(0xFFF0F3FA),
  surfaceContainerHigh: Color(0xFFEAEEF7),
  surfaceContainerHighest: Color(0xFFE3E8F3),
  onSurface: Color(0xFF1B2233),
  onSurfaceVariant: Color(0xFF566079),
  outline: Color(0xFFB4BCCE),
  outlineVariant: Color(0xFFDDE2EC),
);

/// Pure greys (zero saturation) so Veil's own pages carry no colour cast.
const _darkScheme = ColorScheme.dark(
  primary: Color(0xFFE6E6E6),
  onPrimary: Color(0xFF141414),
  primaryContainer: Color(0xFF3A3A3A),
  onPrimaryContainer: Color(0xFFF2F2F2),
  secondary: Color(0xFFBDBDBD),
  onSecondary: Color(0xFF141414),
  secondaryContainer: Color(0xFF333333),
  onSecondaryContainer: Color(0xFFEDEDED),
  tertiary: Color(0xFFD0D0D0),
  onTertiary: Color(0xFF141414),
  tertiaryContainer: Color(0xFF383838),
  onTertiaryContainer: Color(0xFFEDEDED),
  error: Color(0xFFE0E0E0),
  onError: Color(0xFF141414),
  errorContainer: Color(0xFF4A4A4A),
  onErrorContainer: Color(0xFFF5F5F5),
  surface: Color(0xFF121212),
  surfaceContainerLowest: Color(0xFF0B0B0B),
  surfaceContainerLow: Color(0xFF181818),
  surfaceContainer: Color(0xFF1E1E1E),
  surfaceContainerHigh: Color(0xFF262626),
  surfaceContainerHighest: Color(0xFF2E2E2E),
  onSurface: Color(0xFFEDEDED),
  onSurfaceVariant: Color(0xFFB0B0B0),
  outline: Color(0xFF6E6E6E),
  outlineVariant: Color(0xFF3A3A3A),
  inverseSurface: Color(0xFFE6E6E6),
  onInverseSurface: Color(0xFF1A1A1A),
  inversePrimary: Color(0xFF3A3A3A),
  surfaceTint: Color(0x00000000),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
);
