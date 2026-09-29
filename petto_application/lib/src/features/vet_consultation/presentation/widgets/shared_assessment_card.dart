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
    final iconTint = failed ? AppTheme.dangerColor : const Color(0xFFC9932E);
    final risk = failed ? 'Unavailable' : assessment.riskLevel ?? 'Pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDetails(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
            child: Row(
              children: [
                _IconBadge(failed: failed, tint: iconTint),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        failed ? 'Assessment unavailable' : 'AI assessment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.secondaryText,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        assessment.symptomDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppTheme.mutedText,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _RiskChip(label: risk, color: tint),
                if (onRevoke != null) ...[
                  const SizedBox(width: 2),
                  IconButton(
                    tooltip: 'Stop sharing assessment',
                    onPressed: onRevoke,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                    icon: const Icon(Icons.link_off_rounded, size: 19),
                    color: AppTheme.primaryColor,
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppTheme.mutedText,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) {
    final failed = assessment.failed;
    final tint = failed ? AppTheme.dangerColor : const Color(0xFFC9932E);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.78,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 10, 10),
                child: Row(
                  children: [
                    _IconBadge(failed: failed, tint: tint),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            failed
                                ? 'Assessment unavailable'
                                : 'Shared AI assessment',
                            style: Theme.of(sheetContext).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.secondaryText,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            _dateTime(assessment.createdAt),
                            style: Theme.of(sheetContext).textTheme.labelMedium
                                ?.copyWith(color: AppTheme.mutedText),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                  child: Column(
                    children: [
                      _DetailGrid(
                        rows: [
                          _DetailData('Status', assessment.status),
                          _DetailData(
                            'Symptoms',
                            assessment.symptomDescription,
                          ),
                          if (failed)
                            _DetailData(
                              'Failure',
                              assessment.errorCode ?? 'AI analysis unavailable',
                            )
                          else ...[
                            _DetailData(
                              'Risk level',
                              assessment.riskLevel ?? 'Not set',
                            ),
                            _DetailData(
                              'AI result',
                              assessment.aiRawResponse ?? 'Not available',
                            ),
                          ],
                        ],
                      ),
                      if (assessment.imageUri != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.network(
                            assessment.imageUri!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              color: AppTheme.blushSurfaceColor,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateTime(DateTime value) =>
      '${value.day}/${value.month}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.failed, required this.tint});
  final bool failed;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: tint.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: Icon(
      failed ? Icons.warning_amber_rounded : Icons.assignment_turned_in_rounded,
      color: tint,
      size: 21,
    ),
  );
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
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.creamSurfaceColor.withValues(alpha: 0.76),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white, width: 3),
    ),
    child: Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 86,
                child: Text(
                  rows[index].label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  rows[index].value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          if (index != rows.length - 1) const SizedBox(height: 9),
        ],
      ],
    ),
  );
}

class _RiskChip extends StatelessWidget {
  const _RiskChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 96),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    ),
  );
}
