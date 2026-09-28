import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// Whether the glass UI currently renders its dark (neutral graphite) look.
/// Set by [GlassThemeScope]; widgets read colours through [GlassColors].
bool glassDark = false;

Color _pick(Color light, Color dark) => glassDark ? dark : light;

abstract final class GlassColors {
  static Color get bgTop =>
      _pick(const Color(0xFFEAF1FF), const Color(0xFF1D1D1D));
  static Color get bgMid =>
      _pick(const Color(0xFFF4F6FC), const Color(0xFF131313));
  static Color get bgBottom =>
      _pick(const Color(0xFFF3EEF8), const Color(0xFF0A0A0A));
  static Color get glow =>
      _pick(const Color(0xFF8CC8FF), const Color(0xFFFFFFFF));
  static Color get accent =>
      _pick(const Color(0xFF2F7CF6), const Color(0xFFEDEDED));
  static Color get running =>
      _pick(const Color(0xFF1FB57F), const Color(0xFFF2F2F2));
  static Color get text =>
      _pick(const Color(0xFF1B2233), const Color(0xFFF2F2F2));
  static Color get textDim =>
      _pick(const Color(0xFF566079), const Color(0xFFB4B4B4));
  static Color get textFaint =>
      _pick(const Color(0xFF8D96AB), const Color(0xFF7C7C7C));
  static Color get hairline =>
      _pick(const Color(0x1A1B2540), const Color(0x1FFFFFFF));
  static Color get danger =>
      _pick(const Color(0xFFE5484D), const Color(0xFFD9D9D9));

  /// Neutral ink used for faint map dots and inactive tracks.
  static Color get ink =>
      _pick(const Color(0xFF5B6B8C), const Color(0xFFFFFFFF));

  /// Filled call-to-action button (Save) and its label.
  static Color get primaryFill => _pick(
    const Color(0xFF2F7CF6).withValues(alpha: 0.82),
    const Color(0xFFF2F2F2).withValues(alpha: 0.88),
  );
  static Color get onPrimary =>
      _pick(const Color(0xFFFFFFFF), const Color(0xFF111111));

  /// Glyph colour of the play button while the proxy runs.
  static Color get playActive =>
      _pick(const Color(0xFF0E8A5F), const Color(0xFFFFFFFF));

  static Color get switchOn => _pick(
    const Color(0xFF1FB57F).withValues(alpha: 0.85),
    const Color(0xFFBDBDBD),
  );
}

/// Light liquid-glass look: how milky the fill is. Desktop windows are
/// transparent and cannot blur the wallpaper, so their glass is milkier.
double glassMilk = 1;

/// Backdrop blur only helps where Flutter paints what is behind the glass
/// (Android). A transparent desktop window has nothing to blur.
bool glassBlur = true;

void configureGlassForDesktop() {
  glassBlur = false;
  glassMilk = 1.45;
}

const glassTabular = [ui.FontFeature.tabularFigures()];

class GlassBlurScope extends InheritedWidget {
  const GlassBlurScope({
    super.key,
    required this.enabled,
    required super.child,
  });

  final bool enabled;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassBlurScope>()?.enabled ??
      true;

  @override
  bool updateShouldNotify(GlassBlurScope oldWidget) =>
      oldWidget.enabled != enabled;
}

/// Airy pastel backdrop; soft colour blooms keep the frosted blur visible.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, this.child, this.opacity = 1});

  final Widget? child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BackgroundPainter(opacity),
      child: child ?? const SizedBox.expand(),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter(this.opacity);

  final double opacity;
  final bool dark = glassDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GlassColors.bgTop.withValues(alpha: opacity),
            GlassColors.bgMid.withValues(alpha: opacity),
            GlassColors.bgBottom.withValues(alpha: opacity),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
    void bloom(Offset c, double r, Color color) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: color.a * opacity),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    final s = size.shortestSide;
    if (dark) {
      // Neutral light pools only: the dark look stays free of colour casts.
      bloom(
        Offset(size.width * 0.15, size.height * 0.06),
        s * 0.9,
        const Color(0x14FFFFFF),
      );
      bloom(
        Offset(size.width * 0.95, size.height * 0.4),
        s * 0.8,
        const Color(0x0DFFFFFF),
      );
      bloom(
        Offset(size.width * 0.3, size.height * 1.02),
        s * 0.9,
        const Color(0x0FFFFFFF),
      );
      return;
    }
    bloom(
      Offset(size.width * 0.12, size.height * 0.08),
      s * 0.9,
      const Color(0x669CC2FF),
    );
    bloom(
      Offset(size.width * 0.95, size.height * 0.35),
      s * 0.8,
      const Color(0x55F5B8E6),
    );
    bloom(
      Offset(size.width * 0.3, size.height * 1.02),
      s * 0.9,
      const Color(0x5596E6D6),
    );
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.dark != dark;
}

/// Frosted panel: backdrop blur, faint white fill, specular rim and a soft drop shadow.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = EdgeInsets.zero,
    this.blur = 22,
    this.strength = 1,
    this.shadow = true,
    this.tint,
    this.width,
    this.height,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final double strength;
  final bool shadow;
  final Color? tint;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final s = strength;
    Widget content = CustomPaint(
      foregroundPainter: GlassRimPainter(radius: radius, strength: s),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: glassDark
                ? [
                    const Color(
                      0xFF2E2E2E,
                    ).withValues(alpha: math.min(0.94, 0.5 * s * glassMilk)),
                    const Color(
                      0xFF161616,
                    ).withValues(alpha: math.min(0.9, 0.4 * s * glassMilk)),
                    const Color(
                      0xFF222222,
                    ).withValues(alpha: math.min(0.92, 0.46 * s * glassMilk)),
                  ]
                : [
                    Colors.white.withValues(
                      alpha: math.min(0.96, 0.62 * s * glassMilk),
                    ),
                    Colors.white.withValues(
                      alpha: math.min(0.9, 0.42 * s * glassMilk),
                    ),
                    Colors.white.withValues(
                      alpha: math.min(0.92, 0.48 * s * glassMilk),
                    ),
                  ],
            stops: const [0, 0.55, 1],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(borderRadius: borderRadius, color: tint),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    if (blur > 0 && glassBlur && GlassBlurScope.of(context)) {
      // Under a [BackdropGroup] all cards share one backdrop read per frame.
      content = BackdropFilter.grouped(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      );
    }
    content = ClipRRect(borderRadius: borderRadius, child: content);
    if (shadow) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: glassDark
              ? const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 30,
                    offset: Offset(0, 14),
                    spreadRadius: -8,
                  ),
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x2E2A3B66),
                    blurRadius: 30,
                    offset: Offset(0, 14),
                    spreadRadius: -8,
                  ),
                  BoxShadow(
                    color: Color(0x1A1B2540),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: content,
      );
    }
    if (width != null || height != null) {
      content = SizedBox(width: width, height: height, child: content);
    }
    return content;
  }
}

class GlassRimPainter extends CustomPainter {
  GlassRimPainter({required this.radius, this.strength = 1});

  final double radius;
  final double strength;
  final bool dark = glassDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.6),
      Radius.circular(radius),
    );
    final s = strength.clamp(0.0, 1.6);
    // Dark glass keeps a dimmer, still bright-edged rim.
    final k = dark ? 0.42 : 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.3), Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = GlassColors.hairline,
    );
    canvas.drawRRect(
      rrect.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: math.min(1, 0.95 * s * k)),
            Colors.white.withValues(alpha: math.min(1, 0.45 * s * k * k)),
            Colors.white.withValues(alpha: math.min(1, 0.25 * s * k * k)),
            Colors.white.withValues(alpha: math.min(1, 0.8 * s * k)),
          ],
          stops: const [0, 0.35, 0.65, 1],
        ).createShader(rect),
    );
    final highlight = Rect.fromLTWH(
      0,
      0,
      size.width,
      math.min(size.height * 0.6, 48),
    );
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    canvas.drawRect(
      highlight,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(
              alpha: math.min(1, (dark ? 0.08 : 0.45) * s),
            ),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(highlight),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(GlassRimPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.strength != strength ||
      oldDelegate.dark != dark;
}

/// Pressable glass surface with hover lift and press squish.
class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.radius = 18,
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.strength = 1,
    this.tint,
    this.blur = 22,
    this.semanticLabel,
    this.shadow = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final double strength;
  final Color? tint;
  final double blur;
  final String? semanticLabel;
  final bool shadow;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final strength = widget.strength * (_pressed ? 1.3 : (_hover ? 1.15 : 1));
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() {
          _hover = false;
          _pressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.95 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: GlassSurface(
              radius: widget.radius,
              padding: widget.padding,
              width: widget.width,
              height: widget.height,
              strength: strength,
              tint: widget.tint,
              blur: widget.blur,
              shadow: widget.shadow,
              child: Opacity(opacity: enabled ? 1 : 0.5, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

/// One-sided "harpoon" arrow (↿ / ⇂) used in the speed bar.
class HalfArrowIcon extends StatelessWidget {
  const HalfArrowIcon({
    super.key,
    required this.up,
    this.size = 16,
    this.color,
    this.strokeWidth = 1.9,
  });

  final bool up;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.62, size),
      painter: _HalfArrowPainter(
        up: up,
        color: color ?? GlassColors.text,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _HalfArrowPainter extends CustomPainter {
  _HalfArrowPainter({
    required this.up,
    required this.color,
    required this.strokeWidth,
  });

  final bool up;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final inset = strokeWidth;
    final barb = size.height * 0.36;
    final path = Path();
    if (up) {
      final x = size.width * 0.66;
      path
        ..moveTo(x, size.height - inset)
        ..lineTo(x, inset)
        ..lineTo(x - barb * 0.78, inset + barb);
    } else {
      final x = size.width * 0.34;
      path
        ..moveTo(x, inset)
        ..lineTo(x, size.height - inset)
        ..lineTo(x + barb * 0.78, size.height - inset - barb);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HalfArrowPainter oldDelegate) =>
      oldDelegate.up != up || oldDelegate.color != color;
}

/// Rounded play triangle that morphs into pause bars.
class PlayPauseGlyph extends StatelessWidget {
  const PlayPauseGlyph({
    super.key,
    required this.progress,
    this.size = 40,
    this.color,
  });

  final double progress;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PlayPausePainter(progress, color ?? GlassColors.text),
    );
  }
}

class _PlayPausePainter extends CustomPainter {
  _PlayPausePainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final glow = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    Path triangle() {
      final r = w * 0.09;
      final a = Offset(w * 0.28, h * 0.16);
      final b = Offset(w * 0.28, h * 0.84);
      final c = Offset(w * 0.86, h * 0.5);
      return _roundedTriangle(a, b, c, r);
    }

    Path bars() {
      final bw = w * 0.2;
      final gap = w * 0.14;
      final left = (w - bw * 2 - gap) / 2;
      final radius = Radius.circular(bw * 0.38);
      return Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, h * 0.18, bw, h * 0.64),
            radius,
          ),
        )
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left + bw + gap, h * 0.18, bw, h * 0.64),
            radius,
          ),
        );
    }

    void draw(Path p, double opacity, double scale) {
      if (opacity <= 0) return;
      canvas.save();
      canvas.translate(w / 2, h / 2);
      canvas.scale(scale);
      canvas.translate(-w / 2, -h / 2);
      canvas.drawPath(p, glow..color = color.withValues(alpha: 0.22 * opacity));
      canvas.drawPath(p, paint..color = color.withValues(alpha: opacity));
      canvas.restore();
    }

    draw(triangle(), 1 - t, 1 - 0.25 * t);
    draw(bars(), t, 0.75 + 0.25 * t);
  }

  Path _roundedTriangle(Offset a, Offset b, Offset c, double r) {
    Offset towards(Offset from, Offset to, double d) {
      final v = to - from;
      return from + v / v.distance * d;
    }

    final path = Path()..moveTo(towards(a, b, r).dx, towards(a, b, r).dy);
    for (final (p, next) in [(b, c), (c, a), (a, b)]) {
      final prev = p == b ? a : (p == c ? b : c);
      final p1 = towards(p, prev, r);
      final p2 = towards(p, next, r);
      path
        ..lineTo(p1.dx, p1.dy)
        ..quadraticBezierTo(p.dx, p.dy, p2.dx, p2.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_PlayPausePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}

String formatBitRate(num bytesPerSecond) {
  final bits = bytesPerSecond * 8;
  if (bits < 1000) return '${bits.round()} bps';
  const units = ['Kbps', 'Mbps', 'Gbps'];
  var value = bits / 1000;
  var i = 0;
  while (value >= 1000 && i < units.length - 1) {
    value /= 1000;
    i++;
  }
  final text = value >= 100
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$text ${units[i]}';
}

/// Glass pill with ↿ upload and ⇂ download bit rates.
class SpeedBar extends StatelessWidget {
  const SpeedBar({
    super.key,
    required this.up,
    required this.down,
    this.height = 52,
    this.fontSize = 17,
  });

  final num up;
  final num down;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: GlassColors.text,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      fontFeatures: glassTabular,
      letterSpacing: 0.2,
      height: 1.1,
    );
    Widget item(bool isUp, num value) {
      return Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HalfArrowIcon(
              up: isUp,
              size: fontSize * 1.08,
              color: glassDark
                  ? GlassColors.textDim
                  : (isUp ? GlassColors.accent : GlassColors.running),
            ),
            SizedBox(width: fontSize * 0.45),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(formatBitRate(value), style: style, maxLines: 1),
              ),
            ),
          ],
        ),
      );
    }

    return GlassSurface(
      radius: height / 2,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          item(true, up),
          Container(
            width: 1,
            height: height * 0.42,
            color: GlassColors.hairline,
          ),
          item(false, down),
        ],
      ),
    );
  }
}
