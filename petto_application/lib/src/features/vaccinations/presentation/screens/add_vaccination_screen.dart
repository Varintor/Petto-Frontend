import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/top_alert.dart';
import '../controllers/vaccination_controller.dart';

class AddVaccinationScreen extends StatefulWidget {
  final int petId;

  const AddVaccinationScreen({super.key, required this.petId});

  @override
  State<AddVaccinationScreen> createState() => _AddVaccinationScreenState();
}

class _AddVaccinationScreenState extends State<AddVaccinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vaccineNameController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _dateAdministered = DateTime.now();
  DateTime? _nextDueDate;

  @override
  void dispose() {
    _vaccineNameController.dispose();
    _clinicNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isAdministered) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isAdministered
          ? _dateAdministered
          : (_nextDueDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isAdministered) {
          _dateAdministered = picked;
        } else {
          _nextDueDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<VaccinationController>();

    final success = await controller.createVaccination(
      petId: widget.petId,
      vaccineName: _vaccineNameController.text.trim(),
      dateAdministered: _dateAdministered,
      nextDueDate: _nextDueDate,
      clinicName: _clinicNameController.text.trim().isEmpty
          ? null
          : _clinicNameController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (success && mounted) {
      showTopAlert(context, 'Vaccination saved successfully.');
      Navigator.pop(context, true);
    } else if (controller.hasError && mounted) {
      showTopAlert(
        context,
        controller.errorMessage ?? 'Something went wrong.',
        icon: Icons.info_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('เพิ่มบันทึกวัคซีน'),
        actions: [
          IconButton(onPressed: _submit, icon: const Icon(Icons.check)),
        ],
      ),
      body: Consumer<VaccinationController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + keyboardInset),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vaccine Name
                  TextFormField(
                    controller: _vaccineNameController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อวัคซีน',
                      hintText: 'เช่น วัคซีนพาร์โบ, วัคซีนบริเทณ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vaccines),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณาระบุชื่อวัคซีน';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date Administered
                  InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'วันที่ฉีด',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${_dateAdministered.day}/${_dateAdministered.month}/${_dateAdministered.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Next Due Date
                  InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'นัดครั้งต่อไป (ถ้ามี)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event),
                        hintText: 'เลือกวันที่',
                      ),
                      child: Text(
                        _nextDueDate == null
                            ? 'ไม่ระบุ'
                            : '${_nextDueDate!.day}/${_nextDueDate!.month}/${_nextDueDate!.year}',
                        style: TextStyle(
                          fontSize: 16,
                          color: _nextDueDate == null
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Clinic Name
                  TextFormField(
                    controller: _clinicNameController,
                    decoration: const InputDecoration(
                      labelText: 'คลินิก/โรงพยาบาล',
                      hintText: 'ระบุสถานที่ฉีดวัคซีน (ถ้าจำได้)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_hospital),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'บันทึกเพิ่มเติม',
                      hintText: 'รายละเอียดอื่นๆ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  if (!controller.isLoading)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'บันทึกวัคซีน',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  else
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
