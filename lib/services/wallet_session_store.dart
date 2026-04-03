import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

abstract class WalletSessionStore {
  Future<WalletSession?> load();
  Future<void> save(WalletSession session);
  Future<void> clear();
}

class SharedPreferencesWalletSessionStore implements WalletSessionStore {
  SharedPreferencesWalletSessionStore({Future<SharedPreferences>? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance();

  static const _sessionKey = 'wallet_session_v1';

  final Future<SharedPreferences> _preferences;

  @override
  Future<WalletSession?> load() async {
    final preferences = await _preferences;
    final encoded = preferences.getString(_sessionKey);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    final json = jsonDecode(encoded);
    if (json is! Map<String, dynamic>) {
      return null;
    }

    return WalletSession.fromJson(json);
  }

  @override
  Future<void> save(WalletSession session) async {
    final preferences = await _preferences;
    await preferences.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    final preferences = await _preferences;
    await preferences.remove(_sessionKey);
  }
}
