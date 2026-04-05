import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../models/escrow_account.dart';

// ---------------------------------------------------------------------------
// Low-level Borsh write helpers
// ---------------------------------------------------------------------------

void _writeU32LE(ByteData buf, int offset, int value) {
  buf.setUint32(offset, value, Endian.little);
}

void _writeU64LE(ByteData buf, int offset, int value) {
  // Dart int is 64-bit signed; safe for lamport amounts in practice.
  buf.setUint64(offset, value, Endian.little);
}

// ---------------------------------------------------------------------------
// Anchor instruction discriminator
// First 8 bytes of SHA-256("global:<instruction_name>")
// ---------------------------------------------------------------------------

Uint8List _discriminator(String instructionName) {
  final input = utf8.encode('global:$instructionName');
  final digest = sha256.convert(input);
  return Uint8List.fromList(digest.bytes.sublist(0, 8));
}

// Cache discriminators (computed once)
final Uint8List _discCreateRequest = _discriminator('create_request');
final Uint8List _discAcceptRequest = _discriminator('accept_request');
final Uint8List _discRejectRequest = _discriminator('reject_request');
final Uint8List _discSettleRequest = _discriminator('settle_request');

// ---------------------------------------------------------------------------
// Encode helpers
// ---------------------------------------------------------------------------

/// Encodes a Borsh string: 4-byte LE length prefix + UTF-8 bytes.
Uint8List _encodeString(String value) {
  final encoded = utf8.encode(value);
  final buf = ByteData(4 + encoded.length);
  _writeU32LE(buf, 0, encoded.length);
  final result = buf.buffer.asUint8List();
  result.setRange(4, 4 + encoded.length, encoded);
  return result;
}

// ---------------------------------------------------------------------------
// Public encode functions
// ---------------------------------------------------------------------------

/// create_request(track_id: String, amount: u64, timeout_seconds: u64)
/// Layout: [8 discriminator] [4+len track_id] [8 amount] [8 timeout_seconds]
Uint8List encodeCreateRequest(String trackId, int amountLamports, int timeoutSeconds) {
  final trackIdBytes = _encodeString(trackId);
  final total = 8 + trackIdBytes.length + 8 + 8;
  final out = Uint8List(total);
  out.setRange(0, 8, _discCreateRequest);
  out.setRange(8, 8 + trackIdBytes.length, trackIdBytes);
  final bd = ByteData.sublistView(out, 8 + trackIdBytes.length);
  _writeU64LE(bd, 0, amountLamports);
  _writeU64LE(bd, 8, timeoutSeconds);
  return out;
}

/// accept_request() — discriminator only
Uint8List encodeAcceptRequest() {
  return Uint8List.fromList(_discAcceptRequest);
}

/// reject_request() — discriminator only
Uint8List encodeRejectRequest() {
  return Uint8List.fromList(_discRejectRequest);
}

/// settle_request() — discriminator only
Uint8List encodeSettleRequest() {
  return Uint8List.fromList(_discSettleRequest);
}

// ---------------------------------------------------------------------------
// Decode EscrowAccount from on-chain account data
// On-chain layout (after 8-byte discriminator):
//   user:       32 bytes (Pubkey)
//   dj:         32 bytes (Pubkey)
//   track_id:   4-byte LE length + UTF-8 bytes (max 64)
//   amount:     8 bytes u64 LE
//   status:     1 byte u8
//   created_at: 8 bytes i64 LE
//   timeout_at: 8 bytes i64 LE
//   bump:       1 byte u8
// ---------------------------------------------------------------------------

/// Public base58 encoder — used by WalletSession and screens.
String base58Encode(Uint8List bytes) => _base58Encode(bytes);

String _base58Encode(Uint8List bytes) {
  const alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  var value = BigInt.zero;
  for (final b in bytes) {
    value = value * BigInt.from(256) + BigInt.from(b);
  }
  final buffer = StringBuffer();
  while (value > BigInt.zero) {
    final remainder = (value % BigInt.from(58)).toInt();
    value ~/= BigInt.from(58);
    buffer.write(alphabet[remainder]);
  }
  for (final b in bytes) {
    if (b == 0) {
      buffer.write('1');
    } else {
      break;
    }
  }
  return buffer.toString().split('').reversed.join();
}

EscrowAccount decodeEscrowAccount(Uint8List data) {
  // Skip 8-byte Anchor discriminator
  var offset = 8;

  final userBytes = data.sublist(offset, offset + 32);
  offset += 32;
  final djBytes = data.sublist(offset, offset + 32);
  offset += 32;

  final bd = ByteData.sublistView(data);

  final trackIdLen = bd.getUint32(offset, Endian.little);
  offset += 4;
  final trackId = utf8.decode(data.sublist(offset, offset + trackIdLen));
  offset += trackIdLen;

  final amount = bd.getUint64(offset, Endian.little);
  offset += 8;

  final statusByte = bd.getUint8(offset);
  offset += 1;

  final createdAtUnix = bd.getInt64(offset, Endian.little);
  offset += 8;

  final timeoutAtUnix = bd.getInt64(offset, Endian.little);
  offset += 8;

  final bump = bd.getUint8(offset);

  final status = EscrowStatus.values[statusByte.clamp(0, EscrowStatus.values.length - 1)];
  final createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtUnix * 1000, isUtc: true);
  final timeoutAt = DateTime.fromMillisecondsSinceEpoch(timeoutAtUnix * 1000, isUtc: true);

  return EscrowAccount(
    user: _base58Encode(userBytes),
    dj: _base58Encode(djBytes),
    trackId: trackId,
    amount: amount,
    status: status,
    createdAt: createdAt,
    timeoutAt: timeoutAt,
    bump: bump,
  );
}
