import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/models.dart';

// ── 백엔드 주소 설정 ──────────────────────────────────────────────────────────
// --dart-define=BACKEND_URL=https://your-server.com 으로 주입
// 미설정 시 로컬 개발 서버 기본값 사용
const _backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://10.0.2.2:3000', // Android 에뮬레이터 → 호스트 localhost
);

const _baseUrl = '$_backendUrl/api/v1';

// ─────────────────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);
  final String message;
  final int statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

Map<String, String> get _headers => {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

Future<Map<String, dynamic>> _get(String path) async {
  final res = await http.get(Uri.parse('$_baseUrl$path'), headers: _headers);
  _checkStatus(res);
  return jsonDecode(res.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
  final res = await http.post(
    Uri.parse('$_baseUrl$path'),
    headers: _headers,
    body: jsonEncode(body),
  );
  _checkStatus(res);
  return jsonDecode(res.body) as Map<String, dynamic>;
}

void _checkStatus(http.Response res) {
  if (res.statusCode >= 400) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    throw ApiException(
      body['error']?.toString() ?? 'Unknown error',
      res.statusCode,
    );
  }
}

// ── Club API ──────────────────────────────────────────────────────────────────

/// 위치 기반 근처 클럽 목록 조회
Future<List<ClubVenue>> fetchNearbyClubs({
  required double lat,
  required double lng,
  int radiusMeters = 5000,
}) async {
  final data = await _get(
    '/clubs?lat=$lat&lng=$lng&radius=$radiusMeters',
  );
  final list = data['clubs'] as List<dynamic>;
  return list
      .map((e) => ClubVenue.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// 특정 날짜의 타임테이블 (date 미지정 시 오늘)
Future<List<TimetableSlot>> fetchTimetable(
  String clubId, {
  String? date,
}) async {
  final query = date != null ? '?date=$date' : '';
  final data = await _get('/clubs/$clubId/timetable$query');
  final list = data['timetable'] as List<dynamic>;
  return list
      .map((e) => TimetableSlot.fromJson(e as Map<String, dynamic>))
      .toList();
}

// ── Request API ───────────────────────────────────────────────────────────────

/// 선곡 신청 생성
/// [onChainTxSig] 온체인 create_request tx 서명값
Future<SongRequest> createRequest({
  required String clubId,
  required String djId,
  required String requesterWallet,
  required String songId,
  required String songTitle,
  required String artistName,
  required String amountLamports,
  required String onChainTxSig,
}) async {
  final data = await _post('/requests', {
    'club_id': clubId,
    'dj_id': djId,
    'requester_wallet': requesterWallet,
    'song_id': songId,
    'song_title': songTitle,
    'song_artist': artistName,
    'amount_lamports': amountLamports,
    'on_chain_tx_sig': onChainTxSig,
  });
  return SongRequest.fromJson(data['request'] as Map<String, dynamic>);
}

/// 요청 단건 조회 (폴링용)
Future<SongRequest> fetchRequest(String requestId) async {
  final data = await _get('/requests/$requestId');
  return SongRequest.fromJson(data['request'] as Map<String, dynamic>);
}

/// DJ 미승인 요청 목록
Future<List<SongRequest>> fetchPendingRequests(String djId) async {
  final data = await _get('/djs/$djId/requests/pending');
  final list = data['requests'] as List<dynamic>;
  return list
      .map((e) => SongRequest.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// DJ 수락
Future<SongRequest> acceptRequest(String requestId, String djWallet) async {
  final data = await _post('/requests/$requestId/accept', {
    'dj_wallet': djWallet,
  });
  return SongRequest.fromJson(data['request'] as Map<String, dynamic>);
}

/// DJ 거절
Future<SongRequest> rejectRequest(String requestId, String djWallet) async {
  final data = await _post('/requests/$requestId/reject', {
    'dj_wallet': djWallet,
  });
  return SongRequest.fromJson(data['request'] as Map<String, dynamic>);
}

/// 클러버 취소
Future<SongRequest> cancelRequest(
  String requestId,
  String requesterWallet,
) async {
  final data = await _post('/requests/$requestId/cancel', {
    'requester_wallet': requesterWallet,
  });
  return SongRequest.fromJson(data['request'] as Map<String, dynamic>);
}

/// DJ 재생 확인 (20초 타이머 시작)
Future<SongRequest> djConfirmPlay(String requestId, String djWallet) async {
  final data = await _post('/requests/$requestId/dj-confirm', {
    'dj_wallet': djWallet,
  });
  return SongRequest.fromJson(data['request'] as Map<String, dynamic>);
}

/// 요청자 재생 확인 → 즉시 DJ 100% 정산 트리거
Future<SongRequest> requesterConfirm(
  String requestId,
  String requesterWallet,
) async {
  final data = await _post('/requests/$requestId/requester-confirm', {
    'requester_wallet': requesterWallet,
  });
  return SongRequest.fromJson(data['request'] as Map<String, dynamic>);
}

/// Verifier 투표
Future<void> submitVote(
  String requestId,
  String verifierWallet, {
  required bool confirm,
}) async {
  await _post('/requests/$requestId/vote', {
    'verifier_wallet': verifierWallet,
    'confirm': confirm,
  });
}

// ── Checkin API ───────────────────────────────────────────────────────────────

/// 클럽 체크인 (verifier 풀 등록 — 입장 시 호출)
Future<void> checkin(String clubId, String walletAddress) async {
  await _post('/checkins', {
    'club_id': clubId,
    'wallet_address': walletAddress,
  });
}

/// 클럽 체크아웃
Future<void> checkout(String clubId, String walletAddress) async {
  await _post('/checkins/out', {
    'club_id': clubId,
    'wallet_address': walletAddress,
  });
}

// ── 모델 확장: JSON 파싱 ───────────────────────────────────────────────────────

extension ClubVenueJson on ClubVenue {
  static ClubVenue fromJson(Map<String, dynamic> j) {
    return ClubVenue(
      id: j['id'] as String,
      name: j['name'] as String,
      neighborhood: j['address'] as String,
      musicStyle: '',
      heroTagline: j['description'] as String? ?? '',
      vibe: j['description'] as String? ?? '',
      distanceMeters: ((j['distance_m'] as num?) ?? 0).toInt(),
      walkingMinutes: (((j['distance_m'] as num?) ?? 0) / 80).ceil(),
      crowdLevel: 0,
      queueEtaMinutes: 0,
      mapPositionX: 0.5,
      mapPositionY: 0.5,
      residentArtist: '',
      liveSignalSummary: '',
      coverChargeWon: 0,
      creatorPayoutPoolWon: 0,
      mintPriceWon: 0,
      // 실제 좌표는 별도 필드로 노출됨 (네이버 맵 연동 시 사용)
    );
  }

  /// 백엔드에서 내려오는 실제 위경도 (네이버 맵 마커에 사용)
  static double latFromJson(Map<String, dynamic> j) =>
      (j['lat'] as num).toDouble();
  static double lngFromJson(Map<String, dynamic> j) =>
      (j['lng'] as num).toDouble();
}

extension SongRequestJson on SongRequest {
  /// 백엔드 Request → Flutter SongRequest 변환
  static SongRequest fromJson(Map<String, dynamic> j) {
    return SongRequest(
      id: j['id'] as String,
      clubId: j['club_id'] as String,
      songTitle: j['song_title'] as String,
      artistName: j['song_artist'] as String,
      requesterName: j['requester_wallet'] as String,
      requestedAt: DateTime.parse(j['created_at'] as String),
      offeredPriceWon: 0, // 백엔드는 lamports 기준, 필요 시 변환
      status: _statusFromBackend(j['status'] as String),
      djMessage: _defaultDjMessage(j['status'] as String),
    );
  }

  static SongRequestStatus _statusFromBackend(String s) => switch (s) {
        'PENDING' => SongRequestStatus.pendingDjApproval,
        'ACCEPTED' => SongRequestStatus.pendingDjApproval,
        'DJ_CONFIRMED' => SongRequestStatus.awaitingUserApproval,
        'VOTING' => SongRequestStatus.awaitingUserApproval,
        'SETTLED' => SongRequestStatus.queued,
        'REFUNDED' => SongRequestStatus.rejected,
        'REJECTED' => SongRequestStatus.rejected,
        'CANCELLED' => SongRequestStatus.rejected,
        _ => SongRequestStatus.pendingDjApproval,
      };

  static String? _defaultDjMessage(String status) => switch (status) {
        'PENDING' => 'DJ가 세트 흐름을 검토 중이에요.',
        'ACCEPTED' => 'DJ가 수락했어요.',
        'DJ_CONFIRMED' => 'DJ가 재생을 확인했어요. 20초 안에 확인해주세요.',
        'VOTING' => '다른 관객들이 재생 여부를 확인 중이에요.',
        'SETTLED' => '양측 승인이 완료되어 정산됐어요.',
        'REFUNDED' => '에스크로가 환불됐어요.',
        'REJECTED' => '이번 타임라인에는 맞지 않아 거절됐어요.',
        _ => null,
      };
}

// ── 타임테이블 슬롯 (Flutter 전용 모델) ──────────────────────────────────────

class TimetableSlot {
  const TimetableSlot({
    required this.id,
    required this.clubId,
    required this.djId,
    required this.djName,
    required this.djImageUrl,
    required this.startTime,
    required this.endTime,
    required this.isLive,
  });

  final String id;
  final String clubId;
  final String djId;
  final String djName;
  final String? djImageUrl;
  final DateTime startTime;
  final DateTime endTime;
  final bool isLive;

  factory TimetableSlot.fromJson(Map<String, dynamic> j) {
    return TimetableSlot(
      id: j['id'] as String,
      clubId: j['club_id'] as String,
      djId: j['dj_id'] as String,
      djName: j['dj_name'] as String,
      djImageUrl: j['dj_image_url'] as String?,
      startTime: DateTime.parse(j['start_time'] as String).toLocal(),
      endTime: DateTime.parse(j['end_time'] as String).toLocal(),
      isLive: j['is_live'] as bool,
    );
  }
}
