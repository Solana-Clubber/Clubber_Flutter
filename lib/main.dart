import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'app.dart';
import 'services/naver_map_runtime.dart';

const _naverMapClientId = String.fromEnvironment('NAVER_MAP_CLIENT_ID');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if ((Platform.isAndroid || Platform.isIOS) && _naverMapClientId.isNotEmpty) {
    await FlutterNaverMap().init(
      clientId: _naverMapClientId,
      onAuthFailed: (ex) {
        debugPrint('[Clubber][NaverMap] auth failed: ${ex.code} ${ex.message}');
        naverMapAuthFailedNotifier.value = ex;
      },
    );
  }

  runApp(const ClubberApp());
}
