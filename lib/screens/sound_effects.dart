import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';

class SoundEffectsScreen extends StatefulWidget {
  final String currentFilePath; // input file (original song)

  const SoundEffectsScreen({super.key, required this.currentFilePath});

  @override
  State<SoundEffectsScreen> createState() => _SoundEffectsScreenState();
}

class _SoundEffectsScreenState extends State<SoundEffectsScreen> {
  String? _activeEffect;
  final AudioPlayer _player = AudioPlayer();

  final List<Map<String, String>> effects = [
    {
      "name": "Robot Voice",
      "desc": "Vocoder-style robotic voice",
      "id": "robot",
    },
    {"name": "8D Audio", "desc": "Simulated surround panning", "id": "8d"},
    {"name": "Whisper", "desc": "Soft reverb + high-pass", "id": "whisper"},
    {"name": "Lo-Fi", "desc": "Bitcrusher + vinyl crackle", "id": "lofi"},
  ];

  /// Apply effect with FFmpeg and return processed file path
  Future<String> _applyEffect(String inputPath, String effectId) async {
    final dir = await getTemporaryDirectory();
    final outputPath = "${dir.path}/effect_output.mp3";

    // Remove previous effect output if exists
    final outFile = File(outputPath);
    if (await outFile.exists()) {
      await outFile.delete();
    }

    String filter = "";

    switch (effectId) {
      case "robot":
        filter = "asetrate=8000,atempo=1.0,aresample=44100";
        break;
      case "8d":
        filter = "apulsator=hz=0.3";
        break;
      case "whisper":
        filter = "highpass=f=300,aecho=0.8:0.9:1000:0.3";
        break;
      case "lofi":
        filter = "aresample=8000,atempo=1.1,volume=1.2,acrusher=8:0.5:64:0.5";
        break;
    }

    final cmd = '-i "$inputPath" -af "$filter" -y "$outputPath"';
    await FFmpegKit.execute(cmd);

    return outputPath;
  }

  /// Handle effect toggle
  Future<void> _toggleEffect(String effectId) async {
    if (_activeEffect == effectId) {
      // Disable effect -> play original
      setState(() => _activeEffect = null);
      await _player.stop();
      await _player.setFilePath(widget.currentFilePath);
      await _player.play();
    } else {
      // Enable new effect
      setState(() => _activeEffect = effectId);

      String newFile = await _applyEffect(widget.currentFilePath, effectId);

      await _player.stop();
      await _player.setFilePath(newFile);
      await _player.play();
    }
  }

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.setFilePath(widget.currentFilePath);
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Sound Effects"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: effects.length,
        itemBuilder: (context, index) {
          final effect = effects[index];
          final isActive = _activeEffect == effect["id"];
          return GestureDetector(
            onTap: () => _toggleEffect(effect["id"]!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isActive
                    ? Colors.deepPurpleAccent.withOpacity(0.9)
                    : Colors.grey[900],
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: Colors.deepPurpleAccent.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? Icons.music_note : Icons.music_off,
                    size: 48,
                    color: isActive ? Colors.white : Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    effect["name"]!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    effect["desc"]!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (isActive)
                    const Icon(Icons.check_circle, color: Colors.white),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
