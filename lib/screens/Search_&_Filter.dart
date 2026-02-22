import 'package:flutter/material.dart';
import 'package:flutter_final_66111741/database/database_helper.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  String? _selectedSeverity;

  static const List<String> _severityOptions = ['High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    try {
      final keyword = _searchController.text.trim();
      final results = await DatabaseHelper.instance.searchIncidentReports(
        keyword: keyword.isNotEmpty ? keyword : null,
        severity: _selectedSeverity,
      );
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ค้นหา & กรอง', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อผู้แจ้งหรือรายละเอียด...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _performSearch(),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedSeverity,
              decoration: InputDecoration(
                labelText: 'กรองตามความรุนแรง (Severity)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.filter_list),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('ทั้งหมด'),
                ),
                ..._severityOptions.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s),
                )),
              ],
              onChanged: (value) {
                setState(() => _selectedSeverity = value);
                _performSearch();
              },
            ),
            const SizedBox(height: 24),

            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'ผลลัพธ์: ${_results.length} รายการ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
              ),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'No records found',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ไม่พบข้อมูลที่ตรงกับเงื่อนไขการค้นหา',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final r = _results[index];
                  final stationName = r['station_name'] as String? ?? 'ไม่ทราบ';
                  final typeName = r['type_name'] as String? ?? 'ไม่ทราบ';
                  final severity = r['severity'] as String? ?? '-';
                  final reporterName = r['reporter_name'] as String;
                  final description = r['description'] as String;
                  final timestamp = r['timestamp'] as String;
                  final displayTime = timestamp.split('.')[0];

                  Color severityColor;
                  switch (severity) {
                    case 'High':
                      severityColor = Colors.red;
                      break;
                    case 'Medium':
                      severityColor = Colors.orange;
                      break;
                    default:
                      severityColor = Colors.green;
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('รายงาน #${r['report_id']}',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: severityColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(severity,
                                  style: TextStyle(color: severityColor, fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('หน่วยเลือกตั้ง: $stationName'),
                          Text('ประเภทความผิด: $typeName'),
                          Text('ผู้แจ้ง: $reporterName'),
                          Text('เวลา: $displayTime'),
                          const SizedBox(height: 8),
                          Text(description, maxLines: 3, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
