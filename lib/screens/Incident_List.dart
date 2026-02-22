import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_final_66111741/database/database_helper.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final reports = await DatabaseHelper.instance.getIncidentReportsJoined();
      setState(() {
        _reports = List<Map<String, dynamic>>.from(reports);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete(int reportId, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบรายการแจ้งเหตุนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await DatabaseHelper.instance.deleteIncidentReportWithSync(reportId);
      setState(() {
        _reports.removeAt(index);
      });
      if (mounted) {
        final message = result['message'] as String? ?? 'ลบรายการแจ้งเหตุเรียบร้อยแล้ว';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? Center(
                  child: Text('ไม่มีรายการเหตุการณ์',
                      style: TextStyle(color: Colors.grey[600])))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final r = _reports[index];
                    final reportId = r['report_id'] as int;
                    final stationName = r['station_name'] as String? ?? 'ไม่ทราบ';
                    final typeName = r['type_name'] as String? ?? 'ไม่ทราบ';
                    final reporterName = r['reporter_name'] as String;
                    final description = r['description'] as String;
                    final timestamp = r['timestamp'] as String;
                    final evidencePhoto = r['evidence_photo'] as String?;
                    final displayTime = timestamp.split('.')[0];

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (evidencePhoto != null &&
                                evidencePhoto.isNotEmpty &&
                                File(evidencePhoto).existsSync())
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(evidencePhoto),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.grey),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.image_not_supported,
                                    color: Colors.grey),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'รายงาน #$reportId',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('หน่วยเลือกตั้ง: $stationName'),
                                  Text('ประเภทความผิด: $typeName'),
                                  Text('ผู้แจ้ง: $reporterName'),
                                  Text('เวลา: $displayTime'),
                                  const SizedBox(height: 4),
                                  Text(description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'ลบรายการ',
                              onPressed: () =>
                                  _confirmDelete(reportId, index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadReports,
        tooltip: 'รีเฟรช',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
