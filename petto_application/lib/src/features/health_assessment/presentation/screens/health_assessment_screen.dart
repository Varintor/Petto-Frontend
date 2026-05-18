import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/health_assessment_controller.dart';
import '../widgets/image_uploader_widget.dart';
import '../widgets/result_display_widget.dart';

class HealthAssessmentScreen extends StatefulWidget {
  const HealthAssessmentScreen({super.key});

  @override
  State<HealthAssessmentScreen> createState() => _HealthAssessmentScreenState();
}

class _HealthAssessmentScreenState extends State<HealthAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _petNameController = TextEditingController();
  final _symptomsController = TextEditingController();
  String _selectedPetType = 'dog';
  dynamic _selectedImage;

  @override
  void dispose() {
    _petNameController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  void _onImageSelected(dynamic image) {
    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _submitAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<HealthAssessmentController>();
    await controller.submitAssessment(
      petName: _petNameController.text,
      petType: _selectedPetType,
      symptoms: _symptomsController.text.isEmpty ? null : _symptomsController.text,
      imageData: _selectedImage,
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
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.currentAssessment != null) {
            return ResultDisplayWidget(assessment: controller.currentAssessment!);
          }

          if (controller.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(controller.errorMessage ?? 'An error occurred'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: controller.reset,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ImageUploaderWidget(
                    onImageSelected: _onImageSelected,
                    initialImage: _selectedImage,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _petNameController,
                    decoration: const InputDecoration(
                      labelText: 'Pet Name',
                      hintText: 'Enter your pet\'s name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter pet name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedPetType,
                    decoration: const InputDecoration(
                      labelText: 'Pet Type',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'dog', child: Text('Dog')),
                      DropdownMenuItem(value: 'cat', child: Text('Cat')),
                      DropdownMenuItem(value: 'bird', child: Text('Bird')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPetType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _symptomsController,
                    decoration: const InputDecoration(
                      labelText: 'Symptoms',
                      hintText: 'Describe any symptoms',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitAssessment,
                    child: const Text('Submit Assessment'),
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
