import 'dart:async';
import 'dart:math';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'settings_screen.dart';
import 'sound_effects.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<Homescreen> {
  final AudioPlayer _player = AudioPlayer();
  final List<String> _playlist = [];
  int _currentIndex = 0;

  bool _isPlaying = false;
  String? _currentFilePath;

  Color _bgColor = Colors.deepPurple;
  Timer? _bgTimer;

  late PlayerController _waveformController;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Shuffle field
  bool _isShuffling = false;

  void _toggleShuffle() {
    setState(() {
      _isShuffling = !_isShuffling;
      if (_isShuffling) {
        _playlist.shuffle();
        _currentIndex = 0;
        _currentFilePath = _playlist.isNotEmpty ? _playlist[0] : null;
      } else {
        // Optionally, restore original order if you keep a backup
      }
    });
  }

  Future<void> _pickPlaylistFile() async {
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
        type: FileType.custom,
        allowedExtensions: ['mp3'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          String filePath = result.files.single.path!;
          _playlist.add(filePath);
          _currentIndex = _playlist.length - 1;
          _currentFilePath = filePath;
        });
        await _player.setFilePath(_currentFilePath!);
        await _waveformController.preparePlayer(path: _currentFilePath!);
      }
    } else if (status.isPermanentlyDenied) {
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

  @override
  void initState() {
    super.initState();
    _waveformController = PlayerController();

    _bgTimer = Timer.periodic(
      const Duration(milliseconds: 150),
      _updateBackground,
    );

    _player.positionStream.listen((pos) {
      setState(() {
        _currentPosition = pos;
      });
    });
    _player.durationStream.listen((dur) {
      setState(() {
        _totalDuration = dur ?? Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _waveformController.dispose();
    _bgTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickFile() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.pinkAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    // Optional: open drawer or menu
                  },
                ),
                const Text(
                  'Audio Player',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SettingsScreen(audioPlayer: _player),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.pinkAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // color: _bgColor, // Removed to avoid conflict with decoration
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Colors.blueAccent, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.music_note,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Text(
                      _currentFilePath != null
                          ? _getFileName(_currentFilePath!)
                          : "No Song Selected",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Artist Name",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Playlist button
                      IconButton(
                        icon: const Icon(
                          Icons.playlist_add,
                          color: Colors.white,
                        ),
                        onPressed: _pickPlaylistFile,
                        iconSize: 30,
                      ),

                      // Sound Effects button

                      // Previous track
                      IconButton(
                        icon: const Icon(
                          Icons.skip_previous,
                          color: Colors.white,
                        ),
                        onPressed: _previousTrack,
                        iconSize: 36,
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.purple, Colors.blue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: _isPlaying ? _pause : _play,
                          iconSize: 48,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        onPressed: _nextTrack,
                        iconSize: 36,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          color: _isShuffling
                              ? Colors.pinkAccent
                              : Colors.white,
                        ),
                        onPressed: _toggleShuffle,
                        iconSize: 30,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Text(
                          _formatDuration(_currentPosition),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _currentPosition.inSeconds.toDouble().clamp(
                              0,
                              _totalDuration.inSeconds.toDouble(),
                            ),
                            max: _totalDuration.inSeconds > 0
                                ? _totalDuration.inSeconds.toDouble()
                                : 1,
                            onChanged: (value) async {
                              await _player.seek(
                                Duration(seconds: value.toInt()),
                              );
                            },
                            activeColor: Colors.white,
                            inactiveColor: Colors.white30,
                          ),
                        ),
                        Text(
                          _formatDuration(_totalDuration),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.graphic_eq,
                            color: Colors.white,
                          ),
                          onPressed: _currentFilePath == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SoundEffectsScreen(
                                        currentFilePath: _currentFilePath!,
                                      ),
                                    ),
                                  );
                                },
                          iconSize: 30,
                          tooltip: 'Sound Effects',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoMin = twoDigits(d.inMinutes.remainder(60));
    final twoSec = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return '${twoDigits(d.inHours)}:$twoMin:$twoSec';
    } else {
      return '$twoMin:$twoSec';
    }
  }

  String _getFileName(String path) {
    return path.split(RegExp(r'[\\/]')).last;
  }
}
