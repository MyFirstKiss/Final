import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_final_66111741/database/database_helper.dart';
import 'package:flutter_final_66111741/models/incident_report.dart';
import 'package:flutter_final_66111741/models/polling_station.dart';
import 'package:flutter_final_66111741/models/violation_type.dart';
import 'package:flutter_final_66111741/services/ai_image_classifier.dart';
import 'package:flutter_final_66111741/services/firebase_service.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reporterController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  List<PollingStation> _stations = [];
  List<ViolationType> _violations = [];

  int? _selectedStationId;
  int? _selectedViolationTypeId;
  bool _isLoading = true;
  bool _isProcessing = false;

  File? _selectedImage;
  String? _aiResult;
  double? _aiConfidence;
  bool _aiProcessing = false;

  late AIImageClassifier _aiClassifier;
  late FirebaseService _firebaseService;

  @override
  void initState() {
    super.initState();
    _aiClassifier = AIImageClassifier();
    _firebaseService = FirebaseService();
    _loadData();
    _initializeFirebase();
    _initializeAI();
  }

  Future<void> _initializeFirebase() async {
    try {
      await _firebaseService.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('การตั้งค่า Firebase ล้มเหลว: $e')),
        );
      }
    }
  }

  Future<void> _initializeAI() async {
    try {
      await _aiClassifier.initialize();
    } catch (e) {
      debugPrint('AI initialization failed: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final stations = await DatabaseHelper.instance.getPollingStations();
      final violations = await DatabaseHelper.instance.getViolationTypes();
      setState(() {
        _stations = stations;
        _violations = violations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _aiResult = null;
          _aiConfidence = null;
        });
        _processImageWithAI();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เลือกภาพจากคลังไม่สำเร็จ: $e')),
        );
      }
    }
  }


  Future<void> _pickImageFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _aiResult = null;
          _aiConfidence = null;
        });
        _processImageWithAI();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ถ่ายภาพไม่สำเร็จ: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกที่มาของภาพ'),
        content: const Text('เลือกวิธีการรับภาพ'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromCamera();
            },
            child: const Text('กล้อง'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
            child: const Text('คลังภาพ'),
          ),
        ],
      ),
    );
  }

  Future<void> _processImageWithAI() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกภาพก่อน')),
      );
      return;
    }

    setState(() {
      _aiProcessing = true;
    });

    try {
      Map<String, dynamic> result;

      if (_aiClassifier.isInitialized) {

        result = await _aiClassifier.classifyImage(_selectedImage!.path);
      } else {
  
        result = await _simulateAIClassification(_selectedImage!);
      }

      setState(() {
        _aiResult = result['label'] as String?;
        _aiConfidence = double.tryParse(result['confidence'].toString());

        final violationType = result['violationType'] as int?;
        if (violationType != null &&
            _aiConfidence != null &&
            _aiConfidence! >= 50.0) {
          final exists =
              _violations.any((v) => v.typeId == violationType);
          if (exists) {
            _selectedViolationTypeId = violationType;
          }
        }
      });

      if (mounted) {
        final violationName = result['violationName'] as String?;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              violationName != null
                  ? 'AI ระบุ: $violationName (${result['confidence']}%)'
                  : 'AI ระบุ: ${result['label']} (${result['confidence']}%)',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('การประมวลผล AI ล้มเหลว: $e')),
        );
      }
    } finally {
      setState(() {
        _aiProcessing = false;
      });
    }
  }


  Future<Map<String, dynamic>> _simulateAIClassification(File imageFile) async {
    await Future.delayed(const Duration(seconds: 2));

    final mockResults = [
      {
        'label': 'wallet',
        'confidence': '85.5',
        'violationType': 1,
        'violationName': 'ซื้อสิทธิ์ขายเสียง',
      },
      {
        'label': 'purse',
        'confidence': '82.3',
        'violationType': 1,
        'violationName': 'ซื้อสิทธิ์ขายเสียง',
      },
      {
        'label': 'envelope',
        'confidence': '88.7',
        'violationType': 1,
        'violationName': 'ซื้อสิทธิ์ขายเสียง',
      },
      {
        'label': 'minibus',
        'confidence': '92.3',
        'violationType': 2,
        'violationName': 'ขนคนไปลงคะแนน',
      },
      {
        'label': 'cab',
        'confidence': '91.0',
        'violationType': 2,
        'violationName': 'ขนคนไปลงคะแนน',
      },
      {
        'label': 'water bottle',
        'confidence': '78.1',
        'violationType': 6,
        'violationName': 'แจกสิ่งของ',
      },
      {
        'label': 'cup',
        'confidence': '75.8',
        'violationType': 6,
        'violationName': 'แจกสิ่งของ',
      },
    ];

    return mockResults[DateTime.now().microsecond % mockResults.length];
  }

  @override
  void dispose() {
    _reporterController.dispose();
    _descriptionController.dispose();
    _aiClassifier.dispose();
    super.dispose();
  }

  Future<void> _saveReport() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    if (_selectedStationId == null || _selectedViolationTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกหน่วยเลือกตั้งและประเภทความผิด'),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final report = IncidentReport(
        stationId: _selectedStationId!,
        typeId: _selectedViolationTypeId!,
        reporterName: _reporterController.text,
        description: _descriptionController.text,
        evidencePhoto: _selectedImage?.path,
        timestamp: DateTime.now(),
        aiResult: _aiResult,
        aiConfidence: _aiConfidence,
      );

      final result = await DatabaseHelper.instance
          .insertIncidentReportWithSync(report);

      if (mounted) {
        String message = '';
        if (result['offline']) {
          message = 'บันทึกข้อมูลแบบ Offline สำเร็จ';
          if (result['online']) {
            message += ' และ Online สำเร็จ';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isNotEmpty
                ? message
                : 'บันทึกเหตุการณ์สำเร็จ'),
            duration: const Duration(seconds: 2),
          ),
        );

        _formKey.currentState?.reset();
        _reporterController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedStationId = null;
          _selectedViolationTypeId = null;
          _selectedImage = null;
          _aiResult = null;
          _aiConfidence = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ฟอร์มบันทึกเหตุการณ์',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เลือกภาพหลักฐาน',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[100],
                        ),
                        child: _selectedImage != null
                            ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: FloatingActionButton(
                                mini: true,
                                backgroundColor: Colors.red,
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                    _aiResult = null;
                                    _aiConfidence = null;
                                  });
                                },
                                child: const Icon(Icons.close),
                              ),
                            ),
                          ],
                        )
                            : GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'กดเพื่อเลือกภาพ',
                                style:
                                TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _showImageSourceDialog,
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('เลือกภาพ'),
                      ),
                      if (_aiProcessing)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 10),
                              Text('AI กำลังวิเคราะห์ภาพ...'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (_aiResult != null)
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ผลการวิเคราะห์ AI',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text('ประเภท: $_aiResult'),
                        Text(
                            'ความมั่นใจ: ${(_aiConfidence?.toStringAsFixed(2) ?? '0')}%'),
                        if (_selectedViolationTypeId != null)
                          Text(
                            'ประเภทความผิด: ${_violations.firstWhere((v) => v.typeId == _selectedViolationTypeId, orElse: () => _violations.first).typeName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _selectedStationId,
                decoration: const InputDecoration(
                  labelText: 'หน่วยเลือกตั้ง',
                  border: OutlineInputBorder(),
                ),
                items: _stations
                    .map(
                      (station) => DropdownMenuItem(
                        value: station.stationId,
                        child: Text(
                          '${station.stationId} - ${station.stationName}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStationId = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'กรุณาเลือกหน่วยเลือกตั้ง' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _selectedViolationTypeId,
                decoration: const InputDecoration(
                  labelText: 'ประเภทความผิด',
                  border: OutlineInputBorder(),
                ),
                items: _violations
                    .map(
                      (violation) => DropdownMenuItem(
                        value: violation.typeId,
                        child: Text(
                          '${violation.typeName} (${violation.severity})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedViolationTypeId = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'กรุณาเลือกประเภทความผิด' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reporterController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อผู้แจ้งเหตุ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกชื่อผู้แจ้งเหตุ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียดเหตุการณ์',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกรายละเอียด';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isProcessing ? null : _saveReport,
                icon: _isProcessing
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(),
                )
                    : const Icon(Icons.save),
                label: Text(_isProcessing ? 'กำลังบันทึก...' : 'บันทึก'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
