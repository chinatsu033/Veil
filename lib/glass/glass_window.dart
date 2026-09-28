import 'dart:async';
import 'dart:io';

import 'package:flutter_acrylic/flutter_acrylic.dart' as acrylic;
import 'package:material_ui/material_ui.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'glass_prefs.dart';
import 'glass_widgets.dart';

const glassWidgetWidth = 640.0;
const glassWidgetHeight = 180.0;
const glassMapHeight = 622.0;
const glassSettingsHeight = 648.0;
const _alwaysOnTopKey = 'glass.alwaysOnTop';

/// Set by the screenshot harness: paints a fake desktop behind the widget.
bool glassDemoMode = false;

/// Forces the Android layout decisions (used by the harness on desktop hosts).
bool glassMobileLayout = false;

/// [backdrop]: the OS blurs behind the window (Windows 11, macOS) under a light
/// scrim; [transparent]: no blur, denser scrim; [opaque]: Linux, solid panel.
enum GlassWindowMaterial { backdrop, transparent, opaque }

class GlassWindow {
  GlassWindow._();

  static GlassWindowMaterial material = GlassWindowMaterial.opaque;
  static final ValueNotifier<bool> alwaysOnTop = ValueNotifier(false);

  static final ValueNotifier<double> frameHeight = ValueNotifier(
    glassWidgetHeight,
  );
  static const frameDuration = Duration(milliseconds: 240);
  static const _contentFade = Duration(milliseconds: 160);
  static double _height = glassWidgetHeight;
  static double _desired = glassWidgetHeight;
  static int _overlays = 0;
  static int _resizeToken = 0;
  static const _overlayMinHeight = 560.0;
  static bool _windowsBackdrop = false;

  static GlassWindowMaterial get effectiveMaterial =>
      glassDemoMode ? GlassWindowMaterial.transparent : material;

  static bool get animatesFrame =>
      effectiveMaterial == GlassWindowMaterial.transparent;

  static double get frameRadius => _windowsBackdrop ? 0 : 26;

  static double get scrimOpacity =>
      effectiveMaterial == GlassWindowMaterial.backdrop ? 0.72 : 0.86;

  static void overlayPushed() {
    _overlays++;
    if (_height < _overlayMinHeight) unawaited(_resizeTo(_overlayMinHeight));
  }

  static void overlayPopped() {
    if (_overlays == 0) return;
    _overlays--;
    if (_overlays == 0) unawaited(_resizeTo(_desired));
  }

  static Future<void> init() async {
    if (glassDemoMode) return;
    try {
      await windowManager.setAsFrameless();
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.setHasShadow(false);
      await windowManager.setResizable(false);
      await windowManager.setMaximizable(false);
      await windowManager.setMinimumSize(
        const Size(glassWidgetWidth, glassWidgetHeight),
      );
      await windowManager.setSize(
        const Size(glassWidgetWidth, glassWidgetHeight),
      );
    } catch (_) {}
    if (Platform.isWindows) {
      material = await _initWindows();
    } else if (Platform.isMacOS) {
      material = await _initMacos();
    } else {
      // GTK windows here have no alpha visual; readability beats a black rim.
      material = GlassWindowMaterial.opaque;
    }
    if (GlassPrefs.icon.value != GlassIcon.light) {
      await GlassPrefs.applyIcon();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final onTop = prefs.getBool(_alwaysOnTopKey) ?? false;
      alwaysOnTop.value = onTop;
      if (onTop) await windowManager.setAlwaysOnTop(true);
    } catch (_) {}
  }

  static Future<GlassWindowMaterial> _initWindows() async {
    try {
      await acrylic.Window.initialize();
    } catch (_) {
      return GlassWindowMaterial.opaque;
    }
    final build = windowsBuildNumber(Platform.operatingSystemVersion);
    if (build >= 22000) {
      try {
        await _applyWindowsBackdrop(build);
        await windowManager.setWindowCornerPreference(round: true);
        _windowsBackdrop = true;
        return GlassWindowMaterial.backdrop;
      } catch (_) {}
    }
    try {
      await acrylic.Window.setEffect(
        effect: acrylic.WindowEffect.transparent,
        color: Colors.transparent,
      );
      return GlassWindowMaterial.transparent;
    } catch (_) {
      return GlassWindowMaterial.opaque;
    }
  }

  /// 22H2 (22523+) blurs through DWM's system backdrop, which stays smooth
  /// while dragging; 21H2 only offers mica there, legacy acrylic lags.
  static Future<void> _applyWindowsBackdrop(int build) {
    return acrylic.Window.setEffect(
      effect: build >= 22523
          ? acrylic.WindowEffect.acrylic
          : acrylic.WindowEffect.mica,
      dark: glassDark,
    );
  }

  static Future<GlassWindowMaterial> _initMacos() async {
    try {
      final result = await glassAppChannel.invokeMethod<String>(
        'setWindowBackdrop',
        {'dark': glassDark, 'radius': frameRadius},
      );
      return switch (result) {
        'backdrop' => GlassWindowMaterial.backdrop,
        'transparent' => GlassWindowMaterial.transparent,
        _ => GlassWindowMaterial.opaque,
      };
    } catch (_) {
      return GlassWindowMaterial.opaque;
    }
  }

  static Future<void> syncBackdrop() async {
    if (glassDemoMode || material != GlassWindowMaterial.backdrop) return;
    try {
      if (Platform.isWindows) {
        await _applyWindowsBackdrop(
          windowsBuildNumber(Platform.operatingSystemVersion),
        );
      } else if (Platform.isMacOS) {
        await glassAppChannel.invokeMethod<String>('setWindowBackdrop', {
          'dark': glassDark,
          'radius': frameRadius,
        });
      }
    } catch (_) {}
  }

  static Future<void> setAlwaysOnTop(bool value) async {
    alwaysOnTop.value = value;
    if (glassDemoMode) return;
    try {
      await windowManager.setAlwaysOnTop(value);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_alwaysOnTopKey, value);
    } catch (_) {}
  }

  static Future<void> startDragging() async {
    if (glassDemoMode) return;
    try {
      await windowManager.startDragging();
    } catch (_) {}
  }

  static Future<void> animateHeight(double target) {
    _desired = target;
    if (_overlays > 0 && target < _overlayMinHeight) {
      target = _overlayMinHeight;
    }
    return _resizeTo(target);
  }

  // Stepping the native window size per frame janked (a platform round trip
  // and relayout each); resize once and animate the panel height instead.
  static Future<void> _resizeTo(double target) async {
    final token = ++_resizeToken;
    if (target >= _height - 0.5) {
      await _setWindowHeight(target);
      if (token != _resizeToken) return;
      frameHeight.value = target;
      return;
    }
    if (animatesFrame) frameHeight.value = target;
    await Future<void>.delayed(animatesFrame ? frameDuration : _contentFade);
    if (token != _resizeToken) return;
    frameHeight.value = target;
    await _setWindowHeight(target);
  }

  static Future<void> _setWindowHeight(double target) async {
    if ((target - _height).abs() < 0.5) return;
    if (glassDemoMode) {
      _height = target;
      return;
    }
    try {
      if (target > _height) await _ensureRoomBelow(target);
      await windowManager.setSize(Size(glassWidgetWidth, target));
    } catch (_) {}
    _height = target;
  }

  static Future<void> _ensureRoomBelow(double target) async {
    final bounds = await windowManager.getBounds();
    final displays = await screenRetriever.getAllDisplays();
    for (final display in displays) {
      final origin = display.visiblePosition ?? Offset.zero;
      final size = display.visibleSize ?? display.size;
      final area = origin & size;
      if (area.contains(bounds.topLeft + const Offset(4, 4))) {
        final overflow = bounds.top + target - area.bottom;
        if (overflow > 0) {
          final top = (bounds.top - overflow).clamp(area.top, double.infinity);
          await windowManager.setPosition(Offset(bounds.left, top.toDouble()));
        }
        return;
      }
    }
  }
}

int windowsBuildNumber(String version) {
  final match = RegExp(r'Build (\d+)').firstMatch(version);
  return match == null ? 0 : int.parse(match.group(1)!);
}

/// Scrim behind the cards so the desktop never competes with the text.
class GlassWindowFrame extends StatelessWidget {
  const GlassWindowFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = RepaintBoundary(child: child);
    if (GlassWindow.effectiveMaterial == GlassWindowMaterial.opaque) {
      return Stack(
        fit: StackFit.expand,
        children: [const GlassBackground(), content],
      );
    }
    final radius = GlassWindow.frameRadius;
    final scrim = RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: radius > 0 ? GlassRimPainter(radius: radius) : null,
        child: GlassBackground(opacity: GlassWindow.scrimOpacity),
      ),
    );
    return ValueListenableBuilder<double>(
      valueListenable: GlassWindow.frameHeight,
      builder: (context, height, _) => TweenAnimationBuilder<double>(
        tween: Tween(end: height),
        duration: GlassWindow.animatesFrame
            ? GlassWindow.frameDuration
            : Duration.zero,
        curve: Curves.easeOutCubic,
        builder: (context, visible, _) => ClipRRect(
          clipper: _PanelClipper(visible, radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: visible,
                child: scrim,
              ),
              content,
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelClipper extends CustomClipper<RRect> {
  _PanelClipper(this.height, this.radius);

  final double height;
  final double radius;

  @override
  RRect getClip(Size size) => RRect.fromLTRBR(
    0,
    0,
    size.width,
    height.clamp(0, size.height),
    Radius.circular(radius),
  );

  @override
  bool shouldReclip(_PanelClipper oldClipper) =>
      oldClipper.height != height || oldClipper.radius != radius;
}

/// Grows the collapsed widget while a dialog or sheet is up so it has room.
class GlassDialogObserver extends NavigatorObserver {
  bool _isOverlay(Route<dynamic>? route) => route is PopupRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isOverlay(route)) GlassWindow.overlayPushed();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isOverlay(route)) GlassWindow.overlayPopped();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isOverlay(route)) GlassWindow.overlayPopped();
  }
}
