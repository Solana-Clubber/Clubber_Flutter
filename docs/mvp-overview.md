# Clubber MVP Overview

## 한 줄 정의

Clubber은 **Solana 지갑 인증을 기반으로 클럽 입장객과 DJ를 연결하고, 양측 승인 뒤 신청곡 대금을 정산하는 Android-first Flutter 앱**이다.

## 제품 목표

### Guest(입장객)
- Naver Map에서 주변/추천 클럽을 본다.
- 클럽 상세에서 현재 분위기와 요청 현황을 본다.
- 원하는 곡과 제안 금액을 적어 DJ에게 신청한다.
- DJ가 조건을 수정/승인하면 최종 확인한다.
- 최종 확인이 끝나면 DJ에게 결제가 진행된다.

### DJ
- 지갑 로그인 후 DJ 권한을 확인한다.
- 들어온 요청을 검토한다.
- 가격/메시지를 조정해 승인하거나 거절한다.
- 양측 승인 완료 시 큐 반영과 정산 상태를 확인한다.

## 현재 코드 기준 구현 범위

### 구현됨
- Solana Mobile Wallet Adapter 기반 Android 지갑 연결 게이트
- 저장된 지갑 세션 복원 / 연결 해제
- Guest/DJ 역할 분리 진입
- Naver Map 기반 클럽 위치 표기 + fallback 미리보기
- 클럽 상세/요청 제출/상태 확인용 local state
- DJ mock 권한 확인
- DJ 승인 / 사용자 최종 승인으로 이어지는 local request 상태 변화

### 아직 미구현 또는 mock
- Guest -> DJ 실거래 Solana 전송
- 트랜잭션 서명/전송/확정/영수증 저장
- 서버 기반 DJ-Club roster 검증
- 실시간 네트워크 동기화
- 온체인/백엔드 기반 요청 히스토리

## 핵심 상태 전이

```text
Wallet disconnected
-> Wallet connected
-> Role selected

Guest request flow:
Draft
-> pendingDjApproval
-> awaitingUserApproval
-> queued

DJ rejection path:
pendingDjApproval | awaitingUserApproval
-> rejected
```

> `SongRequestStatus.readyForPayment` enum은 존재하지만 현재 메인 플로우에서 실제 결제 단계로 사용되지 않는다. 실정산을 붙일 때 이 상태를 재정의하거나 활용해야 한다.

## 핵심 파일

- 루트 진입: `lib/screens/root_shell.dart`
- 루트 상태: `lib/viewmodels/root_shell_view_model.dart`
- 맵 탐색: `lib/screens/discovery_screen.dart`
- 요청 상태: `lib/state/club_app_store.dart`
- 지갑 서비스: `lib/services/solana_mobile_wallet_service.dart`
- 세션 저장: `lib/services/wallet_session_store.dart`

## 현재 가장 중요한 제품 리스크

1. Phantom/MWA에서 앱으로 돌아왔을 때 authorize/sign 결과가 안정적으로 반영되지 않음
2. 신청곡 승인 흐름은 있지만 실제 Solana 결제 파이프라인이 없음
3. DJ 권한 검증이 mock이라 운영 준비도가 낮음
4. 상태가 대부분 local memory 기반이라 앱 재시작/멀티디바이스 시 일관성이 없음
