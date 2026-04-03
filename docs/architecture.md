# Clubber Architecture

## 앱 구조 요약

```text
UI (screens/widgets)
  -> ViewModel / Riverpod providers
    -> Services
      -> Local persistence / MWA plugin / mock repository
        -> Models
```

## 레이어별 책임

### 1) UI
주요 파일:
- `lib/screens/root_shell.dart`
- `lib/screens/discovery_screen.dart`
- `lib/screens/club_detail_screen.dart`
- `lib/screens/requests_screen.dart`
- `lib/screens/user_requests_screen.dart`

책임:
- 지갑 연결 전/후 화면 전환
- Guest/DJ 화면 분기
- Naver Map 및 fallback 클럽 탐색 UI
- 요청 목록/상세/승인 버튼 렌더링

### 2) 상태 진입점
주요 파일:
- `lib/providers/app_providers.dart`
- `lib/viewmodels/root_shell_view_model.dart`
- `lib/state/club_app_store.dart`

책임:
- Riverpod provider wiring
- 지갑 세션 초기 복원
- 역할 선택 및 DJ onboarding 상태 관리
- 로컬 신청곡 상태 변화 관리

### 3) 도메인 서비스
주요 파일:
- `lib/services/solana_mobile_wallet_service.dart`
- `lib/services/wallet_session_store.dart`
- `lib/services/dj_club_authorization_service.dart`
- `lib/services/seeker_mvp_services.dart`

책임:
- MWA authorize / signMessages / reauthorize / deauthorize
- wallet session local persistence
- DJ 클럽 권한 확인
- 일부 legacy/scaffold service 유지

### 4) 플러그인 및 네이티브 경계
주요 파일:
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/example/lover_cl/MainActivity.kt`

책임:
- Android Activity result bridge
- wallet association intent launch
- Flutter <-> Android plugin result completion

## 현재 런타임 플로우

### A. Wallet connect

```text
RootShell
-> RootShellViewModel.connectWallet()
-> SolanaMobileWalletService.connectAndSignIn()
-> LocalAssociationScenario.startActivityForResult()
-> wallet app (e.g. Phantom) opens
-> scenario.start()
-> client.authorize(...)
-> client.signMessages(...)
-> WalletSession 생성
-> SharedPreferences 저장
-> role selection 진입
```

### B. Wallet restore

```text
app launch
-> RootShellViewModel._restoreWalletSession()
-> WalletSessionStore.load()
-> SolanaMobileWalletService.restoreSession()
-> client.reauthorize(...)
-> session refresh + local overwrite
```

### C. Guest request flow

```text
DiscoveryScreen
-> ClubDetailScreen
-> ClubAppStore.submitSongRequest()
-> pendingDjApproval
-> DJ screen approve
-> awaitingUserApproval
-> user confirm
-> queued
```

## 중요한 구현 경계

### Wallet boundary
- 현재 지갑 세션은 `WalletSession` 모델에 저장된다.
- 앱은 connect 시 authorize + signMessages를 모두 성공해야 로그인 완료로 본다.
- 즉, Phantom이 열렸다는 사실만으로 성공이 아니다.
- Flutter 상태까지 성공 결과가 돌아와야 한다.

### Payment boundary
- 현재 결제는 아직 mock/state 수준이다.
- `wallet_payment.dart` 모델은 있으나 실 트랜잭션 파이프라인은 없다.
- 향후 구현 시 최소 아래 정보가 필요하다:
  - payer wallet
  - DJ wallet
  - request id
  - lamports or token amount
  - transaction signature
  - confirmation status
  - failure / retry state

### Map boundary
- `NAVER_MAP_CLIENT_ID` 없으면 fallback UI로 내려간다.
- 맵 구현과 도메인 데이터는 분리되어 있어, venue repository 교체 시 UI를 크게 바꾸지 않아도 된다.

## 향후 권장 아키텍처 확장

### 1. Settlement coordinator 도입
추천 위치:
- `lib/services/song_request_payment_service.dart`
- 또는 `lib/services/solana_settlement_service.dart`

책임:
- dual approval 이후 전송 인텐트 생성
- MWA sign/send orchestration
- signature/receipt 저장
- 실패 시 재시도 가능한 상태 기록

### 2. Request repository 분리
현재 `ClubAppStore` 내부 로컬 변경으로 끝나는 상태를:
- local cache
- backend sync
- chain receipt sync
로 확장 가능한 구조로 분리하는 것이 좋다.

### 3. Wallet diagnostics channel 강화
현재 debug print 중심 로그를:
- stage code
- timestamp
- wallet package/app name
- returned null vs exception vs timeout
으로 더 구조화하면 Phantom 이슈 분석 속도가 빨라진다.
