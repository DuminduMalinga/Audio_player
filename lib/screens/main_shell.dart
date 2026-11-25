import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../widgets/common.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'now_playing_screen.dart';
import 'recording_screen.dart';
import 'settings_screen.dart';
import 'theme_provide.dart';

/// Lets any screen switch the bottom-navigation tab.
class ShellController extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void go(int index) {
    if (index == _index) return;
    _index = index;
    notifyListeners();
  }
}

/// Home / Record / Favorites / Settings behind one bottom navigation bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Tabs are built the first time they are opened, so the recorder only
  // asks for the microphone when the user actually goes there.
  final Set<int> _visited = {0};

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    final theme = context.watch<ThemeProvider>();
    final index = shell.index;
    _visited.add(index);

    const builders = <Widget Function()>[
      HomeScreen.new,
      SoundRecorderScreen.new,
      FavoritesScreen.new,
      SettingsScreen.new,
    ];

    return Scaffold(
      backgroundColor: theme.ground,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: index,
              children: [
                for (var i = 0; i < builders.length; i++)
                  _visited.contains(i)
                      ? builders[i]()
                      : const SizedBox.shrink(),
              ],
            ),
          ),
          _BottomBar(index: index, onSelected: shell.go),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelected;

  const _BottomBar({required this.index, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final onHome = index == 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: onHome
            ? const BorderRadius.vertical(top: Radius.circular(30))
            : null,
        border: onHome ? null : const Border(top: BorderSide(color: kHairline)),
        boxShadow: onHome
            ? const [
                BoxShadow(
                  color: Color(0x1F785000),
                  blurRadius: 24,
                  offset: Offset(0, -8),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onHome) const MiniPlayer(),
            AppBottomNav(index: index, onSelected: onSelected),
          ],
        ),
      ),
    );
  }
}

/// Compact player shown above the navigation bar on Home.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PlayerService>();
    final accent = context.watch<ThemeProvider>().accent;
    final path = service.currentPath;
    if (path == null) return const SizedBox.shrink();

    final dur = service.duration;
    final known = dur > Duration.zero;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => openNowPlaying(context),
                  child: Row(
                    children: [
                      const DiscArt(size: 46),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trackTitle(path),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: bodyStyle(14, weight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              known
                                  ? 'Local file · ${formatDuration(dur)}'
                                  : 'Local file',
                              style: bodyStyle(12, color: kMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SquareIconButton(
                icon: service.isFavorite(path)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                tooltip: service.isFavorite(path)
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                background: Colors.transparent,
                onPressed: () {
                  final added = service.toggleFavorite(path);
                  showAppSnack(
                    context,
                    added ? 'Added to favorites' : 'Removed from favorites',
                  );
                },
              ),
              const SizedBox(width: 4),
              SquareIconButton(
                icon: service.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                tooltip: service.isPlaying ? 'Pause' : 'Play',
                background: accent,
                onPressed: service.togglePlay,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<Duration>(
            valueListenable: service.position,
            builder: (context, pos, _) {
              final p = known
                  ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                  : 0.0;
              return ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: p,
                  minHeight: 3,
                  backgroundColor: const Color(0xFFEFEFEF),
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
