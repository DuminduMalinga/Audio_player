import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../widgets/common.dart';
import 'theme_provide.dart';

class _Recording {
  final File file;
  final DateTime modified;
  final int bytes;
  _Recording(this.file, this.modified, this.bytes);

  String get name {
    final n = file.path.split(RegExp(r'[\\/]')).last;
    final dot = n.lastIndexOf('.');
    return dot > 0 ? n.substring(0, dot) : n;
  }

  /// Estimated from the 64 kbps AAC bit rate used when recording.
  Duration get length => Duration(seconds: (bytes * 8 / 64000).round());
}

/// Recorder tab: record / pause / resume / save / discard plus the list of
/// saved recordings.
class SoundRecorderScreen extends StatefulWidget {
  const SoundRecorderScreen({super.key});

  @override
  State<SoundRecorderScreen> createState() => _SoundRecorderScreenState();
}

class _SoundRecorderScreenState extends State<SoundRecorderScreen> {
  static const _barCount = 44;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  bool _ready = false;
  bool _recorderOpen = false;
  bool _playerOpen = false;
  bool _isRecording = false;
  bool _isPaused = false;
  String? _recordedFilePath;
  String? _playingPath;

  final Stopwatch _clock = Stopwatch();
  Timer? _ticker;
  StreamSubscription<RecordingDisposition>? _levelSub;
  final List<double> _levels = List.filled(_barCount, 0);

  List<_Recording> _recordings = [];

  @override
  void initState() {
    super.initState();
    _init();
    _loadRecordings();
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

      if (!_recorderOpen) {
        await _recorder.openRecorder();
        _recorderOpen = true;
      }
      if (!_playerOpen) {
        await _player.openPlayer();
        _playerOpen = true;
      }
      await _recorder.setSubscriptionDuration(const Duration(milliseconds: 80));
      _levelSub ??= _recorder.onProgress?.listen(_onLevel);

      final micStatus = await Permission.microphone.request();
      var hasStorage = true;

      if (Platform.isAndroid) {
        var sdkInt = 0;
        try {
          sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
        } catch (e) {
          debugPrint('Error getting Android SDK version: $e');
        }
        if (sdkInt < 29) {
          hasStorage = (await Permission.storage.request()).isGranted;
        }
      }

      if (!micStatus.isGranted || !hasStorage) {
        _showPermissionDialog();
      } else if (mounted) {
        setState(() => _ready = true);
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) showAppSnack(context, 'Initialization error: $e');
    }
  }

  void _onLevel(RecordingDisposition e) {
    if (!_isRecording || _isPaused || !mounted) return;
    final db = e.decibels ?? 0;
    setState(() {
      _levels
        ..removeAt(0)
        ..add((db / 90).clamp(0.05, 1.0));
    });
  }

  void _showPermissionDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission required'),
        content: const Text(
          'Microphone and storage permissions are required to record and save audio.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(ctx).pop();
            },
            child: const Text('Open settings'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- files

  Future<String> _getRecordingFolder() async {
    final Directory folder = Platform.isAndroid
        ? Directory('/storage/emulated/0/Recordings')
        : await getApplicationDocumentsDirectory();
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder.path;
  }

  String get _folderLabel => Platform.isAndroid
      ? '/storage/emulated/0/Recordings'
      : 'App documents folder';

  Future<void> _loadRecordings() async {
    try {
      final Directory folder = Platform.isAndroid
          ? Directory('/storage/emulated/0/Recordings')
          : await getApplicationDocumentsDirectory();
      if (!await folder.exists()) return;
      final items = <_Recording>[];
      for (final f in folder.listSync().whereType<File>()) {
        if (!f.path.endsWith('.aac')) continue;
        final stat = f.statSync();
        items.add(_Recording(f, stat.modified, stat.size));
      }
      items.sort((a, b) => b.modified.compareTo(a.modified));
      if (mounted) setState(() => _recordings = items);
    } catch (e) {
      debugPrint('Could not list recordings: $e');
    }
  }

  // ------------------------------------------------------------ recording

  void _startClock() {
    _clock.start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopClock() {
    _clock.stop();
    _ticker?.cancel();
  }

  void _resetClock() {
    _stopClock();
    _clock.reset();
    for (var i = 0; i < _levels.length; i++) {
      _levels[i] = 0;
    }
  }

  Future<void> _startRecording() async {
    if (!_ready) {
      await _init();
      if (!_ready) return;
    }
    if (_playingPath != null) await _stopPlayback();

    final folder = await _getRecordingFolder();
    final path =
        '$folder/recording_${DateTime.now().millisecondsSinceEpoch}.aac';
    try {
      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
        sampleRate: 44100,
        bitRate: 64000,
      );
      _clock.reset();
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordedFilePath = path;
      });
      _startClock();
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) showAppSnack(context, 'Error starting recording: $e');
    }
  }

  Future<void> _pauseRecording() async {
    if (!_isRecording || _isPaused) return;
    try {
      await _recorder.pauseRecorder();
      _stopClock();
      if (mounted) setState(() => _isPaused = true);
    } catch (e) {
      debugPrint('Error pausing recording: $e');
    }
  }

  Future<void> _resumeRecording() async {
    if (!_isRecording || !_isPaused) return;
    try {
      await _recorder.resumeRecorder();
      _startClock();
      if (mounted) setState(() => _isPaused = false);
    } catch (e) {
      debugPrint('Error resuming recording: $e');
    }
  }

  /// Stops the recorder and keeps the file.
  Future<void> _saveRecording() async {
    if (!_isRecording) {
      showAppSnack(context, 'Nothing to save yet. Tap the mic to record.');
      return;
    }
    final path = _recordedFilePath;
    try {
      await _recorder.stopRecorder();
      _resetClock();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isPaused = false;
        });
      }

      if (path != null) {
        final file = File(path);
        if (await file.exists() && Platform.isAndroid) {
          if (await file.length() < 10000 && mounted) {
            showAppSnack(context, 'Warning: recorded file may be corrupted');
          }
          try {
            const channel = MethodChannel('com.example.sound_recorder/scan');
            await channel.invokeMethod('scanFile', {'path': path});
            if (mounted) {
              showAppSnack(
                context,
                'Saved in Recordings: ${path.split('/').last}',
              );
            }
          } catch (e) {
            debugPrint('Failed to notify media scanner: $e');
          }
        } else if (mounted) {
          showAppSnack(context, 'Recording saved');
        }
      }
      await _loadRecordings();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      if (mounted) showAppSnack(context, 'Error stopping recording: $e');
    }
  }

  /// Stops the recorder and deletes what was captured.
  Future<void> _discardRecording() async {
    if (!_isRecording) return;
    final path = _recordedFilePath;
    try {
      await _recorder.stopRecorder();
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      debugPrint('Error discarding recording: $e');
    }
    _resetClock();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordedFilePath = null;
      });
      showAppSnack(context, 'Recording discarded');
    }
  }

  // ------------------------------------------------------------- playback

  Future<void> _togglePlayback(String path) async {
    try {
      if (_playingPath == path) {
        await _stopPlayback();
        return;
      }
      if (_isRecording) {
        showAppSnack(context, 'Stop recording before playing');
        return;
      }
      if (!_playerOpen) {
        await _player.openPlayer();
        _playerOpen = true;
      }
      if (_player.isPlaying) await _player.stopPlayer();
      final session = await AudioSession.instance;
      await session.setActive(true);
      setState(() => _playingPath = path);
      await _player.startPlayer(
        fromURI: path,
        codec: Codec.aacADTS,
        whenFinished: () {
          if (mounted) setState(() => _playingPath = null);
        },
      );
    } catch (e) {
      debugPrint('Error playing recording: $e');
      if (mounted) {
        setState(() => _playingPath = null);
        showAppSnack(context, 'Error playing recording: $e');
      }
    }
  }

  Future<void> _stopPlayback() async {
    try {
      if (_playerOpen) await _player.stopPlayer();
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    }
    if (mounted) setState(() => _playingPath = null);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _levelSub?.cancel();
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  // ------------------------------------------------------------------ UI

  String _clockText() {
    final ms = _clock.elapsedMilliseconds;
    String two(int n) => n.toString().padLeft(2, '0');
    final m = two((ms ~/ 60000) % 60);
    final s = two((ms ~/ 1000) % 60);
    return '$m:$s';
  }

  String _centis() =>
      '.${(_clock.elapsedMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0')}';

  String _when(DateTime d) {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final time = '${two(d.hour)}:${two(d.minute)}';
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today · $time';
    if (diff == 1) return 'Yesterday · $time';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final status = !_isRecording
        ? 'Ready'
        : (_isPaused ? 'Paused' : 'Recording');
    final dotColor = !_isRecording
        ? const Color(0xFFBDBDBD)
        : (_isPaused ? theme.ground : const Color(0xFFFF5A3C));

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recorder', style: displayStyle(46)),
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: kInk,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status,
                        style: bodyStyle(
                          12,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _clockText(),
                      style: displayStyle(76).copyWith(letterSpacing: 1),
                    ),
                    Text(_centis(), style: displayStyle(40, color: kOnGround)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 96,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: WaveBars(
                    bars: _levels,
                    height: 80,
                    activeColor: kInk,
                    inactiveColor: kInk.withValues(alpha: 0.18),
                    gap: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SideButton(
                      icon: Icons.stop_rounded,
                      tooltip: 'Stop and discard',
                      onTap: _isRecording ? _discardRecording : null,
                    ),
                    const SizedBox(width: 28),
                    Semantics(
                      button: true,
                      label: !_isRecording
                          ? 'Start recording'
                          : (_isPaused
                                ? 'Resume recording'
                                : 'Pause recording'),
                      child: GestureDetector(
                        onTap: !_isRecording
                            ? _startRecording
                            : (_isPaused ? _resumeRecording : _pauseRecording),
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: kInk,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 6,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x40141414),
                                blurRadius: 28,
                                offset: Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRecording && !_isPaused
                                ? Icons.pause_rounded
                                : Icons.mic_rounded,
                            size: 34,
                            color: theme.ground,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                    _SideButton(
                      icon: Icons.check_rounded,
                      tooltip: 'Save recording',
                      onTap: _saveRecording,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.folder_outlined,
                      size: 14,
                      color: kOnGround,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Saves to $_folderLabel',
                        overflow: TextOverflow.ellipsis,
                        style: bodyStyle(
                          12,
                          weight: FontWeight.w500,
                          color: kOnGround,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: AppSheet(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 6, bottom: 8),
                    child: SheetLabel('Recent recordings'),
                  ),
                  Expanded(
                    child: _recordings.isEmpty
                        ? Center(
                            child: Text(
                              'No recordings yet.',
                              style: bodyStyle(
                                14,
                                weight: FontWeight.w500,
                                color: kMuted,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 12),
                            itemCount: _recordings.length,
                            itemBuilder: (context, i) {
                              final r = _recordings[i];
                              final playing = _playingPath == r.file.path;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                  horizontal: 2,
                                ),
                                child: Row(
                                  children: [
                                    SquareIconButton(
                                      icon: playing
                                          ? Icons.stop_rounded
                                          : Icons.play_arrow_rounded,
                                      tooltip: playing
                                          ? 'Stop ${r.name}'
                                          : 'Play ${r.name}',
                                      background: theme.soft,
                                      onPressed: () =>
                                          _togglePlayback(r.file.path),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: bodyStyle(
                                              14,
                                              weight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _when(r.modified),
                                            style: bodyStyle(12, color: kMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      formatDuration(r.length),
                                      style: bodyStyle(
                                        12,
                                        weight: FontWeight.w700,
                                        color: kMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _SideButton({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: onTap == null ? 0.6 : 1),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              icon,
              size: 24,
              color: onTap == null ? kInk.withValues(alpha: 0.4) : kInk,
            ),
          ),
        ),
      ),
    );
  }
}
