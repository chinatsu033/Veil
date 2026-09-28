import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'glass_l10n.dart';
import 'glass_state.dart';
import 'glass_widgets.dart';
import 'region.dart';

bool isZh(BuildContext context) => GlassStrings.of(context).zh;

String regionLabel(BuildContext context, RegionKey? key) {
  final strings = GlassStrings.of(context);
  if (key == null) return strings.chooseRegion;
  return key.label(zh: strings.zh);
}

class DelayBadge extends ConsumerWidget {
  const DelayBadge({super.key, required this.name, required this.testUrl});

  final String name;
  final String? testUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delay = ref.watch(glassDelayProvider((name, testUrl)));
    final strings = GlassStrings.of(context);
    if (delay == 0) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.6,
          color: GlassColors.textDim,
        ),
      );
    }
    if (delay == null) {
      return Text(
        '—',
        style: TextStyle(color: GlassColors.textFaint, fontSize: 13),
      );
    }
    // Dark mode stays colourless: latency reads as brightness instead of hue.
    final color = glassDark
        ? (delay < 0
              ? GlassColors.textFaint
              : delay < 320
              ? GlassColors.text
              : GlassColors.textDim)
        : delay < 0
        ? const Color(0xFFE5484D)
        : delay < 160
        ? const Color(0xFF119C68)
        : delay < 320
        ? const Color(0xFFB88300)
        : const Color(0xFFDB6B12);
    return Text(
      delay < 0 ? strings.timeout : '$delay ms',
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFeatures: glassTabular,
      ),
    );
  }
}

class RegionNodeList extends StatelessWidget {
  const RegionNodeList({
    super.key,
    required this.region,
    required this.selectedNode,
    required this.onSelect,
    required this.testUrl,
    this.currentNode,
    this.itemHeight = 44,
  });

  final GlassRegion? region;
  final String? selectedNode;
  final String? currentNode;
  final ValueChanged<String?> onSelect;
  final String? testUrl;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final strings = GlassStrings.of(context);
    final r = region;
    if (r == null) {
      return Center(
        child: Text(
          strings.noRegions,
          style: TextStyle(color: GlassColors.textDim, fontSize: 13),
        ),
      );
    }
    final items = <Widget>[
      _NodeRow(
        height: itemHeight,
        selected: selectedNode == null,
        leading: Icon(Icons.bolt_rounded, size: 18, color: GlassColors.glow),
        title: strings.autoBest,
        trailing: null,
        onTap: () => onSelect(null),
      ),
      for (final node in r.nodes)
        _NodeRow(
          height: itemHeight,
          selected: selectedNode == node.name,
          current: currentNode == node.name,
          leading: null,
          title: node.display,
          trailing: DelayBadge(name: node.name, testUrl: testUrl),
          onTap: () => onSelect(node.name),
        ),
    ];
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, i) => items[i],
    );
  }
}

class _NodeRow extends StatelessWidget {
  const _NodeRow({
    required this.height,
    required this.selected,
    required this.title,
    required this.onTap,
    this.leading,
    this.trailing,
    this.current = false,
  });

  final double height;
  final bool selected;
  final bool current;
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      onTap: onTap,
      height: height,
      radius: 14,
      blur: 0,
      shadow: false,
      strength: selected ? 1.5 : 0.55,
      tint: selected ? GlassColors.accent.withValues(alpha: 0.12) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: GlassColors.text,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          if (current)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: GlassColors.running,
                shape: BoxShape.circle,
              ),
            ),
          ?trailing,
          if (selected) ...[
            const SizedBox(width: 10),
            Icon(Icons.check_rounded, size: 18, color: GlassColors.text),
          ],
        ],
      ),
    );
  }
}

class RegionChips extends StatelessWidget {
  const RegionChips({
    super.key,
    required this.state,
    required this.selected,
    required this.onSelect,
  });

  final GlassProxyState state;
  final RegionKey? selected;
  final ValueChanged<RegionKey> onSelect;

  @override
  Widget build(BuildContext context) {
    final zh = isZh(context);
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: state.regions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final region = state.regions[i];
          final isSelected = region.key == selected;
          return GlassButton(
            onTap: () => onSelect(region.key),
            radius: 17,
            blur: 0,
            shadow: false,
            strength: isSelected ? 1.6 : 0.7,
            tint: isSelected
                ? GlassColors.accent.withValues(alpha: 0.14)
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: Text(
                region.key.label(zh: zh),
                style: TextStyle(
                  color: isSelected ? GlassColors.accent : GlassColors.textDim,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class GlassPrimaryButton extends StatelessWidget {
  const GlassPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 48,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      onTap: busy ? null : onTap,
      height: height,
      radius: height / 2,
      strength: 1.4,
      tint: GlassColors.primaryFill,
      child: Center(
        child: busy
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: GlassColors.onPrimary,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: GlassColors.onPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 56,
    this.radius = 18,
    this.iconSize,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double radius;
  final double? iconSize;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      onTap: onTap,
      width: size,
      height: size,
      radius: radius,
      semanticLabel: tooltip,
      child: Center(
        child: Icon(
          icon,
          color: GlassColors.text,
          size: iconSize ?? size * 0.42,
        ),
      ),
    );
  }
}

/// Watches traffic itself so a speed tick does not rebuild the whole home.
class LiveSpeedBar extends ConsumerWidget {
  const LiveSpeedBar({super.key, this.height = 52, this.fontSize = 17});

  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(glassSpeedProvider);
    return RepaintBoundary(
      child: SpeedBar(
        up: speed.up,
        down: speed.down,
        height: height,
        fontSize: fontSize,
      ),
    );
  }
}

/// Large start/stop control with a play triangle that morphs to pause.
class GlassPlayButton extends ConsumerStatefulWidget {
  const GlassPlayButton({
    super.key,
    required this.running,
    required this.onTap,
    this.size = 148,
    this.radius = 34,
  });

  final bool running;
  final VoidCallback? onTap;
  final double size;
  final double radius;

  @override
  ConsumerState<GlassPlayButton> createState() => _GlassPlayButtonState();
}

class _GlassPlayButtonState extends ConsumerState<GlassPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.running ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant GlassPlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.running != widget.running) {
      widget.running ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = GlassStrings.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_controller.value);
        return Stack(
          alignment: Alignment.center,
          children: [
            if (t > 0)
              IgnorePointer(
                child: Container(
                  width: widget.size * 0.8,
                  height: widget.size * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.radius),
                    boxShadow: [
                      BoxShadow(
                        color: GlassColors.running.withValues(alpha: 0.22 * t),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            GlassButton(
              onTap: widget.onTap,
              width: widget.size,
              height: widget.size,
              radius: widget.radius,
              strength: 1.15 + 0.25 * t,
              tint: Color.lerp(
                Colors.transparent,
                GlassColors.running.withValues(alpha: 0.16),
                t,
              ),
              semanticLabel: widget.running ? strings.stop : strings.start,
              child: Center(
                child: PlayPauseGlyph(
                  progress: t,
                  size: widget.size * 0.4,
                  color: Color.lerp(
                    GlassColors.text,
                    GlassColors.playActive,
                    t,
                  )!,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
