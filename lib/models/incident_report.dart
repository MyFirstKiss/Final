class IncidentReport {
  IncidentReport({
    this.reportId,
    required this.stationId,
    required this.typeId,
    required this.reporterName,
    required this.description,
    this.evidencePhoto,
    required this.timestamp,
    this.aiResult,
    this.aiConfidence,
  });

  final int? reportId;
  final int stationId;
  final int typeId;
  final String reporterName;
  final String description;
  final String? evidencePhoto;
  final DateTime timestamp;
  final String? aiResult;
  final double? aiConfidence;
}
