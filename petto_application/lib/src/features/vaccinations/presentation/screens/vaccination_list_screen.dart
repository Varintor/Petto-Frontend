import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/vaccination_controller.dart';
import '../../domain/entities/vaccination_entity.dart';
import 'add_vaccination_screen.dart';

class VaccinationListScreen extends StatefulWidget {
  final int petId;
  final String petName;

  const VaccinationListScreen({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  State<VaccinationListScreen> createState() => _VaccinationListScreenState();
}

class _VaccinationListScreenState extends State<VaccinationListScreen> {
  @override
  void initState() {
    super.initState();
    // Load vaccinations on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VaccinationController>().loadVaccinations(widget.petId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ประวัติวัคซีน - ${widget.petName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<VaccinationController>().loadVaccinations(widget.petId);
            },
          ),
        ],
      ),
      body: Consumer<VaccinationController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.vaccinations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.hasError && controller.vaccinations.isEmpty) {
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
                      onPressed: () {
                        controller.loadVaccinations(widget.petId);
                      },
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (controller.vaccinations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.vaccines, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีบันทึกวัคซีน',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'กด + เพื่อเพิ่มบันทึกวัคซีน',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await controller.loadVaccinations(widget.petId);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.vaccinations.length,
              itemBuilder: (context, index) {
                final vaccination = controller.vaccinations[index];
                return _VaccinationCard(vaccination: vaccination);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Capture before the await so we don't use context across the gap,
          // and so the controller is in scope here (outside the Consumer).
          final controller = context.read<VaccinationController>();
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => AddVaccinationScreen(petId: widget.petId),
            ),
          );
          if (result == true) {
            controller.loadVaccinations(widget.petId);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _VaccinationCard extends StatelessWidget {
  final VaccinationEntity vaccination;

  const _VaccinationCard({required this.vaccination});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.vaccines,
                  color: _getStatusColor(vaccination),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vaccination.vaccineName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ฉีดเมื่อ: ${vaccination.dateAdministeredText}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(vaccination),
              ],
            ),
            if (vaccination.nextDueDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(vaccination).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: _getStatusColor(vaccination),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'นัดครั้งต่อไป: ${vaccination.nextDueDateText}',
                      style: TextStyle(
                        color: _getStatusColor(vaccination),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (vaccination.daysUntilDue != null) ...[
                      const Spacer(),
                      Text(
                        _getDaysText(vaccination.daysUntilDue!),
                        style: TextStyle(
                          color: _getStatusColor(vaccination),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (vaccination.clinicName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_hospital, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    vaccination.clinicName!,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
            if (vaccination.notes != null && vaccination.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      vaccination.notes!,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(VaccinationEntity v) {
    if (v.isOverdue) return Colors.red;
    if (v.isDueSoon) return Colors.orange;
    return Colors.green;
  }

  Widget _buildStatusChip(VaccinationEntity vaccination) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(vaccination).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        vaccination.statusText,
        style: TextStyle(
          color: _getStatusColor(vaccination),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getDaysText(int days) {
    if (days < 0) return '${days.abs()} วันเกินกำหนด';
    if (days == 0) return 'วันนี้';
    if (days == 1) return 'พรุ่งนี้';
    return 'อีก $days วัน';
  }
}
