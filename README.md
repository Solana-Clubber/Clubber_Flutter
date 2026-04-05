# Seeker Clubber

**A Seeker-first song request & on-chain settlement app for Solana Seeker phone users.**

Guests request songs from a DJ with SOL escrowed on-chain. When the DJ plays the song and audio recognition confirms playback, the escrow is automatically settled to the DJ's wallet — no middleman, no manual payouts.

---

## Project Overview

- **Project Name**: Clubber
- **One-liner**: A Solana-based song-request marketplace that escrows guest tips on-chain and auto-settles DJs via ambient music recognition.
- **Description**:
  Clubber is an Android-first Solana app that lets club guests tip DJs for specific song requests and pays the DJ automatically only when the song actually plays. A guest searches a track on Spotify, locks SOL into an on-chain escrow account, and the DJ sees the request on their own phone. When the DJ plays the song on the club's sound system, the DJ's phone microphone captures the audio, ACRCloud identifies the track, and the app cross-checks the recognized track against accepted escrows. On a verified match, the escrow automatically releases SOL to the DJ's wallet — with no club staff, no manual payouts, and no trust required. If the DJ rejects the request or never plays the song, the escrow times out and refunds the guest. Everything runs through the Solana Mobile Wallet Adapter on a Seeker phone with no backend service.

---

## Why This Exists

In Korean clubs today, guests who want to request a specific song have to pay a club staff member (MD) in cash, who then passes the request to the DJ. Two structural problems break this:

1. **No guarantee the song plays.** The MD takes the money up front, but the DJ has no obligation or direct relationship to the guest. The song may or may not actually be played.
2. **DJs often don't get paid.** Even when the song is played, the club frequently fails to settle the tip to the DJ after the night ends. Earnings leak out between the guest, the MD, the club, and the DJ.

Clubber removes the intermediaries entirely:

- The guest's SOL is **locked in a Solana escrow account** at the moment of the request — neither the DJ nor the club can touch it until the song plays.
- The DJ's phone **auto-confirms playback** using ambient music recognition, so payment is proof-carrying and doesn't rely on anyone's word.
- **Settlement is on-chain and automatic** — the DJ is paid the moment the song is verified, not at the end of the week (or never).
- If the DJ skips the song, the escrow **auto-refunds** to the guest after a timeout.

The result: a trust-minimized tip flow where the guest pays only when the song they asked for actually plays, and the DJ gets paid the instant it does.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter (Android only), Riverpod |
| Wallet | Solana Mobile Wallet Adapter (Seed Vault / Phantom) |
| Contract | Anchor (Rust) deployed on Solana devnet |
| Song Search | Spotify Web API (Client Credentials OAuth) |
| Music Recognition | ACRCloud HTTP Identify API |
| Map | Naver Map |

---

## Core Flow

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   Guest     │         │   Solana    │         │     DJ      │
│  (Seeker)   │         │   Devnet    │         │  (Seeker)   │
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                       │
       │ 1. Spotify search     │                       │
       │ 2. Build escrow TX    │                       │
       │ 3. Sign via MWA       │                       │
       ├──────────────────────▶│                       │
       │   CreateRequest       │                       │
       │   (0.1 SOL locked)    │                       │
       │                       │                       │
       │                       │ 4. Fetch pending      │
       │                       │◀──────────────────────┤
       │                       │                       │
       │                       │ 5. Accept TX          │
       │                       │◀──────────────────────┤
       │                       │   AcceptRequest       │
       │                       │                       │
       │                       │                       │ 6. DJ plays song
       │                       │                       │ 7. ACRCloud listens (6s)
       │                       │                       │ 8. Spotify lookup + match
       │                       │                       │
       │                       │ 9. Settle TX (auto)   │
       │                       │◀──────────────────────┤
       │                       │   SettleRequest       │
       │                       │   (0.1 SOL → DJ)      │
       │                       │                       │
```

### Detailed Steps

1. **Guest connects wallet** via Seed Vault / MWA → single "Continue with Seeker" button
2. **Guest picks a club** on the Naver Map discovery screen
3. **Guest searches song** using the Spotify Web API (press Enter to search)
4. **Guest sets SOL amount** (default 0.1 SOL) and signs the `create_request` transaction
5. **Escrow PDA is created on-chain** with seeds `["escrow", user, dj, sha256(track_id)]`, locking the SOL
6. **DJ switches to DJ Mode**, sees the pending request in the On-Chain section
7. **DJ taps Accept** → signs `accept_request` TX → escrow status flips to `Accepted`
8. **DJ taps "Start Listening"** → the phone records 6 seconds of ambient audio every 15 seconds
9. **ACRCloud Identify API** recognizes the track from the recording and returns metadata
10. **App cross-references** the recognized track against accepted escrows via Spotify track lookup (fuzzy title match handles version variants like "Shape of You" vs "Shape of You Instrumental")
11. **On match, the DJ phone auto-signs `settle_request`** → SOL + account rent flows from escrow PDA back out: amount to DJ, rent to user
12. If no DJ response within 30 minutes, `timeout_refund` returns the full escrow to the user

---

## Solana Contract (devnet)

- **Program ID**: `9Eu1Zf23iHYLWW28JHPQ841vZTM8fZQvbT1KJ1j2btym`
- **Network**: Solana Devnet
- **Framework**: Anchor 1.0
- **Explorer**: [View Program](https://explorer.solana.com/address/9Eu1Zf23iHYLWW28JHPQ841vZTM8fZQvbT1KJ1j2btym?cluster=devnet)

### Instructions

| Instruction | Signer | Effect |
|-------------|--------|--------|
| `create_request(track_id, amount, timeout_seconds)` | User | Initializes escrow PDA, transfers SOL in |
| `accept_request()` | DJ | Marks escrow as `Accepted` |
| `reject_request()` | DJ | Closes escrow, refunds SOL + rent to user |
| `settle_request()` | DJ | Transfers escrow amount to DJ, closes account, returns rent to user |
| `timeout_refund()` | Anyone (crank) | After timeout, closes escrow and refunds user |

### Account Layout — `SongRequestEscrow`

```rust
pub struct SongRequestEscrow {
    pub user: Pubkey,          // 32 bytes
    pub dj: Pubkey,            // 32 bytes
    pub track_id: String,      // 4 + up to 64 bytes (Spotify track ID)
    pub amount: u64,           // 8 bytes (lamports)
    pub status: u8,            // 1 byte (Pending=0, Accepted=1, Rejected=2, Settled=3, TimedOut=4)
    pub created_at: i64,       // 8 bytes (unix timestamp)
    pub timeout_at: i64,       // 8 bytes
    pub bump: u8,              // 1 byte
}
// Total: 8 (discriminator) + 166 = 174 bytes
// Rent: ~0.00157 SOL (reclaimed on close)
```

---

## Verified Devnet Transactions

Below are live transactions from the end-to-end demo, captured from the Seeker phone.

### 1. CreateRequest — Guest locks 0.1 SOL in escrow

- **Signature**: [`8mirzs33eGBDgqTdGCsehYBwB7epJMofnhyE5nLVcrbSV4CZ9RhvDp3kSh8RnY42n6uYxn2E4mEfscdAzaWB9U8`](https://explorer.solana.com/tx/8mirzs33eGBDgqTdGCsehYBwB7epJMofnhyE5nLVcrbSV4CZ9RhvDp3kSh8RnY42n6uYxn2E4mEfscdAzaWB9U8?cluster=devnet)
- **Track**: `3Vr3zh0r7ALn8VLqCiRR10` (Stargazing by Myles Smith)
- **Amount**: 100,000,000 lamports (0.1 SOL)
- **Escrow PDA**: `EH4VsBz1jNvVv1kHdRrY7WGZ6j62qCmsbRcoAyoKc937`

### 2. AcceptRequest — DJ accepts the request on-chain

- **Signature**: [`52Jbk2VtPdg5joC11hhftn83vskWewE9AFxJcSJiSfC6tepqA6Btoku7ki4Vh6FckMUzEkEg1oNcAae4cesDaCxb`](https://explorer.solana.com/tx/52Jbk2VtPdg5joC11hhftn83vskWewE9AFxJcSJiSfC6tepqA6Btoku7ki4Vh6FckMUzEkEg1oNcAae4cesDaCxb?cluster=devnet)
- **Program Log**: `Instruction: AcceptRequest` → `Request accepted by DJ`
- **Status change**: `Pending` → `Accepted`

### 3. SettleRequest — ACRCloud match triggers auto-settlement

- **Signature**: [`5oWqbX24V4f4S2rtFYDbQ8XmwKokvKtFnpabgn4oM7sFScCTZhNtTgKPkF3L8frwxUQoqyrKxmCrokS56ge9HeGB`](https://explorer.solana.com/tx/5oWqbX24V4f4S2rtFYDbQ8XmwKokvKtFnpabgn4oM7sFScCTZhNtTgKPkF3L8frwxUQoqyrKxmCrokS56ge9HeGB?cluster=devnet)
- **Program Log**: `Instruction: SettleRequest` → `Request settled, 100000000 lamports sent to DJ`
- **Escrow PDA balance**: `0.10204624 SOL` → `0 SOL` (account closed)
- **DJ balance**: `6.59145504 SOL` → `6.69345628 SOL` (+0.102 SOL)

---

## Repository Layout

```
solana_clubber/
├── clubber_contract/             # Anchor Solana program (Rust)
│   └── programs/clubber_contract/
│       ├── src/
│       │   ├── lib.rs            # Program entrypoint
│       │   ├── state.rs          # SongRequestEscrow account
│       │   ├── error.rs          # Error codes
│       │   └── instructions/     # 5 instruction handlers
│       └── tests/
│           └── test_escrow.rs    # 4 integration tests (litesvm)
└── Clubber_Flutter/              # Flutter mobile app
    └── lib/
        ├── screens/              # UI: discovery, club_detail, search_song, requests, user_requests, root_shell
        ├── services/
        │   ├── escrow_service.dart             # Manual TX builder + Borsh + JSON-RPC
        │   ├── solana_mobile_wallet_service.dart # MWA connect / reauthorize / signTransactions
        │   ├── spotify_service.dart            # Client Credentials OAuth + search + getTrackById
        │   └── acr_cloud_service.dart          # Microphone capture + ACRCloud Identify API
        ├── utils/
        │   └── borsh_codec.dart                # Anchor discriminator + Borsh string/u64 encoding
        ├── models/                             # SongRequest, EscrowAccount, SpotifyTrack, ClubVenue
        └── theme/app_theme.dart                # Dark theme + pink accent (#FF1493)
```

---

## Build & Run

### Prerequisites

- Flutter 3.41.5 (managed via FVM)
- Rust + Solana CLI + Anchor 1.0
- Android device or emulator (Seed Vault for Seeker phone recommended)
- A funded devnet wallet (`solana airdrop 2`)
- API keys: Spotify, ACRCloud, Naver Map

### 1. Configure `Clubber_Flutter/config/local.json`

```json
{
  "naverMapClientId": "YOUR_NAVER_MAP_CLIENT_ID",
  "spotifyClientId": "YOUR_SPOTIFY_CLIENT_ID",
  "spotifyClientSecret": "YOUR_SPOTIFY_CLIENT_SECRET",
  "programId": "9Eu1Zf23iHYLWW28JHPQ841vZTM8fZQvbT1KJ1j2btym",
  "rpcUrl": "https://api.devnet.solana.com",
  "acrCloudHost": "identify-ap-southeast-1.acrcloud.com",
  "acrCloudAccessKey": "YOUR_ACR_CLOUD_ACCESS_KEY",
  "acrCloudAccessSecret": "YOUR_ACR_CLOUD_ACCESS_SECRET"
}
```

### 2. Deploy the contract (optional — already deployed to devnet)

```bash
cd clubber_contract
anchor build
anchor deploy --provider.cluster devnet
anchor test
```

### 3. Run the Flutter app

```bash
cd Clubber_Flutter
fvm flutter pub get
fvm flutter run -d <seeker-device-id> --debug
```

### 4. Verify

```bash
# Flutter side
fvm flutter analyze
fvm flutter test

# Contract side
cd clubber_contract
cargo test
```

---

## End-to-end Demo Walkthrough

1. Launch app → Splash → Onboarding → "Continue with Seeker" wallet connect
2. Select **DJ role** first → onboarding (name + club) → DJ wallet is registered for that club
3. Switch role → select **Guest** → open the map → tap a club → "Request a Song"
4. Search a track (press Enter) → pick it → set SOL amount → "Send Request" → **sign CreateRequest TX**
5. Switch back to **DJ Mode** → pull-to-refresh → on-chain request appears in the On-Chain section
6. Tap **Accept** → **sign AcceptRequest TX**
7. Tap **Start Listening** → play the requested song on a nearby speaker
8. Within ~6 seconds, ACRCloud recognizes the song → Spotify title lookup → title match → **auto-sign SettleRequest TX**
9. Check [Solana Explorer (devnet)](https://explorer.solana.com/address/9Eu1Zf23iHYLWW28JHPQ841vZTM8fZQvbT1KJ1j2btym?cluster=devnet) to see the escrow PDA close and the SOL land in the DJ wallet

---

## License

MIT
