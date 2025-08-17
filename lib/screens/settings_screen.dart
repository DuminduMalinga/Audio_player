import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class SettingsScreen extends StatefulWidget {
  final AudioPlayer audioPlayer;

  const SettingsScreen({super.key, required this.audioPlayer});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Theme colors
  Color _primaryColor = Colors.deepPurple;

  // Visualizer sensitivity (1–10)
  double _sensitivity = 5;

  // Background animation type
  final List<String> _backgroundTypes = [
    'Pulse',
    'Wave',
    'Particles',
    'Static',
  ];
  String _selectedBackground = 'Pulse';

  // Full-screen visualizer toggle
  bool _fullScreenVisualizer = false;

  // Predefined theme colors
  final List<Color> _themeColors = [
    Colors.deepPurple,
    Colors.pink,
    Colors.teal,
    Colors.orange,
    Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personalization"),
        backgroundColor: _primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // Return settings to HomeScreen
              Navigator.pop(context, {
                'primaryColor': _primaryColor,
                'sensitivity': _sensitivity,
                'background': _selectedBackground,
                'fullScreen': _fullScreenVisualizer,
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme colors
            const Text(
              "Theme Color",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _themeColors.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _primaryColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _primaryColor == color
                            ? Colors.white
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Visualizer sensitivity
            const Text(
              "Visualizer Sensitivity",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _sensitivity,
              min: 1,
              max: 10,
              divisions: 9,
              label: _sensitivity.toStringAsFixed(1),
              activeColor: _primaryColor,
              onChanged: (value) {
                setState(() => _sensitivity = value);
              },
            ),
            const SizedBox(height: 24),

            // Background animation type
            const Text(
              "Background Animation",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedBackground,
              items: _backgroundTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedBackground = value!);
              },
            ),
            const SizedBox(height: 24),

            // Full-screen visualizer toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Full-Screen Visualizer",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _fullScreenVisualizer,
                  activeColor: _primaryColor,
                  onChanged: (value) {
                    setState(() => _fullScreenVisualizer = value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
