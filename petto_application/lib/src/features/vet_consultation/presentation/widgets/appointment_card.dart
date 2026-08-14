import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/consultation_models.dart';

class ConsultationAppointmentCard extends StatelessWidget {
  const ConsultationAppointmentCard({
    super.key,
    required this.appointment,
    this.onAccept,
    this.onDecline,
    this.busy = false,
  });

  final AppointmentModel appointment;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final date = appointment.startsAt;
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    final timeLabel =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
    final canRespond =
        appointment.isPending && (onAccept != null || onDecline != null);

    return Card(
      key: ValueKey('appointment-${appointment.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.primaryColor.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event_available_rounded,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Appointment proposal',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                _StatusChip(status: appointment.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$dateLabel at $timeLabel',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            if (appointment.reason?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 5),
              Text(appointment.reason!),
            ],
            if (appointment.isAccepted) ...[
              const SizedBox(height: 8),
              const Text(
                'Added to the pet Calendar with a 30-minute reminder.',
                style: TextStyle(color: AppTheme.mutedText),
              ),
            ],
            if (canRespond) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onDecline,
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : onAccept,
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'accepted' => Colors.green,
      'declined' => Colors.redAccent,
      _ => AppTheme.primaryColor,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
