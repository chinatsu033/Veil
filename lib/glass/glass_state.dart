import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'region.dart';
import 'world_map.dart';

/// A selectable exit: applying it walks [path] from the outer group inwards.
class GlassNode {
  const GlassNode({
    required this.name,
    required this.display,
    required this.region,
    required this.path,
    this.isGroup = false,
  });

  final String name;
  final String display;
  final RegionKey region;
  final List<(String group, String proxy)> path;
  final bool isGroup;
}

class GlassRegion {
  const GlassRegion(this.key, this.nodes);

  final RegionKey key;
  final List<GlassNode> nodes;
}

class GlassProxyState {
  const GlassProxyState({
    required this.groupName,
    required this.regions,
    required this.currentRegion,
    required this.currentNode,
    required this.mode,
    required this.testUrl,
  });

  final String? groupName;
  final List<GlassRegion> regions;
  final RegionKey? currentRegion;
  final String? currentNode;
  final Mode mode;
  final String? testUrl;

  List<WorldMapMarker> get markers => [
    for (final r in regions) WorldMapMarker(key: r.key, count: r.nodes.length),
  ];

  GlassRegion? regionOf(RegionKey? key) {
    if (key == null) return null;
    for (final r in regions) {
      if (r.key == key) return r;
    }
    return null;
  }
}

Group? pickTargetGroup(List<Group> groups, Mode mode) {
  if (groups.isEmpty) return null;
  if (mode == Mode.global) {
    return groups.getGroup(GroupName.GLOBAL.name);
  }
  final candidates = groups
      .where(
        (g) =>
            g.type == GroupType.Selector &&
            g.hidden != true &&
            g.name != GroupName.GLOBAL.name,
      )
      .toList();
  if (candidates.isEmpty) return null;
  return candidates.first;
}

GlassProxyState computeGlassProxyState({
  required List<Group> groups,
  required Map<String, String> selectedMap,
  required Mode mode,
}) {
  final target = pickTargetGroup(groups, mode);
  if (target == null) {
    return GlassProxyState(
      groupName: null,
      regions: const [],
      currentRegion: null,
      currentNode: null,
      mode: mode,
      testUrl: null,
    );
  }
  final groupNames = {for (final g in groups) g.name};
  final byRegion = <RegionKey, List<GlassNode>>{};
  final seen = <String>{};
  void add(GlassNode node) {
    if (!seen.add(node.name)) return;
    byRegion.putIfAbsent(node.region, () => []).add(node);
  }

  for (final member in target.all) {
    if (!groupNames.contains(member.name)) {
      final region = parseRegion(member.name);
      if (region != null) {
        add(
          GlassNode(
            name: member.name,
            display: stripFlags(member.name),
            region: region,
            path: [(target.name, member.name)],
          ),
        );
      }
    }
  }
  for (final member in target.all) {
    if (!groupNames.contains(member.name)) continue;
    final sub = groups.getGroup(member.name);
    if (sub == null) continue;
    final groupRegion = parseRegion(member.name);
    if (sub.type == GroupType.Selector) {
      for (final leaf in sub.all) {
        if (groupNames.contains(leaf.name)) continue;
        final region = parseRegion(leaf.name) ?? groupRegion;
        if (region == null) continue;
        add(
          GlassNode(
            name: leaf.name,
            display: stripFlags(leaf.name),
            region: region,
            path: [(target.name, sub.name), (sub.name, leaf.name)],
          ),
        );
      }
    } else if (groupRegion != null) {
      add(
        GlassNode(
          name: sub.name,
          display: stripFlags(sub.name),
          region: groupRegion,
          path: [(target.name, sub.name)],
          isGroup: true,
        ),
      );
    }
  }

  final regions = [
    for (final e in byRegion.entries) GlassRegion(e.key, e.value),
  ]..sort((a, b) => b.nodes.length.compareTo(a.nodes.length));

  final selected = target.getCurrentSelectedName(
    selectedMap[target.name] ?? '',
  );
  RegionKey? currentRegion;
  String? currentNode;
  if (selected.isNotEmpty) {
    final sub = groups.getGroup(selected);
    if (sub != null && sub.type == GroupType.Selector) {
      final inner = sub.getCurrentSelectedName(selectedMap[sub.name] ?? '');
      currentNode = inner.isNotEmpty ? inner : selected;
    } else if (sub != null && parseRegion(sub.name) != null) {
      currentNode = sub.name;
    } else {
      currentNode = computeRealSelectedProxyState(
        selected,
        groups: groups,
        selectedMap: selectedMap,
      ).proxyName;
      if (currentNode.isEmpty) currentNode = selected;
    }
    currentRegion = parseRegion(currentNode) ?? parseRegion(selected);
  }
  return GlassProxyState(
    groupName: target.name,
    regions: regions,
    currentRegion: currentRegion,
    currentNode: currentNode,
    mode: mode,
    testUrl: target.testUrl,
  );
}

final glassProxyStateProvider = Provider<GlassProxyState>((ref) {
  final groups = ref.watch(groupsProvider);
  final selectedMap = ref.watch(glassSelectedMapProvider);
  final mode = ref.watch(patchClashConfigProvider.select((s) => s.mode));
  return computeGlassProxyState(
    groups: groups,
    selectedMap: selectedMap,
    mode: mode,
  );
});

final glassSpeedProvider = Provider<Traffic>((ref) {
  return ref.watch(
    trafficsProvider.select(
      (s) => s.list.isEmpty ? const Traffic() : s.list.last,
    ),
  );
});

abstract class GlassBackend {
  void toggleRunning();

  void refreshGroups();

  Future<void> testNodes(List<String> names, String? testUrl);

  int? delayOf(String name, String? testUrl);

  Future<void> applyNode(GlassNode node);

  void changeMode(Mode mode);

  void setTun(bool value);
}

/// Bridges glass UI intents onto Veil's existing actions.
class RealGlassBackend implements GlassBackend {
  RealGlassBackend(this.ref);

  final Ref ref;

  @override
  void toggleRunning() {
    ref.read(commonActionProvider.notifier).toggleRunning();
  }

  @override
  void refreshGroups() {
    ref.read(proxiesActionProvider.notifier).updateGroupsDebounce();
  }

  @override
  Future<void> testNodes(List<String> names, String? testUrl) async {
    final proxies = [for (final n in names) Proxy(name: n, type: '')];
    await ref.read(proxiesActionProvider.notifier).delayTest(proxies, testUrl);
  }

  @override
  int? delayOf(String name, String? testUrl) {
    final url = ref.read(realTestUrlProvider(testUrl));
    final state = computeRealSelectedProxyState(
      name,
      groups: ref.read(groupsProvider),
      selectedMap: ref.read(selectedMapProvider),
    );
    return ref.read(delayDataSourceProvider)[state.testUrl.takeFirstValid([
      url,
    ])]?[state.proxyName];
  }

  @override
  Future<void> applyNode(GlassNode node) async {
    final action = ref.read(proxiesActionProvider.notifier);
    for (final (group, proxy) in node.path) {
      await action.changeProxy(groupName: group, proxyName: proxy);
    }
    action.updateGroupsDebounce();
  }

  @override
  void changeMode(Mode mode) {
    ref.read(setupActionProvider.notifier).changeMode(mode);
  }

  @override
  void setTun(bool value) {
    if (system.isAndroid) {
      ref
          .read(vpnSettingProvider.notifier)
          .update((s) => s.copyWith(enable: value));
    } else {
      ref
          .read(patchClashConfigProvider.notifier)
          .update((s) => s.copyWith.tun(enable: value));
    }
  }
}

final glassBackendProvider = Provider<GlassBackend>(RealGlassBackend.new);

final glassSelectedMapProvider = Provider<Map<String, String>>((ref) {
  return ref.watch(selectedMapProvider);
});

final glassDelayProvider = Provider.family<int?, (String, String?)>((
  ref,
  args,
) {
  return ref.watch(delayProvider(proxyName: args.$1, testUrl: args.$2));
});

final glassTunProvider = Provider<bool>((ref) {
  if (system.isAndroid) {
    return ref.watch(vpnSettingProvider.select((s) => s.enable));
  }
  return ref.watch(patchClashConfigProvider.select((s) => s.tun.enable));
});

GlassNode? pickBestNode(
  GlassRegion region,
  int? Function(String name) delayOf,
) {
  GlassNode? best;
  var bestDelay = 1 << 30;
  for (final node in region.nodes) {
    final d = delayOf(node.name);
    if (d != null && d > 0 && d < bestDelay) {
      bestDelay = d;
      best = node;
    }
  }
  return best;
}

/// Pending region/node choice while the switcher is open; [save] applies it.
class RegionSelection extends ChangeNotifier {
  RegionSelection(this.backend);

  final GlassBackend backend;
  RegionKey? region;
  String? node;
  Future<void>? _testing;
  RegionKey? _testedRegion;

  void begin(GlassProxyState state) {
    region =
        state.currentRegion ??
        (state.regions.isEmpty ? null : state.regions.first.key);
    node = null;
    _testing = null;
    _testedRegion = null;
    final r = state.regionOf(region);
    if (r != null) _test(r, state.testUrl);
    notifyListeners();
  }

  void pickRegion(GlassProxyState state, RegionKey key) {
    if (region == key) return;
    region = key;
    node = null;
    final r = state.regionOf(key);
    if (r != null) _test(r, state.testUrl);
    notifyListeners();
  }

  void pickNode(String? name) {
    node = name;
    notifyListeners();
  }

  void _test(GlassRegion r, String? testUrl) {
    _testedRegion = r.key;
    _testing = backend.testNodes([for (final n in r.nodes) n.name], testUrl);
  }

  Future<void> save(GlassProxyState state) async {
    final r = state.regionOf(region);
    if (r == null || r.nodes.isEmpty) return;
    GlassNode? target;
    if (node != null) {
      target = r.nodes.where((n) => n.name == node).firstOrNull;
    }
    if (target == null) {
      if (_testedRegion != r.key || _testing == null) _test(r, state.testUrl);
      try {
        await _testing!.timeout(const Duration(seconds: 8));
      } catch (_) {}
      target =
          pickBestNode(r, (name) => backend.delayOf(name, state.testUrl)) ??
          r.nodes.first;
    }
    await backend.applyNode(target);
  }
}
