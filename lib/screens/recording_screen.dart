import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;
import 'package:flutter/services.dart';
import 'package:audio_session/audio_session.dart';

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
    try {
      final session = await AudioSession.instance;
      await session.configure(
        AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
          avAudioSessionMode: AVAudioSessionMode.spokenAudio,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.voiceCommunication,
          ),
        ),
      );

      await _player.openPlayer();
      await _recorder.openRecorder();

      final micStatus = await Permission.microphone.request();
      bool hasStorage = true;

      if (Platform.isAndroid) {
        int sdkInt = 0;
        try {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          sdkInt = androidInfo.version.sdkInt;
        } catch (e) {
          debugPrint("Error getting Android SDK version: $e");
        }

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
    } catch (e) {
      debugPrint("Initialization error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Initialization error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Microphone and storage permissions are required to record and save audio.',
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

  Future<String> _getRecordingFolder() async {
    Directory folder;
    if (Platform.isAndroid) {
      folder = Directory('/storage/emulated/0/Recordings');
    } else {
      folder = await getApplicationDocumentsDirectory();
    }
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder.path;
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) return;

    final folderPath = await _getRecordingFolder();
    final fileName = "recording_${DateTime.now().millisecondsSinceEpoch}.aac";
    final path = "$folderPath/$fileName";

    try {
      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
        sampleRate: 44100,
        bitRate: 64000,
      );
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordedFilePath = path;
        _recordDuration = Duration.zero;
      });
      _startTimer();
      debugPrint("Recording to: $path");
    } catch (e) {
      debugPrint("Error starting recording: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error starting recording: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pauseRecording() async {
    if (_isRecording && !_isPaused) {
      try {
        await _recorder.pauseRecorder();
        setState(() => _isPaused = true);
        _stopTimer();
      } catch (e) {
        debugPrint("Error pausing recording: $e");
      }
    }
  }

  Future<void> _resumeRecording() async {
    if (_isRecording && _isPaused) {
      try {
        await _recorder.resumeRecorder();
        setState(() => _isPaused = false);
        _startTimer();
      } catch (e) {
        debugPrint("Error resuming recording: $e");
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stopRecorder();
      _stopTimer();

      setState(() {
        _isRecording = false;
        _isPaused = false;
      });

      if (_recordedFilePath != null) {
        final file = File(_recordedFilePath!);
        final size = await file.length();
        debugPrint("File exists: ${await file.exists()}, Size: $size bytes");

        if (await file.exists() && Platform.isAndroid) {
          if (size < 10000) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Warning: Recorded file may be corrupted"),
                backgroundColor: Colors.orange,
              ),
            );
          }
          try {
            const channel = MethodChannel('com.example.sound_recorder/scan');
            await channel.invokeMethod('scanFile', {'path': _recordedFilePath});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Saved in Recordings: ${_recordedFilePath!.split('/').last}",
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } catch (e) {
            debugPrint("Failed to notify media scanner: $e");
          }
        }
      }
    } catch (e) {
      debugPrint("Error stopping recording: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error stopping recording: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No recording available"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final file = File(_recordedFilePath!);
    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Recorded file not found"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final session = await AudioSession.instance;
      await session.setActive(true);

      if (_player.isPlaying) await _player.stopPlayer();

      await _player.startPlayer(
        fromURI: _recordedFilePath,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() => _isPlaying = false);
        },
      );

      setState(() => _isPlaying = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error playing recording: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _player.stopPlayer();
      final session = await AudioSession.instance;
      await session.setActive(false);
      setState(() => _isPlaying = false);
    } catch (e) {
      debugPrint("Error stopping playback: $e");
    }
  }

  void _showRecordings() async {
    final folderPath = await _getRecordingFolder();
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No recordings found"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final files = folder
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.aac'))
        .toList();

    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No recordings available"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecordingsScreen(files: files)),
    );
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
                Text(
                  _formatDuration(_recordDuration),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 36),
                _buildMainButton(),
                const SizedBox(height: 28),
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
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _showRecordings,
                  icon: const Icon(Icons.library_music),
                  label: const Text("View Recordings"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
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

class RecordingsScreen extends StatefulWidget {
  final List<File> files;

  const RecordingsScreen({super.key, required this.files});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  String? _currentlyPlayingPath;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player.openPlayer();
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _playPauseRecording(String path) async {
    try {
      if (_isPlaying && _currentlyPlayingPath == path) {
        await _player.stopPlayer();
        setState(() {
          _isPlaying = false;
          _currentlyPlayingPath = null;
        });
      } else {
        if (_player.isPlaying) await _player.stopPlayer();

        setState(() {
          _currentlyPlayingPath = path;
          _isPlaying = true;
        });

        await _player.startPlayer(
          fromURI: path,
          codec: Codec.aacADTS,
          whenFinished: () {
            setState(() {
              _isPlaying = false;
              _currentlyPlayingPath = null;
            });
          },
        );
      }
    } catch (e) {
      debugPrint("Error playing recording: $e");
    }
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
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
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
                    const SizedBox(width: 16),
                    const Text(
                      "Recordings",
                      style: TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.white54,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: widget.files.isEmpty
                    ? const Center(
                        child: Text(
                          "No recordings available",
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: widget.files.length,
                        itemBuilder: (context, index) {
                          final file = widget.files[index];
                          final fileName = file.path.split('/').last;
                          final isPlayingCurrent =
                              _isPlaying && _currentlyPlayingPath == file.path;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.audiotrack,
                                  color: Colors.white,
                                ),
                                title: Text(
                                  fileName,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    isPlayingCurrent
                                        ? Icons.stop
                                        : Icons.play_arrow,
                                    color: Colors.yellowAccent,
                                  ),
                                  onPressed: () =>
                                      _playPauseRecording(file.path),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
