import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'app.dart';
import 'services/local_config_loader.dart';
import 'services/naver_map_runtime.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localConfig = await loadLocalConfig();
  final naverMapClientId = localConfig.naverMapClientId;

  if ((Platform.isAndroid || Platform.isIOS) && naverMapClientId.isNotEmpty) {
    await FlutterNaverMap().init(
      clientId: naverMapClientId,
      onAuthFailed: (ex) {
        debugPrint('[Clubber][NaverMap] auth failed: ${ex.code} ${ex.message}');
        naverMapAuthFailedNotifier.value = ex;
      },
    );
  }

  runApp(const ClubberApp());
}
