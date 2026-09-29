import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/petto_loading.dart';
import '../../data/models/consultation_models.dart';

class ConsultationAppointmentCard extends StatefulWidget {
  const ConsultationAppointmentCard({
    super.key,
    required this.appointment,
    this.onAccept,
    this.onDecline,
    this.onReschedule,
    this.onCancel,
    this.busy = false,
  });

  final AppointmentModel appointment;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;
  final bool busy;

  @override
  State<ConsultationAppointmentCard> createState() =>
      _ConsultationAppointmentCardState();
}

class _ConsultationAppointmentCardState
    extends State<ConsultationAppointmentCard> {
  late bool _expanded = widget.appointment.isPending;

  @override
  void didUpdateWidget(covariant ConsultationAppointmentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appointment.status != widget.appointment.status &&
        !widget.appointment.isPending) {
      _expanded = false;
    }
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final date = appointment.startsAt;
    final timeLabel =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
    final dateLabel = '${date.day} ${_monthLabel(date.month)} ${date.year}';
    final canRespond =
        appointment.isPending &&
        (widget.onAccept != null || widget.onDecline != null);
    final statusColor = _statusColor(appointment.status);
    final reason = appointment.reason?.trim();

    return Container(
      key: ValueKey('appointment-${appointment.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: -10,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              expanded: _expanded,
              label: _expanded
                  ? 'Collapse appointment details'
                  : 'Expand appointment details',
              child: InkWell(
                onTap: _toggleExpanded,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 9, 10, 9),
                  child: Row(
                    children: [
                      _CompactDateTile(date: date, color: statusColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Appointment · $timeLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: AppTheme.secondaryText,
                                    fontWeight: FontWeight.w900,
                                    height: 1.05,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    dateLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppTheme.mutedText,
                                          fontWeight: FontWeight.w800,
                                          height: 1.1,
                                        ),
                                  ),
                                ),
                                Text(
                                  ' · ',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(color: AppTheme.mutedText),
                                ),
                                Text(
                                  _statusLabel(appointment.status),
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: statusColor,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(
                          icon: Icons.schedule_rounded,
                          text: timeLabel,
                          color: AppTheme.accentColor,
                        ),
                        _InfoPill(
                          icon: Icons.calendar_month_rounded,
                          text: dateLabel,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                    if (reason?.isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.creamSurfaceColor.withValues(
                            alpha: 0.9,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.accentColor.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.notes_rounded,
                              color: AppTheme.accentColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                reason!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
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
                    if (appointment.isAccepted) ...[
                      const SizedBox(height: 9),
                      _SoftConfirmation(
                        text: 'Added to Calendar with a 30-minute reminder.',
                        color: statusColor,
                      ),
                    ],
                    if (canRespond) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.busy ? null : widget.onDecline,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                side: BorderSide(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.22,
                                  ),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('Decline'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: widget.busy ? null : widget.onAccept,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: widget.busy
                                  ? const PettoButtonProgress(
                                      width: 26,
                                      height: 6,
                                    )
                                  : const Text('Accept'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!canRespond &&
                        appointment.canBeChanged &&
                        (widget.onReschedule != null ||
                            widget.onCancel != null)) ...[
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          if (widget.onReschedule != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: widget.busy
                                    ? null
                                    : widget.onReschedule,
                                icon: const Icon(
                                  Icons.edit_calendar_rounded,
                                  size: 18,
                                ),
                                label: const Text('Reschedule'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          if (widget.onReschedule != null &&
                              widget.onCancel != null)
                            const SizedBox(width: 10),
                          if (widget.onCancel != null)
                            Expanded(
                              child: TextButton.icon(
                                onPressed: widget.busy ? null : widget.onCancel,
                                icon: const Icon(
                                  Icons.event_busy_rounded,
                                  size: 18,
                                ),
                                label: const Text('Cancel'),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 42),
                                  foregroundColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompactDateTile extends StatelessWidget {
  const _CompactDateTile({required this.date, required this.color});

  final DateTime date;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            date.day.toString().padLeft(2, '0'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _monthLabel(date.month).toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftConfirmation extends StatelessWidget {
  const _SoftConfirmation({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: color, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.secondaryText,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  return switch (status) {
    'accepted' => const Color(0xFF6F8454),
    'declined' => const Color(0xFFC45A62),
    'cancelled' => AppTheme.mutedText,
    _ => AppTheme.primaryColor,
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'accepted' => 'ACCEPTED',
    'declined' => 'DECLINED',
    'cancelled' => 'CANCELLED',
    _ => 'NEEDS RESPONSE',
  };
}

String _monthLabel(int month) {
  const labels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (month < 1 || month > labels.length) return '';
  return labels[month - 1];
}
