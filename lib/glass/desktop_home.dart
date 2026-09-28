import 'dart:async';

import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'glass_l10n.dart';
import 'glass_settings.dart';
import 'glass_state.dart';
import 'glass_widgets.dart';
import 'glass_window.dart';
import 'region_picker.dart';
import 'world_map.dart';

enum DesktopPanel { none, map, settings }

/// Windows mini-widget: play button, speed bar, region pill and settings.
class DesktopGlassHome extends ConsumerStatefulWidget {
  const DesktopGlassHome({super.key, this.initialPanel = DesktopPanel.none});

  final DesktopPanel initialPanel;

  @override
  ConsumerState<DesktopGlassHome> createState() => _DesktopGlassHomeState();
}

class _DesktopGlassHomeState extends ConsumerState<DesktopGlassHome> {
  late DesktopPanel _panel = widget.initialPanel;
  late final RegionSelection _selection = RegionSelection(
    ref.read(glassBackendProvider),
  );
  final _settingsNavigator = GlobalKey<NavigatorState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (_panel == DesktopPanel.map) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _selection.begin(ref.read(glassProxyStateProvider)),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => GlassWindow.animateHeight(_heightFor(_panel)),
    );
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  double _heightFor(DesktopPanel panel) => switch (panel) {
    DesktopPanel.none => glassWidgetHeight,
    DesktopPanel.map => glassMapHeight,
    DesktopPanel.settings => glassSettingsHeight,
  };

  Future<void> _setPanel(DesktopPanel panel) async {
    if (panel == _panel) panel = DesktopPanel.none;
    if (panel == DesktopPanel.map) {
      ref.read(glassBackendProvider).refreshGroups();
      _selection.begin(ref.read(glassProxyStateProvider));
    }
    final grow = _heightFor(panel) > _heightFor(_panel);
    if (grow) {
      await GlassWindow.animateHeight(_heightFor(panel));
      if (mounted) setState(() => _panel = panel);
    } else {
      setState(() => _panel = panel);
      await GlassWindow.animateHeight(_heightFor(panel));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _selection.save(ref.read(glassProxyStateProvider));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (mounted) unawaited(_setPanel(DesktopPanel.none));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(glassProxyStateProvider);
    final running = ref.watch(isStartProvider);
    final hasProfile = ref.watch(
      currentProfileProvider.select((p) => p != null),
    );
    final strings = GlassStrings.of(context);
    final pillText = !hasProfile
        ? strings.noProfile
        : state.mode.name == 'direct'
        ? strings.direct
        : regionLabel(context, state.currentRegion);
    return GlassWindowFrame(
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => GlassWindow.startDragging(),
              child: SizedBox(
                height: glassWidgetHeight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GlassPlayButton(
                        running: running,
                        size: 148,
                        radius: 34,
                        onTap: hasProfile
                            ? ref.read(glassBackendProvider).toggleRunning
                            : () => _setPanel(DesktopPanel.settings),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          children: [
                            const LiveSpeedBar(height: 64, fontSize: 19),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _RegionPill(
                                      text: pillText,
                                      running: running,
                                      expanded: _panel == DesktopPanel.map,
                                      onTap: () => _setPanel(
                                        hasProfile
                                            ? DesktopPanel.map
                                            : DesktopPanel.settings,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  AspectRatio(
                                    aspectRatio: 1,
                                    child: GlassButton(
                                      onTap: () =>
                                          _setPanel(DesktopPanel.settings),
                                      radius: 22,
                                      strength: _panel == DesktopPanel.settings
                                          ? 1.5
                                          : 1,
                                      semanticLabel: strings.settings,
                                      child: AnimatedRotation(
                                        turns: _panel == DesktopPanel.settings
                                            ? 0.25
                                            : 0,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        child: Icon(
                                          Icons.settings_rounded,
                                          color: GlassColors.text,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, -0.04),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: switch (_panel) {
                  DesktopPanel.none => const SizedBox.shrink(),
                  DesktopPanel.map => Padding(
                    key: const ValueKey('map'),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _MapCard(
                      selection: _selection,
                      state: state,
                      saving: _saving,
                      onSave: _save,
                    ),
                  ),
                  DesktopPanel.settings => Padding(
                    key: const ValueKey('settings'),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: GlassSurface(
                      radius: 24,
                      blur: 0,
                      strength: 1.1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Navigator(
                          key: _settingsNavigator,
                          onGenerateRoute: (_) => PageRouteBuilder<void>(
                            pageBuilder: (_, _, _) =>
                                const GlassSettingsBody(compact: true),
                          ),
                        ),
                      ),
                    ),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionPill extends StatelessWidget {
  const _RegionPill({
    required this.text,
    required this.running,
    required this.expanded,
    required this.onTap,
  });

  final String text;
  final bool running;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      onTap: onTap,
      radius: 36,
      strength: expanded ? 1.45 : 1,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: running ? GlassColors.running : GlassColors.textFaint,
              boxShadow: running
                  ? [
                      BoxShadow(
                        color: GlassColors.running.withValues(alpha: 0.7),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: GlassColors.text,
                fontSize: 19,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 240),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: GlassColors.textDim,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.selection,
    required this.state,
    required this.saving,
    required this.onSave,
  });

  final RegionSelection selection;
  final GlassProxyState state;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final strings = GlassStrings.of(context);
    return GlassSurface(
      radius: 24,
      blur: 0,
      strength: 1.25,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: ListenableBuilder(
        listenable: selection,
        builder: (context, _) {
          final region = state.regionOf(selection.region);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, ?current],
                      ),
                      child: Text(
                        regionLabel(context, selection.region),
                        key: ValueKey(selection.region),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: GlassColors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    region == null
                        ? strings.tapToSwitch
                        : strings.nodes(region.nodes.length),
                    style: TextStyle(color: GlassColors.textDim, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              RegionChips(
                state: state,
                selected: selection.region,
                onSelect: (key) => selection.pickRegion(state, key),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: WorldDotMap(
                  markers: state.markers,
                  selected: selection.region,
                  onSelect: (key) => selection.pickRegion(state, key),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: _HorizontalNodes(
                  region: region,
                  selectedNode: selection.node,
                  currentNode: state.currentNode,
                  testUrl: state.testUrl,
                  onSelect: selection.pickNode,
                ),
              ),
              const SizedBox(height: 12),
              GlassPrimaryButton(
                label: strings.save,
                height: 44,
                busy: saving,
                onTap: region == null ? null : onSave,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HorizontalNodes extends StatelessWidget {
  const _HorizontalNodes({
    required this.region,
    required this.selectedNode,
    required this.currentNode,
    required this.testUrl,
    required this.onSelect,
  });

  final GlassRegion? region;
  final String? selectedNode;
  final String? currentNode;
  final String? testUrl;
  final ValueChanged<String?> onSelect;

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
    Widget card({
      required bool selected,
      required Widget title,
      required Widget subtitle,
      required VoidCallback onTap,
    }) {
      return GlassButton(
        onTap: onTap,
        width: 150,
        radius: 16,
        blur: 0,
        shadow: false,
        strength: selected ? 1.6 : 0.6,
        tint: selected ? GlassColors.accent.withValues(alpha: 0.16) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [title, const SizedBox(height: 3), subtitle],
        ),
      );
    }

    final titleStyle = TextStyle(
      color: GlassColors.text,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        card(
          selected: selectedNode == null,
          onTap: () => onSelect(null),
          title: Text(strings.autoBest.split(' · ').first, style: titleStyle),
          subtitle: Text(
            strings.autoBest.split(' · ').last,
            style: TextStyle(color: GlassColors.textDim, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        for (final node in r.nodes) ...[
          const SizedBox(width: 8),
          card(
            selected: selectedNode == node.name,
            onTap: () => onSelect(node.name),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    node.display,
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (currentNode == node.name)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: GlassColors.running,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: DelayBadge(name: node.name, testUrl: testUrl),
          ),
        ],
      ],
    );
  }
}
