import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class SoundRecorderScreen extends StatefulWidget {
  const SoundRecorderScreen({super.key});

  @override
  State<SoundRecorderScreen> createState() => _SoundRecorderScreenState();
}

class _SoundRecorderScreenState extends State<SoundRecorderScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isPlaying = false;
  String? _recordedFilePath;

  Duration _recordDuration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _player.openPlayer();
    await _recorder.openRecorder();

    final micStatus = await Permission.microphone.request();
    bool hasStorage = true;

    if (Platform.isAndroid) {
      int sdkInt = 0;
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        sdkInt = androidInfo.version.sdkInt;
      } catch (_) {}

      if (sdkInt < 29) {
        final storageStatus = await Permission.storage.request();
        hasStorage = storageStatus.isGranted;
      }
    }

    if (!micStatus.isGranted || !hasStorage) {
      _showPermissionDialog();
    } else {
      _isRecorderInitialized = true;
      setState(() {});
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Microphone permission is required to record audio.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(ctx).pop();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordDuration += const Duration(seconds: 1));
    });
  }

  void _stopTimer() => _timer?.cancel();

  Future<String> _getDownloadPath() async {
    if (Platform.isAndroid) {
      return "/storage/emulated/0/Download";
    } else {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    }
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) return;

    final downloadPath = await _getDownloadPath();
    final fileName = "recording_${DateTime.now().millisecondsSinceEpoch}.m4a";
    final path = "$downloadPath/$fileName";

    await _recorder.startRecorder(toFile: path, codec: Codec.aacMP4);

    setState(() {
      _isRecording = true;
      _isPaused = false;
      _recordedFilePath = path;
      _recordDuration = Duration.zero;
    });

    _startTimer();
    debugPrint("Recording to: $path");
  }

  Future<void> _pauseRecording() async {
    if (_isRecording && !_isPaused) {
      await _recorder.pauseRecorder();
      setState(() => _isPaused = true);
      _stopTimer();
    }
  }

  Future<void> _resumeRecording() async {
    if (_isRecording && _isPaused) {
      await _recorder.resumeRecorder();
      setState(() => _isPaused = false);
      _startTimer();
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    await _recorder.stopRecorder();
    _stopTimer();

    setState(() {
      _isRecording = false;
      _isPaused = false;
    });

    if (Platform.isAndroid && _recordedFilePath != null) {
      try {
        const channel = MethodChannel('com.example.sound_recorder/scan');
        await channel.invokeMethod('scanFile', {'path': _recordedFilePath});
      } catch (e) {
        debugPrint("Failed to notify media scanner: $e");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Saved in Downloads: ${_recordedFilePath!.split('/').last}",
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath == null) return;
    final file = File(_recordedFilePath!);
    if (!await file.exists()) return;

    await _player.startPlayer(
      fromURI: _recordedFilePath,
      codec: Codec.aacMP4,
      whenFinished: () => setState(() => _isPlaying = false),
    );

    setState(() => _isPlaying = true);
  }

  Future<void> _stopPlayback() async {
    await _player.stopPlayer();
    setState(() => _isPlaying = false);
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.pinkAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Back Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white24,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // "Star" Text
                const Text(
                  "You are The New Born Star",
                  style: TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.white54,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Mic Icon
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.blueAccent, Colors.purpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.mic, size: 90, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 24),

                // Timer
                Text(
                  _formatDuration(_recordDuration),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 36),

                // Main Record / Pause Button
                _buildMainButton(),

                const SizedBox(height: 28),

                // Stop Recording Button
                ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : null,
                  icon: const Icon(Icons.stop),
                  label: const Text("Stop Recording"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording
                        ? Colors.redAccent
                        : Colors.white30,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Play Recording Button
                if (_recordedFilePath != null)
                  ElevatedButton.icon(
                    onPressed: _isPlaying ? _stopPlayback : _playRecording,
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    label: Text(
                      _isPlaying ? "Stop Playback" : "Play Recording",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton() {
    if (!_isRecording) {
      return _buildCircleButton(Icons.mic, _startRecording);
    } else if (_isPaused) {
      return _buildCircleButton(Icons.mic, _resumeRecording);
    } else {
      return _buildCircleButton(Icons.pause, _pauseRecording);
    }
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 45),
      ),
    );
  }
}
