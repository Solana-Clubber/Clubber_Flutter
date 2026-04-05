import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_providers.dart';
import '../screens/search_song_screen.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/clubber_card.dart';

class ClubDetailScreen extends ConsumerStatefulWidget {
  const ClubDetailScreen({required this.clubId, super.key});

  final String clubId;

  @override
  ConsumerState<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends ConsumerState<ClubDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(clubAppStoreProvider);
    final club = store.clubById(widget.clubId);
    final requests = store.requestsForClub(club.id);
    final totalSol = requests.fold<int>(
          0,
          (sum, r) => sum + r.amountLamports,
        ) /
        1e9;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _ClubHeader(club: club),
              ),
              // ── Stats row ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: _StatsRow(
                    totalRequests: store.totalRequestsForClub(club.id),
                    totalSol: totalSol,
                  ),
                ),
              ),
              // ── Now Playing ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _NowPlayingCard(residentArtist: club.residentArtist),
                ),
              ),
              // ── Recent Plays ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _RecentPlaysSection(club: club),
                ),
              ),
              // ── Request list ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Text(
                    'Song Requests',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              if (requests.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Center(
                      child: Text(
                        'No requests yet.',
                        style: TextStyle(color: AppTheme.grey),
                      ),
                    ),
                  ),
                )
              else
                SliverList.separated(
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _RequestCard(
                        request: request,
                        onConfirm:
                            request.status == SongRequestStatus.accepted
                                ? () => _confirmRequest(context, request)
                                : null,
                      ),
                    );
                  },
                ),
              // Bottom padding for FAB
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          // ── Fixed bottom button ─────────────────────────────────────────
          Positioned(
            left: 20,
            right: 20,
            bottom: 32,
            child: _RequestSongButton(
              onTap: () => _showMakeRequestSheet(context, club),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRequest(BuildContext context, SongRequest request) {
    final success =
        ref.read(clubAppStoreProvider).confirmRequestByUser(request.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Settled successfully.' : 'Cannot settle right now.',
        ),
      ),
    );
  }

  void _showMakeRequestSheet(BuildContext context, ClubVenue club) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MakeRequestSheet(
        clubId: widget.clubId,
        club: club,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Club header with gradient
// ---------------------------------------------------------------------------

class _ClubHeader extends StatelessWidget {
  const _ClubHeader({required this.club});
  final ClubVenue club;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF1493),
            Color(0xFF9C59B5),
            Color(0xFF1A1A2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              // Music style badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  club.musicStyle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                club.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${club.neighborhood} · 도보 ${club.walkingMinutes}분',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats row (3 circular badges)
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.totalRequests,
    required this.totalSol,
  });

  final int totalRequests;
  final double totalSol;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBadge(
            value: '$totalRequests',
            label: 'Requests',
            color: AppTheme.pink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBadge(
            value: totalSol.toStringAsFixed(2),
            label: 'Total SOL',
            color: AppTheme.purple,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _StatBadge(
            value: '4.8',
            label: 'Rating',
            color: AppTheme.gold,
          ),
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClubberCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.grey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Now playing card
// ---------------------------------------------------------------------------

class _NowPlayingCard extends StatelessWidget {
  const _NowPlayingCard({required this.residentArtist});
  final String residentArtist;

  @override
  Widget build(BuildContext context) {
    return ClubberCard(
      pinkAccent: true,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.panelRaised,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.music_note,
                color: AppTheme.grey, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No song currently playing',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tonight with $residentArtist',
                  style: const TextStyle(
                    color: AppTheme.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.graphic_eq, color: AppTheme.pink, size: 20),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Request card
// ---------------------------------------------------------------------------

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, this.onConfirm});
  final SongRequest request;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return ClubberCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.panelRaised,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.music_note,
                color: AppTheme.grey, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.songTitle,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  request.artistName,
                  style: const TextStyle(
                    color: AppTheme.grey,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatSol(request.amountLamports),
                style: const TextStyle(
                  color: AppTheme.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              _StatusBadge(status: request.status),
            ],
          ),
          if (onConfirm != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onConfirm,
              child: const Text('Settle'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final SongRequestStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: status.badgeColor.withValues(alpha: 0.50), width: 1),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fixed bottom "Request a Song" pill button
// ---------------------------------------------------------------------------

class _RequestSongButton extends StatelessWidget {
  const _RequestSongButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.pink, AppTheme.purple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius:
              BorderRadius.circular(AppTheme.radiusButton),
          boxShadow: [
            BoxShadow(
              color: AppTheme.pink.withValues(alpha: 0.40),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Request a Song',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Make Request bottom sheet
// ---------------------------------------------------------------------------

class _MakeRequestSheet extends ConsumerStatefulWidget {
  const _MakeRequestSheet({
    required this.clubId,
    required this.club,
  });

  final String clubId;
  final ClubVenue club;

  @override
  ConsumerState<_MakeRequestSheet> createState() =>
      _MakeRequestSheetState();
}

class _MakeRequestSheetState extends ConsumerState<_MakeRequestSheet> {
  final _offerController = TextEditingController(text: '0.1');
  final _noteController = TextEditingController();
  SpotifyTrack? _selectedTrack;
  bool _isSending = false;
  bool _priorityRequest = false;

  static const _quickAmounts = [0.1, 0.25, 0.5, 1.0];

  @override
  void dispose() {
    _offerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickSong() async {
    final track = await Navigator.push<SpotifyTrack>(
      context,
      MaterialPageRoute<SpotifyTrack>(
        builder: (_) => const SearchSongScreen(),
      ),
    );
    if (track != null) setState(() => _selectedTrack = track);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppTheme.panel,
        borderRadius:
            BorderRadius.all(Radius.circular(AppTheme.radiusCard)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Request a Song',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'To DJ: ${widget.club.residentArtist}',
            style: const TextStyle(color: AppTheme.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          // Song picker
          GestureDetector(
            onTap: _pickSong,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.panelRaised,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusCard),
              ),
              child: _selectedTrack == null
                  ? const Row(
                      children: [
                        Icon(Icons.music_note,
                            color: AppTheme.grey, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Select a song',
                          style: TextStyle(color: AppTheme.grey),
                        ),
                        Spacer(),
                        Icon(Icons.chevron_right,
                            color: AppTheme.grey),
                      ],
                    )
                  : _SelectedTrackRow(
                      track: _selectedTrack!,
                      onClear: () =>
                          setState(() => _selectedTrack = null),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          // SOL amount display
          Center(
            child: Text(
              '${_offerController.text} SOL',
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Quick amount chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _quickAmounts.map((amount) {
              final selected = _offerController.text == '$amount';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _offerController.text = '$amount'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.pink.withValues(alpha: 0.20)
                          : AppTheme.panelRaised,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppTheme.pink
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$amount◎',
                      style: TextStyle(
                        color:
                            selected ? AppTheme.pink : AppTheme.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Note field
          TextField(
            key: const Key('request-note-field'),
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Add a note (optional)',
            ),
          ),
          const SizedBox(height: 16),
          // Priority Request toggle (visual only for MVP)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.panelRaised,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded,
                    color: AppTheme.gold, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority Request',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Move to front of the queue',
                        style: TextStyle(
                          color: AppTheme.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _priorityRequest,
                  onChanged: (v) => setState(() => _priorityRequest = v),
                  activeThumbColor: AppTheme.pink,
                  activeTrackColor: AppTheme.pink.withValues(alpha: 0.40),
                  inactiveTrackColor: AppTheme.panel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Send button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              key: const Key('club-request-submit'),
              onPressed: _isSending
                  ? null
                  : () => _sendRequest(context, widget.club),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white),
                    )
                  : const Text('Send Request'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest(
      BuildContext context, ClubVenue club) async {
    final track = _selectedTrack;
    if (track == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a song first.')),
      );
      return;
    }

    final solAmount =
        double.tryParse(_offerController.text.trim()) ?? 0.0;
    final lamports = (solAmount * 1e9).toInt();
    if (lamports <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount.')),
      );
      return;
    }

    final vmSession =
        ref.read(rootShellViewModelProvider).walletSession;
    if (vmSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please connect your wallet first.')),
      );
      return;
    }

    final djPubkey = club.djWalletAddress;
    final userPubkey = vmSession.publicKeyBase58;
    final escrowService = await ref.read(escrowServiceProvider.future);

    if (escrowService == null) {
      debugPrint('[ClubDetail] escrowService is null (no programId), falling back to local mock');
      _submitLocalMock(
          context, club, track, lamports, userPubkey, djPubkey);
      return;
    }
    debugPrint('[ClubDetail] escrowService available, building TX...');

    // Read all services BEFORE closing bottom sheet (ref becomes invalid after pop)
    final walletService = ref.read(solanaMobileWalletServiceProvider);
    final store = ref.read(clubAppStoreProvider);
    final messenger = ScaffoldMessenger.of(context);

    // Close bottom sheet so MWA signing screen is visible
    Navigator.of(context).pop();

    // Use parent screen's setState if still mounted
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Building transaction...')),
      );

      final escrowPda = await escrowService.deriveEscrowPda(
        userPubkey,
        djPubkey,
        track.id,
      );
      final txBytes = await escrowService.buildCreateRequestTx(
        userPubkey: userPubkey,
        djPubkey: djPubkey,
        trackId: track.id,
        amountLamports: lamports,
      );
      final signedTxBytes = await walletService.signAndSendTransaction(
        vmSession,
        Uint8List.fromList(txBytes),
      );

      if (signedTxBytes == null) {
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Wallet signing cancelled.')),
        );
        return;
      }

      // Send the signed TX to RPC
      messenger.showSnackBar(
        const SnackBar(content: Text('Sending transaction...')),
      );
      final txSig = await escrowService.sendSignedTransaction(
        Uint8List.fromList(signedTxBytes),
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(
              'Request sent! TX: ${txSig.substring(0, 16)}…'),
          duration: const Duration(seconds: 5),
        ),
      );

      store.submitSongRequest(
            clubId: widget.clubId,
            requesterName: 'Guest',
            songTitle: track.name,
            artistName: track.artist,
            amountLamports: lamports,
            trackId: track.id,
            userPubkey: userPubkey,
            djPubkey: djPubkey,
            escrowPda: escrowPda,
            note: _noteController.text.trim(),
          );

      // Bottom sheet already closed before TX signing
    } catch (e, stackTrace) {
      debugPrint('[ClubDetail] TX error: $e');
      debugPrint('[ClubDetail] Stack: $stackTrace');
      if (!mounted) return;
      messenger.showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _submitLocalMock(
    BuildContext context,
    ClubVenue club,
    SpotifyTrack track,
    int lamports,
    String userPubkey,
    String djPubkey,
  ) {
    final result = ref.read(clubAppStoreProvider).submitSongRequest(
          clubId: widget.clubId,
          requesterName: 'Guest',
          songTitle: track.name,
          artistName: track.artist,
          amountLamports: lamports,
          trackId: track.id,
          userPubkey: userPubkey,
          djPubkey: djPubkey,
          note: _noteController.text.trim(),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? '${result.message} (no program deployed — local save)'
              : result.message,
        ),
      ),
    );

    if (result.success && mounted) Navigator.of(context).pop();
  }
}

// ---------------------------------------------------------------------------
// Selected track row (reused in sheet)
// ---------------------------------------------------------------------------

class _SelectedTrackRow extends StatelessWidget {
  const _SelectedTrackRow(
      {required this.track, required this.onClear});

  final SpotifyTrack track;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: track.albumArtUrl != null
              ? Image.network(
                  track.albumArtUrl!,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                track.artist,
                style: const TextStyle(
                    color: AppTheme.grey, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClear,
          icon: const Icon(Icons.close,
              size: 18, color: AppTheme.grey),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      width: 44,
      height: 44,
      color: AppTheme.panelRaised,
      child: const Icon(Icons.music_note,
          color: AppTheme.grey, size: 20),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Plays section (placeholder for MVP)
// ---------------------------------------------------------------------------

class _RecentPlaysSection extends StatelessWidget {
  const _RecentPlaysSection({required this.club});
  final ClubVenue club;

  static const _placeholder = [
    _RecentPlay(title: 'Levels', artist: 'Avicii', duration: '3:19'),
    _RecentPlay(title: 'Get Lucky', artist: 'Daft Punk', duration: '4:07'),
    _RecentPlay(title: 'One More Time', artist: 'Daft Punk', duration: '5:20'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Plays',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        ..._placeholder.map(
          (play) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ClubberCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.panelRaised,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.headphones,
                        color: AppTheme.grey, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          play.title,
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          play.artist,
                          style: const TextStyle(
                            color: AppTheme.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    play.duration,
                    style: const TextStyle(
                      color: AppTheme.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentPlay {
  const _RecentPlay({
    required this.title,
    required this.artist,
    required this.duration,
  });
  final String title;
  final String artist;
  final String duration;
}

// ---------------------------------------------------------------------------
// Status label / color extensions
// ---------------------------------------------------------------------------

extension on SongRequestStatus {
  String get label => switch (this) {
        SongRequestStatus.pending => 'Pending',
        SongRequestStatus.accepted => 'Accepted',
        SongRequestStatus.settled => 'Settled',
        SongRequestStatus.rejected => 'Rejected',
        SongRequestStatus.timedOut => 'Timed Out',
      };

  Color get badgeColor => switch (this) {
        SongRequestStatus.pending => AppTheme.gold,
        SongRequestStatus.accepted => AppTheme.cyan,
        SongRequestStatus.settled => AppTheme.pink,
        SongRequestStatus.rejected => AppTheme.red,
        SongRequestStatus.timedOut => AppTheme.red,
      };
}
