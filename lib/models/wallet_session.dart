import 'dart:convert';
import 'dart:typed_data';

class WalletSession {
  const WalletSession({
    required this.authToken,
    required this.publicKeyBase64,
    required this.cluster,
    required this.signedInMessage,
    required this.signedMessageBase64,
    required this.signatureBase64,
    required this.connectedAt,
    this.accountLabel,
    this.walletUriBase,
    this.lastVerifiedAt,
  });

  final String authToken;
  final String publicKeyBase64;
  final String cluster;
  final String signedInMessage;
  final String signedMessageBase64;
  final String signatureBase64;
  final DateTime connectedAt;
  final String? accountLabel;
  final String? walletUriBase;
  final DateTime? lastVerifiedAt;

  Uint8List get publicKey => base64Decode(publicKeyBase64);
  Uint8List get signedMessage => base64Decode(signedMessageBase64);
  Uint8List get signature => base64Decode(signatureBase64);

  String get walletAddressPreview {
    final hex = publicKey
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    if (hex.length <= 12) {
      return hex;
    }
    return '${hex.substring(0, 6)}…${hex.substring(hex.length - 6)}';
  }

  Map<String, dynamic> toJson() {
    return {
      'authToken': authToken,
      'publicKeyBase64': publicKeyBase64,
      'cluster': cluster,
      'signedInMessage': signedInMessage,
      'signedMessageBase64': signedMessageBase64,
      'signatureBase64': signatureBase64,
      'connectedAt': connectedAt.toIso8601String(),
      'accountLabel': accountLabel,
      'walletUriBase': walletUriBase,
      'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
    };
  }

  factory WalletSession.fromJson(Map<String, dynamic> json) {
    return WalletSession(
      authToken: json['authToken'] as String,
      publicKeyBase64: json['publicKeyBase64'] as String,
      cluster: json['cluster'] as String? ?? 'testnet',
      signedInMessage: json['signedInMessage'] as String,
      signedMessageBase64: json['signedMessageBase64'] as String,
      signatureBase64: json['signatureBase64'] as String,
      connectedAt: DateTime.parse(json['connectedAt'] as String),
      accountLabel: json['accountLabel'] as String?,
      walletUriBase: json['walletUriBase'] as String?,
      lastVerifiedAt: json['lastVerifiedAt'] == null
          ? null
          : DateTime.parse(json['lastVerifiedAt'] as String),
    );
  }

  WalletSession copyWith({
    String? authToken,
    String? publicKeyBase64,
    String? cluster,
    String? signedInMessage,
    String? signedMessageBase64,
    String? signatureBase64,
    DateTime? connectedAt,
    String? accountLabel,
    String? walletUriBase,
    DateTime? lastVerifiedAt,
    bool clearAccountLabel = false,
    bool clearWalletUriBase = false,
  }) {
    return WalletSession(
      authToken: authToken ?? this.authToken,
      publicKeyBase64: publicKeyBase64 ?? this.publicKeyBase64,
      cluster: cluster ?? this.cluster,
      signedInMessage: signedInMessage ?? this.signedInMessage,
      signedMessageBase64: signedMessageBase64 ?? this.signedMessageBase64,
      signatureBase64: signatureBase64 ?? this.signatureBase64,
      connectedAt: connectedAt ?? this.connectedAt,
      accountLabel: clearAccountLabel
          ? null
          : (accountLabel ?? this.accountLabel),
      walletUriBase: clearWalletUriBase
          ? null
          : (walletUriBase ?? this.walletUriBase),
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
    );
  }
}
