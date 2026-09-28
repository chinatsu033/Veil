import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

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

enum GlassWindowMaterial { transparent, none }

class GlassWindow {
  GlassWindow._();

  static GlassWindowMaterial material = GlassWindowMaterial.none;
  static final ValueNotifier<bool> alwaysOnTop = ValueNotifier(false);
  static double _height = glassWidgetHeight;
  static double _desired = glassWidgetHeight;
  static int _overlays = 0;
  static int _resizeToken = 0;
  static const _overlayMinHeight = 560.0;

  static void overlayPushed() {
    _overlays++;
    if (_height < _overlayMinHeight) unawaited(_animateTo(_overlayMinHeight));
  }

  static void overlayPopped() {
    if (_overlays == 0) return;
    _overlays--;
    if (_overlays == 0) unawaited(_animateTo(_desired));
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
      // Fully transparent window: only the glass cards are drawn, floating
      // straight over the desktop (Windows 10 and 11 alike; macOS below).
      try {
        await acrylic.Window.initialize();
        await acrylic.Window.setEffect(
          effect: acrylic.WindowEffect.transparent,
          color: Colors.transparent,
        );
        material = GlassWindowMaterial.transparent;
      } catch (_) {
        material = GlassWindowMaterial.none;
      }
    } else if (Platform.isMacOS) {
      try {
        final transparent = await glassAppChannel.invokeMethod<bool>(
          'setWindowTransparent',
        );
        material = transparent == true
            ? GlassWindowMaterial.transparent
            : GlassWindowMaterial.none;
      } catch (_) {
        material = GlassWindowMaterial.none;
      }
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

  /// Grows or shrinks the window from its top edge, keeping it on screen.
  static Future<void> animateHeight(double target) {
    _desired = target;
    if (_overlays > 0 && target < _overlayMinHeight) {
      target = _overlayMinHeight;
    }
    return _animateTo(target);
  }

  static Future<void> _animateTo(
    double target, {
    Duration duration = const Duration(milliseconds: 240),
  }) async {
    if (glassDemoMode) {
      _height = target;
      return;
    }
    final token = ++_resizeToken;
    final start = _height;
    if ((target - start).abs() < 1) return;
    try {
      if (target > start) await _ensureRoomBelow(target);
      const steps = 12;
      for (var i = 1; i <= steps; i++) {
        if (token != _resizeToken) return;
        final t = Curves.easeOutCubic.transform(i / steps);
        final h = ui.lerpDouble(start, target, t)!;
        await windowManager.setSize(Size(glassWidgetWidth, h.roundToDouble()));
        _height = h;
        await Future<void>.delayed(
          Duration(milliseconds: duration.inMilliseconds ~/ steps),
        );
      }
      _height = target;
    } catch (_) {
      _height = target;
    }
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

/// The window itself stays invisible so the glass cards float over the
/// desktop. Where per-pixel transparency is unavailable (e.g. Linux), a light
/// frosted panel keeps the gaps from turning black.
class GlassWindowFrame extends StatelessWidget {
  const GlassWindowFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (glassDemoMode ||
        GlassWindow.material == GlassWindowMaterial.transparent) {
      return child;
    }
    const radius = 26.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const GlassBackground(),
          CustomPaint(
            foregroundPainter: GlassRimPainter(radius: radius),
            child: child,
          ),
        ],
      ),
    );
  }
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
