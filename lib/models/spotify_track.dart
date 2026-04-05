class SpotifyTrack {
  const SpotifyTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.albumName,
    this.albumArtUrl,
    this.durationMs,
  });

  final String id;
  final String name;
  final String artist;
  final String albumName;
  final String? albumArtUrl;
  final int? durationMs;

  factory SpotifyTrack.fromSpotifyJson(Map<String, dynamic> json) {
    final album = json['album'] as Map<String, dynamic>? ?? {};
    final artists = json['artists'] as List<dynamic>? ?? [];
    final images = album['images'] as List<dynamic>? ?? [];

    final artistName = artists.isNotEmpty
        ? (artists.first as Map<String, dynamic>)['name'] as String? ?? ''
        : '';

    final albumArtUrl = images.isNotEmpty
        ? (images.first as Map<String, dynamic>)['url'] as String?
        : null;

    return SpotifyTrack(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      artist: artistName,
      albumName: album['name'] as String? ?? '',
      albumArtUrl: albumArtUrl,
      durationMs: json['duration_ms'] as int?,
    );
  }
}
