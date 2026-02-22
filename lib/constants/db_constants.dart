class DbConstants {
  DbConstants._();

  static const String dbName = 'election_incident.db';
  static const int dbVersion = 1;

  static const String pollingStationTable = 'polling_station';
  static const String stationId = 'station_id';
  static const String stationName = 'station_name';
  static const String zone = 'zone';
  static const String province = 'province';

  static const String violationTypeTable = 'violation_type';
  static const String typeId = 'type_id';
  static const String typeName = 'type_name';
  static const String severity = 'severity';

  static const String incidentReportTable = 'incident_report';
  static const String reportId = 'report_id';
  static const String reporterName = 'reporter_name';
  static const String description = 'description';
  static const String evidencePhoto = 'evidence_photo';
  static const String timestamp = 'timestamp';
  static const String aiResult = 'ai_result';
  static const String aiConfidence = 'ai_confidence';

  static const String createPollingStationTable = '''
    CREATE TABLE $pollingStationTable (
      $stationId INTEGER PRIMARY KEY,
      $stationName TEXT NOT NULL,
      $zone TEXT NOT NULL,
      $province TEXT NOT NULL
    )
  ''';

  static const String createViolationTypeTable = '''
    CREATE TABLE $violationTypeTable (
      $typeId INTEGER PRIMARY KEY,
      $typeName TEXT NOT NULL,
      $severity TEXT NOT NULL
    )
  ''';

  static const String createIncidentReportTable = '''
    CREATE TABLE $incidentReportTable (
      $reportId INTEGER PRIMARY KEY AUTOINCREMENT,
      $stationId INTEGER NOT NULL,
      $typeId INTEGER NOT NULL,
      $reporterName TEXT NOT NULL,
      $description TEXT NOT NULL,
      $evidencePhoto TEXT,
      $timestamp TEXT NOT NULL,
      $aiResult TEXT,
      $aiConfidence REAL,
      FOREIGN KEY ($stationId) REFERENCES $pollingStationTable($stationId),
      FOREIGN KEY ($typeId) REFERENCES $violationTypeTable($typeId)
    )
  ''';
}
