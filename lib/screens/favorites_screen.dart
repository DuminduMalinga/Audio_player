import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:provider/provider.dart';
import 'theme_provide.dart';

class FavoritesScreen extends StatefulWidget {
  final List<String> favoritesList;
  final AudioPlayer audioPlayer;
  final PlayerController waveformController;
  final Function(String) onSongSelected;
  final Function(String) onRemoveFromFavorites;

  const FavoritesScreen({
    super.key,
    required this.favoritesList,
    required this.audioPlayer,
    required this.waveformController,
    required this.onSongSelected,
    required this.onRemoveFromFavorites,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String? _currentPlayingPath;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _setupPlayerListener();
  }

  void _setupPlayerListener() {
    widget.audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
  }

  void updateCurrentPlaying(String? path) {
    setState(() {
      _currentPlayingPath = path;
    });
  }

  String _getFileName(String path) {
    return path.split(RegExp(r'[\\/]')).last;
  }

  Future<void> _playFavorite(String filePath) async {
    try {
      await widget.audioPlayer.setFilePath(filePath);
      await widget.waveformController.preparePlayer(
        path: filePath,
        shouldExtractWaveform: true,
      );
      await widget.audioPlayer.play();
      widget.onSongSelected(filePath);

      setState(() {
        _currentPlayingPath = filePath;
        _isPlaying = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pauseResume() async {
    if (_isPlaying) {
      await widget.audioPlayer.pause();
    } else {
      await widget.audioPlayer.play();
    }
  }

  void _removeFromFavorites(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove from Favorites'),
          content: Text('Remove "${_getFileName(filePath)}" from favorites?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                widget.onRemoveFromFavorites(filePath);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Removed from favorites: ${_getFileName(filePath)}',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
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
              // Header
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
                      "Your Favorites",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Favorites count
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "${widget.favoritesList.length} favorites",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Favorites list
              Expanded(
                child: widget.favoritesList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 80,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No favorites yet",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Tap ♥ on any song to add it here",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: widget.favoritesList.length,
                        itemBuilder: (context, index) {
                          final filePath = widget.favoritesList[index];
                          final fileName = _getFileName(filePath);
                          final isCurrentlyPlaying =
                              _currentPlayingPath == filePath && _isPlaying;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: isCurrentlyPlaying
                                  ? Border.all(
                                      color: Colors.greenAccent,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: isCurrentlyPlaying
                                        ? [Colors.greenAccent, Colors.green]
                                        : [
                                            Colors.purpleAccent,
                                            Colors.deepPurple,
                                          ],
                                  ),
                                ),
                                child: Icon(
                                  isCurrentlyPlaying
                                      ? Icons.music_note
                                      : Icons.audiotrack,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                fileName,
                                style: TextStyle(
                                  color: isCurrentlyPlaying
                                      ? Colors.greenAccent
                                      : Colors.white,
                                  fontWeight: isCurrentlyPlaying
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: isCurrentlyPlaying
                                  ? const Text(
                                      "Now Playing",
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isCurrentlyPlaying)
                                    IconButton(
                                      icon: Icon(
                                        _isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.greenAccent,
                                      ),
                                      onPressed: _pauseResume,
                                    ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _removeFromFavorites(filePath),
                                  ),
                                ],
                              ),
                              onTap: () => _playFavorite(filePath),
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
