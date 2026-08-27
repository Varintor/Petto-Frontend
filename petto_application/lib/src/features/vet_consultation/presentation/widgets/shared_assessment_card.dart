import 'package:flutter/material.dart';

import '../../data/models/consultation_models.dart';

class SharedAssessmentPanel extends StatelessWidget {
  const SharedAssessmentPanel({
    super.key,
    required this.assessment,
    this.onRevoke,
  });

  final SharedAssessmentModel assessment;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final failed = assessment.failed;
    return Card(
      color: failed ? const Color(0xFFFFF3E8) : const Color(0xFFF0F5FF),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Icon(
            failed ? Icons.warning_amber_rounded : Icons.auto_awesome_rounded,
          ),
        ),
        title: Text(
          failed
              ? 'AI assessment unavailable'
              : 'Shared assessment • ${assessment.riskLevel ?? 'Pending'}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(assessment.symptomDescription),
        trailing: onRevoke == null
            ? null
            : IconButton(
                tooltip: 'Stop sharing assessment',
                onPressed: onRevoke,
                icon: const Icon(Icons.link_off_rounded),
              ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Status', assessment.status),
          _row('Symptoms', assessment.symptomDescription),
          if (failed) ...[
            _row('Failure', assessment.errorCode ?? 'AI analysis unavailable'),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'No risk result was generated. This record must not be interpreted as a successful assessment.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ] else ...[
            _row('Risk level', assessment.riskLevel ?? 'Not available'),
            _row('AI result', assessment.aiRawResponse ?? 'Not available'),
          ],
          _row(
            'Created',
            '${assessment.createdAt.day}/${assessment.createdAt.month}/${assessment.createdAt.year} '
                '${assessment.createdAt.hour.toString().padLeft(2, '0')}:'
                '${assessment.createdAt.minute.toString().padLeft(2, '0')}',
          ),
          if (assessment.imageUri != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                assessment.imageUri!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Text(
                  'The assessment image is temporarily unavailable.',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text('$label: $value'),
  );
}
