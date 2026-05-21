import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/health_assessment_controller.dart';
import '../widgets/image_uploader_widget.dart';
import '../widgets/result_display_widget.dart';

class HealthAssessmentScreen extends StatefulWidget {
  final int? petId; // Optional: สามารถส่ง Pet ID มาจากภายนอกได้

  const HealthAssessmentScreen({super.key, this.petId});

  @override
  State<HealthAssessmentScreen> createState() => _HealthAssessmentScreenState();
}

class _HealthAssessmentScreenState extends State<HealthAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();
  File? _selectedImageFile;
  dynamic _selectedImage;

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  void _onImageSelected(dynamic image) {
    setState(() {
      _selectedImage = image;
      // แปลงเป็น File ถ้าเป็น mobile platform
      if (image is File) {
        _selectedImageFile = image;
      }
    });
  }

  Future<void> _submitAssessment() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปภาพ')),
      );
      return;
    }

    final controller = context.read<HealthAssessmentController>();

    // ใช้ petId จาก widget หรือใช้ค่า default = 1
    final petId = widget.petId ?? 1;

    await controller.submitAssessment(
      petId: petId,
      symptomDescription: _symptomsController.text.isEmpty
          ? 'ไม่ระบุอาการเพิ่มเติม'
          : _symptomsController.text,
      imageFile: _selectedImageFile,
      imageBytes: _selectedImage is! File ? _selectedImage : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Assessment'),
      ),
      body: Consumer<HealthAssessmentController>(
        builder: (context, controller, child) {
          // ==================== Loading State ====================
          if (controller.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังส่งข้อมูลไปยัง AI...'),
                ],
              ),
            );
          }

          // ==================== Success State ====================
          if (controller.currentAssessment != null) {
            return ResultDisplayWidget(
              assessment: controller.currentAssessment!,
              onReset: () {
                controller.reset();
                setState(() {
                  _selectedImage = null;
                  _selectedImageFile = null;
                  _symptomsController.clear();
                });
              },
            );
          }

          // ==================== Error State ====================
          if (controller.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      controller.error?.message ?? 'An error occurred',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    if (controller.error?.statusCode != null)
                      Text(
                        'HTTP ${controller.error?.statusCode}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: controller.reset,
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            );
          }

          // ==================== Form State ====================
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ส่วนอัปโหลดรูปภาพ
                  ImageUploaderWidget(
                    onImageSelected: _onImageSelected,
                    initialImage: _selectedImage,
                  ),
                  const SizedBox(height: 24),

                  // ส่วนกรอกอาการ
                  TextFormField(
                    controller: _symptomsController,
                    decoration: const InputDecoration(
                      labelText: 'อาการเพิ่มเติม (ถ้ามี)',
                      hintText: 'ระบุอาการเพิ่มเติมของสัตว์เลี้ยง...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),

                  // แสดง Pet ID ที่จะส่ง
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.pets, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Pet ID: ${widget.petId ?? 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ปุ่มส่งข้อมูล
                  ElevatedButton(
                    onPressed: _selectedImage == null ? null : _submitAssessment,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'ส่งให้ AI วินิจฉัย',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    '* กรุณาเลือกรูปภาพก่อนกดส่ง',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
