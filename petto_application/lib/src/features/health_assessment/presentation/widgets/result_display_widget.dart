import 'package:flutter/material.dart';
import '../../domain/entities/assessment_entity.dart';

class ResultDisplayWidget extends StatelessWidget {
  final AssessmentEntity assessment;

  const ResultDisplayWidget({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text(
                  'Assessment Complete',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoCard('Pet Name', assessment.petName),
          const SizedBox(height: 12),
          _buildInfoCard('Pet Type', assessment.petType),
          const SizedBox(height: 12),
          if (assessment.symptoms != null && assessment.symptoms!.isNotEmpty)
            _buildInfoCard('Symptoms', assessment.symptoms!),
          const SizedBox(height: 24),
          Text(
            'AI Diagnosis',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              assessment.diagnosis,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('Confidence Score', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: assessment.confidenceScore,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    assessment.confidenceScore > 0.7
                        ? Colors.green
                        : assessment.confidenceScore > 0.4
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(assessment.confidenceScore * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Back to Home'),
          ),
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
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
