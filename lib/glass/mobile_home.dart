import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'glass_l10n.dart';
import 'glass_settings.dart';
import 'glass_state.dart';
import 'glass_widgets.dart';
import 'glass_window.dart';
import 'region.dart';
import 'region_picker.dart';
import 'world_map.dart';

/// Android portrait home: region title, glowing world map, play + speed bar.
class MobileGlassHome extends ConsumerStatefulWidget {
  const MobileGlassHome({super.key, this.initialSwitching = false});

  final bool initialSwitching;

  @override
  ConsumerState<MobileGlassHome> createState() => _MobileGlassHomeState();
}

class _MobileGlassHomeState extends ConsumerState<MobileGlassHome> {
  late bool _switching = widget.initialSwitching;
  late final RegionSelection _selection = RegionSelection(
    ref.read(glassBackendProvider),
  );
  final _mapScroll = ScrollController();
  bool _saving = false;
  double _mapWidth = 0;
  double _viewWidth = 0;

  @override
  void initState() {
    super.initState();
    if (_switching) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _selection.begin(ref.read(glassProxyStateProvider)),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerMapDefault());
    _selection.addListener(_onSelection);
  }

  void _onSelection() {
    if (!mounted) return;
    setState(() {});
    _revealOnMap(_selection.region);
  }

  void _revealOnMap(RegionKey? key) {
    if (key == null || !_mapScroll.hasClients) return;
    final mapHeight = _mapWidth / mapAspectRatio;
    final x = projectLatLon(
      Rect.fromLTWH(0, 0, _mapWidth, mapHeight),
      key.lat,
      key.lon,
    ).dx;
    final offset = _mapScroll.offset;
    if (x > offset + 36 && x < offset + _viewWidth - 36) return;
    final target = (x - _viewWidth / 2).clamp(
      0.0,
      _mapScroll.position.maxScrollExtent,
    );
    _mapScroll.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _selection.removeListener(_onSelection);
    _selection.dispose();
    _mapScroll.dispose();
    super.dispose();
  }

  void _centerMapDefault() {
    if (!_mapScroll.hasClients || _mapWidth <= _viewWidth) return;
    final mapHeight = _mapWidth / mapAspectRatio;
    final x = projectLatLon(
      Rect.fromLTWH(0, 0, _mapWidth, mapHeight),
      0,
      16,
    ).dx;
    _mapScroll.jumpTo(
      (x - _viewWidth / 2).clamp(0.0, _mapScroll.position.maxScrollExtent),
    );
  }

  void _enterSwitch() {
    final state = ref.read(glassProxyStateProvider);
    if (state.regions.isEmpty) return;
    ref.read(glassBackendProvider).refreshGroups();
    _selection.begin(state);
    setState(() => _switching = true);
  }

  void _exitSwitch() {
    setState(() => _switching = false);
    _revealOnMap(ref.read(glassProxyStateProvider).currentRegion);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _selection.save(ref.read(glassProxyStateProvider));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (mounted) _exitSwitch();
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const GlassSettingsPage()));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(glassProxyStateProvider);
    final running = ref.watch(isStartProvider);
    final hasProfile = ref.watch(
      currentProfileProvider.select((p) => p != null),
    );
    final strings = GlassStrings.of(context);
    final padding = MediaQuery.paddingOf(context);
    final title = _switching
        ? regionLabel(context, _selection.region)
        : !hasProfile
        ? strings.noProfile
        : state.mode == Mode.direct
        ? strings.direct
        : regionLabel(context, state.currentRegion);
    final caption = _switching
        ? strings.chooseRegion
        : !hasProfile
        ? strings.importHint
        : '${running ? strings.running : strings.stopped} · ${state.mode.label}';
    const slide = Duration(milliseconds: 380);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_switching) {
          _exitSwitch();
        } else if (!glassDemoMode) {
          ref.read(systemActionProvider.notifier).handleClose();
        }
      },
      child: Scaffold(
        backgroundColor: GlassColors.bgBottom,
        body: BackdropGroup(
          child: GlassBackground(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                _viewWidth = width;
                _mapWidth = width * 1.22;
                final mapHeight = _mapWidth / mapAspectRatio;
                const headerHeight = 150.0;
                final controlsHeight = 84 + 28 + padding.bottom;
                final normalGap =
                    ((height -
                                    padding.top -
                                    headerHeight -
                                    mapHeight -
                                    controlsHeight) /
                                2 -
                            16)
                        .clamp(8.0, 400.0);
                return Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(height: padding.top),
                        SizedBox(
                          height: headerHeight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _switching || !hasProfile
                                ? null
                                : _enterSwitch,
                            child: _Header(
                              title: title,
                              caption: caption,
                              switching: _switching,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: slide,
                          curve: Curves.easeOutCubic,
                          height: _switching ? 0 : normalGap,
                        ),
                        SizedBox(
                          height: mapHeight,
                          child: ListenableBuilder(
                            listenable: _selection,
                            builder: (context, _) => SingleChildScrollView(
                              controller: _mapScroll,
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: SizedBox(
                                width: _mapWidth,
                                height: mapHeight,
                                child: WorldDotMap(
                                  markers: state.markers,
                                  selected: _switching
                                      ? _selection.region
                                      : state.currentRegion,
                                  onSelect: (key) {
                                    if (!_switching) {
                                      if (hasProfile) {
                                        _enterSwitch();
                                        _selection.pickRegion(state, key);
                                      }
                                      return;
                                    }
                                    _selection.pickRegion(state, key);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween(
                                      begin: const Offset(0, 0.06),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: _switching
                                ? _SwitchPanel(
                                    key: const ValueKey('switch'),
                                    selection: _selection,
                                    state: state,
                                    saving: _saving,
                                    onSave: _save,
                                    bottomPadding: padding.bottom,
                                  )
                                : _NodePill(
                                    key: const ValueKey('normal'),
                                    state: state,
                                    visible:
                                        hasProfile &&
                                        state.mode != Mode.direct &&
                                        state.currentNode != null,
                                    onTap: _enterSwitch,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: padding.top + 12,
                      right: 16,
                      child: AnimatedSlide(
                        duration: slide,
                        curve: Curves.easeInOutCubic,
                        offset: _switching ? const Offset(2.2, 0) : Offset.zero,
                        child: GlassIconButton(
                          icon: Icons.settings_rounded,
                          size: 48,
                          radius: 16,
                          iconSize: 24,
                          tooltip: strings.settings,
                          onTap: _openSettings,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: padding.bottom + 28,
                      child: AnimatedSlide(
                        duration: slide,
                        curve: Curves.easeInOutCubic,
                        offset: _switching ? const Offset(0, 2.4) : Offset.zero,
                        child: AnimatedOpacity(
                          duration: slide,
                          opacity: _switching ? 0 : 1,
                          child: IgnorePointer(
                            ignoring: _switching,
                            child: SizedBox(
                              height: 84,
                              child: Row(
                                children: [
                                  GlassPlayButton(
                                    running: running,
                                    size: 84,
                                    radius: 26,
                                    onTap: hasProfile
                                        ? ref
                                              .read(glassBackendProvider)
                                              .toggleRunning
                                        : _openSettings,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: LiveSpeedBar(
                                      height: 84,
                                      fontSize: 17,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NodePill extends StatelessWidget {
  const _NodePill({
    super.key,
    required this.state,
    required this.visible,
    required this.onTap,
  });

  final GlassProxyState state;
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.expand();
    final strings = GlassStrings.of(context);
    final node = state.currentNode!;
    return Align(
      alignment: const Alignment(0, -0.55),
      child: GestureDetector(
        onTap: onTap,
        child: GlassSurface(
          radius: 22,
          strength: 0.8,
          padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.dns_rounded, size: 16, color: GlassColors.textDim),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  stripFlags(node),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: GlassColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DelayBadge(name: node, testUrl: state.testUrl),
              const SizedBox(width: 6),
              Tooltip(
                message: strings.tapToSwitch,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: GlassColors.textFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.caption,
    required this.switching,
  });

  final String title;
  final String caption;
  final bool switching;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 72),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              caption,
              key: ValueKey(caption),
              style: TextStyle(
                color: GlassColors.textDim,
                fontSize: 13,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween(begin: 0.96, end: 1.0).animate(animation),
                child: child,
              ),
            ),
            child: Row(
              key: ValueKey(title),
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GlassColors.text,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      shadows: [
                        Shadow(
                          color: glassDark
                              ? const Color(0x99000000)
                              : const Color(0xCCFFFFFF),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!switching) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: GlassColors.textDim,
                    size: 28,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchPanel extends StatelessWidget {
  const _SwitchPanel({
    super.key,
    required this.selection,
    required this.state,
    required this.saving,
    required this.onSave,
    required this.bottomPadding,
  });

  final RegionSelection selection;
  final GlassProxyState state;
  final bool saving;
  final VoidCallback onSave;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final strings = GlassStrings.of(context);
    return ListenableBuilder(
      listenable: selection,
      builder: (context, _) {
        final region = state.regionOf(selection.region);
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RegionChips(
                state: state,
                selected: selection.region,
                onSelect: (k) => selection.pickRegion(state, k),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GlassSurface(
                  radius: 24,
                  padding: const EdgeInsets.all(10),
                  child: RegionNodeList(
                    region: region,
                    selectedNode: selection.node,
                    currentNode: state.currentNode,
                    testUrl: state.testUrl,
                    onSelect: selection.pickNode,
                    itemHeight: 46,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GlassPrimaryButton(
                label: strings.save,
                height: 54,
                busy: saving,
                onTap: region == null ? null : onSave,
              ),
            ],
          ),
        );
      },
    );
  }
}
