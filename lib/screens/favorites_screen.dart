import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../widgets/common.dart';
import 'now_playing_screen.dart';
import 'theme_provide.dart';

/// Hearted songs. Lives in the bottom navigation.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PlayerService>();
    final theme = context.watch<ThemeProvider>();
    final favs = service.favorites;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Favorites', style: displayStyle(46)),
                    const SizedBox(height: 6),
                    Text(
                      favs.length == 1 ? '1 song' : '${favs.length} songs',
                      style: bodyStyle(
                        14,
                        weight: FontWeight.w500,
                        color: kOnGround,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: kInk,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 24,
                    color: theme.ground,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: _MixCard(
              accent: theme.accent,
              ground: theme.ground,
              onPlay: () async {
                final navigator = Navigator.of(context);
                final ok = await service.playFavorites();
                if (!context.mounted) return;
                if (!ok) {
                  showAppSnack(context, 'Heart a song first');
                  return;
                }
                navigator.push(
                  MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
                );
              },
            ),
          ),
          Expanded(
            child: AppSheet(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 10),
                    child: const SheetLabel('Hearted songs'),
                  ),
                  Expanded(
                    child: favs.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                'Tap the heart on any song to keep it here.',
                                textAlign: TextAlign.center,
                                style: bodyStyle(
                                  14,
                                  weight: FontWeight.w500,
                                  color: kMuted,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 12),
                            itemCount: favs.length,
                            itemBuilder: (context, i) => _FavRow(
                              path: favs[i],
                              index: i,
                              service: service,
                              theme: theme,
                            ),
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

class _MixCard extends StatelessWidget {
  final Color accent;
  final Color ground;
  final VoidCallback onPlay;

  const _MixCard({
    required this.accent,
    required this.ground,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kInk,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: DashedRings(size: 140, color: ground),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR MIX',
                      style: bodyStyle(
                        12,
                        weight: FontWeight.w700,
                        color: ground,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Play favorites',
                      style: displayStyle(30, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Plays only songs you’ve hearted',
                      style: bodyStyle(
                        13,
                        weight: FontWeight.w500,
                        color: const Color(0xFFD6D6D6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: 'Play favorites',
                child: Material(
                  color: accent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onPlay,
                    child: const SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 30,
                        color: kInk,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FavRow extends StatelessWidget {
  final String path;
  final int index;
  final PlayerService service;
  final ThemeProvider theme;

  const _FavRow({
    required this.path,
    required this.index,
    required this.service,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final playing = service.currentPath == path && service.isPlaying;
    final dark = index.isEven;
    final len = service.durationOf(path);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        final navigator = Navigator.of(context);
        if (service.currentPath != path || !service.favoritesOnly) {
          await service.playPath(path, fromFavorites: true);
        }
        navigator.push(
          MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: dark ? kInk : theme.accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                playing ? Icons.equalizer_rounded : Icons.music_note_rounded,
                size: 20,
                color: dark ? Colors.white : kInk,
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
                    playing
                        ? 'Now playing'
                        : (len != null
                              ? formatDuration(len)
                              : trackSource(path)),
                    style: bodyStyle(12, color: kMuted),
                  ),
                ],
              ),
            ),
            SquareIconButton(
              icon: Icons.favorite_rounded,
              tooltip: 'Remove ${trackTitle(path)} from favorites',
              background: theme.soft,
              onPressed: () {
                service.toggleFavorite(path);
                showAppSnack(context, 'Removed from favorites');
              },
            ),
          ],
        ),
      ),
    );
  }
}
