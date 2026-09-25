import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/consultation_models.dart';

class SharedHealthCardPanel extends StatelessWidget {
  const SharedHealthCardPanel({super.key, required this.card, this.onRevoke});

  final SharedHealthCardModel card;
  final VoidCallback? onRevoke;

  String _items(List<String> values) =>
      values.isEmpty ? 'None recorded' : values.join(', ');

  @override
  Widget build(BuildContext context) {
    final snapshot = card.snapshot;
    final latestAssessment = snapshot['latest_assessment'] as Map?;
    final latestVaccination = snapshot['latest_vaccination'] as Map?;
    final recentActivity = snapshot['recent_activity'] as Map?;
    final species = _clean(snapshot['species'] as String?);
    final breed = _clean(snapshot['breed'] as String?);
    final blood = _clean(snapshot['blood_type'] as String?);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.13),
          width: 1.1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          minTileHeight: 48,
          tilePadding: const EdgeInsets.symmetric(horizontal: 2),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.badge_rounded,
              color: AppTheme.primaryColor,
              size: 19,
            ),
          ),
          title: Text(
            '${card.petName} Health ID',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Shared ${_date(card.sharedAt)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          trailing: onRevoke == null
              ? null
              : SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    tooltip: 'Stop sharing',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: onRevoke,
                    icon: const Icon(Icons.link_off_rounded, size: 20),
                    color: AppTheme.primaryColor,
                  ),
                ),
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniFact(label: 'Type', value: species),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniFact(label: 'Breed', value: breed),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniFact(label: 'Blood', value: blood),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _CareList(
              title: 'Care notes',
              items: [
                _CareItem('Allergies', _items(card.allergies)),
                _CareItem('Conditions', _items(card.chronicConditions)),
                _CareItem('Medication', _items(card.currentMedications)),
                if (latestAssessment != null)
                  _CareItem(
                    'Assessment',
                    '${latestAssessment['risk_level'] ?? latestAssessment['status'] ?? 'Recorded'} • ${latestAssessment['title']}',
                  ),
                if (latestVaccination != null)
                  _CareItem(
                    'Vaccination',
                    latestVaccination['title'] as String? ?? 'Recorded',
                  ),
                if (recentActivity != null)
                  _CareItem(
                    'Activity',
                    recentActivity['summary'] as String? ?? 'Recorded',
                  ),
                if (card.profileUpdatedAt != null)
                  _CareItem(
                    'Updated',
                    '${_date(card.profileUpdatedAt!)} '
                        '${card.profileUpdatedAt!.hour.toString().padLeft(2, '0')}:'
                        '${card.profileUpdatedAt!.minute.toString().padLeft(2, '0')}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _clean(String? value) =>
      value == null || value.trim().isEmpty ? 'Not set' : value.trim();

  String _date(DateTime value) => '${value.day}/${value.month}/${value.year}';
}

class _MiniFact extends StatelessWidget {
  const _MiniFact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.blushSurfaceColor.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedText,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CareItem {
  const _CareItem(this.label, this.value);
  final String label;
  final String value;
}

class _CareList extends StatelessWidget {
  const _CareList({required this.title, required this.items});
  final String title;
  final List<_CareItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.creamSurfaceColor.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 88,
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.mutedText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.value,
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
