import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../widgets/common.dart';
import 'theme_provide.dart';

class _Preset {
  final String id;
  final String name;
  final IconData icon;
  final double? pitch;
  final double? speed;
  const _Preset(this.id, this.name, this.icon, this.pitch, this.speed);
}

/// Pitch / speed effects. Changes are heard live on the shared player;
/// "Apply to track" keeps them, leaving the screen any other way restores
/// the previous sound.
class SoundEffectsScreen extends StatefulWidget {
  const SoundEffectsScreen({super.key});

  @override
  State<SoundEffectsScreen> createState() => _SoundEffectsScreenState();
}

class _SoundEffectsScreenState extends State<SoundEffectsScreen> {
  static const _presets = <_Preset>[
    _Preset('normal', 'Normal', Icons.show_chart_rounded, 1.0, 1.0),
    _Preset('pitchUp', 'Pitch up', Icons.arrow_upward_rounded, 1.4, 1.0),
    _Preset('pitchDown', 'Pitch down', Icons.arrow_downward_rounded, 0.7, 1.0),
    _Preset('faster', 'Faster', Icons.fast_forward_rounded, 1.0, 1.5),
    _Preset('slower', 'Slower', Icons.slow_motion_video_rounded, 1.0, 0.7),
    _Preset('vader', 'Darth Vader', Icons.dark_mode_rounded, 0.55, 0.9),
    _Preset('squirrel', 'Squirrel', Icons.bolt_rounded, 1.8, 1.25),
    _Preset('custom', 'Custom', Icons.tune_rounded, null, null),
  ];

  late final PlayerService _service;
  late final double _initialPitch;
  late final double _initialSpeed;
  late double _pitch;
  late double _speed;
  late String _preset;
  bool _applied = false;

  @override
  void initState() {
    super.initState();
    _service = context.read<PlayerService>();
    _initialPitch = _service.pitch;
    _initialSpeed = _service.speed;
    _pitch = _initialPitch;
    _speed = _initialSpeed;
    _preset = _matchPreset();
  }

  String _matchPreset() {
    for (final p in _presets) {
      if (p.pitch != null &&
          (p.pitch! - _pitch).abs() < 0.01 &&
          (p.speed! - _speed).abs() < 0.01) {
        return p.id;
      }
    }
    return 'custom';
  }

  void _push({bool play = true}) =>
      _service.applyEffect(_pitch, _speed, startPlaying: play);

  void _pick(_Preset p) {
    setState(() {
      _preset = p.id;
      if (p.pitch != null) {
        _pitch = p.pitch!;
        _speed = p.speed!;
      }
    });
    if (p.pitch != null) _push();
  }

  void _reset() {
    setState(() {
      _preset = 'normal';
      _pitch = 1.0;
      _speed = 1.0;
    });
    _push(play: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final path = context.select<PlayerService, String?>((s) => s.currentPath);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_applied) {
          _service.applyEffect(_initialPitch, _initialSpeed);
        }
      },
      child: Scaffold(
        backgroundColor: theme.ground,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppBackButton(tooltip: 'Back to now playing'),
                        if (path != null)
                          Flexible(
                            child: Container(
                              margin: const EdgeInsets.only(left: 12),
                              height: 36,
                              padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const DiscArt(size: 26),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      trackTitle(path),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: bodyStyle(
                                        12,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Sound effects', style: displayStyle(46)),
                  ],
                ),
              ),
              Expanded(
                child: AppSheet(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      22,
                      22,
                      20 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      children: [
                        GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.8,
                          children: [
                            for (final p in _presets)
                              _PresetTile(
                                preset: p,
                                selected: p.id == _preset,
                                color: theme.accent,
                                onTap: () => _pick(p),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: kField,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: [
                              _LabeledSlider(
                                label: 'Pitch',
                                value: _pitch,
                                onChanged: (v) => setState(() {
                                  _pitch = v;
                                  _preset = 'custom';
                                }),
                                onChangeEnd: (_) => _push(),
                              ),
                              const SizedBox(height: 12),
                              _LabeledSlider(
                                label: 'Speed',
                                value: _speed,
                                onChanged: (v) => setState(() {
                                  _speed = v;
                                  _preset = 'custom';
                                }),
                                onChangeEnd: (_) => _push(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: 'Reset',
                                outlined: true,
                                onPressed: _reset,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: PrimaryButton(
                                label: 'Apply to track',
                                icon: Icons.check_rounded,
                                onPressed: () {
                                  _applied = true;
                                  _service.applyEffect(_pitch, _speed);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final _Preset preset;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _PresetTile({
    required this.preset,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: preset.name,
      child: Material(
        color: selected ? color : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(preset.icon, size: 24, color: kInk),
                const SizedBox(height: 8),
                Text(
                  preset.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: bodyStyle(11, weight: FontWeight.w700, height: 1.15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: bodyStyle(14, weight: FontWeight.w800)),
            Text(
              '${value.toStringAsFixed(2)}x',
              style: bodyStyle(14, weight: FontWeight.w700, color: kMuted),
            ),
          ],
        ),
        Slider(
          value: value.clamp(0.5, 2.0),
          min: 0.5,
          max: 2.0,
          divisions: 30,
          semanticFormatterCallback: (v) => '$label ${v.toStringAsFixed(2)}x',
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}
