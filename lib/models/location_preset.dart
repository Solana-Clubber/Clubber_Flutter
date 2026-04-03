class LocationPreset {
  const LocationPreset({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.updatedAt,
  });

  final String id;
  final String label;
  final String subtitle;
  final double latitude;
  final double longitude;
  final int accuracyMeters;
  final DateTime updatedAt;
}
