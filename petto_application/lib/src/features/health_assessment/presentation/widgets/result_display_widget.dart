import 'package:flutter/material.dart';

import '../../domain/entities/assessment_entity.dart';

class ResultDisplayWidget extends StatelessWidget {
  const ResultDisplayWidget({
    super.key,
    required this.assessment,
    this.onReset,
    this.onBackToDashboard,
    this.compactMode = false,
    this.onTalkToVet,
    this.onSaveNotes,
  });

  final AssessmentEntity assessment;
  final VoidCallback? onReset;
  final VoidCallback? onBackToDashboard;
  final bool compactMode;
  final VoidCallback? onTalkToVet;
  final VoidCallback? onSaveNotes;

  ({Color color, IconData icon, String label}) get _risk {
    switch (assessment.riskBucket) {
      case 'high':
        return (
          color: const Color(0xFFE57373),
          icon: Icons.error_rounded,
          label: assessment.riskLevel.isEmpty ? 'High Risk' : assessment.riskLevel,
        );
      case 'low':
        return (
          color: const Color(0xFF57C785),
          icon: Icons.check_circle_rounded,
          label: assessment.riskLevel.isEmpty ? 'Low Risk' : assessment.riskLevel,
        );
      default:
        return (
          color: const Color(0xFFFFB74D),
          icon: Icons.warning_amber_rounded,
          label:
              assessment.riskLevel.isEmpty ? 'Moderate Risk' : assessment.riskLevel,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultBack = onBackToDashboard ??
        () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        };
    final risk = _risk;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Risk banner (driven by the backend risk_level)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: risk.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: risk.color.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(risk.icon, color: risk.color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assessment Complete',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: risk.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        risk.label,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: risk.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (assessment.petName.isNotEmpty)
            _buildInfoCard('Pet Name', assessment.petName),
          if (assessment.petName.isNotEmpty) const SizedBox(height: 12),
          if (assessment.petType.isNotEmpty)
            _buildInfoCard('Pet Type', assessment.petType),
          if (assessment.petType.isNotEmpty) const SizedBox(height: 12),
          if (assessment.symptoms != null && assessment.symptoms!.isNotEmpty)
            _buildInfoCard('Symptoms', assessment.symptoms!),
          const SizedBox(height: 24),
          Text('AI Analysis', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              assessment.aiResponse.isEmpty
                  ? 'ไม่มีรายละเอียดจาก AI'
                  : assessment.aiResponse,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '⚠️ นี่เป็นการคัดกรองเบื้องต้นด้วย AI ไม่ใช่การวินิจฉัยทางการแพทย์ '
            'หากกังวลควรปรึกษาสัตวแพทย์',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (compactMode) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReset ?? defaultBack,
                    child: const Text('New Scan'),
                  ),
                ),
                if (onTalkToVet != null || onBackToDashboard != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onTalkToVet ?? onBackToDashboard,
                      child: const Text('Talk to Vet'),
                    ),
                  ),
                ],
              ],
            ),
            if (onSaveNotes != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onSaveNotes,
                child: const Text('Save Notes'),
              ),
            ],
          ] else ...[
            if (onReset != null)
              ElevatedButton(
                onPressed: onReset,
                child: const Text('Analyze Another Case'),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: defaultBack,
              child: const Text('Back to Home'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
