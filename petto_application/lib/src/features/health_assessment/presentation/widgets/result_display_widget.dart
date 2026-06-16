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
    final symptomText =
        (assessment.symptoms != null && assessment.symptoms!.trim().isNotEmpty)
        ? assessment.symptoms!.trim()
        : 'No symptom description';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: risk.color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: risk.color.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: risk.color,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(risk.icon, color: Colors.white, size: 23),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assessment Complete',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.secondaryText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        risk.label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: risk.color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (assessment.petName.isNotEmpty || assessment.petType.isNotEmpty)
            Row(
              children: [
                if (assessment.petName.isNotEmpty)
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      Icons.pets_rounded,
                      'Pet Name',
                      assessment.petName,
                    ),
                  ),
                if (assessment.petName.isNotEmpty &&
                    assessment.petType.isNotEmpty)
                  const SizedBox(width: 12),
                if (assessment.petType.isNotEmpty)
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      Icons.category_rounded,
                      'Pet Type',
                      assessment.petType,
                    ),
                  ),
              ],
            ),
          if (assessment.petName.isNotEmpty || assessment.petType.isNotEmpty)
            const SizedBox(height: 12),
          _buildSymptomCard(context, symptomText),
          const SizedBox(height: 16),
          _ResultAiAnalysisPanel(
            riskColor: risk.color,
            riskLabel: risk.label,
            symptoms: symptomText,
            response: assessment.aiResponse,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.creamSurfaceColor.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_rounded,
                  color: AppTheme.primaryColor.withValues(alpha: 0.72),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Preliminary AI screening, not a diagnosis. Consult a veterinarian if symptoms persist or worsen.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedText,
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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

  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomCard(BuildContext context, String symptomText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.report_rounded,
              color: AppTheme.primaryColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Symptoms',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  symptomText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedText,
                    height: 1.38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultAiAnalysisPanel extends StatelessWidget {
  const _ResultAiAnalysisPanel({
    required this.riskColor,
    required this.riskLabel,
    required this.symptoms,
    required this.response,
  });

  final Color riskColor;
  final String riskLabel;
  final String symptoms;
  final String response;

  @override
  Widget build(BuildContext context) {
    final observations = _pointsFrom(
      response,
      fallback: [
        'Review visible signs together with the reported symptoms.',
        'Track appetite, breathing, activity, comfort, and behavior changes.',
      ],
    );
    final highRisk = riskLabel.toLowerCase().contains('high');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.99),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: riskColor.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: riskColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ResultAnalysisSection(
            icon: Icons.visibility_rounded,
            title: 'Observations',
            color: AppTheme.primaryColor,
            items: observations.take(2).toList(),
          ),
          const SizedBox(height: 10),
          _ResultAnalysisSection(
            icon: Icons.health_and_safety_rounded,
            title: 'Potential concerns',
            color: riskColor,
            items: highRisk
                ? [
                    'Symptoms may require prompt professional review.',
                    'Watch for worsening breathing, weakness, collapse, or pain.',
                  ]
                : [
                    'Symptoms may be mild but should still be monitored.',
                    'Follow up if there is no improvement.',
                  ],
          ),
          const SizedBox(height: 10),
          _ResultAnalysisSection(
            icon: Icons.lightbulb_rounded,
            title: 'Recommended actions',
            color: AppTheme.accentColor,
            items: [
              'Do: Keep ${_shortSymptom(symptoms)} under close observation.',
              'Do not: Ignore sudden behavior or breathing changes.',
              'Urgency: Contact your care team if symptoms persist.',
            ],
            itemIcons: const [
              Icons.check_circle_rounded,
              Icons.cancel_rounded,
              Icons.notifications_active_rounded,
            ],
            itemColors: [
              AppTheme.successColor,
              AppTheme.primaryColor,
              AppTheme.accentColor,
            ],
          ),
        ],
      ),
    );
  }

  List<String> _pointsFrom(String value, {required List<String> fallback}) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return fallback;
    final pieces = cleaned
        .split(RegExp(r'(?<=[.!?])\s+|\n+|•'))
        .map((line) => line.trim())
        .where((line) => line.length > 8)
        .toList();
    if (pieces.isEmpty) return fallback;
    return pieces.take(3).toList();
  }

  String _shortSymptom(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'No symptom description') {
      return 'your pet';
    }
    return trimmed.length > 34 ? '${trimmed.substring(0, 34)}...' : trimmed;
  }
}

class _ResultAnalysisSection extends StatelessWidget {
  const _ResultAnalysisSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
    this.itemIcons,
    this.itemColors,
  });

  final IconData icon;
  final String title;
  final Color color;
  final List<String> items;
  final List<IconData>? itemIcons;
  final List<Color>? itemColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 9),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.secondaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final entry in items.indexed) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  itemIcons != null && entry.$1 < itemIcons!.length
                      ? itemIcons![entry.$1]
                      : Icons.circle_rounded,
                  size: itemIcons != null ? 16 : 7,
                  color: itemColors != null && entry.$1 < itemColors!.length
                      ? itemColors![entry.$1]
                      : color.withValues(alpha: 0.72),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.$2,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryText.withValues(alpha: 0.86),
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (entry.$1 != items.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
