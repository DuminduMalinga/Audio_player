import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EqualizerScreen extends StatefulWidget {
  final AudioPlayer audioPlayer;

  const EqualizerScreen({super.key, required this.audioPlayer});

  @override
  _EqualizerScreenState createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  late List<int> _bandLevels;
  final int _numberOfBands = 5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEQSettings();
  }

  Future<void> _loadEQSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _bandLevels = List.generate(
      _numberOfBands,
      (index) => prefs.getInt('eq_band_$index') ?? 0,
    );

    // Simulate a small loading delay
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _setBandLevel(int bandIndex, int level) {
    setState(() {
      _bandLevels[bandIndex] = level;
    });
  }

  Future<void> _saveEQSettings() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _numberOfBands; i++) {
      await prefs.setInt('eq_band_$i', _bandLevels[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Equalizer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Adjust Bands', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _numberOfBands,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Text('Band ${index + 1}: ${_bandLevels[index]}'),
                      Slider(
                        min: -10,
                        max: 10,
                        divisions: 20,
                        value: _bandLevels[index].toDouble(),
                        onChanged: (value) =>
                            _setBandLevel(index, value.toInt()),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _saveEQSettings();
                Navigator.pop(context);
              },
              child: const Text('Save & Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
