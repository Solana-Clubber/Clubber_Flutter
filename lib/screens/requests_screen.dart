import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_providers.dart';
import '../services/acr_cloud_service.dart';
import '../services/local_config_loader.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/clubber_card.dart';

class DjApprovalScreen extends ConsumerStatefulWidget {
  const DjApprovalScreen({super.key});

  @override
  ConsumerState<DjApprovalScreen> createState() => _DjApprovalScreenState();
}

class _DjApprovalScreenState extends ConsumerState<DjApprovalScreen> {
  List<EscrowAccount> _onChainRequests = [];
  bool _loadingChain = false;
  String? _chainError;

  bool _isListening = false;
  AcrResult? _lastAcrResult;
  Timer? _acrTimer;
  bool _acrInitialized = false;
  String? _acrInitError;

  @override
  void initState() {
    super.initState();
    _fetchOnChainRequests();
    _initAcr();
  }

  @override
  void dispose() {
    _acrTimer?.cancel();
    super.dispose();
  }

  Future<void> _initAcr() async {
    try {
      final config = await loadLocalConfig();
      if (config.acrCloudHost.isEmpty) return;
      final acrService = ref.read(acrCloudServiceProvider);
      await acrService.init(
        host: config.acrCloudHost,
        accessKey: config.acrCloudAccessKey,
        accessSecret: config.acrCloudAccessSecret,
      );
      if (mounted) setState(() => _acrInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _acrInitError = e.toString());
    }
  }

  Future<void> _fetchOnChainRequests() async {
    final escrowService = await ref.read(escrowServiceProvider.future);
    if (escrowService == null) return;

    final session = ref.read(rootShellViewModelProvider).walletSession;
    if (session == null) return;

    setState(() {
      _loadingChain = true;
      _chainError = null;
    });
    try {
      final accounts =
          await escrowService.fetchRequestsForDj(session.publicKeyBase58);
      if (mounted) {
        setState(() {
          _onChainRequests = accounts;
          _loadingChain = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chainError = e.toString();
          _loadingChain = false;
        });
      }
    }
  }

  void _startListening() {
    setState(() {
      _isListening = true;
      _lastAcrResult = null;
    });
    _acrTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _runAcrRecognition();
    });
    _runAcrRecognition();
  }

  void _stopListening() {
    _acrTimer?.cancel();
    _acrTimer = null;
    setState(() => _isListening = false);
    final acrService = ref.read(acrCloudServiceProvider);
    acrService.stopRecognition().catchError((_) {});
  }

  Future<void> _runAcrRecognition() async {
    if (!_acrInitialized || !mounted) return;
    final acrService = ref.read(acrCloudServiceProvider);
    final result = await acrService.recognizeAmbient();
    if (!mounted) return;
    setState(() => _lastAcrResult = result);

    if (result.status == 'match') {
      await _checkAutoSettle(result);
    }
  }

  Future<void> _checkAutoSettle(AcrResult acrResult) async {
    debugPrint('[DjMode] ACR match result: title=${acrResult.title} spotify=${acrResult.spotifyTrackId}');
    debugPrint('[DjMode] on-chain requests: ${_onChainRequests.length}');
    for (final r in _onChainRequests) {
      debugPrint('[DjMode]   escrow status=${r.status} track=${r.trackId}');
    }
    final accepted = _onChainRequests
        .where((a) => a.status == EscrowStatus.accepted)
        .toList();
    debugPrint('[DjMode] accepted escrows: ${accepted.length}');

    for (final account in accepted) {
      if (acrResult.matchesTrack(
        account.trackId,
        account.trackId,
        '',
      )) {
        await _settleOnChain(account);
        return;
      }
    }

    final localAccepted = ref.read(clubAppStoreProvider).acceptedRequests;
    for (final req in localAccepted) {
      if (acrResult.matchesTrack(req.trackId, req.songTitle, req.artistName)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ACR 인식: "${req.songTitle}" 매칭됨. 정산 처리 중…',
            ),
          ),
        );
        ref.read(clubAppStoreProvider).settleRequest(req.id);
        return;
      }
    }
  }

  Future<void> _settleOnChain(EscrowAccount account) async {
    final escrowService = await ref.read(escrowServiceProvider.future);
    if (escrowService == null) return;

    final session = ref.read(rootShellViewModelProvider).walletSession;
    if (session == null) return;

    try {
      final escrowPda = await escrowService.deriveEscrowPda(
        account.user,
        account.dj,
        account.trackId,
      );
      final txBytes = await escrowService.buildSettleRequestTx(
        djPubkey: session.publicKeyBase58,
        escrowPda: escrowPda,
        userPubkey: account.user,
      );
      final walletService = ref.read(solanaMobileWalletServiceProvider);
      final sig = await walletService.signAndSendTransaction(
        session,
        Uint8List.fromList(txBytes),
      );
      if (!mounted) return;
      if (sig != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('자동 정산 완료!')),
        );
        await _fetchOnChainRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('자동 정산 오류: $e')),
        );
      }
    }
  }

  Future<void> _acceptRequest(SongRequest request) async {
    final escrowService = await ref.read(escrowServiceProvider.future);

    if (escrowService == null) {
      ref.read(clubAppStoreProvider).acceptRequestByDj(
            request.id,
            djMessage: '좋아요. 이번 블록 안에 반영할게요.',
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DJ 수락 완료 (로컬).')),
      );
      return;
    }

    final session = ref.read(rootShellViewModelProvider).walletSession;
    if (session == null) return;

    try {
      final escrowPda = request.escrowPda;
      if (escrowPda == null || escrowPda.isEmpty) {
        ref.read(clubAppStoreProvider).acceptRequestByDj(request.id);
        return;
      }
      final txBytes = await escrowService.buildAcceptRequestTx(
        djPubkey: session.publicKeyBase58,
        escrowPda: escrowPda,
      );
      final walletService = ref.read(solanaMobileWalletServiceProvider);
      final sig = await walletService.signAndSendTransaction(
        session,
        Uint8List.fromList(txBytes),
      );
      if (!mounted) return;
      if (sig != null) {
        ref.read(clubAppStoreProvider).acceptRequestByDj(request.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수락 완료.')),
        );
        await _fetchOnChainRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수락 오류: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(SongRequest request) async {
    final escrowService = await ref.read(escrowServiceProvider.future);

    if (escrowService == null) {
      ref.read(clubAppStoreProvider).rejectRequestByDj(
            request.id,
            djMessage: '이번 셋 분위기와 맞지 않아 다음 기회에 부탁드려요.',
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('요청을 거절했어요 (로컬).')),
      );
      return;
    }

    final session = ref.read(rootShellViewModelProvider).walletSession;
    if (session == null) return;

    try {
      final escrowPda = request.escrowPda;
      if (escrowPda == null || escrowPda.isEmpty) {
        ref.read(clubAppStoreProvider).rejectRequestByDj(request.id);
        return;
      }
      final txBytes = await escrowService.buildRejectRequestTx(
        djPubkey: session.publicKeyBase58,
        escrowPda: escrowPda,
        userPubkey: request.userPubkey,
      );
      final walletService = ref.read(solanaMobileWalletServiceProvider);
      final sig = await walletService.signAndSendTransaction(
        session,
        Uint8List.fromList(txBytes),
      );
      if (!mounted) return;
      if (sig != null) {
        ref.read(clubAppStoreProvider).rejectRequestByDj(request.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('거절 완료.')),
        );
        await _fetchOnChainRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('거절 오류: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(clubAppStoreProvider);
    final pending = store.pendingRequests;
    final accepted = store.acceptedRequests;

    return RefreshIndicator(
      color: AppTheme.green,
      backgroundColor: AppTheme.panel,
      onRefresh: _fetchOnChainRequests,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Header: DJ Mode title + online indicator
          const _DjModeHeader(),
          const SizedBox(height: 16),

          // Stats row
          _StatsRow(store: store),
          const SizedBox(height: 16),

          // ACRCloud / Music Detection card
          _MusicDetectionCard(
            isListening: _isListening,
            isInitialized: _acrInitialized,
            initError: _acrInitError,
            lastResult: _lastAcrResult,
            onStartListening: _startListening,
            onStopListening: _stopListening,
          ),
          const SizedBox(height: 16),

          // On-chain error banner
          if (_chainError != null) ...[
            const _ChainErrorBanner(),
            const SizedBox(height: 12),
          ],

          // On-chain loading
          if (_loadingChain)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.green,
                  ),
                ),
              ),
            ),

          // Pending requests section
          _SectionHeading(
            label: 'Latest Requests',
            count: pending.length,
          ),
          const SizedBox(height: 10),
          if (pending.isEmpty)
            const _EmptyState(label: 'No pending requests')
          else
            ...pending.map(
              (req) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DjRequestCard(
                  request: req,
                  onAccept: () => _acceptRequest(req),
                  onReject: () => _rejectRequest(req),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Queue / accepted section
          _SectionHeading(
            label: 'Queue',
            count: accepted.length,
          ),
          const SizedBox(height: 10),
          if (accepted.isEmpty)
            const _EmptyState(label: 'No songs in queue')
          else
            ...accepted.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _QueueCard(
                      position: entry.key + 1,
                      request: entry.value,
                    ),
                  ),
                ),

          // On-chain accounts section
          if (_onChainRequests.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeading(
              label: 'On-Chain',
              count: _onChainRequests.length,
            ),
            const SizedBox(height: 10),
            ..._onChainRequests.map(
              (account) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OnChainRow(account: account),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DJ Mode header
// ---------------------------------------------------------------------------

class _DjModeHeader extends StatelessWidget {
  const _DjModeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'DJ Mode',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(width: 10),
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppTheme.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'Online',
          style: TextStyle(
            color: AppTheme.green,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stats row: songs played, SOL earned, rating
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.store});

  final dynamic store;

  @override
  Widget build(BuildContext context) {
    final settled = (store.settledRequests as List).length;
    final totalLamports = (store.settledRequests as List<SongRequest>)
        .fold<int>(0, (sum, r) => sum + r.amountLamports);
    final solEarned = totalLamports / 1e9;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: settled.toString(),
            label: 'Played',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: solEarned.toStringAsFixed(solEarned < 10 ? 2 : 1),
            label: 'SOL Earned',
            valueColor: AppTheme.green,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: _StatCard(
            value: '4.8',
            label: 'Rating',
            valueColor: AppTheme.orange,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    this.valueColor = AppTheme.white,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return ClubberCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Music Detection card (ACRCloud)
// ---------------------------------------------------------------------------

class _MusicDetectionCard extends StatelessWidget {
  const _MusicDetectionCard({
    required this.isListening,
    required this.isInitialized,
    required this.initError,
    required this.lastResult,
    required this.onStartListening,
    required this.onStopListening,
  });

  final bool isListening;
  final bool isInitialized;
  final String? initError;
  final AcrResult? lastResult;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;

  @override
  Widget build(BuildContext context) {
    return ClubberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq, color: AppTheme.green, size: 18),
              const SizedBox(width: 8),
              Text(
                'Music Detection',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (isListening) const _WaveformIndicator(),
            ],
          ),
          const SizedBox(height: 14),
          if (initError != null)
            Text(
              'Init error: $initError',
              style: const TextStyle(color: AppTheme.red, fontSize: 12),
            )
          else if (!isInitialized)
            const Text(
              'ACRCloud not configured — add acr_cloud_host to config/local.json',
              style: TextStyle(color: AppTheme.grey, fontSize: 13),
            )
          else ...[
            if (lastResult != null) ...[
              _AcrResultDisplay(result: lastResult!),
              const SizedBox(height: 12),
            ],
            // Pill toggle switch
            _ListeningToggle(
              isListening: isListening,
              onStart: onStartListening,
              onStop: onStopListening,
            ),
          ],
        ],
      ),
    );
  }
}

class _ListeningToggle extends StatelessWidget {
  const _ListeningToggle({
    required this.isListening,
    required this.onStart,
    required this.onStop,
  });

  final bool isListening;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isListening ? onStop : onStart,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        decoration: BoxDecoration(
          color: isListening
              ? AppTheme.green.withValues(alpha: 0.15)
              : AppTheme.panelRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isListening ? AppTheme.green : AppTheme.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isListening ? Icons.stop_circle_outlined : Icons.mic_none,
              size: 16,
              color: isListening ? AppTheme.green : AppTheme.grey,
            ),
            const SizedBox(width: 8),
            Text(
              isListening ? 'Stop Listening' : 'Start Listening',
              style: TextStyle(
                color: isListening ? AppTheme.green : AppTheme.grey,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformIndicator extends StatelessWidget {
  const _WaveformIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final h in [6.0, 10.0, 7.0, 12.0, 5.0])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              width: 3,
              height: h,
              decoration: BoxDecoration(
                color: AppTheme.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

class _AcrResultDisplay extends StatelessWidget {
  const _AcrResultDisplay({required this.result});

  final AcrResult result;

  @override
  Widget build(BuildContext context) {
    if (result.status == 'no_match') {
      return const Text(
        'No match detected',
        style: TextStyle(color: AppTheme.grey, fontSize: 13),
      );
    }
    if (result.status == 'error') {
      return Text(
        'Error: ${result.title ?? 'unknown'}',
        style: const TextStyle(color: AppTheme.red, fontSize: 13),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.green.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.music_note, color: AppTheme.green, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title ?? '—',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.white,
                  ),
                ),
                Text(
                  result.artist ?? '—',
                  style: const TextStyle(color: AppTheme.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (result.confidence > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${result.confidence}%',
                style: const TextStyle(
                  color: AppTheme.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section heading
// ---------------------------------------------------------------------------

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label, this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (count != null && count! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.pink.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppTheme.pink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        label,
        style: const TextStyle(color: AppTheme.grey, fontSize: 13),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DJ request card (pending) with accept/reject icon buttons
// ---------------------------------------------------------------------------

class _DjRequestCard extends ConsumerWidget {
  const _DjRequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  final SongRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutesAgo = DateTime.now().difference(request.requestedAt).inMinutes;
    final timeLabel = minutesAgo < 1
        ? 'just now'
        : minutesAgo < 60
            ? '${minutesAgo}m ago'
            : '${(minutesAgo / 60).floor()}h ago';

    return ClubberCard(
      child: Row(
        children: [
          // Orange pending dot
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              color: AppTheme.orange,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.songTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  request.artistName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      formatSol(request.amountLamports),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.grey,
                      ),
                    ),
                  ],
                ),
                if (request.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    request.note,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Accept icon button
          _ActionIconButton(
            key: ValueKey('dj-approve-${request.id}'),
            icon: Icons.check,
            color: AppTheme.green,
            onTap: onAccept,
          ),
          const SizedBox(width: 8),
          // Reject icon button
          _ActionIconButton(
            key: ValueKey('dj-reject-${request.id}'),
            icon: Icons.close,
            color: AppTheme.red,
            onTap: onReject,
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Queue card (accepted requests)
// ---------------------------------------------------------------------------

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.position, required this.request});

  final int position;
  final SongRequest request;

  @override
  Widget build(BuildContext context) {
    return ClubberCard(
      child: Row(
        children: [
          // Green dot for accepted
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              color: AppTheme.green,
              shape: BoxShape.circle,
            ),
          ),
          // Position number
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: AppTheme.panelRaised,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$position',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grey,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.songTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  request.artistName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            formatSol(request.amountLamports),
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// On-chain row
// ---------------------------------------------------------------------------

class _OnChainRow extends StatelessWidget {
  const _OnChainRow({required this.account});

  final EscrowAccount account;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (account.status) {
      EscrowStatus.pending => AppTheme.orange,
      EscrowStatus.accepted => AppTheme.green,
      EscrowStatus.settled => AppTheme.pink,
      EscrowStatus.rejected => AppTheme.red,
      EscrowStatus.timedOut => AppTheme.red,
    };
    final statusLabel = switch (account.status) {
      EscrowStatus.pending => 'Pending',
      EscrowStatus.accepted => 'Accepted',
      EscrowStatus.rejected => 'Rejected',
      EscrowStatus.settled => 'Settled',
      EscrowStatus.timedOut => 'Timed Out',
    };

    return ClubberCard(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.trackId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.white,
                  ),
                ),
                Text(
                  formatSol(account.amount),
                  style: const TextStyle(
                    color: AppTheme.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chain error banner
// ---------------------------------------------------------------------------

class _ChainErrorBanner extends StatelessWidget {
  const _ChainErrorBanner();

  @override
  Widget build(BuildContext context) {
    return const ClubberCard(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.orange, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'On-chain fetch failed — showing local data',
              style: TextStyle(color: AppTheme.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
