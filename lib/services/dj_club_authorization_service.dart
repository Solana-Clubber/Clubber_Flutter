import '../models/models.dart';

class DjClubAuthorizationResult {
  const DjClubAuthorizationResult({
    required this.isAuthorized,
    required this.statusLabel,
    required this.detail,
  });

  final bool isAuthorized;
  final String statusLabel;
  final String detail;
}

abstract class DjClubAuthorizationService {
  Future<DjClubAuthorizationResult> authorizeDj({
    required WalletSession session,
    required String djName,
    required String clubId,
  });
}

class MockDjClubAuthorizationService implements DjClubAuthorizationService {
  const MockDjClubAuthorizationService();

  static const Map<String, String> _authorizedClubNotes = {
    'club-axis-seoul': 'Axis Seoul mock roster matched this connected wallet.',
    'club-signal-hannam':
        'Signal Hannam mock roster matched this connected wallet.',
  };

  @override
  Future<DjClubAuthorizationResult> authorizeDj({
    required WalletSession session,
    required String djName,
    required String clubId,
  }) async {
    final normalizedName = djName.trim();
    if (normalizedName.length < 2) {
      return const DjClubAuthorizationResult(
        isAuthorized: false,
        statusLabel: 'Name required',
        detail: 'DJ 이름은 최소 두 글자 이상이어야 합니다.',
      );
    }

    final note = _authorizedClubNotes[clubId];
    if (note == null) {
      return const DjClubAuthorizationResult(
        isAuthorized: false,
        statusLabel: 'Mock auth denied',
        detail: '이 클럽은 현재 mock DJ roster에 등록되어 있지 않습니다.',
      );
    }

    return DjClubAuthorizationResult(
      isAuthorized: true,
      statusLabel: 'Mock club auth approved',
      detail: '$note DJ: $normalizedName',
    );
  }
}
