import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:equalizer_flutter/equalizer_flutter.dart';
import 'package:provider/provider.dart';
import 'theme_provide.dart';

class BassControlScreen extends StatefulWidget {
  final AudioPlayer player;
  final String? initialPreset;
  final List<int>? initialLevels;
  const BassControlScreen({
    super.key,
    required this.player,
    this.initialPreset,
    this.initialLevels,
  });

  @override
  _BassControlScreenState createState() => _BassControlScreenState();
}

class _BassControlScreenState extends State<BassControlScreen> {
  final List<int> _freqs = [60, 230, 910, 4000, 14000];
  List<int> _bandLevels = [0, 0, 0, 0, 0];
  int _minLevel = -10;
  int _maxLevel = 10;
  String _selectedPreset = "Normal";
  int _numBands = 5;

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
    // Use initial preset/levels if provided
    if (widget.initialPreset != null) {
      _selectedPreset = widget.initialPreset!;
    }
    if (widget.initialLevels != null &&
        widget.initialLevels!.length == _freqs.length) {
      _bandLevels = List<int>.from(widget.initialLevels!);
    }
    _initEqualizer();
  }

  Future<void> _applyPresetLevels(List<int> levels) async {
    // Pad or truncate levels to match _numBands
    List<int> paddedLevels = List<int>.from(levels);
    if (paddedLevels.length < _numBands) {
      paddedLevels.addAll(List.filled(_numBands - paddedLevels.length, 0));
    } else if (paddedLevels.length > _numBands) {
      paddedLevels = paddedLevels.sublist(0, _numBands);
    }
    for (int i = 0; i < _numBands; i++) {
      _bandLevels[i] = paddedLevels[i].clamp(_minLevel, _maxLevel);
      if (_eqReady) {
        try {
          await EqualizerFlutter.setBandLevel(i, _bandLevels[i]);
        } catch (_) {}
      }
    }
    setState(() {});
  }

  Future<void> _initEqualizer() async {
    // Wait until audio session ID is valid
    while ((widget.player.androidAudioSessionId ?? 0) == 0) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final sessionId = widget.player.androidAudioSessionId!;
    await EqualizerFlutter.init(sessionId);
    await EqualizerFlutter.setEnabled(true);

    final range = await EqualizerFlutter.getBandLevelRange();
    _minLevel = range[0];
    _maxLevel = range[1];

    // Use fixed 5 bands (matching _freqs and UI)
    _numBands = 5;
    _bandLevels = List<int>.filled(_numBands, 0);

    await _applyPresetLevels(_presets[_selectedPreset]!);

    setState(() {
      _eqReady = true;
      _debugInfo = 'Equalizer ready';
    });
  }

  // (removed duplicate _applyPresetLevels)

  void _onSliderChanged(int index, double value) async {
    _bandLevels[index] = value.toInt();
    if (_eqReady) {
      try {
        await EqualizerFlutter.setBandLevel(index, _bandLevels[index]);
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
                              "$freq Hz",
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
              // Add this just above the closing of Column in SafeArea
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: primaryGradient.first,
                    ),
                    onPressed: () {
                      // Pass back selected preset or band levels if needed
                      Navigator.pop(context, {
                        "preset": _selectedPreset,
                        "levels": List<int>.from(_bandLevels),
                      });
                    },
                    child: const Text(
                      "Save",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
