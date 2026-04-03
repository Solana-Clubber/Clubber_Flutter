# Phantom / MWA Debugging Harness

## 현재 막힌 문제

증상:
- Flutter 앱에서 지갑 연결 버튼을 누르면 Phantom 앱은 열린다.
- 하지만 Clubber로 돌아온 뒤 authorize/sign 결과가 정상 세션으로 이어지지 않는다.
- 결과적으로 `WalletSession` 생성 또는 Flutter 상태 반영이 실패해 데이터가 "안 가져와지는" 것으로 보인다.

이 문서는 **Phantom이 열리는 것**과 **Flutter가 성공 결과를 받는 것**을 구분해서 점검하기 위한 하네스다.

## 현재 코드상 성공 조건

성공으로 간주하려면 아래가 모두 만족해야 한다.

1. `LocalAssociationScenario.isAvailable()` 가 `true`
2. `startActivityForResult()` 완료
3. `scenario.start()` 완료
4. `client.authorize(...)` 가 null이 아닌 결과 반환
5. `client.signMessages(...)` 에서 signature 반환
6. Flutter `WalletSession` 생성
7. `RootShellViewModel` 에 세션 저장
8. `SharedPreferences` 에 세션 영속화

하나라도 실패하면 사용자 입장에서는 "Phantom은 열렸는데 데이터가 안 돌아온다"로 보인다.

## 현재 코드에서 꼭 봐야 할 파일

- `lib/services/solana_mobile_wallet_service.dart`
- `lib/viewmodels/root_shell_view_model.dart`
- `android/app/src/main/AndroidManifest.xml`

## 현재 의존성 상태

현재 repo는 pub.dev `solana_mobile_client 0.1.2` 를 사용한다.
Flutter 앱 쪽 문제와 지갑 앱 쪽 문제를 분리해서 디버깅해야 한다.

## 가장 먼저 확인할 것

### 1. 지원 환경
- Android 실제 기기 또는 Android 에뮬레이터인가?
- Phantom 또는 Mock MWA Wallet 이 실제로 설치되어 있는가?
- iOS 환경에서 테스트 중이라면 현재 MWA 기준 지원 범위 밖이다.

### 2. 패키지 버전 확인
- `pubspec.yaml` 에서 `solana_mobile_client` 버전이 의도치 않게 바뀌지 않았는가?
- `flutter pub get` 이후 lockfile이 예상 버전과 일치하는가?

### 3. 로그 stage 확인
현재 wallet service 로그 태그:
- `[SolanaMobileWalletService] ...`
- `[RootShellViewModel][wallet] ...`

특히 아래 stage에서 멈추는지 본다.
- `connect:startActivityForResult`
- `connect:start`
- `connect:authorize`
- `connect:signMessages`
- `connect:close`

## 재현 체크리스트

### 기본 재현
1. 앱 실행
2. Wallet gate 진입
3. `Solana wallet 연결` 버튼 탭
4. Phantom 실행 확인
5. authorize 승인
6. 필요 시 sign message 승인
7. Clubber 복귀 후 역할 선택 화면 진입 여부 확인

### 기대 결과
- 성공: 역할 선택 화면이 열리고 wallet label이 표시됨
- 실패: gate 화면 유지 + 에러 배지 표시 또는 무응답/timeout

## 권장 검증 순서

```bash
fvm flutter pub get
fvm flutter analyze
fvm flutter test test/services/solana_mobile_wallet_service_test.dart test/viewmodels/root_shell_view_model_test.dart test/widget_test.dart
```

그 다음 실제 Android 기기/에뮬레이터에서:
- authorize
- signMessages
- app relaunch 후 restore
- disconnect/deauthorize
를 순서대로 확인한다.

## 실패 원인 가설 트리

### A. App return / bridge 문제
증상:
- Phantom은 열리지만 Flutter future가 풀리지 않음

의심 지점:
- Flutter plugin 내부 activity result 전달 지연
- 앱 복귀 타이밍과 authorize 요청 lifecycle 불일치
- wallet return intent 이후 Dart 상태 업데이트 누락

### B. authorize 단계 문제
증상:
- wallet 복귀 후 `authorize` null 또는 exception

의심 지점:
- identity 정보 불일치
- wallet-side cancel
- session handshake 실패
- wallet availability 감지와 실제 authorize 가능 상태의 불일치

### C. signMessages 단계 문제
증상:
- authorize는 됐지만 로그인 완료로 넘어가지 않음

의심 지점:
- Phantom에서 message signing 미승인
- signed message payload 비어 있음
- app이 authorize 성공만으로 로그인 완료 처리하지 않도록 설계되어 있음

### D. Flutter state/persistence 문제
증상:
- 세션은 받은 것 같지만 화면이 안 바뀜

의심 지점:
- `WalletSession` 생성 실패
- `RootShellViewModel.connectWallet()` 예외 처리 진입
- SharedPreferences 저장 실패

## 다음 디버깅 작업 우선순위

1. 실제 기기 로그 캡처로 실패 stage 고정
2. `startActivityForResult -> start -> authorize -> signMessages` 중 어디서 끊기는지 확인
3. 필요하면 native plugin 쪽에 request code / result code / uri prefix 로그 추가
4. authorize 결과와 signMessages 결과를 분리해서 UI 디버그 배지로 노출
5. 성공/실패 케이스를 golden이 아닌 integration-style 테스트로 보강

## 구현 시 주의

- authorize 성공만으로 로그인 완료 처리하지 말 것
- `signMessages` 가 비어 있으면 실패로 남길 것
- timeout을 없애지 말고, 어느 stage timeout인지 사용자/로그 양쪽에 남길 것
- 실제 해결 전까지 README와 docs에서 "Phantom 재검증 필요" 상태를 유지할 것

## 공식 참고 문서

- Solana Mobile MWA overview: https://docs.solanamobile.com/developers/mobile-wallet-adapter
- Solana Mobile - MWA for mobile apps: https://docs.solanamobile.com/mobile-wallet-adapter/mobile-apps
- Solana Mobile - Flutter overview: https://docs.solanamobile.com/get-started/flutter/overview

위 문서들 기준으로 보면 MWA는 **Android 지원, iOS 미지원**이 현재 공식 전제다. Phantom 호환 자체는 문서상 지원 범주에 포함되지만, 이 저장소에서는 실제 Flutter/native bridge 복귀를 별도로 검증해야 한다.
