import 'package:flutter/material.dart';
import 'package:flutter_final_66111741/database/database_helper.dart';
import 'package:flutter_final_66111741/models/polling_station.dart';

class EditPollingStationScreen extends StatefulWidget {
  const EditPollingStationScreen({super.key});

  @override
  State<EditPollingStationScreen> createState() => _EditPollingStationScreenState();
}

class _EditPollingStationScreenState extends State<EditPollingStationScreen> {
  List<PollingStation> _stations = [];
  bool _isLoading = true;

  PollingStation? _editingStation;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _zoneController = TextEditingController();
  final _provinceController = TextEditingController();
  bool _isSaving = false;

  static const List<String> _allowedPrefixes = [
    'โรงเรียน', 'วัด', 'เต็นท์', 'ศาลา', 'หอประชุม',
  ];

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _zoneController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  Future<void> _loadStations() async {
    try {
      final stations = await DatabaseHelper.instance.getPollingStations();
      setState(() { _stations = stations; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _selectStation(PollingStation station) {
    setState(() {
      _editingStation = station;
      _nameController.text = station.stationName;
      _zoneController.text = station.zone;
      _provinceController.text = station.province;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingStation = null;
      _nameController.clear();
      _zoneController.clear();
      _provinceController.clear();
    });
  }

  bool _isValidPrefix(String name) {
    return _allowedPrefixes.any((p) => name.startsWith(p));
  }

  Future<void> _saveStation() async {
    if (!_formKey.currentState!.validate()) return;

    final station = _editingStation!;
    final newName = _nameController.text.trim();
    final newZone = _zoneController.text.trim();
    final newProvince = _provinceController.text.trim();

    if (!_isValidPrefix(newName)) {
      _showErrorDialog(
        'รูปแบบชื่อไม่ถูกต้อง',
        'ชื่อหน่วยเลือกตั้งต้องขึ้นต้นด้วยคำต่อไปนี้:\n'
        '• โรงเรียน\n• วัด\n• เต็นท์\n• ศาลา\n• หอประชุม\n\n'
        'กรุณาแก้ไขชื่อหน่วยให้ถูกต้อง',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final isDuplicate = await DatabaseHelper.instance.isStationNameDuplicate(newName, station.stationId);
      if (isDuplicate) {
        setState(() => _isSaving = false);
        _showErrorDialog('ชื่อหน่วยซ้ำ', 'ชื่อ "$newName" มีอยู่แล้วในระบบ\nกรุณาใช้ชื่ออื่น');
        return;
      }

      final incidentCount = await DatabaseHelper.instance.getIncidentCountByStation(station.stationId);

      if (incidentCount > 0) {
        setState(() => _isSaving = false);
        final confirmed = await _showConfirmDialog(incidentCount);
        if (confirmed != true) return;
        setState(() => _isSaving = true);
      }

      await DatabaseHelper.instance.updatePollingStation(
        station.stationId,
        stationName: newName, zone: newZone, province: newProvince,
      );

      final updated = await DatabaseHelper.instance.getPollingStations();
      setState(() {
        _stations = updated;
        _editingStation = null;
        _nameController.clear();
        _zoneController.clear();
        _provinceController.clear();
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ]),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('ตกลง')),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(int count) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          const Expanded(child: Text('มีประวัติร้องเรียน')),
        ]),
        content: Text('หน่วยนี้มีประวัติร้องเรียน $count เรื่อง\nยืนยันการแก้ไขข้อมูลหรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('ยืนยัน')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _editingStation != null ? _buildEditForm() : _buildStationList(),
    );
  }

  Widget _buildStationList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('จัดการหน่วยเลือกตั้ง', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('เลือกหน่วยที่ต้องการแก้ไข',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_stations.isEmpty)
            const Center(child: Text('ไม่มีข้อมูลหน่วยเลือกตั้ง'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final station = _stations[index];
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _selectStation(station),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${station.stationId} - ${station.stationName}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('เขต: ${station.zone}'),
                          Text('จังหวัด: ${station.province}'),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _selectStation(station),
                                icon: const Icon(Icons.edit),
                                label: const Text('แก้ไข'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    final station = _editingStation!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              IconButton(onPressed: _cancelEditing, icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 8),
              Expanded(child: Text('แก้ไขหน่วยเลือกตั้ง', style: Theme.of(context).textTheme.titleLarge)),
            ]),
            const SizedBox(height: 8),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('รหัสหน่วย: ${station.stationId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'ชื่อหน่วยเลือกตั้ง',
                hintText: 'เช่น โรงเรียน..., วัด..., เต็นท์...',
                border: const OutlineInputBorder(),
                helperText: 'ต้องขึ้นต้นด้วย: โรงเรียน, วัด, เต็นท์, ศาลา, หอประชุม',
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.location_city),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'กรุณากรอกชื่อหน่วยเลือกตั้ง' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _zoneController,
              decoration: const InputDecoration(
                labelText: 'เขต', border: OutlineInputBorder(), prefixIcon: Icon(Icons.map),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'กรุณากรอกเขต' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _provinceController,
              decoration: const InputDecoration(
                labelText: 'จังหวัด', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'กรุณากรอกจังหวัด' : null,
            ),
            const SizedBox(height: 24),

            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _cancelEditing,
                  child: const Text('ยกเลิก'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveStation,
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึก'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
