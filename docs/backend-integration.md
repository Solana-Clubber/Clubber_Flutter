# 백엔드 연동 가이드

> PR: `feature/backend-integration`  
> 작성일: 2026-04-04  
> 백엔드 담당: 창현

---

## 개요

이 PR은 Express.js 백엔드와의 연동 레이어를 추가합니다.  
**기존 Flutter 코드는 일절 수정하지 않았습니다.** 아래 두 파일을 신규 추가했고, 연동은 Flutter 팀이 `ClubAppStore` 및 화면에서 선택적으로 붙이면 됩니다.

| 추가 파일 | 역할 |
|-----------|------|
| `lib/services/api_service.dart` | REST API 호출 함수 모음 |
| `lib/services/websocket_service.dart` | WebSocket 실시간 이벤트 수신 |

---

## 백엔드 서버 정보

```
위치: backend/ (이 레포 루트 기준)
포트: 3000
WebSocket: ws://<host>:3000/ws
REST: http://<host>:3000/api/v1
```

### 로컬 실행

```bash
cd backend
cp .env.example .env        # DATABASE_URL 등 환경변수 설정
npm run db:reset             # PostgreSQL 스키마 + 목업 시드 데이터 투입
npm run dev                  # 개발 서버 시작
```

**Android 에뮬레이터에서 localhost 접근:**  
에뮬레이터는 `10.0.2.2`로 호스트 머신 localhost에 접근합니다.  
`api_service.dart` 기본값이 이미 `10.0.2.2:3000`으로 설정되어 있습니다.

**실제 기기에서 접근:**  
```bash
# 앱 실행 시 --dart-define으로 서버 주소 주입
fvm flutter run --dart-define=BACKEND_URL=http://192.168.x.x:3000 --dart-define=NAVER_MAP_CLIENT_ID=<id>
```

---

## 시드 데이터 목업

`db:reset` 이후 사용 가능한 데이터:

### 클럽 (clubs)

| ID | 이름 | 위치 |
|----|------|------|
| `a1000000-...-0001` | CLUB OCTAGON | 강남 (37.4977, 127.0242) |
| `a1000000-...-0002` | CLUB FF | 홍대 (37.5520, 126.9244) |
| `a1000000-...-0003` | CAKESHOP | 이태원 (37.5343, 126.9949) |

전체 UUID는 `backend/src/db/seed.sql` 참조.

### DJ (djs)

| ID | 이름 | 지갑 |
|----|------|------|
| `b1000000-...-0001` | DJ SODA | `DJWa11et111...` |
| `b1000000-...-0002` | PEGGY GOU | `DJWa11et222...` |
| `b1000000-...-0003` | DJ WRECKX | `DJWa11et333...` |
| `b1000000-...-0004` | CALL SUPER | `DJWa11et444...` |
| `b1000000-...-0005` | DJ RAIDEN | `DJWa11et555...` |
| `b1000000-...-0006` | HYUKOH DJ SET | `DJWa11et666...` |

### 타임테이블

4/3 ~ 4/5 23:59 KST 기준 각 클럽마다 2~3 슬롯 배정.  
예시: `GET /api/v1/clubs/a1000000-0000-0000-0000-000000000001/timetable?date=2026-04-05`

---

## API 레퍼런스

### 클럽

```
GET  /api/v1/clubs?lat={lat}&lng={lng}&radius={m}   근처 클럽 목록
GET  /api/v1/clubs/:id                              클럽 단건
GET  /api/v1/clubs/:id/timetable?date=YYYY-MM-DD    타임테이블 (DJ 포함)
GET  /api/v1/clubs/:clubId/djs/live                 현재 라이브 DJ
```

### 요청(Request) — 상태 머신

```
POST /api/v1/requests                               신청 생성
GET  /api/v1/requests/:id                           단건 조회
GET  /api/v1/djs/:djId/requests/pending             DJ 미승인 목록

POST /api/v1/requests/:id/accept                    DJ 수락
POST /api/v1/requests/:id/reject                    DJ 거절
POST /api/v1/requests/:id/cancel                    클러버 취소

POST /api/v1/requests/:id/dj-confirm                DJ 재생 확인 → 20초 타이머 시작
POST /api/v1/requests/:id/requester-confirm         요청자 확인 → 즉시 정산(경로1)
POST /api/v1/requests/:id/vote                      Verifier 투표(경로2)
```

### 체크인

```
POST /api/v1/checkins          { wallet_address, club_id }  입장 시 호출 필수
POST /api/v1/checkins/out      { wallet_address, club_id }  퇴장 시 호출
GET  /api/v1/clubs/:clubId/checkins/count           현재 활성 인원
```

---

## 상태 머신 & Flutter 상태 매핑

```
백엔드 상태                Flutter SongRequestStatus
──────────────────────────────────────────────────
PENDING                →  pendingDjApproval
ACCEPTED               →  pendingDjApproval   (DJ 수락, 아직 재생 미확인)
DJ_CONFIRMED           →  awaitingUserApproval (20초 확인 대기)
VOTING                 →  awaitingUserApproval (다중 투표 진행 중)
SETTLED                →  queued
REFUNDED               →  rejected
REJECTED               →  rejected
CANCELLED              →  rejected
```

전체 플로우:
```
PENDING
  ├─ accept  → ACCEPTED
  │    └─ dj-confirm → DJ_CONFIRMED (20초 타이머)
  │         ├─ requester-confirm → SETTLED (DJ 100%)
  │         └─ 타임아웃 → VOTING
  │              ├─ n/m 충족 → SETTLED (DJ 90% + verifier 10%)
  │              └─ n/m 미달/타임아웃 → REFUNDED
  ├─ reject  → REJECTED (즉시 환불)
  └─ cancel  → CANCELLED (즉시 환불)
```

---

## WebSocket 이벤트

연결 후 `REGISTER` 메시지를 보내면 해당 wallet/club 기준으로 이벤트를 수신합니다.

```dart
final ws = ClubberWebSocketService();
ws.connect(
  walletAddress: session.walletAddress,
  clubId: currentClubId,
  role: 'CLUBBER', // 또는 'DJ'
);

ws.messages.listen((msg) {
  switch (msg.event) {
    case WsEvent.requestAccepted:
      // DJ가 수락 → 클러버에게 알림
    case WsEvent.djConfirmed:
      // DJ 재생 확인 → 20초 확인 버튼 UI 표시
      final timeoutMs = msg.payload['timeoutMs'] as int; // 20000
    case WsEvent.votingStarted:
      // 내가 verifier로 선정됨 → 투표 UI 표시
      final reward = msg.payload['reward'] as String;
    case WsEvent.requestSettled:
      // 정산 완료
    case WsEvent.requestRefunded:
      // 환불 완료
    default:
      break;
  }
});
```

| 이벤트 | 수신자 | payload 주요 필드 |
|--------|--------|-------------------|
| `REQUEST_CREATED` | DJ | `request` |
| `REQUEST_ACCEPTED` | 클러버 | `request` |
| `REQUEST_REJECTED` | 클러버 | `request` |
| `DJ_CONFIRMED` | 클러버 | `request`, `timeoutMs` |
| `VOTING_STARTED` | 선정된 verifier | `requestId`, `songTitle`, `reward`, `expiresAt` |
| `VERIFIER_VOTED` | 클럽 전체 | `requestId`, `confirmCount`, `total` |
| `REQUEST_SETTLED` | 클럽 전체 | `request`, `settlementType` |
| `REQUEST_REFUNDED` | 클럽 전체 | `request`, `reason` |

---

## Flutter 팀 연동 체크리스트

- [ ] `fvm flutter pub get` 실행 (`http`, `web_socket_channel` 추가됨)
- [ ] `checkin()` — 클럽 입장 시점에 호출 (verifier 풀 등록 필수)
- [ ] `fetchNearbyClubs()` → `ClubAppStore._clubs` 교체 또는 병행
- [ ] `fetchTimetable()` → 클럽 상세 화면 DJ 정보 표시
- [ ] `createRequest()` → `ClubAppStore.submitSongRequest()` 대체
  - 온체인 `create_request` tx 서명 후 `on_chain_tx_sig` 전달
- [ ] `ClubberWebSocketService.connect()` → `RootShell` 또는 `ClubDetailScreen` 에서 초기화
- [ ] DJ 화면: `fetchPendingRequests()`, `acceptRequest()`, `rejectRequest()`, `djConfirmPlay()`
- [ ] 클러버 화면: `requesterConfirm()` — `DJ_CONFIRMED` 상태에서 20초 내 호출

---

## 온체인 연동 포인트

백엔드가 **오프체인 상태 관리**를 담당하고, 실제 SOL 이동은 **Anchor 프로그램**이 처리합니다.

```
1. 클러버: Anchor create_request tx 서명 → tx_sig를 POST /requests 에 포함
2. DJ 수락: accept_request tx 서명 (옵션) + POST /requests/:id/accept 호출
3. DJ 재생 확인: dj_confirm_play tx 서명 (옵션) + POST /requests/:id/dj-confirm 호출
4. 요청자 확인: requester_confirm tx 서명 → 온체인 정산 트리거
5. 환불: 백엔드 크랭크가 자동 처리
```

Anchor 프로그램 위치: `program/programs/dj_request/src/lib.rs`  
PDA seed: `["request", requester_pubkey, request_id_bytes]`

---

## 문의

백엔드 코드 질문은 창현에게.  
이 문서 마지막 업데이트: 2026-04-04
