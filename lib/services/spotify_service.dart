import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/spotify_track.dart';
import 'local_config_loader.dart';

class SpotifyService {
  SpotifyService._();

  static final SpotifyService instance = SpotifyService._();

  String? _accessToken;
  DateTime? _tokenExpiry;

  Future<String> _getAccessToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    final config = await loadLocalConfig();
    final clientId = config.spotifyClientId;
    final clientSecret = config.spotifyClientSecret;

    final credentials =
        base64Encode(utf8.encode('$clientId:$clientSecret'));

    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials'},
    );

    if (response.statusCode != 200) {
      debugPrint('[SpotifyService] token error: ${response.statusCode} ${response.body}');
      throw SpotifyException(
        'Failed to obtain access token: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint('[SpotifyService] token acquired, expires in ${data['expires_in']}s');
    _accessToken = data['access_token'] as String;
    final expiresIn = (data['expires_in'] as int?) ?? 3600;
    _tokenExpiry =
        DateTime.now().add(Duration(seconds: expiresIn - 60));

    return _accessToken!;
  }

  Future<List<SpotifyTrack>> searchTracks(
    String query, {
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) return [];

    const maxRetries = 3;
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      final token = await _getAccessToken();

      final uri = Uri.parse(
        'https://api.spotify.com/v1/search?q=${Uri.encodeComponent(query)}&type=track&limit=$limit',
      );
      debugPrint('[SpotifyService] search url: $uri');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint('[SpotifyService] search response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tracks =
            (data['tracks']?['items'] as List<dynamic>?) ?? [];
        return tracks
            .whereType<Map<String, dynamic>>()
            .map(SpotifyTrack.fromSpotifyJson)
            .toList();
      }

      if (response.statusCode == 429) {
        final retryAfter = int.tryParse(
              response.headers['retry-after'] ?? '1',
            ) ??
            1;
        await Future<void>.delayed(Duration(seconds: retryAfter));
        continue;
      }

      if (response.statusCode == 401) {
        // Token may have been invalidated; clear cache and retry
        _accessToken = null;
        _tokenExpiry = null;
        continue;
      }

      debugPrint('[SpotifyService] search error: ${response.statusCode} ${response.body}');
      throw SpotifyException(
        'Search failed: ${response.statusCode} ${response.body}',
      );
    }

    throw const SpotifyException('Max retries exceeded');
  }
}

class SpotifyException implements Exception {
  const SpotifyException(this.message);

  final String message;

  @override
  String toString() => 'SpotifyException: $message';
}
