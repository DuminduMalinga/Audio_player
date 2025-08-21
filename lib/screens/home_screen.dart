import 'dart:async';
import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'settings_screen.dart';
import 'sound_effects.dart';
import 'recording_screen.dart';
import 'profile.dart';
import 'theme_provide.dart';

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
  bool _isFavorite = false;

  late PlayerController _waveformController;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  bool _isShuffling = false;

  void _toggleShuffle() {
    setState(() {
      _isShuffling = !_isShuffling;
      if (_isShuffling) {
        _playlist.shuffle();
        _currentIndex = 0;
        _currentFilePath = _playlist.isNotEmpty ? _playlist[0] : null;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _waveformController = PlayerController();

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

    _player.playingStream.listen((playing) {
      setState(() {
        _isPlaying = playing;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _waveformController.dispose();
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

    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
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
          const SnackBar(
            content: Text("Permission denied to read audio files"),
          ),
        );
      }
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      for (var file in result.files) {
        if (file.path != null && !_playlist.contains(file.path!)) {
          _playlist.add(file.path!);
        }
      }
      setState(() {
        _currentIndex = _playlist.length - result.files.length;
        _currentFilePath = _playlist[_currentIndex];
      });

      await _player.setFilePath(_currentFilePath!);
      await _waveformController.preparePlayer(
        path: _currentFilePath!,
        shouldExtractWaveform: true,
      );
      _play();
    }
  }

  Future<void> _play() async {
    if (_currentFilePath != null && !_isPlaying) {
      await _player.play();
      await _waveformController.startPlayer();
    }
  }

  Future<void> _pause() async {
    if (_isPlaying) {
      await _player.pause();
      await _waveformController.pausePlayer();
    }
  }

  Future<void> _nextTrack() async {
    if (_playlist.isNotEmpty) {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
      _currentFilePath = _playlist[_currentIndex];
      await _player.setFilePath(_currentFilePath!);
      await _waveformController.preparePlayer(
        path: _currentFilePath!,
        shouldExtractWaveform: true,
      );
      _play();
    }
  }

  Future<void> _previousTrack() async {
    if (_playlist.isNotEmpty) {
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
      _currentFilePath = _playlist[_currentIndex];
      await _player.setFilePath(_currentFilePath!);
      await _waveformController.preparePlayer(
        path: _currentFilePath!,
        shouldExtractWaveform: true,
      );
      _play();
    }
  }

  Future<void> _pickPlaylistFile() async {
    await _pickFile();
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

  void _openMenu() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: themeProvider.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuItem(Icons.person, "Profile", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                }),
                _buildMenuItem(Icons.playlist_play, "Playlist", () async {
                  Navigator.pop(context);
                  await _pickFile();
                }),
                _buildMenuItem(Icons.favorite, "Favourite", () {
                  Navigator.pop(context);
                }),
                _buildMenuItem(Icons.mic, "Your Recordings", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecordingsListScreen(
                        audioPlayer: _player,
                        waveformController: _waveformController,
                        onRecordingSelected: (filePath) {
                          setState(() {
                            if (!_playlist.contains(filePath)) {
                              _playlist.add(filePath);
                              _currentIndex = _playlist.length - 1;
                            } else {
                              _currentIndex = _playlist.indexOf(filePath);
                            }
                            _currentFilePath = filePath;
                          });
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
      horizontalTitleGap: 0,
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: _openMenu,
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
              Expanded(
                flex: 4,
                child: Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: themeProvider.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.music_note,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Text(
                      _currentFilePath != null
                          ? _getFileName(_currentFilePath!)
                          : "No Song Selected",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Artist Name",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                          await _player.seek(Duration(seconds: value.toInt()));
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
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: _isShuffling ? Colors.pinkAccent : Colors.white,
                    ),
                    onPressed: _toggleShuffle,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: _previousTrack,
                    iconSize: 36,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: themeProvider.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (_isPlaying) {
                          _pause();
                        } else {
                          _play();
                        }
                      },
                      iconSize: 48,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: _nextTrack,
                    iconSize: 36,
                  ),
                  IconButton(
                    icon: const Icon(Icons.repeat, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.favorite,
                      color: _isFavorite ? Colors.red : Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                    },
                    iconSize: 30,
                  ),
                  IconButton(
                    icon: const Icon(Icons.graphic_eq, color: Colors.white),
                    onPressed: () async {
                      if (_currentFilePath == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Please select a song first!",
                              style: TextStyle(color: Colors.black87),
                            ),
                            backgroundColor: Colors.transparent,
                          ),
                        );
                        return;
                      }

                      final effect = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SoundEffectsScreen(
                            currentFilePath: _currentFilePath!,
                          ),
                        ),
                      );

                      if (effect != null && effect is Map<String, dynamic>) {
                        await _player.stop();
                        await _player.setFilePath(_currentFilePath!);
                        try {
                          await _player.setPitch(effect["pitch"] as double);
                        } catch (_) {}
                        await _player.setSpeed(effect["speed"] as double);
                        await _player.play();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SoundRecorderScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.playlist_add, color: Colors.white),
                    onPressed: _pickPlaylistFile,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class RecordingsListScreen extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final PlayerController waveformController;
  final Function(String) onRecordingSelected;

  const RecordingsListScreen({
    super.key,
    required this.audioPlayer,
    required this.waveformController,
    required this.onRecordingSelected,
  });

  @override
  State<RecordingsListScreen> createState() => _RecordingsListScreenState();
}

class _RecordingsListScreenState extends State<RecordingsListScreen> {
  List<File> _recordings = [];
  String? _currentFilePath;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoadRecordings();
    _setupPlayerListeners();
  }

  Future<void> _checkPermissionsAndLoadRecordings() async {
    PermissionStatus status;
    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        status = await Permission.audio.request();
      } else {
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.storage.request();
    }

    if (!status.isGranted) return;

    await _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    Directory folder;
    if (Platform.isAndroid) {
      folder = Directory('/storage/emulated/0/Recordings');
    } else {
      folder = await getApplicationDocumentsDirectory();
    }

    if (await folder.exists()) {
      final files = folder
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.aac'))
          .toList();
      setState(() {
        _recordings = files;
      });
    }
  }

  void _setupPlayerListeners() {
    widget.audioPlayer.playingStream.listen((playing) {
      setState(() {
        _isPlaying = playing;
      });
    });
  }

  Future<void> _playRecording(String filePath) async {
    try {
      if (_isPlaying || widget.audioPlayer.playing) {
        await widget.audioPlayer.stop();
        await widget.waveformController.stopPlayer();
      }

      _currentFilePath = filePath;
      widget.onRecordingSelected(filePath);

      await widget.audioPlayer.setFilePath(filePath);
      await widget.waveformController.preparePlayer(
        path: filePath,
        shouldExtractWaveform: true,
      );
      await widget.audioPlayer.play();
      await widget.waveformController.startPlayer();

      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      debugPrint("Error playing recording: $e");
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await widget.audioPlayer.pause();
      await widget.waveformController.pausePlayer();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      debugPrint("Error pausing recording: $e");
    }
  }

  String _getFileName(String path) {
    return path.split(RegExp(r'[\\/]')).last;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Recordings'),
        backgroundColor: themeProvider.primaryGradient.first,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: themeProvider.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _recordings.isEmpty
            ? const Center(
                child: Text(
                  'No recordings found',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _recordings.length,
                itemBuilder: (context, index) {
                  final file = _recordings[index];
                  return Card(
                    color: Colors.white24,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        _currentFilePath == file.path && _isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      title: Text(
                        _getFileName(file.path),
                        style: const TextStyle(color: Colors.white),
                      ),
                      tileColor: Colors.transparent,
                      onTap: () async {
                        if (_currentFilePath == file.path && _isPlaying) {
                          await _pauseRecording();
                        } else {
                          await _playRecording(file.path);
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
