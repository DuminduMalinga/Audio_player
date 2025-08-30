import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'theme_provide.dart';

class SettingsScreen extends StatefulWidget {
  final AudioPlayer audioPlayer;

  const SettingsScreen({super.key, required this.audioPlayer});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _playbackSpeed = 1.0;
  final List<String> _eqPresets = [
    'Normal',
    'Pop',
    'Classical',
    'Dance',
    'HipHop',
    'Jazz',
    'Bass Boost',
  ];
  String _selectedPreset = 'Normal';
  bool _crossfadeEnabled = false;
  bool _shuffleEnabled = false;
  bool _repeatEnabled = false;

  final List<List<Color>> _themeGradients = [
    [Colors.deepPurple, Colors.pinkAccent],
    [Colors.teal, Colors.greenAccent],
    [Colors.orange, Colors.redAccent],
    [Colors.blueGrey, Colors.lightBlueAccent],
    [Colors.pink, Colors.purpleAccent],
  ];

  void _saveSettings() {
    // Already set the gradient when tapped, so just pop
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: themeProvider.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
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
                      onPressed: _saveSettings,
                    ),
                    const Text(
                      "Settings",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.save, color: Colors.white),
                      onPressed: _saveSettings,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Theme Gradient
                      const Text(
                        "Theme Gradient",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children: _themeGradients.map((gradient) {
                          return GestureDetector(
                            onTap: () => themeProvider.setGradient(gradient),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      themeProvider.primaryGradient == gradient
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Playback Speed
                      const Text(
                        "Playback Speed",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Slider(
                        value: _playbackSpeed,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        label: "${_playbackSpeed.toStringAsFixed(1)}x",
                        activeColor: themeProvider.primaryGradient[0],
                        inactiveColor: Colors.white30,
                        onChanged: (value) {
                          setState(() => _playbackSpeed = value);
                          widget.audioPlayer.setSpeed(value);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Equalizer Preset
                      const Text(
                        "Equalizer Preset",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedPreset,
                          dropdownColor: Colors.black87,
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white),
                          isExpanded: true,
                          items: _eqPresets
                              .map(
                                (preset) => DropdownMenuItem(
                                  value: preset,
                                  child: Text(preset),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedPreset = value!),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Crossfade
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Enable Crossfade",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: _crossfadeEnabled,
                            activeThumbColor: themeProvider.primaryGradient[0],
                            onChanged: (value) =>
                                setState(() => _crossfadeEnabled = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Shuffle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Shuffle",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: _shuffleEnabled,
                            activeThumbColor: themeProvider.primaryGradient[0],
                            onChanged: (value) =>
                                setState(() => _shuffleEnabled = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Repeat
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Repeat",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: _repeatEnabled,
                            activeThumbColor: themeProvider.primaryGradient[0],
                            onChanged: (value) =>
                                setState(() => _repeatEnabled = value),
                          ),
                        ],
                      ),
                    ],
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
