import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../widgets/common.dart';
import 'playlist_screen.dart';
import 'sound_effects.dart';
import 'theme_provide.dart';

void openNowPlaying(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const NowPlayingScreen()));
}

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  static const _speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PlayerService>();
    final theme = context.watch<ThemeProvider>();
    final path = service.currentPath;
    final accent = theme.accent;
    final dur = service.duration;
    final known = dur > Duration.zero;

    return Scaffold(
      backgroundColor: theme.ground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(
              height: 28,
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: AppSheet(
                radius: 34,
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      14,
                      22,
                      16 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: box.maxHeight - 30,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const AppBackButton(onSheet: true),
                              Text(
                                'NOW PLAYING',
                                style: bodyStyle(
                                  13,
                                  weight: FontWeight.w700,
                                  color: kMuted,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              SquareIconButton(
                                icon: Icons.queue_music_rounded,
                                tooltip: 'Queue',
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const PlaylistScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _ProgressRing(
                            service: service,
                            accent: accent,
                            hasTrack: path != null,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      path != null
                                          ? trackTitle(path)
                                          : 'No song selected',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: bodyStyle(
                                        22,
                                        weight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      path != null
                                          ? 'Local file · ${trackExtension(path)}'
                                          : 'Pick audio files on Home',
                                      style: bodyStyle(14, color: kMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SquareIconButton(
                                icon: service.isFavorite(path)
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                tooltip: service.isFavorite(path)
                                    ? 'Remove from favorites'
                                    : 'Add to favorites',
                                background: theme.soft,
                                onPressed: path == null
                                    ? null
                                    : () {
                                        final added = service.toggleFavorite(
                                          path,
                                        );
                                        showAppSnack(
                                          context,
                                          added
                                              ? 'Added to favorites'
                                              : 'Removed from favorites',
                                        );
                                      },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ValueListenableBuilder<Duration>(
                            valueListenable: service.position,
                            builder: (context, pos, _) => WaveBars(
                              bars: service.barsFor(path, 48),
                              height: 40,
                              progress: known
                                  ? (pos.inMilliseconds / dur.inMilliseconds)
                                        .clamp(0.0, 1.0)
                                  : 0,
                              activeColor: accent,
                              gap: 3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _Controls(service: service, accent: accent),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 44,
                                  padding: const EdgeInsets.only(
                                    left: 12,
                                    right: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kSurface,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.volume_up_rounded,
                                        size: 20,
                                      ),
                                      Expanded(
                                        child: Slider(
                                          value: service.volume,
                                          semanticFormatterCallback: (v) =>
                                              'Volume ${(v * 100).round()} percent',
                                          onChanged: service.setVolume,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Tooltip(
                                message: 'Playback speed',
                                child: Material(
                                  color: kSurface,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      final i = _speeds.indexWhere(
                                        (s) => (s - service.speed).abs() < 0.01,
                                      );
                                      service.setSpeed(
                                        _speeds[(i + 1) % _speeds.length],
                                      );
                                    },
                                    child: Container(
                                      height: 44,
                                      constraints: const BoxConstraints(
                                        minWidth: 56,
                                      ),
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        '${service.speed.toStringAsFixed(service.speed * 100 % 10 == 0 ? 1 : 2)}x',
                                        style: bodyStyle(
                                          13,
                                          weight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Material(
                                color: kInk,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    if (path == null) {
                                      showAppSnack(
                                        context,
                                        'Please select a song first!',
                                      );
                                      return;
                                    }
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const SoundEffectsScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.graphic_eq_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Effects',
                                          style: bodyStyle(
                                            13,
                                            weight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final PlayerService service;
  final Color accent;
  const _Controls({required this.service, required this.accent});

  @override
  Widget build(BuildContext context) {
    final soft = context.read<ThemeProvider>().soft;
    final repeatOn = service.repeat != RepeatMode.off;

    Widget flat(
      IconData icon,
      String tip,
      VoidCallback? onTap, {
      bool active = false,
      double size = 24,
    }) {
      return Tooltip(
        message: tip,
        child: Material(
          color: active ? soft : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, size: size, color: kInk),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        flat(
          service.repeat == RepeatMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          'Repeat ${service.repeat.name}',
          service.cycleRepeat,
          active: repeatOn,
        ),
        flat(
          Icons.skip_previous_rounded,
          'Previous',
          service.previous,
          size: 32,
        ),
        Tooltip(
          message: service.isPlaying ? 'Pause' : 'Play',
          child: Material(
            color: accent,
            elevation: 6,
            shadowColor: accent.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: service.togglePlay,
              child: SizedBox(
                width: 72,
                height: 72,
                child: Icon(
                  service.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 36,
                  color: kInk,
                ),
              ),
            ),
          ),
        ),
        flat(Icons.skip_next_rounded, 'Next', service.next, size: 32),
        flat(
          Icons.shuffle_rounded,
          service.shuffle ? 'Shuffle on' : 'Shuffle off',
          () => service.setShuffle(!service.shuffle),
          active: service.shuffle,
        ),
      ],
    );
  }
}

/// Half-circle gauge around the artwork. Drag along the bottom arc to seek.
class _ProgressRing extends StatelessWidget {
  final PlayerService service;
  final Color accent;
  final bool hasTrack;

  const _ProgressRing({
    required this.service,
    required this.accent,
    required this.hasTrack,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final size = min(300.0, width - 90);
    final dur = service.duration;
    final known = dur > Duration.zero;

    void seekTo(Offset local) {
      if (!known) return;
      final c = Offset(size / 2, size / 2);
      final d = local - c;
      double p;
      if (d.dy >= 0) {
        p = ((pi - atan2(d.dy, d.dx)) / pi).clamp(0.0, 1.0);
      } else {
        p = d.dx < 0 ? 0.0 : 1.0;
      }
      service.seek(Duration(milliseconds: (dur.inMilliseconds * p).round()));
    }

    return Semantics(
      label: 'Playback position',
      child: GestureDetector(
        onTapDown: (e) => seekTo(e.localPosition),
        onPanUpdate: (e) => seekTo(e.localPosition),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ValueListenableBuilder<Duration>(
                  valueListenable: service.position,
                  builder: (context, pos, _) {
                    final p = known
                        ? (pos.inMilliseconds / dur.inMilliseconds).clamp(
                            0.0,
                            1.0,
                          )
                        : 0.0;
                    return CustomPaint(painter: _RingPainter(p, accent));
                  },
                ),
              ),
              Positioned(
                left: size * 0.1833,
                top: size * 0.1067,
                width: size * 0.6333,
                height: size * 0.7667,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(size * 0.3167),
                    topRight: Radius.circular(size * 0.3167),
                    bottomLeft: const Radius.circular(30),
                    bottomRight: const Radius.circular(30),
                  ),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x38785000),
                          blurRadius: 34,
                          offset: Offset(0, 20),
                        ),
                      ],
                    ),
                    child: AlbumArt(
                      width: size * 0.6333,
                      height: size * 0.7667,
                      radius: 0,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -6,
                top: size / 2 - 12,
                child: ValueListenableBuilder<Duration>(
                  valueListenable: service.position,
                  builder: (_, pos, __) =>
                      _TimeLabel(formatDuration(pos), color: kInk),
                ),
              ),
              Positioned(
                right: -8,
                top: size / 2 - 12,
                child: _TimeLabel(formatDuration(dur), color: kMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _TimeLabel(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: bodyStyle(12, weight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color accent;
  _RingPainter(this.progress, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 10;
    final rect = Rect.fromCircle(center: c, radius: r);
    final track = Paint()
      ..color = const Color(0xFFEFEFEF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    canvas.drawCircle(c, r, track);

    final arc = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, -pi * progress, false, arc);

    final theta = pi - pi * progress;
    final knob = c + Offset(cos(theta), sin(theta)) * r;
    canvas.drawCircle(knob, 10, Paint()..color = Colors.white);
    canvas.drawCircle(knob, 7, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.accent != accent;
}
