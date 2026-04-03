# Removal Inventory

메인 제품 플로우(지갑 인증 -> 역할 선택 -> 클럽 탐색 -> 신청곡 요청/승인 -> 결제) 밖에 있는 정리 후보를 적는다.

## 현재 후보

### 1. Seeker scaffold 계열
관련 파일:
- `lib/services/seeker_mvp_services.dart`
- `lib/models/location_preset.dart`
- `lib/models/mint_eligibility.dart`
- `lib/models/venue_presence_proof.dart`
- `lib/models/verified_review.dart`
- `lib/models/artist_settlement.dart`

메모:
- 일부는 장기적으로 온체인/현장 검증 기능으로 재사용 가능하다.
- 하지만 현재 Club request MVP의 핵심 blocker는 아니므로, 남길지 걷어낼지 방향 결정이 필요하다.

### 2. `WalletPayment`의 얕은 모델링
관련 파일:
- `lib/models/wallet_payment.dart`

메모:
- 실제 payment intent / tx receipt / confirmation 구조가 없어서 현재 모델은 너무 얕다.
- 삭제보다는 확장 가능성이 높다.

### 3. 사용되지 않는 request 상태 정리
관련 파일:
- `lib/models/song_request.dart`

메모:
- `readyForPayment` 가 현재 실제 플로우에서 쓰이지 않는다.
- 실정산 도입 시 활용하거나, 아니면 상태 머신을 다시 정리해야 한다.

## 정리 원칙

- 지금 당장 제품 blocker 해결에 도움 안 되면 대규모 삭제보다 보류가 낫다.
- 다만 새 기능을 붙일 때 혼선을 주면 그때는 작게 나눠 제거한다.
- 삭제 전에는 해당 모델/서비스가 테스트나 화면에서 참조되는지 확인한다.
