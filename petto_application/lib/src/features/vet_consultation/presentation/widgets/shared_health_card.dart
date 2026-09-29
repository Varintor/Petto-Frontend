import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/consultation_models.dart';

class SharedHealthCardPanel extends StatelessWidget {
  const SharedHealthCardPanel({
    super.key,
    required this.card,
    this.onRevoke,
    this.initiallyExpanded = false,
  });

  final SharedHealthCardModel card;
  final VoidCallback? onRevoke;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (initiallyExpanded) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: _decoration(24),
        child: Column(
          children: [
            _Header(card: card, onRevoke: onRevoke, compact: false),
            const SizedBox(height: 12),
            _HealthDetails(card: card),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _decoration(20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDetails(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
            child: _Header(card: card, onRevoke: onRevoke),
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration(double radius) => BoxDecoration(
    color: AppTheme.surfaceColor.withValues(alpha: 0.98),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white, width: 3),
    boxShadow: AppTheme.subtleShadow,
  );

  Future<void> _showDetails(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.72,
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
                    const _HealthIcon(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${card.petName} Health ID',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(sheetContext).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.secondaryText,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            'Shared ${_date(card.sharedAt)}',
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
                  child: _HealthDetails(card: card),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _date(DateTime value) => '${value.day}/${value.month}/${value.year}';
}

class _Header extends StatelessWidget {
  const _Header({required this.card, this.onRevoke, this.compact = true});

  final SharedHealthCardModel card;
  final VoidCallback? onRevoke;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final species = _clean(card.snapshot['species'] as String?);
    final breed = _clean(card.snapshot['breed'] as String?);
    final blood = _clean(card.snapshot['blood_type'] as String?);
    return Row(
      children: [
        const _HealthIcon(),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${card.petName} Health ID',
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
                compact
                    ? '$species • $breed • Blood $blood'
                    : 'Shared ${_date(card.sharedAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.mutedText,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        if (onRevoke != null)
          IconButton(
            tooltip: 'Stop sharing',
            onPressed: onRevoke,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            icon: const Icon(Icons.link_off_rounded, size: 19),
            color: AppTheme.primaryColor,
          )
        else if (compact)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.mutedText,
            ),
          ),
      ],
    );
  }

  String _clean(String? value) =>
      value == null || value.trim().isEmpty ? 'Not set' : value.trim();
  String _date(DateTime value) => '${value.day}/${value.month}/${value.year}';
}

class _HealthIcon extends StatelessWidget {
  const _HealthIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: const Color(0xFFEEF0E5),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: const Icon(Icons.badge_rounded, color: Color(0xFF6F7E5A), size: 21),
  );
}

class _HealthDetails extends StatelessWidget {
  const _HealthDetails({required this.card});
  final SharedHealthCardModel card;

  @override
  Widget build(BuildContext context) {
    final snapshot = card.snapshot;
    final latestAssessment = snapshot['latest_assessment'] as Map?;
    final latestVaccination = snapshot['latest_vaccination'] as Map?;
    final recentActivity = snapshot['recent_activity'] as Map?;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniFact(
                label: 'Type',
                value: _clean(snapshot['species'] as String?),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _MiniFact(
                label: 'Breed',
                value: _clean(snapshot['breed'] as String?),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _MiniFact(
                label: 'Blood',
                value: _clean(snapshot['blood_type'] as String?),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        _CareList(
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
          ],
        ),
      ],
    );
  }

  String _clean(String? value) =>
      value == null || value.trim().isEmpty ? 'Not set' : value.trim();
  String _items(List<String> values) =>
      values.isEmpty ? 'None recorded' : values.join(', ');
}

class _MiniFact extends StatelessWidget {
  const _MiniFact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    decoration: BoxDecoration(
      color: AppTheme.blushSurfaceColor.withValues(alpha: 0.58),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white, width: 2),
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
        const SizedBox(height: 2),
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

class _CareItem {
  const _CareItem(this.label, this.value);
  final String label;
  final String value;
}

class _CareList extends StatelessWidget {
  const _CareList({required this.items});
  final List<_CareItem> items;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.creamSurfaceColor.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white, width: 3),
    ),
    child: Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 88,
                child: Text(
                  items[index].label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  items[index].value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          if (index != items.length - 1) const SizedBox(height: 7),
        ],
      ],
    ),
  );
}
