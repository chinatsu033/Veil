import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/dashboard/widgets/widgets.dart';
import 'package:fl_clash/views/config/advanced.dart';
import 'package:fl_clash/views/profiles/add.dart';
import 'package:fl_clash/views/views.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'glass_l10n.dart';
import 'glass_prefs.dart';
import 'glass_state.dart';
import 'glass_widgets.dart';
import 'glass_window.dart';

bool get _androidUi => system.isAndroid || glassMobileLayout;

void _open(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

class GlassSwitch extends StatelessWidget {
  const GlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 56,
    this.height = 32,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final thumb = height - 6;
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            color: value
                ? GlassColors.switchOn
                : GlassColors.ink.withValues(alpha: glassDark ? 0.16 : 0.28),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: glassDark ? (value ? 0.4 : 0.14) : (value ? 0.7 : 0.6),
              ),
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: thumb,
              height: thumb,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B2540).withValues(alpha: 0.22),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                  if (value)
                    BoxShadow(
                      color: GlassColors.running.withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassSegmented<T> extends StatelessWidget {
  const GlassSegmented({
    super.key,
    required this.values,
    required this.value,
    required this.labelOf,
    required this.onChanged,
    this.height = 40,
  });

  final List<T> values;
  final T value;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final index = values.indexOf(value);
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        color: GlassColors.ink.withValues(alpha: glassDark ? 0.08 : 0.12),
        border: Border.all(
          color: Colors.white.withValues(alpha: glassDark ? 0.12 : 0.6),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth / values.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: w * (index < 0 ? 0 : index),
                top: 0,
                bottom: 0,
                width: w,
                child: GlassSurface(
                  radius: (height - 6) / 2,
                  blur: 0,
                  shadow: false,
                  strength: 1.6,
                  tint: Colors.white.withValues(alpha: glassDark ? 0.16 : 0.7),
                  child: const SizedBox.expand(),
                ),
              ),
              Row(
                children: [
                  for (final v in values)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(v),
                        child: Center(
                          child: Text(
                            labelOf(v),
                            style: TextStyle(
                              color: v == value
                                  ? GlassColors.accent
                                  : GlassColors.textDim,
                              fontSize: 14,
                              fontWeight: v == value
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color: GlassColors.accent.withValues(alpha: 0.12),
            border: Border.all(
              color: Colors.white.withValues(alpha: glassDark ? 0.14 : 0.7),
            ),
          ),
          child: Icon(icon, size: 19, color: GlassColors.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: GlassColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class GlassTunCard extends ConsumerWidget {
  const GlassTunCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = GlassStrings.of(context);
    final value = ref.watch(glassTunProvider);
    return GlassSurface(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CardHeader(
            icon: Icons.hub_rounded,
            title: context.appLocalizations.tun,
            trailing: GlassSwitch(
              value: value,
              onChanged: ref.read(glassBackendProvider).setTun,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _androidUi ? strings.tunHintAndroid : strings.tunHintDesktop,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: GlassColors.textDim,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class GlassModeCard extends ConsumerWidget {
  const GlassModeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(patchClashConfigProvider.select((s) => s.mode));
    return GlassSurface(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CardHeader(
            icon: Icons.alt_route_rounded,
            title: context.appLocalizations.outboundMode,
          ),
          const SizedBox(height: 14),
          GlassSegmented<Mode>(
            values: Mode.values,
            value: mode,
            labelOf: (m) => m.label,
            onChanged: ref.read(glassBackendProvider).changeMode,
          ),
        ],
      ),
    );
  }
}

/// Appearance (light / dark / follow system) and the launcher icon choice.
class GlassAppearanceCard extends ConsumerWidget {
  const GlassAppearanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = GlassStrings.of(context);
    return GlassSurface(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(icon: Icons.palette_rounded, title: strings.appearance),
          const SizedBox(height: 14),
          ValueListenableBuilder<GlassAppearance>(
            valueListenable: GlassPrefs.appearance,
            builder: (_, value, _) => GlassSegmented<GlassAppearance>(
              values: GlassAppearance.values,
              value: value,
              labelOf: (v) => switch (v) {
                GlassAppearance.light => strings.themeLight,
                GlassAppearance.dark => strings.themeDark,
                GlassAppearance.system => strings.themeSystem,
              },
              onChanged: GlassPrefs.setAppearance,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.apps_rounded, size: 18, color: GlassColors.textDim),
              const SizedBox(width: 8),
              Text(
                strings.icon,
                style: TextStyle(
                  color: GlassColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<GlassIcon>(
            valueListenable: GlassPrefs.icon,
            builder: (_, value, _) => Row(
              children: [
                for (final option in GlassIcon.values) ...[
                  if (option != GlassIcon.values.first)
                    const SizedBox(width: 12),
                  Expanded(
                    child: _IconOption(
                      asset: option == GlassIcon.light
                          ? 'assets/images/icon.png'
                          : 'assets/images/icon_dark.png',
                      label: option == GlassIcon.light
                          ? strings.iconLight
                          : strings.iconDark,
                      selected: value == option,
                      onTap: () async {
                        await GlassPrefs.setIcon(option);
                        if (system.isDesktop) {
                          await ref
                              .read(systemActionProvider.notifier)
                              .updateTray();
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _androidUi ? strings.iconHintAndroid : strings.iconHintDesktop,
            style: TextStyle(
              color: GlassColors.textFaint,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.asset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      onTap: onTap,
      radius: 18,
      blur: 0,
      shadow: false,
      strength: selected ? 1.5 : 0.6,
      tint: selected ? GlassColors.accent.withValues(alpha: 0.12) : null,
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(asset, width: 44, height: 44),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: GlassColors.text,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: selected ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: GlassColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class GlassProfilesCard extends ConsumerWidget {
  const GlassProfilesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = GlassStrings.of(context);
    final profile = ref.watch(currentProfileProvider);
    final count = ref.watch(profilesProvider.select((p) => p.length));
    final info = profile?.subscriptionInfo;
    final used = (info?.upload ?? 0) + (info?.download ?? 0);
    final total = info?.total ?? 0;
    final expire = info?.expire ?? 0;
    final subtitle = <String>[
      if (total > 0) '${used.traffic.show} / ${total.traffic.show}',
      if (expire > 0)
        DateTime.fromMillisecondsSinceEpoch(
          expire * 1000,
        ).toString().substring(0, 10),
    ].join('  ·  ');
    Widget action(IconData icon, String label, VoidCallback? onTap) {
      return Expanded(
        child: GlassButton(
          onTap: onTap,
          height: 40,
          radius: 14,
          blur: 0,
          shadow: false,
          strength: 0.9,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: GlassColors.text),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: GlassColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GlassSurface(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            icon: Icons.folder_rounded,
            title: context.appLocalizations.profiles,
            trailing: count > 1
                ? Text(
                    '$count',
                    style: TextStyle(color: GlassColors.textDim, fontSize: 13),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            profile?.label.isNotEmpty == true
                ? profile!.label
                : (profile == null ? strings.noProfile : profile.url),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: GlassColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle.isEmpty ? strings.profilesCardHint : subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: GlassColors.textDim,
              fontSize: 12.5,
              fontFeatures: glassTabular,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (used / total).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: const Color(
                  0xFF5B6B8C,
                ).withValues(alpha: 0.14),
                color: GlassColors.accent,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              action(
                Icons.add_link_rounded,
                strings.importUrl,
                () => _open(context, const _AddProfilePage()),
              ),
              const SizedBox(width: 8),
              action(
                Icons.refresh_rounded,
                strings.update,
                profile == null || profile.url.isEmpty
                    ? null
                    : () => unawaited(
                        ref
                            .read(profilesActionProvider.notifier)
                            .updateProfile(profile, showLoading: true),
                      ),
              ),
              const SizedBox(width: 8),
              action(
                Icons.tune_rounded,
                strings.manage,
                () => _open(context, const ProfilesView()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddProfilePage extends StatelessWidget {
  const _AddProfilePage();

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: context.appLocalizations.addProfile,
      body: AddProfileView(context: context),
    );
  }
}

class GlassTrafficPage extends StatelessWidget {
  const GlassTrafficPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: GlassStrings.of(context).trafficStats,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [NetworkSpeed(), SizedBox(height: 16), TrafficUsage()],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 50,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: GlassColors.textDim),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: GlassColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: GlassColors.textFaint,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionGroup extends StatelessWidget {
  const _OptionGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 22,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                indent: 48,
                endIndent: 14,
                color: GlassColors.hairline,
              ),
          ],
        ],
      ),
    );
  }
}

/// Settings: big cards for TUN, outbound mode and profiles, then the Veil tools.
class GlassSettingsBody extends ConsumerWidget {
  const GlassSettingsBody({
    super.key,
    this.compact = false,
    this.padding,
    this.initialOffset = 0,
  });

  final bool compact;
  final EdgeInsets? padding;

  /// Starting scroll position (used by the screenshot harness).
  final double initialOffset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final strings = GlassStrings.of(context);
    final systemProxy = ref.watch(
      networkSettingProvider.select((s) => s.systemProxy),
    );
    final autoLaunch = ref.watch(
      appSettingProvider.select((s) => s.autoLaunch),
    );
    final cards = compact
        ? [
            const SizedBox(
              height: 136,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: GlassTunCard()),
                  SizedBox(width: 12),
                  Expanded(flex: 5, child: GlassModeCard()),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const GlassProfilesCard(),
            const SizedBox(height: 12),
            const GlassAppearanceCard(),
          ]
        : [
            const SizedBox(height: 126, child: GlassTunCard()),
            const SizedBox(height: 12),
            const SizedBox(height: 126, child: GlassModeCard()),
            const SizedBox(height: 12),
            const GlassProfilesCard(),
            const SizedBox(height: 12),
            const GlassAppearanceCard(),
          ];
    return Material(
      type: MaterialType.transparency,
      child: ListView(
        controller: initialOffset > 0
            ? ScrollController(initialScrollOffset: initialOffset)
            : null,
        padding: padding ?? EdgeInsets.all(compact ? 14 : 16),
        children: [
          ...cards,
          const SizedBox(height: 16),
          _OptionGroup(
            children: [
              _OptionRow(
                icon: Icons.view_timeline_rounded,
                title: l.requests,
                onTap: () => _open(context, const RequestsView()),
              ),
              _OptionRow(
                icon: Icons.ballot_rounded,
                title: l.connections,
                onTap: () => _open(context, const ConnectionsView()),
              ),
              _OptionRow(
                icon: Icons.stacked_line_chart_rounded,
                title: strings.trafficStats,
                onTap: () => _open(context, const GlassTrafficPage()),
              ),
              _OptionRow(
                icon: Icons.article_rounded,
                title: l.logs,
                onTap: () => _open(context, const LogsView()),
              ),
              _OptionRow(
                icon: Icons.storage_rounded,
                title: l.resources,
                onTap: () => _open(context, const ResourcesView()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _OptionGroup(
            children: [
              if (!_androidUi)
                _OptionRow(
                  icon: Icons.shuffle_rounded,
                  title: l.systemProxy,
                  trailing: GlassSwitch(
                    value: systemProxy,
                    onChanged: (v) => ref
                        .read(networkSettingProvider.notifier)
                        .update((s) => s.copyWith(systemProxy: v)),
                  ),
                ),
              if (!_androidUi)
                _OptionRow(
                  icon: Icons.rocket_launch_rounded,
                  title: l.autoLaunch,
                  trailing: GlassSwitch(
                    value: autoLaunch,
                    onChanged: (v) => ref
                        .read(appSettingProvider.notifier)
                        .update((s) => s.copyWith(autoLaunch: v)),
                  ),
                ),
              if (!_androidUi)
                ValueListenableBuilder<bool>(
                  valueListenable: GlassWindow.alwaysOnTop,
                  builder: (_, onTop, _) => _OptionRow(
                    icon: Icons.push_pin_rounded,
                    title: strings.alwaysOnTop,
                    trailing: GlassSwitch(
                      value: onTop,
                      onChanged: GlassWindow.setAlwaysOnTop,
                    ),
                  ),
                ),
              if (_androidUi)
                _OptionRow(
                  icon: Icons.view_list_rounded,
                  title: l.accessControl,
                  onTap: () => _open(context, const AccessView()),
                ),
              _OptionRow(
                icon: Icons.edit_rounded,
                title: l.basicConfig,
                onTap: () => _open(context, const ConfigView()),
              ),
              _OptionRow(
                icon: Icons.build_rounded,
                title: l.advancedConfig,
                onTap: () => _open(context, const AdvancedConfigView()),
              ),
              _OptionRow(
                icon: Icons.settings_applications_rounded,
                title: l.application,
                onTap: () => _open(context, const ApplicationSettingView()),
              ),
              _OptionRow(
                icon: Icons.cloud_sync_rounded,
                title: l.backupAndRestore,
                onTap: () => _open(context, const BackupAndRestore()),
              ),
              _OptionRow(
                icon: Icons.info_rounded,
                title: l.about,
                onTap: () => _open(context, const AboutView()),
              ),
              if (!_androidUi)
                _OptionRow(
                  icon: Icons.power_settings_new_rounded,
                  title: l.exit,
                  trailing: const SizedBox.shrink(),
                  onTap: () =>
                      ref.read(systemActionProvider.notifier).handleExit(),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              strings.license,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GlassColors.textFaint,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Full-screen settings route used on Android.
class GlassSettingsPage extends StatelessWidget {
  const GlassSettingsPage({super.key, this.initialOffset = 0});

  final double initialOffset;

  @override
  Widget build(BuildContext context) {
    final strings = GlassStrings.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: GlassColors.bgBottom,
      body: GlassBackground(
        child: Column(
          children: [
            SizedBox(height: top + 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GlassButton(
                    onTap: () => Navigator.of(context).maybePop(),
                    width: 44,
                    height: 44,
                    radius: 14,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: GlassColors.text,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    strings.settings,
                    style: TextStyle(
                      color: GlassColors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GlassSettingsBody(
                initialOffset: initialOffset,
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.paddingOf(context).bottom,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
