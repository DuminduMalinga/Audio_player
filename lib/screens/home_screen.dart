import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'now_playing_screen.dart';
import 'playlist_screen.dart';
import 'profile.dart';
import 'theme_provide.dart';

/// Library: pick files, jump to playlist / favourites, see recent songs.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PlayerService>();
    final theme = context.watch<ThemeProvider>();
    final recent = service.recentTracks;
    final current =
        service.currentPath ??
        (service.recent.isNotEmpty ? service.recent.first : null);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Music', style: displayStyle(46)),
                Row(
                  children: [
                    ProfileAvatar(
                      foreground: theme.ground,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Settings',
                      iconSize: 28,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: const Icon(Icons.sort_rounded, color: kInk),
                      onPressed: () => context.read<ShellController>().go(3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: _PickButton(onTap: () => pickAudioWithUi(context)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 18, left: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _LibraryTabs(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        SizedBox(
                          height: 224,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(4, 4, 24, 12),
                            children: [
                              _NowCard(path: current),
                              const SizedBox(width: 16),
                              _PlaylistCard(count: service.playlist.length),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (recent.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 24, top: 8),
                            child: Text(
                              'Pick audio files to fill your library.',
                              style: bodyStyle(14, color: kOnGround),
                            ),
                          )
                        else
                          for (final path in recent)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 24,
                                bottom: 4,
                              ),
                              child: _TrackRow(
                                path: path,
                                dark: recent.indexOf(path).isEven,
                                accent: theme.accent,
                              ),
                            ),
                      ],
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

class _PickButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PickButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kInk, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.create_new_folder_outlined,
                size: 20,
                color: kInk,
              ),
              const SizedBox(width: 8),
              Text(
                'Pick audio files',
                style: bodyStyle(14, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vertical "My playlist / Like / Recent" labels down the left edge.
class _LibraryTabs extends StatelessWidget {
  const _LibraryTabs();

  @override
  Widget build(BuildContext context) {
    Widget tab(
      String label,
      VoidCallback? onTap, {
      bool active = false,
      IconData? icon,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: RotatedBox(
          quarterTurns: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: bodyStyle(
                    14,
                    weight: active ? FontWeight.w800 : FontWeight.w700,
                    color: active ? kInk : kOnGround,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 18, color: kInk),
                ],
                if (active) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: kInk,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 44,
      child: Column(
        children: [
          tab(
            'My playlist',
            () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PlaylistScreen())),
            icon: Icons.play_circle_outline_rounded,
          ),
          const SizedBox(height: 28),
          tab('Like', () => context.read<ShellController>().go(2)),
          const SizedBox(height: 28),
          tab('Recent', null, active: true),
        ],
      ),
    );
  }
}

class _NowCard extends StatelessWidget {
  final String? path;
  const _NowCard({required this.path});

  @override
  Widget build(BuildContext context) {
    final has = path != null;
    return Semantics(
      button: true,
      label: has ? 'Open ${trackTitle(path!)}' : 'Pick audio files',
      child: Material(
        color: Colors.white,
        elevation: 8,
        shadowColor: const Color(0x38785000),
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () => has ? openNowPlaying(context) : pickAudioWithUi(context),
          child: SizedBox(
            width: 168,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: Column(
                children: [
                  const Expanded(
                    child: AlbumArt(width: 140, height: 140, radius: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    has ? trackTitle(path!) : 'No song yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyStyle(14, weight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final int count;
  const _PlaylistCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kInk,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PlaylistScreen())),
        child: SizedBox(
          width: 168,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My playlist',
                  style: bodyStyle(
                    14,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count == 1 ? '1 song' : '$count songs',
                  style: bodyStyle(12, color: const Color(0xFFD6D6D6)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  final String path;
  final bool dark;
  final Color accent;

  const _TrackRow({
    required this.path,
    required this.dark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final service = context.read<PlayerService>();
    final len = service.durationOf(path);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        if (service.currentPath != path) await service.playPath(path);
        if (context.mounted) openNowPlaying(context);
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 62),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: dark ? kInk : accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.music_note_rounded,
                size: 22,
                color: dark ? Colors.white : kInk,
              ),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 3),
                  Text(
                    trackSource(path),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyStyle(12, color: kOnGround),
                  ),
                ],
              ),
            ),
            if (len != null)
              Text(formatDuration(len), style: bodyStyle(12, color: kOnGround)),
          ],
        ),
      ),
    );
  }
}
