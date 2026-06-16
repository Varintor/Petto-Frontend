import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
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
          color: AppTheme.dangerColor,
          icon: Icons.error_rounded,
          label: assessment.riskLevel.isEmpty
              ? 'High Risk'
              : assessment.riskLevel,
        );
      case 'low':
        return (
          color: AppTheme.successColor,
          icon: Icons.check_circle_rounded,
          label: assessment.riskLevel.isEmpty
              ? 'Low Risk'
              : assessment.riskLevel,
        );
      default:
        return (
          color: AppTheme.accentColor,
          icon: Icons.warning_amber_rounded,
          label: assessment.riskLevel.isEmpty
              ? 'Moderate Risk'
              : assessment.riskLevel,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultBack =
        onBackToDashboard ??
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
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 20, color: risk.color),
              const SizedBox(width: 8),
              Text('AI Analysis', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildAiSections(context, risk.color),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is a preliminary AI screening, not a medical diagnosis. '
                    'Please consult a licensed veterinarian if you are concerned.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
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

  // ---- AI response formatting ----

  List<Widget> _buildAiSections(BuildContext context, Color accent) {
    final sections = _parseAiResponse(assessment.aiResponse);
    if (sections.isEmpty) {
      // Fallback: AI didn't follow the expected structure — show raw text.
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
            ],
          ),
          child: Text(
            assessment.aiResponse.isEmpty
                ? 'No details returned by AI.'
                : assessment.aiResponse,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ),
      ];
    }
    return [
      for (final s in sections) ...[
        _buildSectionCard(context, s, accent),
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _buildSectionCard(BuildContext context, _AiSection s, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(s.icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                s.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...s.body.map(_buildBodyLine),
        ],
      ),
    );
  }

  Widget _buildBodyLine(String line) {
    final clean = line.replaceFirst(RegExp(r'^[\-\*•]\s*'), '').trim();
    final upper = clean.toUpperCase();
    IconData? icon;
    Color? color;
    if (upper.startsWith('DO NOT') || upper.startsWith("DON'T")) {
      icon = Icons.cancel_rounded;
      color = AppTheme.dangerColor;
    } else if (upper.startsWith('DO:') || upper.startsWith('DO ')) {
      icon = Icons.check_circle_rounded;
      color = AppTheme.successColor;
    } else if (upper.startsWith('URGENCY')) {
      icon = Icons.schedule_rounded;
      color = AppTheme.accentColor;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 6),
          ] else ...[
            Padding(
              padding: const EdgeInsets.only(top: 7, right: 8),
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
          Expanded(
            child: Text(clean, style: const TextStyle(fontSize: 14, height: 1.45)),
          ),
        ],
      ),
    );
  }

  List<_AiSection> _parseAiResponse(String raw) {
    if (raw.trim().isEmpty) return [];
    final text = raw
        .replaceAll(
          RegExp(
            r'^\s*risk\s*:\s*(low|moderate|high)\s*$',
            multiLine: true,
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll('**', '')
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        .trim();

    final defs = <(List<String>, String, IconData)>[
      (['OBSERVATION'], 'Observations', Icons.visibility_rounded),
      (
        ['POTENTIAL CONCERN', 'CONCERN'],
        'Potential Concerns',
        Icons.medical_services_rounded,
      ),
      (
        ['RECOMMENDED ACTION', 'FIRST-AID', 'NEXT STEP'],
        'Recommended Actions',
        Icons.tips_and_updates_rounded,
      ),
      (['DISCLAIMER'], 'Disclaimer', Icons.info_outline_rounded),
    ];

    bool isHeader(String line, List<String> keys) {
      final up =
          line.toUpperCase().replaceAll(RegExp(r'^[\s\d\.\)\-:]+'), '').trim();
      return keys.any(up.startsWith);
    }

    final sections = <_AiSection>[];
    _AiSection? current;
    for (final line in text.split('\n')) {
      (List<String>, String, IconData)? matched;
      for (final d in defs) {
        if (isHeader(line, d.$1)) {
          matched = d;
          break;
        }
      }
      if (matched != null) {
        current = _AiSection(title: matched.$2, icon: matched.$3, body: []);
        sections.add(current);
      } else if (current != null && line.trim().isNotEmpty) {
        current.body.add(line.trim());
      }
    }
    return sections;
  }
}

class _AiSection {
  _AiSection({required this.title, required this.icon, required this.body});
  final String title;
  final IconData icon;
  final List<String> body;
}
