import 'package:flutter/material.dart';

import '../models/spotify_track.dart';
import '../services/spotify_service.dart';
import '../theme/app_theme.dart';

class SearchSongScreen extends StatefulWidget {
  const SearchSongScreen({super.key});

  @override
  State<SearchSongScreen> createState() => _SearchSongScreenState();
}

// Genre tag data for recent searches
const _recentGenres = [
  _GenreTag(label: 'Trance', color: Color(0xFF9C59B5)),
  _GenreTag(label: 'Get Lucky', color: Color(0xFFFF1493)),
  _GenreTag(label: 'Levels', color: Color(0xFF00FF88)),
  _GenreTag(label: 'House', color: Color(0xFF52E3E1)),
  _GenreTag(label: 'Techno', color: Color(0xFFFF8C00)),
];

class _SearchSongScreenState extends State<SearchSongScreen> {
  final _controller = TextEditingController();

  List<SpotifyTrack> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmitted(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _loading = false;
      });
      return;
    }
    _search(query);
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await SpotifyService.instance.searchTracks(query);
      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _formatDuration(int? ms) {
    if (ms == null) return '';
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.panel,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back,
                color: AppTheme.white, size: 20),
          ),
        ),
        title: const Text(
          'Search Song',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onSubmitted: _onSubmitted,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: AppTheme.white),
              decoration: InputDecoration(
                hintText: 'Search for a song...',
                hintStyle:
                    const TextStyle(color: AppTheme.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppTheme.pink),
                filled: true,
                fillColor: AppTheme.panel,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusInput),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusInput),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusInput),
                  borderSide:
                      const BorderSide(color: AppTheme.pink, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.pink),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppTheme.red, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.red),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _search(_controller.text),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return _RecentSearchesView(
        onGenreTap: (label) {
          _controller.text = label;
          _search(label);
        },
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final track = _results[index];
        return _TrackTile(
          track: track,
          duration: _formatDuration(track.durationMs),
          onTap: () => Navigator.pop(context, track),
        );
      },
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.track,
    required this.duration,
    required this.onTap,
  });

  final SpotifyTrack track;
  final String duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.panel,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: Row(
          children: [
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: track.albumArtUrl != null
                  ? Image.network(
                      track.albumArtUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const _AlbumPlaceholder(),
                    )
                  : const _AlbumPlaceholder(),
            ),
            const SizedBox(width: 12),
            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    style: const TextStyle(
                        color: AppTheme.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Duration
            if (duration.isNotEmpty)
              Text(
                duration,
                style: const TextStyle(
                    color: AppTheme.grey, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlbumPlaceholder extends StatelessWidget {
  const _AlbumPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.panelRaised,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note, color: AppTheme.grey, size: 24),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent searches view
// ---------------------------------------------------------------------------

class _RecentSearchesView extends StatelessWidget {
  const _RecentSearchesView({required this.onGenreTap});
  final ValueChanged<String> onGenreTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Searches',
            style: TextStyle(
              color: AppTheme.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _recentGenres.map((genre) {
              return GestureDetector(
                onTap: () => onGenreTap(genre.label),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: genre.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: genre.color.withValues(alpha: 0.50),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    genre.label,
                    style: TextStyle(
                      color: genre.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'Search for a song to request',
              style: TextStyle(color: AppTheme.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreTag {
  const _GenreTag({required this.label, required this.color});
  final String label;
  final Color color;
}
