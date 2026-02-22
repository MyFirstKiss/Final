import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_final_66111741/models/incident_report.dart';
import 'package:flutter_final_66111741/models/polling_station.dart';
import 'package:flutter_final_66111741/models/violation_type.dart';
import 'package:flutter_final_66111741/services/firebase_service.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'election_report.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE incident_report ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pending'");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE incident_report ADD COLUMN firebase_doc_id TEXT");
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pending_delete (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          firebase_doc_id TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE polling_station (
        station_id INTEGER PRIMARY KEY,
        station_name TEXT NOT NULL,
        zone TEXT NOT NULL,
        province TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE violation_type (
        type_id INTEGER PRIMARY KEY,
        type_name TEXT NOT NULL,
        severity TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE incident_report (
        report_id INTEGER PRIMARY KEY AUTOINCREMENT,
        station_id INTEGER NOT NULL,
        type_id INTEGER NOT NULL,
        reporter_name TEXT NOT NULL,
        description TEXT NOT NULL,
        evidence_photo TEXT,
        timestamp DATETIME NOT NULL,
        ai_result TEXT,
        ai_confidence REAL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        firebase_doc_id TEXT,
        FOREIGN KEY (station_id) REFERENCES polling_station(station_id),
        FOREIGN KEY (type_id) REFERENCES violation_type(type_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_delete (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_doc_id TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await _insertPollingStations(db);
    await _insertViolationTypes(db);
  }

  Future<void> _insertPollingStations(Database db) async {
    final stations = [
      {'station_id': 101, 'station_name': 'โรงเรียนวัดพระมหาธาตุ', 'zone': 'เขต 1', 'province': 'กรุงเทพมหานคร'},
      {'station_id': 102, 'station_name': 'เต็นท์หน้าตลาดท่าวัง', 'zone': 'เขต 2', 'province': 'กรุงเทพมหานคร'},
      {'station_id': 103, 'station_name': 'ศาลากลางหมู่บ้านคีรีวง', 'zone': 'เขต 3', 'province': 'กรุงเทพมหานคร'},
      {'station_id': 104, 'station_name': 'โรงเรียนสวนกุหลาบวิทยาลัย', 'zone': 'เขต 4', 'province': 'นนทบุรี'},
      {'station_id': 105, 'station_name': 'วิทยาลัยอภัยภูเบศร', 'zone': 'เขต 5', 'province': 'นนทบุรี'},
    ];
    for (var s in stations) {
      await db.insert('polling_station', s);
    }
  }

  Future<void> _insertViolationTypes(Database db) async {
    final types = [
      {'type_id': 1, 'type_name': 'ซื้อสิทธิ์ขายเสียง', 'severity': 'High'},
      {'type_id': 2, 'type_name': 'ขนคนไปลงคะแนน', 'severity': 'High'},
      {'type_id': 3, 'type_name': 'หาเสียงเกินเวลา', 'severity': 'Medium'},
      {'type_id': 4, 'type_name': 'การกลั่นแกล้งผู้สมัคร', 'severity': 'Medium'},
      {'type_id': 5, 'type_name': 'ละเมิดสิทธิ์ผู้เลือกตั้ง', 'severity': 'High'},
      {'type_id': 6, 'type_name': 'แจกสิ่งของ', 'severity': 'Medium'},
    ];
    for (var v in types) {
      await db.insert('violation_type', v);
    }
  }

  Future<void> init() async {
    await database;
  }

  Future<List<PollingStation>> getPollingStations() async {
    final db = await database;
    final maps = await db.query('polling_station');
    return List.generate(maps.length, (i) {
      return PollingStation(
        stationId: maps[i]['station_id'] as int,
        stationName: maps[i]['station_name'] as String,
        zone: maps[i]['zone'] as String,
        province: maps[i]['province'] as String,
      );
    });
  }

  Future<List<ViolationType>> getViolationTypes() async {
    final db = await database;
    final maps = await db.query('violation_type');
    return List.generate(maps.length, (i) {
      return ViolationType(
        typeId: maps[i]['type_id'] as int,
        typeName: maps[i]['type_name'] as String,
        severity: maps[i]['severity'] as String,
      );
    });
  }

  Future<int> insertIncidentReport(IncidentReport report, {String syncStatus = 'pending'}) async {
    final db = await database;
    return await db.insert('incident_report', {
      'station_id': report.stationId,
      'type_id': report.typeId,
      'reporter_name': report.reporterName,
      'description': report.description,
      'evidence_photo': report.evidencePhoto,
      'timestamp': report.timestamp.toIso8601String(),
      'ai_result': report.aiResult,
      'ai_confidence': report.aiConfidence,
      'sync_status': syncStatus,
    });
  }

  Future<Map<String, dynamic>> insertIncidentReportWithSync(IncidentReport report) async {
    final reportId = await insertIncidentReport(report);
    final result = <String, dynamic>{
      'success': true,
      'reportId': reportId,
      'offline': true,
      'online': false,
      'errors': <String>[],
    };

    try {
      final firebaseService = FirebaseService();
      if (!firebaseService.isInitialized) {
        await firebaseService.initialize();
      }
      if (firebaseService.isInitialized) {
        String? docId;
        try {
          docId = await firebaseService.uploadIncidentReport(report);
        } catch (e) {
          (result['errors'] as List<String>).add('Firebase upload failed: $e');
        }

        if (docId != null) {
          result['firebaseId'] = docId;
          result['online'] = true;
          try {
            final db = await database;
            await db.update(
              'incident_report',
              {'sync_status': 'synced', 'firebase_doc_id': docId},
              where: 'report_id = ?',
              whereArgs: [reportId],
            );
          } catch (e) {
            (result['errors'] as List<String>).add('Failed to update local sync status: $e');
          }
        }
      }
    } catch (e) {
      (result['errors'] as List<String>).add('Firebase sync failed: $e');
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedReports() async {
    final db = await database;
    return await db.query(
      'incident_report',
      where: "sync_status = 'pending'",
    );
  }

  Future<Map<String, dynamic>> syncPendingReports() async {
    int synced = 0;
    int failed = 0;

    bool hasInternet = false;
    try {
      final lookup = await InternetAddress.lookup('google.com');
      hasInternet = lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      hasInternet = false;
    }

    if (!hasInternet) {
      return {'synced': 0, 'failed': 0, 'message': 'ไม่มีอินเทอร์เน็ต'};
    }

    try {
      final firebaseService = FirebaseService();
      if (!firebaseService.isInitialized) {
        await firebaseService.initialize();
      }
      if (!firebaseService.isInitialized) {
        return {'synced': 0, 'failed': 0, 'message': 'Firebase ยังไม่พร้อม'};
      }

      final unsyncedList = await getUnsyncedReports();
      final db = await database;

      for (final row in unsyncedList) {
        try {
          final report = IncidentReport(
            reportId: row['report_id'] as int?,
            stationId: row['station_id'] as int,
            typeId: row['type_id'] as int,
            reporterName: row['reporter_name'] as String,
            description: row['description'] as String,
            evidencePhoto: row['evidence_photo'] as String?,
            timestamp: DateTime.parse(row['timestamp'] as String),
            aiResult: row['ai_result'] as String?,
            aiConfidence: row['ai_confidence'] as double?,
          );

          final docId = await firebaseService.uploadIncidentReport(report);
          await db.update(
            'incident_report',
            {'sync_status': 'synced', 'firebase_doc_id': docId},
            where: 'report_id = ?',
            whereArgs: [row['report_id']],
          );
          synced++;
        } catch (_) {
          failed++;
        }
      }
    } catch (_) {}

    final deleteResult = await syncPendingDeletes();

    return {
      'synced': synced,
      'failed': failed,
      'deleted': deleteResult['deleted'],
      'message': synced > 0 ? 'Sync สำเร็จ $synced รายการ' : 'ไม่มีรายการที่ต้อง Sync',
    };
  }

  Future<Map<String, dynamic>> syncPendingDeletes() async {
    int deleted = 0;
    int failed = 0;

    bool hasInternet = false;
    try {
      final lookup = await InternetAddress.lookup('google.com');
      hasInternet = lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      hasInternet = false;
    }

    if (!hasInternet) {
      return {'deleted': 0, 'failed': 0, 'message': 'ไม่มีอินเทอร์เน็ต'};
    }

    try {
      final firebaseService = FirebaseService();
      if (!firebaseService.isInitialized) {
        await firebaseService.initialize();
      }
      if (!firebaseService.isInitialized) {
        return {'deleted': 0, 'failed': 0, 'message': 'Firebase ยังไม่พร้อม'};
      }

      final db = await database;
      final pendingDeletes = await db.query('pending_delete');

      for (final row in pendingDeletes) {
        try {
          final docId = row['firebase_doc_id'] as String;
          await firebaseService.deleteIncidentReport(docId);
          await db.delete('pending_delete', where: 'id = ?', whereArgs: [row['id']]);
          deleted++;
        } catch (_) {
          failed++;
        }
      }
    } catch (_) {}

    return {
      'deleted': deleted,
      'failed': failed,
      'message': deleted > 0 ? 'ลบจาก Firebase สำเร็จ $deleted รายการ' : 'ไม่มีรายการรอลบ',
    };
  }

  Future<List<IncidentReport>> getIncidentReports() async {
    final db = await database;
    final maps = await db.query('incident_report');
    return List.generate(maps.length, (i) {
      return IncidentReport(
        reportId: maps[i]['report_id'] as int?,
        stationId: maps[i]['station_id'] as int,
        typeId: maps[i]['type_id'] as int,
        reporterName: maps[i]['reporter_name'] as String,
        description: maps[i]['description'] as String,
        evidencePhoto: maps[i]['evidence_photo'] as String?,
        timestamp: DateTime.parse(maps[i]['timestamp'] as String),
        aiResult: maps[i]['ai_result'] as String?,
        aiConfidence: maps[i]['ai_confidence'] as double?,
      );
    });
  }

  Future<int> getTotalIncidentReports() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM incident_report');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> updatePollingStation(int stationId, {required String stationName, required String zone, required String province}) async {
    final db = await database;
    return await db.update(
      'polling_station',
      {'station_name': stationName, 'zone': zone, 'province': province},
      where: 'station_id = ?',
      whereArgs: [stationId],
    );
  }

  Future<bool> isStationNameDuplicate(String stationName, int excludeStationId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM polling_station WHERE station_name = ? AND station_id != ?',
      [stationName, excludeStationId],
    );
    return ((result.first['count'] as int?) ?? 0) > 0;
  }

  Future<int> getIncidentCountByStation(int stationId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM incident_report WHERE station_id = ?',
      [stationId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> deleteIncidentReport(int reportId) async {
    final db = await database;
    return await db.delete(
      'incident_report',
      where: 'report_id = ?',
      whereArgs: [reportId],
    );
  }

  Future<Map<String, dynamic>> deleteIncidentReportWithSync(int reportId) async {
    final db = await database;

    final rows = await db.query(
      'incident_report',
      columns: ['firebase_doc_id'],
      where: 'report_id = ?',
      whereArgs: [reportId],
    );
    final firebaseDocId = rows.isNotEmpty ? rows.first['firebase_doc_id'] as String? : null;

    await db.delete('incident_report', where: 'report_id = ?', whereArgs: [reportId]);

    if (firebaseDocId == null || firebaseDocId.isEmpty) {
      return {'success': true, 'online': false, 'message': 'ลบจาก SQLite เรียบร้อย (ไม่มีข้อมูลบน Firebase)'};
    }

    try {
      final firebaseService = FirebaseService();
      if (!firebaseService.isInitialized) {
        await firebaseService.initialize();
      }
      await firebaseService.deleteIncidentReport(firebaseDocId);
      await syncPendingDeletes();
      return {'success': true, 'online': true, 'message': 'ลบจาก SQLite และ Firebase เรียบร้อย'};
    } catch (e) {
      await db.insert('pending_delete', {
        'firebase_doc_id': firebaseDocId,
        'created_at': DateTime.now().toIso8601String(),
      });
      return {'success': true, 'online': false, 'message': 'ลบจาก SQLite แล้ว จะลบจาก Firebase เมื่อออนไลน์'};
    }
  }

  Future<List<Map<String, dynamic>>> getIncidentReportsJoined() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT ir.*, ps.station_name, vt.type_name
      FROM incident_report ir
      LEFT JOIN polling_station ps ON ir.station_id = ps.station_id
      LEFT JOIN violation_type vt ON ir.type_id = vt.type_id
      ORDER BY ir.report_id DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getTop3PollingStations() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT ps.station_id, ps.station_name, ps.zone, ps.province,
             COUNT(ir.report_id) as complaint_count
      FROM polling_station ps
      LEFT JOIN incident_report ir ON ps.station_id = ir.station_id
      GROUP BY ps.station_id, ps.station_name, ps.zone, ps.province
      ORDER BY complaint_count DESC
      LIMIT 3
    ''');
  }

  Future<List<Map<String, dynamic>>> searchIncidentReports({
    String? keyword,
    String? severity,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (keyword != null && keyword.trim().isNotEmpty) {
      conditions.add('(ir.reporter_name LIKE ? OR ir.description LIKE ?)');
      final pattern = '%${keyword.trim()}%';
      args.add(pattern);
      args.add(pattern);
    }

    if (severity != null && severity.isNotEmpty) {
      conditions.add('vt.severity = ?');
      args.add(severity);
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    return await db.rawQuery('''
      SELECT ir.*, ps.station_name, vt.type_name, vt.severity
      FROM incident_report ir
      LEFT JOIN polling_station ps ON ir.station_id = ps.station_id
      LEFT JOIN violation_type vt ON ir.type_id = vt.type_id
      $whereClause
      ORDER BY ir.report_id DESC
    ''', args);
  }
}
