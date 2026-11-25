import 'dart:async';
import 'dart:math';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

enum TrackRepeatMode { off, all, one }

enum PickResult { added, cancelled, denied, permanentlyDenied }

/// File name without folder or extension.
String trackTitle(String path) {
  final name = path.split(RegExp(r'[\\/]')).last;
  final dot = name.lastIndexOf('.');
  return dot > 0 ? name.substring(0, dot) : name;
}

/// Containing folder name, e.g. "Downloads".
String trackSource(String path) {
  final parts = path.split(RegExp(r'[\\/]'));
  if (parts.length < 2) return 'Local file';
  final folder = parts[parts.length - 2];
  // The file picker copies files into a numbered cache folder.
  return RegExp(r'^\d+$').hasMatch(folder) ? 'Local file' : folder;
}

/// Upper-case extension, e.g. "MP3".
String trackExtension(String path) {
  final name = path.split(RegExp(r'[\\/]')).last;
  final dot = name.lastIndexOf('.');
  return dot > 0 ? name.substring(dot + 1).toUpperCase() : 'AUDIO';
}

String formatDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final m = two(d.inMinutes.remainder(60));
  final s = two(d.inSeconds.remainder(60));
  return d.inHours > 0 ? '${two(d.inHours)}:$m:$s' : '$m:$s';
}

/// One shared player used by every screen: library, now playing,
/// playlist, favourites and effects.
class PlayerService extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();
  final PlayerController _waveExtractor = PlayerController();
  final Random _random = Random();

  final List<String> playlist = [];
  final List<String> favorites = [];
  final List<String> recent = [];
  final Map<String, Duration> durations = {};

  /// Position changes many times a second, so it has its own notifier.
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);

  String? currentPath;
  bool favoritesOnly = false;
  bool isPlaying = false;
  Duration duration = Duration.zero;

  bool shuffle = false;
  TrackRepeatMode repeat = TrackRepeatMode.off;
  double speed = 1.0;
  double pitch = 1.0;
  double volume = 0.7;

  // Settings that are stored for the UI only (not wired to the engine yet).
  String eqPreset = 'Pop';
  bool crossfadeOn = false;
  int crossfadeSeconds = 4;

  List<double> _waveform = [];
  bool _handlingCompletion = false;

  PlayerService() {
    player.setVolume(volume);
    player.positionStream.listen((p) => position.value = p);
    player.durationStream.listen((d) {
      duration = d ?? Duration.zero;
      final path = currentPath;
      if (path != null && d != null) durations[path] = d;
      notifyListeners();
    });
    player.playingStream.listen((playing) {
      isPlaying = playing;
      notifyListeners();
    });
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _onCompleted();
    });
  }

  // ---------------------------------------------------------------- queue

  /// The list that next / previous move through.
  List<String> get queue =>
      favoritesOnly && favorites.isNotEmpty ? favorites : playlist;

  /// Recently played tracks first, then the rest of the playlist.
  List<String> get recentTracks {
    final list = <String>[...recent];
    for (final p in playlist.reversed) {
      if (!list.contains(p)) list.add(p);
    }
    return list.take(12).toList();
  }

  bool isFavorite(String? path) => path != null && favorites.contains(path);

  Duration? durationOf(String path) => durations[path];

  // ------------------------------------------------------------- playback

  /// Starts [path]; adds it to the playlist when it is new.
  /// Returns false when the file could not be opened.
  Future<bool> playPath(String path, {bool fromFavorites = false}) async {
    if (!playlist.contains(path)) playlist.add(path);
    favoritesOnly = fromFavorites;
    currentPath = path;
    recent
      ..remove(path)
      ..insert(0, path);
    if (recent.length > 20) recent.removeLast();
    _waveform = [];
    duration = durations[path] ?? Duration.zero;
    position.value = Duration.zero;
    notifyListeners();

    try {
      await player.setFilePath(path);
      unawaited(player.play());
      unawaited(_loadWaveform(path));
      return true;
    } catch (e) {
      debugPrint('Error opening $path: $e');
      return false;
    }
  }

  Future<void> togglePlay() async {
    if (currentPath == null) return;
    if (player.playing) {
      await player.pause();
    } else {
      unawaited(player.play());
    }
  }

  Future<void> pause() => player.pause();

  Future<void> seek(Duration to) => player.seek(to);

  Future<void> next() => _step(1);

  Future<void> previous() async {
    if (position.value > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
    } else {
      await _step(-1);
    }
  }

  Future<void> _step(int dir) async {
    final q = queue;
    if (q.isEmpty) return;
    String target;
    if (shuffle && q.length > 1) {
      do {
        target = q[_random.nextInt(q.length)];
      } while (target == currentPath);
    } else {
      var i = currentPath == null ? -1 : q.indexOf(currentPath!);
      i = i == -1 ? 0 : (i + dir + q.length) % q.length;
      target = q[i];
    }
    await playPath(target, fromFavorites: favoritesOnly);
  }

  Future<void> _onCompleted() async {
    if (_handlingCompletion) return;
    _handlingCompletion = true;
    try {
      final q = queue;
      final i = currentPath == null ? -1 : q.indexOf(currentPath!);
      final hasNext = shuffle ? q.length > 1 : (i != -1 && i < q.length - 1);
      if (hasNext || (repeat == TrackRepeatMode.all && q.isNotEmpty)) {
        await _step(1);
      } else {
        await player.pause();
        await player.seek(Duration.zero);
      }
    } finally {
      _handlingCompletion = false;
    }
  }

  Future<bool> playAll() async {
    if (playlist.isEmpty) return false;
    final first = shuffle
        ? playlist[_random.nextInt(playlist.length)]
        : playlist.first;
    return playPath(first);
  }

  Future<bool> shufflePlay() async {
    if (playlist.isEmpty) return false;
    shuffle = true;
    return playPath(playlist[_random.nextInt(playlist.length)]);
  }

  Future<bool> playFavorites() async {
    if (favorites.isEmpty) return false;
    final first = shuffle
        ? favorites[_random.nextInt(favorites.length)]
        : favorites.first;
    return playPath(first, fromFavorites: true);
  }

  // -------------------------------------------------------------- library

  Future<PickResult> pickFiles() async {
    PermissionStatus status;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final info = await DeviceInfoPlugin().androidInfo;
      status = info.version.sdkInt >= 33
          ? await Permission.audio.request()
          : await Permission.storage.request();
    } else {
      status = await Permission.storage.request();
    }

    if (!status.isGranted) {
      return status.isPermanentlyDenied
          ? PickResult.permanentlyDenied
          : PickResult.denied;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return PickResult.cancelled;

    String? first;
    for (final file in result.files) {
      final path = file.path;
      if (path == null) continue;
      first ??= path;
      if (!playlist.contains(path)) playlist.add(path);
    }
    notifyListeners();
    if (first != null) await playPath(first);
    return PickResult.added;
  }

  Future<void> removeFromPlaylist(String path) async {
    playlist.remove(path);
    recent.remove(path);
    if (currentPath == path) {
      currentPath = null;
      await player.stop();
    }
    notifyListeners();
  }

  /// Returns true when the song was added, false when it was removed.
  bool toggleFavorite(String path) {
    final added = !favorites.contains(path);
    if (added) {
      favorites.add(path);
    } else {
      favorites.remove(path);
    }
    notifyListeners();
    return added;
  }

  // ------------------------------------------------------------- settings

  void setShuffle(bool value) {
    shuffle = value;
    notifyListeners();
  }

  Future<void> setRepeat(TrackRepeatMode mode) async {
    repeat = mode;
    await player.setLoopMode(
      mode == TrackRepeatMode.one ? LoopMode.one : LoopMode.off,
    );
    notifyListeners();
  }

  Future<void> cycleRepeat() => setRepeat(
    TrackRepeatMode.values[(repeat.index + 1) % TrackRepeatMode.values.length],
  );

  Future<void> setSpeed(double value) async {
    speed = value;
    notifyListeners();
    try {
      await player.setSpeed(value);
    } catch (e) {
      debugPrint('setSpeed failed: $e');
    }
  }

  Future<void> setPitch(double value) async {
    pitch = value;
    notifyListeners();
    try {
      await player.setPitch(value);
    } catch (_) {
      // Pitch is not supported on every platform.
    }
  }

  /// Applies a pitch + speed effect. With [startPlaying] the track is
  /// started so the effect can be heard straight away.
  Future<void> applyEffect(
    double newPitch,
    double newSpeed, {
    bool startPlaying = false,
  }) async {
    await setPitch(newPitch);
    await setSpeed(newSpeed);
    if (startPlaying && currentPath != null && !player.playing) {
      unawaited(player.play());
    }
  }

  Future<void> setVolume(double value) async {
    volume = value;
    notifyListeners();
    await player.setVolume(value);
  }

  void setEqPreset(String value) {
    eqPreset = value;
    notifyListeners();
  }

  void setCrossfadeOn(bool value) {
    crossfadeOn = value;
    notifyListeners();
  }

  void setCrossfadeSeconds(int value) {
    crossfadeSeconds = value;
    notifyListeners();
  }

  // ------------------------------------------------------------- waveform

  Future<void> _loadWaveform(String path) async {
    try {
      final data = await _waveExtractor.extractWaveformData(
        path: path,
        noOfSamples: 48,
      );
      if (currentPath != path || data.isEmpty) return;
      final peak = data.fold<double>(0, (m, v) => max(m, v.abs()));
      if (peak <= 0) return;
      _waveform = data.map((v) => (v.abs() / peak).clamp(0.0, 1.0)).toList();
      notifyListeners();
    } catch (_) {
      // Fall back to the generated bars below.
    }
  }

  /// [count] bar heights between 0 and 1: the real waveform when it could
  /// be extracted, otherwise a stable pattern derived from the file name.
  List<double> barsFor(String? path, int count) {
    if (_waveform.length >= count) {
      final step = _waveform.length / count;
      return List.generate(
        count,
        (i) => _waveform[(i * step).floor()].clamp(0.18, 1.0),
      );
    }
    var seed = (path ?? 'none').hashCode & 0x7fffffff;
    return List.generate(count, (_) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return 0.2 + (seed % 1000) / 1000 * 0.8;
    });
  }

  @override
  void dispose() {
    position.dispose();
    _waveExtractor.dispose();
    player.dispose();
    super.dispose();
  }
}
