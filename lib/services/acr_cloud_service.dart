import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Recognition result from ACRCloud HTTP API.
class AcrResult {
  const AcrResult({
    required this.status,
    this.title,
    this.artist,
    this.spotifyTrackId,
    this.confidence = 0,
  });

  /// One of: 'match', 'no_match', 'error'.
  final String status;
  final String? title;
  final String? artist;
  final String? spotifyTrackId;
  final int confidence;

  factory AcrResult.fromJson(Map<String, dynamic> json) {
    return AcrResult(
      status: json['status'] as String? ?? 'no_match',
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      spotifyTrackId: json['spotify_track_id'] as String?,
      confidence: json['confidence'] as int? ?? 0,
    );
  }

  /// 3-tier matching against a requested track.
  bool matchesTrack(
    String requestedTrackId,
    String requestedTitle,
    String requestedArtist,
  ) {
    if (status != 'match') return false;
    // Tier 1: Spotify track ID match (exact)
    if (spotifyTrackId != null && spotifyTrackId!.isNotEmpty) {
      if (spotifyTrackId == requestedTrackId) return true;
    }
    // Tier 2: Normalized title match (fuzzy, ignores version suffixes)
    if (title != null) {
      final normRecognized = _stripVersions(_normalize(title!));
      final normRequested = _stripVersions(_normalize(requestedTitle));
      // Either contains the other → match (handles "Shape of You" vs "Shape of You Instrumental")
      if (normRecognized.isNotEmpty && normRequested.isNotEmpty) {
        if (normRecognized == normRequested ||
            normRecognized.contains(normRequested) ||
            normRequested.contains(normRecognized)) {
          return true;
        }
      }
    }
    return false;
  }

  static String _stripVersions(String s) {
    // Remove common suffixes that ACRCloud may add
    return s
        .replaceAll(RegExp(r'\b(instrumental|remix|cover|acoustic|karaoke|live|remastered|radio edit|extended|version)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _normalize(String s) {
    return s.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
  }
}

/// ACRCloud recognition service using the HTTP identify API.
/// Records ambient audio via the microphone, then posts it to
/// `https://<host>/v1/identify` with an HMAC-SHA1 signed request.
class AcrCloudService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isInitialized = false;
  String _host = '';
  String _accessKey = '';
  String _accessSecret = '';

  Future<void> init({
    required String host,
    required String accessKey,
    required String accessSecret,
  }) async {
    _host = host;
    _accessKey = accessKey;
    _accessSecret = accessSecret;
    _isInitialized = host.isNotEmpty && accessKey.isNotEmpty;
    debugPrint(
        '[AcrCloudService] init: host=$host initialized=$_isInitialized');
  }

  bool get isInitialized => _isInitialized;

  /// Record ~6 seconds of audio and send to ACRCloud for recognition.
  Future<AcrResult> recognizeAmbient() async {
    if (!_isInitialized) {
      debugPrint('[AcrCloudService] not initialized');
      return const AcrResult(status: 'error');
    }

    if (!await _recorder.hasPermission()) {
      debugPrint('[AcrCloudService] mic permission denied');
      return const AcrResult(status: 'error');
    }

    // Record 6 seconds of audio to a temp file
    final tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/acr_sample_${DateTime.now().millisecondsSinceEpoch}.wav';

    try {
      debugPrint('[AcrCloudService] starting recording: $filePath');
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 8000,
          numChannels: 1,
        ),
        path: filePath,
      );
      await Future<void>.delayed(const Duration(seconds: 6));
      final recordedPath = await _recorder.stop();
      debugPrint('[AcrCloudService] recording stopped: $recordedPath');

      if (recordedPath == null) {
        return const AcrResult(status: 'error');
      }

      final audioBytes = await File(recordedPath).readAsBytes();
      debugPrint('[AcrCloudService] audio size: ${audioBytes.length} bytes');

      return _identify(audioBytes);
    } catch (e) {
      debugPrint('[AcrCloudService] recognition error: $e');
      return const AcrResult(status: 'error');
    }
  }

  Future<void> stopRecognition() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  Future<AcrResult> _identify(List<int> audioBytes) async {
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    const httpMethod = 'POST';
    const httpUri = '/v1/identify';
    const dataType = 'audio';
    const signatureVersion = '1';

    // Build string to sign: method\nuri\naccess_key\ndata_type\nsig_version\ntimestamp
    final stringToSign = [
      httpMethod,
      httpUri,
      _accessKey,
      dataType,
      signatureVersion,
      timestamp,
    ].join('\n');

    // HMAC-SHA1 signature, base64 encoded
    final hmac = Hmac(sha1, utf8.encode(_accessSecret));
    final digest = hmac.convert(utf8.encode(stringToSign));
    final signature = base64Encode(digest.bytes);

    final url = Uri.https(_host, httpUri);
    final request = http.MultipartRequest('POST', url);
    request.fields['access_key'] = _accessKey;
    request.fields['sample_bytes'] = audioBytes.length.toString();
    request.fields['timestamp'] = timestamp;
    request.fields['signature'] = signature;
    request.fields['data_type'] = dataType;
    request.fields['signature_version'] = signatureVersion;
    request.files.add(http.MultipartFile.fromBytes(
      'sample',
      audioBytes,
      filename: 'sample.wav',
    ));

    debugPrint('[AcrCloudService] POST $url');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    debugPrint(
        '[AcrCloudService] response ${response.statusCode}: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}');

    if (response.statusCode != 200) {
      return AcrResult(status: 'error', title: 'HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final statusMap = decoded['status'] as Map<String, dynamic>?;
    final statusCode = statusMap?['code'] as int? ?? -1;

    // code 0 = success with match, 1001 = no match
    if (statusCode != 0) {
      return const AcrResult(status: 'no_match');
    }

    final metadata = decoded['metadata'] as Map<String, dynamic>?;
    final musicList = metadata?['music'] as List<dynamic>?;
    if (musicList == null || musicList.isEmpty) {
      return const AcrResult(status: 'no_match');
    }

    final top = musicList[0] as Map<String, dynamic>;
    final title = top['title'] as String?;
    final artists = top['artists'] as List<dynamic>?;
    final firstArtist = artists != null && artists.isNotEmpty
        ? (artists[0] as Map<String, dynamic>)['name'] as String?
        : null;
    final score = top['score'] as int? ?? 0;

    // Extract Spotify track ID from external_metadata if available
    final externalMeta = top['external_metadata'] as Map<String, dynamic>?;
    final spotify = externalMeta?['spotify'] as Map<String, dynamic>?;
    final spotifyTrack = spotify?['track'] as Map<String, dynamic>?;
    final spotifyTrackId = spotifyTrack?['id'] as String?;

    debugPrint(
        '[AcrCloudService] matched: $title by $firstArtist (score=$score, spotify=$spotifyTrackId)');

    return AcrResult(
      status: 'match',
      title: title,
      artist: firstArtist,
      spotifyTrackId: spotifyTrackId,
      confidence: score,
    );
  }
}
