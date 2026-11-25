import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../widgets/common.dart';
import 'profile.dart';
import 'theme_provide.dart';

/// Theme, playback and equalizer options. Lives in the bottom navigation.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  static const _eqPresets = ['Normal', 'Pop', 'Rock', 'Jazz', 'Bass boost'];

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PlayerService>();
    final theme = context.watch<ThemeProvider>();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Settings', style: displayStyle(46)),
                ProfileAvatar(
                  foreground: theme.ground,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AppSheet(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                children: [
                  const SheetLabel('Theme'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < ThemeProvider.palettes.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _ThemeDot(
                            palette: ThemeProvider.palettes[i],
                            selected: i == theme.index,
                            onTap: () => theme.select(i),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const SheetLabel('Playback speed'),
                  const SizedBox(height: 10),
                  Segmented<double>(
                    values: _speeds,
                    selected: _speeds.firstWhere(
                      (s) => (s - service.speed).abs() < 0.01,
                      orElse: () => 1.0,
                    ),
                    labelOf: (s) =>
                        '${s.toStringAsFixed(s * 4 == (s * 4).roundToDouble() && s * 10 == (s * 10).roundToDouble() ? 1 : 2)}x',
                    onSelected: service.setSpeed,
                  ),
                  const SizedBox(height: 22),
                  const SheetLabel('Equalizer'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final q in _eqPresets)
                        PillChip(
                          label: q,
                          selected: q == service.eqPreset,
                          onTap: () => service.setEqPreset(q),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kField,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        _SwitchRow(
                          title: 'Crossfade',
                          subtitle: service.crossfadeOn
                              ? '${service.crossfadeSeconds} s between songs'
                              : 'Off',
                          value: service.crossfadeOn,
                          onChanged: service.setCrossfadeOn,
                        ),
                        Row(
                          children: [
                            Text(
                              '0s',
                              style: bodyStyle(
                                12,
                                weight: FontWeight.w700,
                                color: kMuted,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: service.crossfadeSeconds.toDouble(),
                                min: 0,
                                max: 12,
                                divisions: 12,
                                semanticFormatterCallback: (v) =>
                                    'Crossfade length ${v.round()} seconds',
                                onChanged: service.crossfadeOn
                                    ? (v) =>
                                          service.setCrossfadeSeconds(v.round())
                                    : null,
                              ),
                            ),
                            Text(
                              '12s',
                              style: bodyStyle(
                                12,
                                weight: FontWeight.w700,
                                color: kMuted,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 1, color: Color(0xFFE6E6E6)),
                        _SwitchRow(
                          title: 'Shuffle',
                          value: service.shuffle,
                          onChanged: service.setShuffle,
                        ),
                        const Divider(height: 1, color: Color(0xFFE6E6E6)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Repeat',
                                style: bodyStyle(15, weight: FontWeight.w800),
                              ),
                              SizedBox(
                                width: 180,
                                child: Segmented<TrackRepeatMode>(
                                  values: TrackRepeatMode.values,
                                  selected: service.repeat,
                                  trackColor: Colors.white,
                                  itemHeight: 36,
                                  labelOf: (m) => switch (m) {
                                    TrackRepeatMode.off => 'Off',
                                    TrackRepeatMode.all => 'All',
                                    TrackRepeatMode.one => 'One',
                                  },
                                  onSelected: service.setRepeat,
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
        ],
      ),
    );
  }
}

class _ThemeDot extends StatelessWidget {
  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeDot({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: palette.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? kInk : const Color(0xFFEDEDED),
              width: 3,
            ),
          ),
          child: ClipOval(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.5, 0.5],
                  colors: [palette.ground, palette.second],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: bodyStyle(15, weight: FontWeight.w800)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: bodyStyle(12, color: kMuted)),
              ],
            ],
          ),
          AppSwitch(label: title, value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
