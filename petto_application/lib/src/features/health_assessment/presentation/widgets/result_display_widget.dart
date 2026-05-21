import 'package:flutter/material.dart';
import '../../domain/entities/assessment_entity.dart';
import '../../data/models/assessment_model.dart';

class ResultDisplayWidget extends StatelessWidget {
  final AssessmentEntity assessment;
  final VoidCallback? onReset;

  const ResultDisplayWidget({
    super.key,
    required this.assessment,
    this.onReset,
  });

  Color _getRiskColor(String riskLevel) {
    final level = riskLevel.toLowerCase();
    if (level.contains('high') || level.contains('critical') || level.contains('severe')) {
      return Colors.red;
    } else if (level.contains('moderate') || level.contains('medium')) {
      return Colors.orange;
    } else if (level.contains('low') || level.contains('minor')) {
      return Colors.green;
    }
    return Colors.grey;
  }

  IconData _getRiskIcon(String riskLevel) {
    final level = riskLevel.toLowerCase();
    if (level.contains('high') || level.contains('critical')) {
      return Icons.dangerous;
    } else if (level.contains('moderate')) {
      return Icons.warning;
    } else if (level.contains('low')) {
      return Icons.check_circle;
    }
    return Icons.help;
  }

  @override
  Widget build(BuildContext context) {
    final model = AssessmentModel.fromEntity(assessment);
    final riskColor = _getRiskColor(assessment.riskLevel);
    final riskIcon = _getRiskIcon(assessment.riskLevel);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Risk Level Header
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      riskColor.withValues(alpha: 0.9),
                      riskColor.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(riskIcon, size: 48, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        assessment.riskLevel.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // AI Response Card (Main Diagnosis)
                  _buildAiResponseCard(context, model),

                  const SizedBox(height: 16),

                  // Risk Level Indicator
                  _buildRiskLevelCard(context, model, riskColor),

                  const SizedBox(height: 16),

                  // Image Preview (if available)
                  if (assessment.imageUri != null)
                    _buildImageCard(context),

                  const SizedBox(height: 16),

                  // Recommendations
                  _buildRecommendationsCard(context, model),

                  const SizedBox(height: 16),

                  // Metadata
                  _buildMetadataCard(context),

                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiResponseCard(BuildContext context, AssessmentModel model) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, size: 24),
                const SizedBox(width: 8),
                Text(
                  'AI Analysis Result',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              assessment.aiRawResponse,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskLevelCard(BuildContext context, AssessmentModel model, Color riskColor) {
    return Card(
      elevation: 2,
      color: riskColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getRiskIcon(assessment.riskLevel), color: riskColor),
                const SizedBox(width: 8),
                Text(
                  'Risk Level Assessment',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: model.getRiskScore(),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              minHeight: 12,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Risk Score',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                Text(
                  '${(model.getRiskScore() * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              assessment.imageUri!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Image not available'),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Submitted Image',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(BuildContext context, AssessmentModel model) {
    final recommendations = model.extractRecommendations();

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  'Key Recommendations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...recommendations.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[900],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assessment Details',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const Divider(height: 16),
            _buildInfoRow('Assessment ID', '#${assessment.id}'),
            const SizedBox(height: 8),
            _buildInfoRow('Pet ID', '#${assessment.petId}'),
            const SizedBox(height: 8),
            _buildInfoRow('Symptoms', assessment.symptomDescription),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Created',
              '${assessment.createdAt.day}/${assessment.createdAt.month}/${assessment.createdAt.year} ${assessment.createdAt.hour}:${assessment.createdAt.minute.toString().padLeft(2, '0')}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh),
          label: const Text('New Assessment'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.home),
          label: const Text('Back to Home'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
