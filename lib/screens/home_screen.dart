import 'dart:async';
import 'dart:math';
//import 'package:audio_player/screens/settings_screen.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'equalizer_screen.dart';
//import 'settings_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum VisualizerMode { barSpectrum, circularWaves, particleBursts, oscilloscope }

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<Homescreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  final List<String> _playlist = [];
  int _currentIndex = 0;

  bool _isPlaying = false;
  String? _currentFilePath;

  late AnimationController _spectrumController;

  Color _bgColor = Colors.deepPurple;
  Timer? _bgTimer;

  late PlayerController _waveformController;

  VisualizerMode _currentVisualizerMode = VisualizerMode.barSpectrum;

  @override
  void initState() {
    super.initState();
    _waveformController = PlayerController();

    _spectrumController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat();

    _bgTimer = Timer.periodic(
      const Duration(milliseconds: 150),
      _updateBackground,
    );
  }

  @override
  void dispose() {
    _player.dispose();
    _waveformController.dispose();
    _spectrumController.dispose();
    _bgTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickFile() async {
    // Android 13+ uses READ_MEDIA_AUDIO, below uses READ_EXTERNAL_STORAGE
    PermissionStatus status;
    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.android) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        status = await Permission.audio.request();
      } else {
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _currentFilePath = result.files.single.path!;
          _playlist.add(_currentFilePath!);
          _currentIndex = _playlist.length - 1;
        });
        await _player.setFilePath(_currentFilePath!);
        await _waveformController.preparePlayer(path: _currentFilePath!);
      }
    } else if (status.isPermanentlyDenied) {
      // Open app settings if permission is permanently denied
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Please enable storage or audio permission in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission denied to read audio files")),
      );
    }
  }

  Future<void> _play() async {
    if (_currentFilePath != null) {
      await _player.play();
      _waveformController.startPlayer();
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _pause() async {
    await _player.pause();
    _waveformController.pausePlayer();
    setState(() => _isPlaying = false);
  }

  Future<void> _stop() async {
    await _player.stop();
    _waveformController.stopPlayer();
    setState(() => _isPlaying = false);
  }

  Future<void> _nextTrack() async {
    if (_playlist.isNotEmpty) {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
      _currentFilePath = _playlist[_currentIndex];
      await _player.setFilePath(_currentFilePath!);
      await _waveformController.preparePlayer(path: _currentFilePath!);
      _play();
    }
  }

  Future<void> _previousTrack() async {
    if (_playlist.isNotEmpty) {
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
      _currentFilePath = _playlist[_currentIndex];
      await _player.setFilePath(_currentFilePath!);
      await _waveformController.preparePlayer(path: _currentFilePath!);
      _play();
    }
  }

  void _updateBackground(Timer timer) {
    if (_isPlaying) {
      final intensity = Random().nextDouble();
      setState(() {
        _bgColor = Color.lerp(
          Colors.deepPurple,
          Colors.pinkAccent,
          intensity.clamp(0, 1),
        )!;
      });
    }
  }

  // --- Visualizer Widgets ---
  Widget _buildVisualizer() {
    switch (_currentVisualizerMode) {
      case VisualizerMode.barSpectrum:
        return _buildBarSpectrum();
      case VisualizerMode.circularWaves:
        return _buildCircularWaves();
      case VisualizerMode.particleBursts:
        return _buildParticleBursts();
      case VisualizerMode.oscilloscope:
        return _buildOscilloscope();
    }
  }

  Widget _buildBarSpectrum() {
    return SizedBox(
      height: 100,
      child: AnimatedBuilder(
        animation: _spectrumController,
        builder: (_, __) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(20, (index) {
              final height = Random().nextDouble() * 80 + 20;
              return Container(
                width: 6,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildCircularWaves() {
    return SizedBox(
      height: 100,
      child: Center(
        child: AnimatedBuilder(
          animation: _spectrumController,
          builder: (_, __) {
            double size = 30 + Random().nextDouble() * 60;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.4),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildParticleBursts() {
    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(10, (i) {
          double dx = (Random().nextDouble() - 0.5) * 200;
          double dy = (Random().nextDouble() - 0.5) * 80;
          return AnimatedBuilder(
            animation: _spectrumController,
            builder: (_, __) {
              return Positioned(
                left: 100 + dx,
                top: 50 + dy,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildOscilloscope() {
    return SizedBox(
      height: 100,
      child: AnimatedBuilder(
        animation: _spectrumController,
        builder: (_, __) {
          return CustomPaint(
            size: const Size(double.infinity, 100),
            painter: _OscilloscopePainter(),
          );
        },
      ),
    );
  }

  Widget _miniVisualizerPreview(VisualizerMode mode) {
    switch (mode) {
      case VisualizerMode.barSpectrum:
        return _miniBarSpectrum();
      case VisualizerMode.circularWaves:
        return _miniCircularWaves();
      case VisualizerMode.particleBursts:
        return _miniParticleBursts();
      case VisualizerMode.oscilloscope:
        return _miniOscilloscope();
    }
  }

  Widget _miniBarSpectrum() {
    return SizedBox(
      height: 40,
      child: AnimatedBuilder(
        animation: _spectrumController,
        builder: (_, __) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final height = Random().nextDouble() * 30 + 10;
              return Container(
                width: 4,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _miniCircularWaves() {
    return SizedBox(
      height: 40,
      child: AnimatedBuilder(
        animation: _spectrumController,
        builder: (_, __) {
          double scale = 0.8 + Random().nextDouble() * 0.4;
          return Center(
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _miniParticleBursts() {
    return SizedBox(
      height: 40,
      child: AnimatedBuilder(
        animation: _spectrumController,
        builder: (_, __) {
          return Stack(
            alignment: Alignment.center,
            children: List.generate(5, (i) {
              final dx = (Random().nextDouble() - 0.5) * 20;
              final dy = (Random().nextDouble() - 0.5) * 20;
              return Positioned(
                left: 20 + dx,
                top: 20 + dy,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _miniOscilloscope() {
    return SizedBox(
      height: 40,
      child: CustomPaint(
        size: const Size(60, 40),
        painter: _OscilloscopePainter(),
      ),
    );
  }

  String formatVisualizerName(String mode) {
    final name = mode.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (Match m) => '${m[1]} ${m[2]}',
    );
    return name
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Widget _buildVisualizerCard(VisualizerMode mode) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentVisualizerMode = mode),
        child: Card(
          color: _currentVisualizerMode == mode ? Colors.pink : Colors.white24,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _miniVisualizerPreview(mode),
                const SizedBox(height: 4),
                Text(
                  formatVisualizerName(mode.toString().split('.').last),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _bgColor,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      // Waveform
                      if (_currentFilePath != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AudioFileWaveforms(
                            size: Size(MediaQuery.of(context).size.width, 120),
                            playerController: _waveformController,
                            enableSeekGesture: true,
                            waveformType: WaveformType.fitWidth,
                            playerWaveStyle: const PlayerWaveStyle(
                              fixedWaveColor: Colors.white,
                              liveWaveColor: Colors.pink,
                              waveCap: StrokeCap.round,
                            ),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "Select a file to start playing",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),

                      const SizedBox(height: 50),
                      _buildVisualizer(),
                      const SizedBox(height: 50),

                      // 2x2 Visualizer Selector
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Row(
                              children: VisualizerMode.values
                                  .sublist(0, 2)
                                  .map((mode) => _buildVisualizerCard(mode))
                                  .toList(),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: VisualizerMode.values
                                  .sublist(2, 4)
                                  .map((mode) => _buildVisualizerCard(mode))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Playback controls
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.skip_previous,
                        color: Colors.white,
                      ),
                      onPressed: _previousTrack,
                      iconSize: 36,
                    ),
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: _isPlaying ? _pause : _play,
                      iconSize: 48,
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop, color: Colors.white),
                      onPressed: _stop,
                      iconSize: 36,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                      onPressed: _nextTrack,
                      iconSize: 36,
                    ),
                  ],
                ),
              ),

              // File picker & equalizer
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text("Select Audio File"),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EqualizerScreen(audioPlayer: _player),
                          ),
                        );
                      },
                      icon: const Icon(Icons.equalizer),
                      label: const Text("Equalizer"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Oscilloscope painter
class _OscilloscopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (double x = 0; x < size.width; x++) {
      double y =
          size.height / 2 + sin(x / 3 + DateTime.now().millisecond / 50) * 10;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
