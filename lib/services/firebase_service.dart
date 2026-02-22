import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_final_66111741/models/incident_report.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  late FirebaseFirestore _firestore;
  bool _isInitialized = false;

  FirebaseService._internal();
  factory FirebaseService() => _instance;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await Firebase.initializeApp();
      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Firebase: $e');
    }
  }

  bool get isInitialized => _isInitialized;

  Future<String?> uploadIncidentReport(IncidentReport report) async {
    if (!_isInitialized) throw Exception('Firebase not initialized');

    try {
      String? photoValue;
      if (report.evidencePhoto != null) {
        photoValue = _isLocalPath(report.evidencePhoto!) ? 'OFFLINE_ONLY' : report.evidencePhoto;
      }

      final data = {
        'station_id': report.stationId,
        'type_id': report.typeId,
        'reporter_name': report.reporterName,
        'description': report.description,
        'evidence_photo': photoValue,
        'timestamp': Timestamp.fromDate(report.timestamp),
        'ai_result': report.aiResult,
        'ai_confidence': report.aiConfidence,
        'sync_status': 'synced',
        'created_at': Timestamp.now(),
      };

      final docRef = await _firestore.collection('incident_reports').add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to upload report: $e');
    }
  }

  bool _isLocalPath(String path) {
    if (RegExp(r'^[a-zA-Z]:\\').hasMatch(path)) {
      return true;
    }
    if (path.startsWith('/')) {
      return true;
    }
    if (path.contains('file://') || path.contains('/data/') ||
        path.contains('/storage/') || path.contains(r'C:\') ||
        path.contains(r'D:\')) {
      return true;
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> getIncidentReports({int limit = 50}) async {
    if (!_isInitialized) throw Exception('Firebase not initialized');
    try {
      final snapshot = await _firestore
          .collection('incident_reports')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get reports: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getReportsByStation(int stationId) async {
    if (!_isInitialized) throw Exception('Firebase not initialized');
    try {
      final snapshot = await _firestore
          .collection('incident_reports')
          .where('station_id', isEqualTo: stationId)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get reports by station: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getReportsByViolationType(int typeId) async {
    if (!_isInitialized) throw Exception('Firebase not initialized');
    try {
      final snapshot = await _firestore
          .collection('incident_reports')
          .where('type_id', isEqualTo: typeId)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get reports by type: $e');
    }
  }

  Future<void> updateIncidentReport(String docId, Map<String, dynamic> updates) async {
    if (!_isInitialized) throw Exception('Firebase not initialized');
    try {
      await _firestore.collection('incident_reports').doc(docId).update(updates);
    } catch (e) {
      throw Exception('Failed to update report: $e');
    }
  }

  Future<void> deleteIncidentReport(String docId) async {
    if (!_isInitialized) throw Exception('Firebase not initialized');
    try {
      await _firestore.collection('incident_reports').doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    if (!_isInitialized) throw Exception('Firebase not initialized');
    try {
      final snapshot = await _firestore.collection('incident_reports').get();
      final docs = snapshot.docs;

      final violationCounts = <int, int>{};
      final stationCounts = <int, int>{};
      for (var doc in docs) {
        final typeId = doc.data()['type_id'] as int;
        final stationId = doc.data()['station_id'] as int;
        violationCounts[typeId] = (violationCounts[typeId] ?? 0) + 1;
        stationCounts[stationId] = (stationCounts[stationId] ?? 0) + 1;
      }

      return {
        'total_reports': docs.length,
        'by_violation_type': violationCounts,
        'by_station': stationCounts,
      };
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }
}
