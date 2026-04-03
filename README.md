# Clubber 안드로이드 우선 지갑 인증 DJ 요청 MVP

Flutter 기반 iOS/Android DJ 요청 앱입니다. 현재 저장소는 **안드로이드 우선 Solana 지갑 인증 + User/DJ 역할 분리 DJ 요청 MVP** 기준으로 정리되어 있습니다.

## 핵심 플로우

1. 앱 시작 시 저장된 Solana 지갑 세션 복원을 먼저 시도합니다.
2. 유효한 세션이 없으면 `RootShell` 이 역할 선택 대신 지갑 연결 게이트를 먼저 보여줍니다.
3. Android 에서는 Solana Mobile Wallet Adapter의 authorize + 서명 로그인으로 인증합니다.
4. 지갑 인증 후 하나의 앱 안에서 User / DJ 역할을 선택합니다.
5. **User 경로**는 지도 우선 탐색, 클럽 상세, 참석자 요청 제출, 내 요청 상태 확인으로 이어집니다.
6. **DJ 경로**는 DJ 온보딩과 로컬/목 클럽 권한 확인을 통과한 뒤 승인 화면으로 진입합니다.
7. 지갑 인증 토큰 / 서명된 세션은 로컬에 저장되어 재실행 시 복원됩니다.

## 현재 한 줄 상태

- 메인 지갑 인증 진입 흐름은 구현되어 있습니다.
- `solana_mobile_client` 는 현재 pub.dev 배포 버전 `0.1.2` 기준으로 사용합니다.
- 실제 지갑 연결 정상 경로는 Android 기기/에뮬레이터 + Mock MWA Wallet 환경에서 추가 검증이 필요합니다.
- DJ 클럽 권한 확인은 아직 로컬/목 기준이며 서버 기반은 아닙니다.
- 레거시 Seeker / wallet / mint 관련 정리 후보가 일부 남아 있습니다.

## 문서 가이드

겹치는 설명은 아래처럼 역할을 나눠 정리했습니다.

- `AGENTS.md` — 이 저장소 전용 작업 하네스. 제품 목표, 우선순위, 검증 규칙을 담습니다.
- `docs/README.md` — 문서 인덱스입니다. 처음 들어온 사람이 읽을 순서를 안내합니다.
- `docs/mvp-overview.md` — **기준 문서**. 현재 MVP 구조, 범위, 구현 상태를 한 번에 설명합니다.
- `docs/architecture.md` — Flutter/MWA/Android 경계를 포함한 코드 구조를 설명합니다.
- `docs/mwa-phantom-debugging.md` — Phantom/MWA 복귀 이슈를 추적하는 디버깅 하네스입니다.
- `docs/implementation-review.md` — 구현 리뷰, 품질 관찰, 리스크, 후속 우선순위만 다룹니다.
- `docs/delivery-harness.md` — 다음 기능 구현 시 따라야 할 체크리스트와 DoD를 담습니다.
- `docs/removal-inventory.md` — 메인 흐름 밖 레거시 정리 후보만 추적합니다.

## 실행 방법

```bash
fvm flutter pub get
fvm flutter run --dart-define=NAVER_MAP_CLIENT_ID=<your-client-id>
```

- `NAVER_MAP_CLIENT_ID` 가 없으면 테스트/미설정용 대체 미리보기가 표시됩니다.
- 실제 지갑 연결 검증은 Android + Mock MWA Wallet 환경이 필요합니다.

## 검증 방법

```bash
fvm flutter analyze
fvm flutter test
```

## Solana Mobile Wallet Adapter 점검 메모

- 현재 앱은 pub.dev `solana_mobile_client 0.1.2` 를 사용합니다.
- Phantom 재검증 전 확인 순서:
  1. `fvm flutter pub get`
  2. `fvm flutter analyze lib test`
  3. `fvm flutter test test/services/solana_mobile_wallet_service_test.dart test/viewmodels/root_shell_view_model_test.dart test/widget_test.dart`
  4. Android 기기 또는 에뮬레이터 + Phantom/Mock MWA Wallet 으로 authorize → signMessages → restore/deauthorize 재실행
