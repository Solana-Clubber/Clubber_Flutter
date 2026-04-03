# Delivery Harness

이 문서는 앞으로 Clubber 기능을 추가할 때 사용하는 **실행 체크리스트**다.

## 작업 시작 전

### 1. 읽기 순서
1. `../AGENTS.md`
2. `mvp-overview.md`
3. `architecture.md`
4. wallet 관련이면 `mwa-phantom-debugging.md`

### 2. 현재 작업이 어디 레이어인지 먼저 분류
- UI
- state/viewmodel
- wallet/MWA
- domain/service
- data persistence
- native Android/plugin

레이어를 먼저 정하지 않으면 작은 수정도 금방 꼬인다.

## 권장 구현 순서

### A. Phantom/MWA 이슈 작업
1. 재현 stage 고정
2. 로그 추가
3. native/Flutter bridge 수정
4. 단위 테스트/회귀 테스트 추가
5. 실제 기기 재검증
6. README/docs 반영

### B. 실정산 기능 작업
1. 상태 모델링 (`readyForPayment`, pending tx, completed tx)
2. request approval flow와 payment trigger 연결
3. transaction build/sign/send 구현
4. confirmation/receipt 저장
5. 실패/재시도 UX 추가
6. mock 문구 제거 및 docs 갱신

### C. DJ auth 실서비스화
1. mock auth 경계 분리
2. backend contract 정의
3. wallet-based DJ proof 연결
4. onboarding UI와 에러 상태 보강

## 코딩 체크리스트

- `solana_mobile_client` 버전/소스를 의도치 않게 바꾸지 않았는가?
- wallet 관련 예외를 삼키지 않았는가?
- 로그가 실패 stage를 구분하도록 남는가?
- 사용자에게 fake success를 보여주지 않는가?
- mock 상태라면 UI 문구도 mock/preview 성격을 유지하는가?

## 검증 체크리스트

### 필수
```bash
fvm flutter analyze
fvm flutter test
```

### wallet 변경 시 추가
- Android 실제 기기 또는 wallet 설치된 emulator 수동 검증
- authorize success
- sign message success
- restore success
- disconnect success
- cancel path success

## Definition of Done

### Wallet/MWA
- 앱 -> Phantom -> 앱 복귀가 성공/실패 어느 쪽이든 무응답 없이 종료된다.
- Flutter 화면 상태가 결과를 반영한다.
- timeout 또는 오류 stage가 로그에 남는다.
- 회귀 테스트가 있다.

### Settlement
- dual approval 이후 실제 결제 요청이 시작된다.
- tx signature를 저장한다.
- confirmed / failed / pending 상태를 복원할 수 있다.
- 사용자에게 결제 완료를 거짓으로 보여주지 않는다.

### Docs
- 관련 문서가 최신 상태다.
- README의 문서 링크가 깨지지 않는다.
