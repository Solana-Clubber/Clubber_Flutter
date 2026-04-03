# Clubber Project Harness

This `AGENTS.md` applies to the repository root and every file under it.

## Project mission

Clubber is an **Android-first Flutter club app** built around **Solana wallet-gated entry**.

Core product target:
1. Show club locations on **Naver Map**.
2. Split the app into **Guest** and **DJ** roles after wallet sign-in.
3. Let guests submit paid song requests to DJs.
4. Let DJs approve/reject pricing and queue fit.
5. Let the guest confirm the DJ-approved request.
6. Only after **both sides approve**, execute the **guest -> DJ** on-chain settlement.

## Current implementation truth

Treat the repository as being in this state unless you verify otherwise in code:

- **Wallet gate exists**: wallet connect / restore / disconnect is implemented in the root shell.
- **MWA is Android-only** in this app. Do not present iOS MWA as supported.
- **Naver Map club discovery exists** with a placeholder fallback when `NAVER_MAP_CLIENT_ID` is missing.
- **Role split exists**: User flow and DJ onboarding flow are both wired.
- **Song request approvals are currently local/mock state**, not real on-chain settlement.
- **DJ authorization is currently mock-based**, not server-backed.
- **Current blocker**: when Phantom opens during MWA flow, authorization/session data is not reliably hydrated back into Flutter.

## Non-negotiable guardrails

1. **Do not change the `solana_mobile_client` source/version lightly** unless you verify wallet flow behavior and update docs/tests.
2. **Do not claim real on-chain payment is complete** unless transaction creation, signing, submission, confirmation, and receipt persistence all exist.
3. **Keep wallet work Android-first**. If you touch iOS, document that it is out of supported MWA scope unless you are explicitly implementing a non-MWA fallback.
4. **Preserve wallet stage logging and timeout behavior** unless you have a verified reason to change it.
5. If you change the wallet or payment flow, update the corresponding docs under `docs/` in the same task.

## Source-of-truth map

### App shell / product flow
- `lib/screens/root_shell.dart`
- `lib/viewmodels/root_shell_view_model.dart`
- `lib/providers/app_providers.dart`

### Wallet / Solana / MWA
- `lib/services/solana_mobile_wallet_service.dart`
- `lib/services/wallet_session_store.dart`
- `lib/models/wallet_session.dart`

### Club / request domain
- `lib/state/club_app_store.dart`
- `lib/data/mock_club_repository.dart`
- `lib/models/song_request.dart`
- `lib/models/wallet_payment.dart`

### Map / venue discovery
- `lib/screens/discovery_screen.dart`
- `lib/models/club_venue.dart`

### DJ authorization
- `lib/services/dj_club_authorization_service.dart`

### Tests
- `test/services/solana_mobile_wallet_service_test.dart`
- `test/viewmodels/root_shell_view_model_test.dart`

## Required reading before editing sensitive areas

### If touching wallet / Phantom / MWA
Read first:
- `docs/mwa-phantom-debugging.md`
- `docs/architecture.md`
- `README.md`

### If touching product scope / request flow
Read first:
- `docs/mvp-overview.md`
- `docs/implementation-review.md`

### If cleaning legacy scaffolding
Read first:
- `docs/removal-inventory.md`

## Delivery priorities

When choosing what to build next, prefer this order unless the user overrides it:
1. **Phantom/MWA session return reliability**
2. **Real settlement pipeline after dual approval**
3. **Durable backend-backed DJ/club authorization**
4. **Persisted request/payment history**
5. **Operational polish** (observability, copy, empty states, cleanup)

## Verification commands

Use the bundled Flutter SDK in this repo.

```bash
fvm flutter pub get
fvm flutter analyze
fvm flutter test
```

For wallet regression work, also verify on Android with a real wallet app if possible.

## Done definition for wallet/payment changes

Do not call wallet/payment work done until all of the following are true:
- Flutter state receives a non-null success/failure result after returning from wallet app.
- Persisted session restore/deauthorize behavior still works.
- Logs clearly identify the failing stage when wallet flow breaks.
- Automated tests pass.
- Relevant docs in `docs/` and `README.md` are updated.

## Documentation map

- `docs/README.md` — doc index
- `docs/mvp-overview.md` — product scope and main flow
- `docs/architecture.md` — code boundaries and runtime flow
- `docs/mwa-phantom-debugging.md` — current wallet blocker and debug harness
- `docs/implementation-review.md` — risk review and next milestones
- `docs/delivery-harness.md` — execution checklist for future implementation tasks
- `docs/removal-inventory.md` — legacy/cleanup tracking
