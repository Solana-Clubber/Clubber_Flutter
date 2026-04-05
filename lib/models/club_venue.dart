class ClubVenue {
  const ClubVenue({
    required this.id,
    required this.name,
    required this.neighborhood,
    required this.musicStyle,
    required this.heroTagline,
    required this.vibe,
    required this.distanceMeters,
    required this.walkingMinutes,
    required this.crowdLevel,
    required this.queueEtaMinutes,
    required this.mapPositionX,
    required this.mapPositionY,
    required this.residentArtist,
    required this.liveSignalSummary,
    this.djWalletAddress = '',
    this.spotlightMoments = const <String>[],
    this.amenities = const <String>[],
    this.tags = const <String>[],
  });

  final String id;
  final String name;
  final String neighborhood;
  final String musicStyle;
  final String heroTagline;
  final String vibe;
  final int distanceMeters;
  final int walkingMinutes;
  final int crowdLevel;
  final int queueEtaMinutes;
  final double mapPositionX;
  final double mapPositionY;
  final String residentArtist;
  final String liveSignalSummary;
  final String djWalletAddress;
  final List<String> spotlightMoments;
  final List<String> amenities;
  final List<String> tags;

  ClubVenue copyWith({
    String? id,
    String? name,
    String? neighborhood,
    String? musicStyle,
    String? heroTagline,
    String? vibe,
    int? distanceMeters,
    int? walkingMinutes,
    int? crowdLevel,
    int? queueEtaMinutes,
    double? mapPositionX,
    double? mapPositionY,
    String? residentArtist,
    String? liveSignalSummary,
    String? djWalletAddress,
    List<String>? spotlightMoments,
    List<String>? amenities,
    List<String>? tags,
  }) {
    return ClubVenue(
      id: id ?? this.id,
      name: name ?? this.name,
      neighborhood: neighborhood ?? this.neighborhood,
      musicStyle: musicStyle ?? this.musicStyle,
      heroTagline: heroTagline ?? this.heroTagline,
      vibe: vibe ?? this.vibe,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      walkingMinutes: walkingMinutes ?? this.walkingMinutes,
      crowdLevel: crowdLevel ?? this.crowdLevel,
      queueEtaMinutes: queueEtaMinutes ?? this.queueEtaMinutes,
      mapPositionX: mapPositionX ?? this.mapPositionX,
      mapPositionY: mapPositionY ?? this.mapPositionY,
      residentArtist: residentArtist ?? this.residentArtist,
      liveSignalSummary: liveSignalSummary ?? this.liveSignalSummary,
      djWalletAddress: djWalletAddress ?? this.djWalletAddress,
      spotlightMoments: spotlightMoments ?? this.spotlightMoments,
      amenities: amenities ?? this.amenities,
      tags: tags ?? this.tags,
    );
  }
}
