import 'dart:convert';

import 'package:flutter/services.dart';

class LocalConfig {
  const LocalConfig({this.naverMapClientId = ''});

  final String naverMapClientId;
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
    );
  } catch (_) {
    return const LocalConfig();
  }
}
