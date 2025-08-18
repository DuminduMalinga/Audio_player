import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:equalizer_flutter/equalizer_flutter.dart';
import 'package:provider/provider.dart';
import 'theme_provide.dart';

class BassControlScreen extends StatefulWidget {
  final AudioPlayer player;
  const BassControlScreen({super.key, required this.player});

  @override
  _BassControlScreenState createState() => _BassControlScreenState();
}

class _BassControlScreenState extends State<BassControlScreen> {
  final List<int> _freqs = [60, 230, 910, 4000, 14000];
  List<int> _bandLevels = [0, 0, 0, 0, 0];
  int _minLevel = -10;
  int _maxLevel = 10;
  String _selectedPreset = "Normal";

  final Map<String, List<int>> _presets = {
    "Normal": [0, 0, 0, 0, 0],
    "Pop": [-1, 2, 3, 2, -1],
    "Classical": [3, 2, 0, 2, 3],
    "Dance": [5, 3, 0, 2, 4],
    "HipHop": [5, 3, 1, -1, 0],
    "Jazz": [2, 2, 0, 3, 2],
    "Custom": [0, 0, 0, 0, 0],
  };

  bool _eqReady = false;
  String _debugInfo = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initEqualizer();
  }

  Future<void> _initEqualizer() async {
    try {
      final sessionId = await widget.player.androidAudioSessionId ?? 0;
      await EqualizerFlutter.init(sessionId);
      await EqualizerFlutter.setEnabled(true);

      final range = await EqualizerFlutter.getBandLevelRange();
      _minLevel = range.isNotEmpty ? range[0] : -10;
      _maxLevel = range.length > 1 ? range[1] : 10;

      await _applyPresetLevels(_presets[_selectedPreset]!);

      setState(() {
        _eqReady = true;
        _debugInfo = 'Equalizer initialized.';
      });
    } catch (e) {
      debugPrint("Error initializing EQ: $e");
      setState(() {
        _debugInfo = "Error initializing EQ: $e";
      });
    }
  }

  Future<void> _applyPresetLevels(List<int> levels) async {
    for (int i = 0; i < _freqs.length; i++) {
      _bandLevels[i] = levels[i].clamp(_minLevel, _maxLevel);
      if (_eqReady) {
        try {
          await EqualizerFlutter.setBandLevel(_freqs[i], _bandLevels[i]);
        } catch (_) {}
      }
    }
    setState(() {});
  }

  void _onSliderChanged(int index, double value) async {
    _bandLevels[index] = value.toInt();
    if (_eqReady) {
      try {
        await EqualizerFlutter.setBandLevel(_freqs[index], _bandLevels[index]);
      } catch (_) {}
    }
    if (_selectedPreset != "Custom") {
      setState(() {
        _selectedPreset = "Custom";
        _presets["Custom"] = List<int>.from(_bandLevels);
      });
    } else {
      setState(() {});
    }
  }

  void _onPresetChanged(String? preset) async {
    if (preset == null) return;
    setState(() {
      _selectedPreset = preset;
    });
    await _applyPresetLevels(_presets[preset]!);
  }

  @override
  void dispose() {
    EqualizerFlutter.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryGradient = themeProvider.primaryGradient;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Bass / EQ Control",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Preset Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGradient.last.withOpacity(
                          0.5,
                        ), // THEME shadow
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPreset,
                      isExpanded: true,
                      alignment: Alignment.centerRight,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      dropdownColor: primaryGradient.first.withOpacity(
                        0.9,
                      ), // THEME dropdown
                      items: _presets.keys
                          .map(
                            (preset) => DropdownMenuItem(
                              value: preset,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  preset,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _onPresetChanged,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sliders
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _freqs.length,
                  itemBuilder: (context, index) {
                    final freq = _freqs[index];
                    final level = _bandLevels[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primaryGradient.first.withOpacity(
                                0.5,
                              ), // THEME shadow
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${freq} Hz",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: primaryGradient.first,
                                inactiveTrackColor: primaryGradient.last
                                    .withOpacity(0.3),
                                thumbColor: primaryGradient.last,
                              ),
                              child: Slider(
                                value: level.toDouble(),
                                min: _minLevel.toDouble(),
                                max: _maxLevel.toDouble(),
                                onChanged: (val) =>
                                    _onSliderChanged(index, val),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: SelectableText(
                  _debugInfo,
                  style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
