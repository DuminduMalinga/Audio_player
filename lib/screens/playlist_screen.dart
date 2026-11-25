import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../widgets/common.dart';
import 'now_playing_screen.dart';
import 'theme_provide.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PlayerService>();
    final theme = context.watch<ThemeProvider>();
    final tracks = service.playlist;

    return Scaffold(
      backgroundColor: theme.ground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppBackButton(),
                      OutlinedButton.icon(
                        onPressed: () => pickAudioWithUi(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add files'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kInk,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          side: const BorderSide(color: kInk, width: 2),
                          textStyle: bodyStyle(13, weight: FontWeight.w700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('My playlist', style: displayStyle(46)),
                  const SizedBox(height: 6),
                  Text(
                    tracks.length == 1 ? '1 song' : '${tracks.length} songs',
                    style: bodyStyle(
                      14,
                      weight: FontWeight.w500,
                      color: kOnGround,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _BigAction(
                          label: 'Play all',
                          icon: Icons.play_arrow_rounded,
                          dark: true,
                          onTap: () => _start(context, service.playAll),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BigAction(
                          label: 'Shuffle',
                          icon: Icons.shuffle_rounded,
                          dark: false,
                          onTap: () => _start(context, service.shufflePlay),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: AppSheet(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
                child: tracks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Your playlist is empty.\nTap “Add files” to pick songs.',
                            textAlign: TextAlign.center,
                            style: bodyStyle(
                              14,
                              weight: FontWeight.w500,
                              color: kMuted,
                              height: 1.5,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(
                          bottom: 16 + MediaQuery.of(context).padding.bottom,
                        ),
                        itemCount: tracks.length,
                        itemBuilder: (context, i) => _PlaylistRow(
                          index: i,
                          path: tracks[i],
                          service: service,
                          theme: theme,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start(
    BuildContext context,
    Future<bool> Function() play,
  ) async {
    final navigator = Navigator.of(context);
    final ok = await play();
    if (!context.mounted) return;
    if (!ok) {
      showAppSnack(context, 'Add some songs first');
      return;
    }
    navigator.push(MaterialPageRoute(builder: (_) => const NowPlayingScreen()));
  }
}

class _BigAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool dark;
  final VoidCallback onTap;

  const _BigAction({
    required this.label,
    required this.icon,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : kInk;
    return Material(
      color: dark ? kInk : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: bodyStyle(15, weight: FontWeight.w700, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  final int index;
  final String path;
  final PlayerService service;
  final ThemeProvider theme;

  const _PlaylistRow({
    required this.index,
    required this.path,
    required this.service,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final current = service.currentPath == path;
    final dark = index.isOdd;
    final len = service.durationOf(path);
    final tileBg = current
        ? theme.accent
        : (dark ? kInk : const Color(0xFFF2F2F2));
    final tileFg = (!current && dark) ? Colors.white : kInk;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: current ? theme.soft.withValues(alpha: 0.6) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final navigator = Navigator.of(context);
          if (!current) await service.playPath(path);
          navigator.push(
            MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '${index + 1}',
                  textAlign: TextAlign.center,
                  style: bodyStyle(13, weight: FontWeight.w700, color: kMuted),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  current && service.isPlaying
                      ? Icons.equalizer_rounded
                      : Icons.music_note_rounded,
                  size: 20,
                  color: tileFg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trackTitle(path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle(15, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trackSource(path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle(12, color: kMuted),
                    ),
                  ],
                ),
              ),
              if (len != null)
                Text(formatDuration(len), style: bodyStyle(12, color: kMuted)),
              IconButton(
                tooltip: 'More options for ${trackTitle(path)}',
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: kInk,
                ),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => _showMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final fav = service.isFavorite(path);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    trackTitle(path),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyStyle(16, weight: FontWeight.w800),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: kInk,
                ),
                title: Text(
                  fav ? 'Remove from favorites' : 'Add to favorites',
                  style: bodyStyle(15, weight: FontWeight.w700),
                ),
                onTap: () {
                  service.toggleFavorite(path);
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.remove_circle_outline_rounded,
                  color: kInk,
                ),
                title: Text(
                  'Remove from playlist',
                  style: bodyStyle(15, weight: FontWeight.w700),
                ),
                onTap: () {
                  service.removeFromPlaylist(path);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
