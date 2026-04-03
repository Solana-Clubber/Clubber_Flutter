# Implementation Review

## 현재 잘 되어 있는 점

### 1. 앱 진입 논리가 명확함
- 지갑 연결 전/후가 `RootShell` 에서 분리되어 있다.
- 세션 복원 -> 연결 게이트 -> 역할 선택 순서가 읽기 쉽다.

### 2. Wallet service 경계가 분리되어 있음
- MWA 호출이 `SolanaMobileWalletService` 에 모여 있다.
- UI가 native plugin 세부사항을 직접 알지 않아도 된다.

### 3. Naver Map이 graceful fallback을 가짐
- client id 미설정 시에도 fallback map preview가 있어 개발이 막히지 않는다.

### 4. request workflow가 MVP 수준으로는 충분히 보임
- Guest 제출
- DJ 승인/거절
- User 최종 확인
구조가 로컬 상태로 이미 표현되어 있다.

## 핵심 부족점

### 1. 실정산 파이프라인 부재
현재 제품의 가장 중요한 가치인 "양측 승인 후 코인 전송"이 아직 state transition으로만 존재한다.

### 2. wallet 이슈가 앱 전체 진행을 막고 있음
Phantom/MWA 복귀 신뢰성이 확보되지 않으면:
- role gate 진입
- DJ auth
- 이후 settlement
모두 불안정해진다.

### 3. mock 경계가 많음
- DJ authorization
- club/request data
- settlement rail
이 모두 mock 성격이라 실제 운영 기능과의 간극이 크다.

### 4. legacy scaffold가 일부 남아 있음
`seeker_*`, `mint_*`, `presence_proof` 관련 구조는 향후 방향이 명확하지 않으면 제품 집중도를 떨어뜨릴 수 있다.

## 추천 우선순위

### P0
1. Phantom/MWA 복귀 안정화
2. dual approval 이후 실 transaction orchestration 설계

### P1
3. DJ roster/backend verification
4. request/payment persistence model 도입

### P2
5. 관찰성(log, diagnostics, wallet failure UI) 강화
6. mock/legacy scaffold 정리

## 실정산 구현 최소 요구사항

아래가 없으면 결제 완료라고 말하면 안 된다.

- DJ wallet destination 확보
- amount -> lamports/token amount 매핑 규칙
- transaction 생성
- wallet signing
- network submission
- confirmation polling or subscription
- 실패/중복 전송 방지
- 영수증/tx signature 저장
- UI 재진입 시 복원 가능한 pending/completed state

## 추천 다음 작업 단위

### Slice 1 — Wallet stabilization
- native/Flutter stage instrumentation 추가
- Phantom 실제 기기 재현
- restore/deauthorize 회귀 검증

### Slice 2 — Settlement domain modeling
- `readyForPayment` 상태 실제 사용
- `PaymentIntent`, `PaymentReceipt` 모델 도입
- request와 payment를 분리된 상태 객체로 관리

### Slice 3 — Solana transfer execution
- sign/send path 구현
- tx confirmation 저장
- UI retry/error UX 추가

### Slice 4 — Backend auth
- club roster lookup
- DJ wallet allowlist / signed proof 기반 검증

## 문서 유지 규칙

아래를 건드리면 이 문서도 같이 갱신하는 것이 좋다.
- 제품의 핵심 순서 변경
- mock -> real 전환
- wallet blocker 해결 여부
- settlement 구조 추가
