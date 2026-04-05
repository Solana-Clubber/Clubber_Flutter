import 'dart:convert';

import 'package:flutter/services.dart';

class LocalConfig {
  const LocalConfig({
    this.naverMapClientId = '',
    this.spotifyClientId = '',
    this.spotifyClientSecret = '',
    this.programId = '',
    this.rpcUrl = 'https://api.devnet.solana.com',
    this.acrCloudHost = '',
    this.acrCloudAccessKey = '',
    this.acrCloudAccessSecret = '',
  });

  final String naverMapClientId;
  final String spotifyClientId;
  final String spotifyClientSecret;
  final String programId;
  final String rpcUrl;
  final String acrCloudHost;
  final String acrCloudAccessKey;
  final String acrCloudAccessSecret;
}

Future<LocalConfig> loadLocalConfig() async {
  try {
    final raw = await rootBundle.loadString('config/local.json');
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return const LocalConfig();
    }
    return LocalConfig(
      naverMapClientId: decoded['naverMapClientId'] as String? ?? '',
      spotifyClientId: decoded['spotifyClientId'] as String? ?? '',
      spotifyClientSecret: decoded['spotifyClientSecret'] as String? ?? '',
      programId: decoded['programId'] as String? ?? '',
      rpcUrl:
          decoded['rpcUrl'] as String? ?? 'https://api.devnet.solana.com',
      acrCloudHost: decoded['acrCloudHost'] as String? ?? '',
      acrCloudAccessKey: decoded['acrCloudAccessKey'] as String? ?? '',
      acrCloudAccessSecret: decoded['acrCloudAccessSecret'] as String? ?? '',
    );
  } catch (_) {
    return const LocalConfig();
  }
}
