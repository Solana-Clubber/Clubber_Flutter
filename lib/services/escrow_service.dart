import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

import '../models/escrow_account.dart';
import '../utils/borsh_codec.dart';

// ---------------------------------------------------------------------------
// EscrowService
// Builds serialized Solana transactions for each escrow instruction.
// Uses borsh_codec.dart for instruction data and the solana Dart package for
// TX construction (Message / CompiledMessage).
// RPC calls are made directly via HTTP JSON-RPC 2.0.
// ---------------------------------------------------------------------------

class EscrowService {
  EscrowService({required this.programId, required this.rpcUrl});

  final String programId;
  final String rpcUrl;

  // -------------------------------------------------------------------------
  // PDA derivation
  // Seeds: ["escrow", userPubkey bytes, djPubkey bytes, sha256(trackId)]
  // -------------------------------------------------------------------------

  /// Derive the escrow PDA address (base58).
  Future<String> deriveEscrowPda(
    String userPubkey,
    String djPubkey,
    String trackId,
  ) async {
    final progId = Ed25519HDPublicKey.fromBase58(programId);
    final userBytes = _base58Decode(userPubkey);
    final djBytes = _base58Decode(djPubkey);
    final trackIdHash = sha256.convert(utf8.encode(trackId)).bytes;

    final pda = await Ed25519HDPublicKey.findProgramAddress(
      seeds: [
        utf8.encode('escrow'),
        userBytes,
        djBytes,
        Uint8List.fromList(trackIdHash),
      ],
      programId: progId,
    );
    return pda.toBase58();
  }

  // -------------------------------------------------------------------------
  // Transaction builders
  // Each method:
  //   1. Encodes instruction data via borsh_codec
  //   2. Builds the account list
  //   3. Fetches recent blockhash
  //   4. Compiles to a legacy Message and returns the raw message bytes
  //      (no signatures yet — MWA signs them)
  // -------------------------------------------------------------------------

  /// Build create_request TX.
  Future<Uint8List> buildCreateRequestTx({
    required String userPubkey,
    required String djPubkey,
    required String trackId,
    required int amountLamports,
    int timeoutSeconds = 1800,
  }) async {
    debugPrint('[EscrowService] createRequest: user=$userPubkey dj=$djPubkey track=$trackId amount=$amountLamports');
    final escrowPda = await deriveEscrowPda(userPubkey, djPubkey, trackId);
    debugPrint('[EscrowService] escrowPda=$escrowPda');
    final instrData = encodeCreateRequest(trackId, amountLamports, timeoutSeconds);
    debugPrint('[EscrowService] instrData length=${instrData.length}');

    // Accounts (order matches Anchor struct): user (signer, writable),
    //   dj (readonly), escrow PDA (writable), system_program (readonly)
    final accounts = [
      AccountMeta.writeable(
        pubKey: Ed25519HDPublicKey.fromBase58(userPubkey),
        isSigner: true,
      ),
      AccountMeta.readonly(
        pubKey: Ed25519HDPublicKey.fromBase58(djPubkey),
        isSigner: false,
      ),
      AccountMeta.writeable(
        pubKey: Ed25519HDPublicKey.fromBase58(escrowPda),
        isSigner: false,
      ),
      AccountMeta.readonly(
        pubKey: Ed25519HDPublicKey.fromBase58(_systemProgramId),
        isSigner: false,
      ),
    ];

    return _buildTx(
      feePayer: userPubkey,
      accounts: accounts,
      instrData: instrData,
    );
  }

  /// Build accept_request TX.
  Future<Uint8List> buildAcceptRequestTx({
    required String djPubkey,
    required String escrowPda,
  }) async {
    final instrData = encodeAcceptRequest();

    // Accounts (order matches Anchor AcceptRequest struct):
    //   escrow (writable), dj (signer)
    final accounts = [
      AccountMeta.writeable(
        pubKey: Ed25519HDPublicKey.fromBase58(escrowPda),
        isSigner: false,
      ),
      AccountMeta.readonly(
        pubKey: Ed25519HDPublicKey.fromBase58(djPubkey),
        isSigner: true,
      ),
    ];

    return _buildTx(
      feePayer: djPubkey,
      accounts: accounts,
      instrData: instrData,
    );
  }

  /// Build reject_request TX.
  Future<Uint8List> buildRejectRequestTx({
    required String djPubkey,
    required String escrowPda,
    required String userPubkey,
  }) async {
    final instrData = encodeRejectRequest();

    // Accounts (order matches Anchor RejectRequest struct):
    //   escrow (writable, closes to user), dj (signer), user (writable, receives SOL)
    final accounts = [
      AccountMeta.writeable(
        pubKey: Ed25519HDPublicKey.fromBase58(escrowPda),
        isSigner: false,
      ),
      AccountMeta.readonly(
        pubKey: Ed25519HDPublicKey.fromBase58(djPubkey),
        isSigner: true,
      ),
      AccountMeta.writeable(
        pubKey: Ed25519HDPublicKey.fromBase58(userPubkey),
        isSigner: false,
      ),
    ];

    return _buildTx(
      feePayer: djPubkey,
      accounts: accounts,
      instrData: instrData,
    );
  }

  /// Build settle_request TX.
  Future<Uint8List> buildSettleRequestTx({
    required String djPubkey,
    required String escrowPda,
    required String userPubkey,
  }) async {
    final instrData = encodeSettleRequest();

    // Accounts (order matches Anchor SettleRequest struct):
    //   escrow (writable, closes to user), dj (signer, writable, receives SOL),
    //   user (writable, receives rent)
    final accounts = [
      AccountMeta.writeable(
        pubKey: Ed25519HDPublicKey.fromBase58(escrowPda),
        isSigner: false,
      ),
      AccountMeta.writeable(
        pubKey: Ed25519HDPublicKey.fromBase58(djPubkey),
        isSigner: true,
      ),
      AccountMeta.writeable(
        pubKey: Ed25519HDPublicKey.fromBase58(userPubkey),
        isSigner: false,
      ),
    ];

    return _buildTx(
      feePayer: djPubkey,
      accounts: accounts,
      instrData: instrData,
    );
  }

  /// Build timeout_refund TX (permissionless crank).
  Future<Uint8List> buildTimeoutRefundTx({
    required String crankerPubkey,
    required String escrowPda,
    required String userPubkey,
  }) async {
    final instrData = _encodeTimeoutRefund();

    // Accounts (order matches Anchor TimeoutRefund struct):
    //   escrow (writable, closes to user), cranker (signer), user (writable)
    final accounts = [
      AccountMeta.writeable(
        pubKey: Ed25519HDPublicKey.fromBase58(escrowPda),
        isSigner: false,
      ),
      AccountMeta.readonly(
        pubKey: Ed25519HDPublicKey.fromBase58(crankerPubkey),
        isSigner: true,
      ),
      AccountMeta.writeable(
        pubKey: Ed25519HDPublicKey.fromBase58(userPubkey),
        isSigner: false,
      ),
    ];

    return _buildTx(
      feePayer: crankerPubkey,
      accounts: accounts,
      instrData: instrData,
    );
  }

  // -------------------------------------------------------------------------
  // Send signed transaction
  // -------------------------------------------------------------------------

  /// Send a signed transaction to the RPC and return the TX signature string.
  Future<String> sendSignedTransaction(Uint8List signedTx) async {
    final base64Tx = base64Encode(signedTx);
    final result = await _rpcCall('sendTransaction', [
      base64Tx,
      {'encoding': 'base64', 'preflightCommitment': 'confirmed'},
    ]);
    debugPrint('[EscrowService] sendTransaction result: $result');
    return result as String;
  }

  // -------------------------------------------------------------------------
  // On-chain account fetching
  // -------------------------------------------------------------------------

  /// Fetch and decode an escrow account from on-chain. Returns null if the
  /// account does not exist or cannot be decoded.
  Future<EscrowAccount?> fetchEscrowAccount(String escrowPda) async {
    final result = await _rpcCall('getAccountInfo', [
      escrowPda,
      {'encoding': 'base64'},
    ]);

    final value = result['value'] as Map<String, dynamic>?;
    if (value == null) return null;

    final dataList = value['data'] as List<dynamic>?;
    if (dataList == null || dataList.isEmpty) return null;

    final base64Data = dataList[0] as String?;
    if (base64Data == null || base64Data.isEmpty) return null;

    try {
      final bytes = base64Decode(base64Data);
      return decodeEscrowAccount(Uint8List.fromList(bytes));
    } catch (e) {
      debugPrint('[EscrowService] fetchEscrowAccount decode error: $e');
      return null;
    }
  }

  /// Fetch all pending/accepted requests for a DJ.
  /// DJ pubkey is at byte offset 40 (8 discriminator + 32 user).
  Future<List<EscrowAccount>> fetchRequestsForDj(String djPubkey) async {
    return _fetchProgramAccounts(djPubkey, offset: 40);
  }

  /// Fetch all requests created by a user.
  /// User pubkey is at byte offset 8 (after discriminator).
  Future<List<EscrowAccount>> fetchRequestsForUser(String userPubkey) async {
    return _fetchProgramAccounts(userPubkey, offset: 8);
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  static const String _systemProgramId =
      '11111111111111111111111111111111';

  /// Anchor discriminator for timeout_refund.
  static final Uint8List _discTimeoutRefund = _computeDiscriminator(
    'timeout_refund',
  );

  static Uint8List _computeDiscriminator(String instructionName) {
    final input = utf8.encode('global:$instructionName');
    final digest = sha256.convert(input);
    return Uint8List.fromList(digest.bytes.sublist(0, 8));
  }

  Uint8List _encodeTimeoutRefund() {
    return Uint8List.fromList(_discTimeoutRefund);
  }

  static const _computeBudgetProgramId =
      'ComputeBudget111111111111111111111111111111';

  /// Manually build a legacy Solana transaction message.
  /// Bypasses Message.compile() to avoid account index issues with
  /// duplicate keys (user == dj in single-phone demo).
  Future<Uint8List> _buildTx({
    required String feePayer,
    required List<AccountMeta> accounts,
    required Uint8List instrData,
  }) async {
    final blockhash = await _getRecentBlockhash();

    final feePayerBytes = _base58Decode(feePayer);
    final programBytes = _base58Decode(programId);
    final computeBudgetBytes = _base58Decode(_computeBudgetProgramId);
    final systemBytes = _base58Decode(_systemProgramId);

    // 1. Collect unique keys with their flags
    // Map<base58 -> {bytes, isSigner, isWritable}>
    final keyMap = <String, _KeyMeta>{};

    void addKey(String b58, Uint8List bytes, bool signer, bool writable) {
      final existing = keyMap[b58];
      if (existing != null) {
        existing.isSigner = existing.isSigner || signer;
        existing.isWritable = existing.isWritable || writable;
      } else {
        keyMap[b58] = _KeyMeta(bytes: bytes, isSigner: signer, isWritable: writable);
      }
    }

    // Fee payer is always signer + writable
    addKey(feePayer, feePayerBytes, true, true);

    // Main instruction accounts
    for (final acct in accounts) {
      final b58 = acct.pubKey.toBase58();
      addKey(b58, _base58Decode(b58), acct.isSigner, acct.isWriteable);
    }

    // Programs (readonly, not signer)
    addKey(programId, programBytes, false, false);
    addKey(_computeBudgetProgramId, computeBudgetBytes, false, false);
    addKey(_systemProgramId, systemBytes, false, false);

    // 2. Sort: writable signers → readonly signers → writable non-signers → readonly non-signers
    // Fee payer must be index 0
    final sorted = keyMap.entries.toList();
    sorted.sort((a, b) {
      int score(_KeyMeta m, String key) {
        if (key == feePayer) return -1000; // fee payer always first
        if (m.isSigner && m.isWritable) return 0;
        if (m.isSigner && !m.isWritable) return 1;
        if (!m.isSigner && m.isWritable) return 2;
        return 3;
      }
      return score(a.value, a.key).compareTo(score(b.value, b.key));
    });

    final keyIndex = <String, int>{};
    final allKeyBytes = <int>[];
    int numRequiredSigs = 0;
    int numReadonlySigned = 0;
    int numReadonlyUnsigned = 0;

    for (var i = 0; i < sorted.length; i++) {
      final e = sorted[i];
      keyIndex[e.key] = i;
      allKeyBytes.addAll(e.value.bytes);
      if (e.value.isSigner) {
        numRequiredSigs++;
        if (!e.value.isWritable) numReadonlySigned++;
      } else {
        if (!e.value.isWritable) numReadonlyUnsigned++;
      }
    }

    // Debug
    for (var i = 0; i < sorted.length; i++) {
      debugPrint('[EscrowService] key[$i]: ${sorted[i].key} (signer=${sorted[i].value.isSigner}, writable=${sorted[i].value.isWritable})');
    }

    // 3. Resolve account indices for instructions
    final computeBudgetIdx = keyIndex[_computeBudgetProgramId]!;
    final programIdx = keyIndex[programId]!;

    // ComputeBudget: SetComputeUnitLimit(400_000)
    final setLimitData = Uint8List(5);
    setLimitData[0] = 2;
    ByteData.sublistView(setLimitData, 1).setUint32(0, 400000, Endian.little);

    // ComputeBudget: SetComputeUnitPrice(1)
    final setPriceData = Uint8List(9);
    setPriceData[0] = 3;
    ByteData.sublistView(setPriceData, 1).setUint64(0, 1, Endian.little);

    // Main instruction account indices (in the order Anchor expects)
    final mainAcctIndices = accounts.map((a) => keyIndex[a.pubKey.toBase58()]!).toList();
    debugPrint('[EscrowService] main instr account indices: $mainAcctIndices');

    // 4. Build message bytes
    final msg = BytesBuilder();

    // Header
    msg.addByte(numRequiredSigs);
    msg.addByte(numReadonlySigned);
    msg.addByte(numReadonlyUnsigned);

    // Account keys
    _writeCompactU16(msg, sorted.length);
    msg.add(allKeyBytes);

    // Recent blockhash
    msg.add(_base58Decode(blockhash));

    // Instructions (3)
    _writeCompactU16(msg, 3);

    // Instruction 0: SetComputeUnitLimit
    msg.addByte(computeBudgetIdx);
    _writeCompactU16(msg, 0); // no accounts
    _writeCompactU16(msg, setLimitData.length);
    msg.add(setLimitData);

    // Instruction 1: SetComputeUnitPrice
    msg.addByte(computeBudgetIdx);
    _writeCompactU16(msg, 0);
    _writeCompactU16(msg, setPriceData.length);
    msg.add(setPriceData);

    // Instruction 2: Main instruction
    msg.addByte(programIdx);
    _writeCompactU16(msg, mainAcctIndices.length);
    for (final idx in mainAcctIndices) {
      msg.addByte(idx);
    }
    _writeCompactU16(msg, instrData.length);
    msg.add(instrData);

    final messageBytes = msg.toBytes();

    // Wrap in transaction: [0x01][64 zero bytes][message]
    final txBytes = <int>[
      0x01,
      ...List.filled(64, 0),
      ...messageBytes,
    ];

    debugPrint('[EscrowService] TX built: ${txBytes.length} bytes (msg=${messageBytes.length}, blockhash=$blockhash)');
    return Uint8List.fromList(txBytes);
  }

  static void _writeCompactU16(BytesBuilder bb, int value) {
    if (value < 0x80) {
      bb.addByte(value);
    } else if (value < 0x4000) {
      bb.addByte((value & 0x7f) | 0x80);
      bb.addByte(value >> 7);
    } else {
      bb.addByte((value & 0x7f) | 0x80);
      bb.addByte(((value >> 7) & 0x7f) | 0x80);
      bb.addByte(value >> 14);
    }
  }

  /// getProgramAccounts with a memcmp filter at [offset] for [pubkey].
  Future<List<EscrowAccount>> _fetchProgramAccounts(
    String pubkey, {
    required int offset,
  }) async {
    final pubkeyBytes = _base58Decode(pubkey);
    final base64Filter = base64Encode(pubkeyBytes);

    final result = await _rpcCall('getProgramAccounts', [
      programId,
      {
        'encoding': 'base64',
        'filters': [
          {
            'memcmp': {
              'offset': offset,
              'bytes': base64Filter,
              'encoding': 'base64',
            },
          },
        ],
      },
    ]);

    if (result is! List) return [];

    final accounts = <EscrowAccount>[];
    for (final item in result) {
      try {
        final accountData =
            (item as Map<String, dynamic>)['account']
                as Map<String, dynamic>?;
        if (accountData == null) continue;

        final dataList = accountData['data'] as List<dynamic>?;
        if (dataList == null || dataList.isEmpty) continue;

        final base64Data = dataList[0] as String?;
        if (base64Data == null || base64Data.isEmpty) continue;

        final bytes = base64Decode(base64Data);
        accounts.add(decodeEscrowAccount(Uint8List.fromList(bytes)));
      } catch (e) {
        debugPrint('[EscrowService] fetchProgramAccounts decode error: $e');
      }
    }
    return accounts;
  }

  /// Fetch recent blockhash via JSON-RPC.
  Future<String> _getRecentBlockhash() async {
    final result = await _rpcCall('getLatestBlockhash', [
      {'commitment': 'confirmed'},
    ]);
    return result['value']['blockhash'] as String;
  }

  /// Execute a JSON-RPC 2.0 call against [rpcUrl].
  Future<dynamic> _rpcCall(String method, List<dynamic> params) async {
    final response = await http.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': method,
        'params': params,
      }),
    );

    if (response.statusCode != 200) {
      throw EscrowServiceException(
        'RPC $method failed: HTTP ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded.containsKey('error')) {
      throw EscrowServiceException(
        'RPC $method error: ${decoded['error']}',
      );
    }
    return decoded['result'];
  }

  // ---------------------------------------------------------------------------
  // Base58 decode helper (mirrors the encode in borsh_codec.dart but decodes)
  // ---------------------------------------------------------------------------

  static Uint8List _base58Decode(String input) {
    const alphabet =
        '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    var value = BigInt.zero;
    for (final ch in input.split('')) {
      final digit = alphabet.indexOf(ch);
      if (digit < 0) {
        throw ArgumentError('Invalid base58 character: $ch');
      }
      value = value * BigInt.from(58) + BigInt.from(digit);
    }

    final bytes = <int>[];
    while (value > BigInt.zero) {
      bytes.add((value % BigInt.from(256)).toInt());
      value ~/= BigInt.from(256);
    }

    // Leading '1' characters = leading zero bytes
    for (final ch in input.split('')) {
      if (ch == '1') {
        bytes.add(0);
      } else {
        break;
      }
    }

    return Uint8List.fromList(bytes.reversed.toList());
  }
}

class _KeyMeta {
  _KeyMeta({required this.bytes, required this.isSigner, required this.isWritable});
  final Uint8List bytes;
  bool isSigner;
  bool isWritable;
}

class EscrowServiceException implements Exception {
  const EscrowServiceException(this.message);

  final String message;

  @override
  String toString() => 'EscrowServiceException: $message';
}
