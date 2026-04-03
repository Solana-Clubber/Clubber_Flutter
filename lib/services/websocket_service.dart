import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

// 백엔드 WS 주소 (api_service.dart 의 _backendUrl 과 맞추기)
const _backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

String get _wsUrl => _backendUrl
    .replaceFirst('http://', 'ws://')
    .replaceFirst('https://', 'wss://');

// ── WS 이벤트 타입 ─────────────────────────────────────────────────────────────

enum WsEvent {
  requestCreated,
  requestAccepted,
  requestRejected,
  djConfirmed,
  votingStarted,
  verifierVoted,
  requestSettled,
  requestRefunded,
  requestCancelled,
  unknown,
}

class WsMessage {
  const WsMessage({required this.event, required this.payload});
  final WsEvent event;
  final Map<String, dynamic> payload;
}

WsEvent _parseEvent(String raw) => switch (raw) {
      'REQUEST_CREATED' => WsEvent.requestCreated,
      'REQUEST_ACCEPTED' => WsEvent.requestAccepted,
      'REQUEST_REJECTED' => WsEvent.requestRejected,
      'DJ_CONFIRMED' => WsEvent.djConfirmed,
      'VOTING_STARTED' => WsEvent.votingStarted,
      'VERIFIER_VOTED' => WsEvent.verifierVoted,
      'REQUEST_SETTLED' => WsEvent.requestSettled,
      'REQUEST_REFUNDED' => WsEvent.requestRefunded,
      'REQUEST_CANCELLED' => WsEvent.requestCancelled,
      _ => WsEvent.unknown,
    };

// ── ClubberWebSocketService ────────────────────────────────────────────────────

/// 사용법:
///
/// ```dart
/// final ws = ClubberWebSocketService();
/// ws.connect(walletAddress: '...', clubId: '...', role: 'CLUBBER');
///
/// ws.messages.listen((msg) {
///   if (msg.event == WsEvent.djConfirmed) {
///     // DJ 재생 확인 → 20초 타이머 UI 표시
///   }
/// });
///
/// // 화면 종료 시
/// ws.disconnect();
/// ```
class ClubberWebSocketService {
  WebSocketChannel? _channel;
  final _controller = StreamController<WsMessage>.broadcast();

  Stream<WsMessage> get messages => _controller.stream;
  bool get isConnected => _channel != null;

  void connect({
    required String walletAddress,
    required String clubId,
    required String role, // 'CLUBBER' | 'DJ'
  }) {
    disconnect();

    _channel = WebSocketChannel.connect(Uri.parse('$_wsUrl/ws'));

    // 연결 직후 자신의 정보 등록
    _send({
      'type': 'REGISTER',
      'walletAddress': walletAddress,
      'clubId': clubId,
      'role': role,
    });

    _channel!.stream.listen(
      (raw) {
        try {
          final json = jsonDecode(raw as String) as Map<String, dynamic>;
          _controller.add(WsMessage(
            event: _parseEvent(json['event'] as String? ?? ''),
            payload: json['payload'] as Map<String, dynamic>? ?? {},
          ));
        } catch (_) {
          // malformed message 무시
        }
      },
      onDone: () {
        _channel = null;
      },
      onError: (_) {
        _channel = null;
      },
    );
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void _send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
