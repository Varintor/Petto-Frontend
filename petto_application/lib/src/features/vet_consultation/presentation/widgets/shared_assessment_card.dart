import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
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
    final tint = failed ? AppTheme.dangerColor : AppTheme.primaryColor;
    final risk = failed ? 'Unavailable' : assessment.riskLevel ?? 'Pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: tint.withValues(alpha: 0.13), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.055),
            blurRadius: 18,
            spreadRadius: -12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              failed
                  ? Icons.warning_amber_rounded
                  : Icons.assignment_turned_in_rounded,
              color: tint,
            ),
          ),
          title: Text(
            failed ? 'AI assessment unavailable' : 'Shared assessment',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              assessment.symptomDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w700,
                height: 1.24,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ShareChip(label: risk, color: tint),
              if (onRevoke != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Stop sharing assessment',
                  onPressed: onRevoke,
                  icon: const Icon(Icons.link_off_rounded),
                  color: AppTheme.primaryColor,
                ),
              ],
            ],
          ),
          children: [
            const SizedBox(height: 10),
            _DetailGrid(
              rows: [
                _DetailData('Status', assessment.status),
                _DetailData('Symptoms', assessment.symptomDescription),
                if (failed)
                  _DetailData(
                    'Failure',
                    assessment.errorCode ?? 'AI analysis unavailable',
                  )
                else ...[
                  _DetailData('Risk level', assessment.riskLevel ?? 'Not set'),
                  _DetailData(
                    'AI result',
                    assessment.aiRawResponse ?? 'Not available',
                  ),
                ],
                _DetailData('Created', _dateTime(assessment.createdAt)),
              ],
            ),
            if (assessment.imageUri != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  assessment.imageUri!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.blushSurfaceColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'The assessment image is temporarily unavailable.',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _dateTime(DateTime value) =>
      '${value.day}/${value.month}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

class _DetailData {
  const _DetailData(this.label, this.value);
  final String label;
  final String value;
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.rows});
  final List<_DetailData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.creamSurfaceColor.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      row.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.mutedText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryText,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
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

class _ShareChip extends StatelessWidget {
  const _ShareChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
