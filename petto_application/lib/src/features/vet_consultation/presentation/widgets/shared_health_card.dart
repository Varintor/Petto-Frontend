import 'package:flutter/material.dart';

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
    return Card(
      color: const Color(0xFFF7EEEC),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.badge_rounded)),
        title: Text(
          '${card.petName} • Shared Health ID',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          'Snapshot shared ${card.sharedAt.day}/${card.sharedAt.month}/${card.sharedAt.year}',
        ),
        trailing: onRevoke == null
            ? null
            : IconButton(
                tooltip: 'Stop sharing',
                onPressed: onRevoke,
                icon: const Icon(Icons.link_off_rounded),
              ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Species', snapshot['species'] as String?),
          _row('Breed', snapshot['breed'] as String?),
          _row('Blood type', snapshot['blood_type'] as String?),
          _row('Allergies', _items(card.allergies)),
          _row('Conditions', _items(card.chronicConditions)),
          _row('Medication', _items(card.currentMedications)),
          if (latestAssessment != null)
            _row(
              'Latest assessment',
              '${latestAssessment['risk_level'] ?? latestAssessment['status'] ?? 'Recorded'} • ${latestAssessment['title']}',
            ),
          if (latestVaccination != null)
            _row('Latest vaccination', latestVaccination['title'] as String?),
          if (recentActivity != null)
            _row('Recent activity', recentActivity['summary'] as String?),
          if (card.profileUpdatedAt != null)
            _row(
              'Health profile updated',
              '${card.profileUpdatedAt!.day}/${card.profileUpdatedAt!.month}/${card.profileUpdatedAt!.year} '
                  '${card.profileUpdatedAt!.hour.toString().padLeft(2, '0')}:'
                  '${card.profileUpdatedAt!.minute.toString().padLeft(2, '0')}',
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String? value) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Text(
      '$label: ${value == null || value.trim().isEmpty ? 'Not set' : value}',
    ),
  );
}
