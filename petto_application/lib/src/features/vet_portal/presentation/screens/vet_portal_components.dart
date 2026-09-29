part of 'vet_portal_screen.dart';

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.mine, this.time});

  final String text;
  final bool mine;
  final DateTime? time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: mine ? _VetUi.blush : _VetUi.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (time != null) ...[
              const SizedBox(height: 7),
              Text(
                '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: AppTheme.mutedText.withValues(alpha: 0.72),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Panel(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _TintIcon(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(item.icon, color: item.accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
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

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.highlighted = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: highlighted ? AppTheme.primaryColor : _VetUi.surface,
        borderRadius: BorderRadius.circular(30),
        border: highlighted ? null : Border.all(color: _VetUi.border),
        boxShadow: [
          BoxShadow(
            color: _VetUi.softShadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TintIcon extends StatelessWidget {
  const _TintIcon({
    required this.icon,
    this.filled = false,
    this.compact = false,
  });

  final IconData icon;
  final bool filled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 50.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? AppTheme.primaryColor : _VetUi.blush,
        borderRadius: BorderRadius.circular(compact ? 15 : 18),
      ),
      child: Icon(
        icon,
        color: filled ? Colors.white : AppTheme.primaryColor,
        size: compact ? 21 : 24,
      ),
    );
  }
}

class _MiniTimePill extends StatelessWidget {
  const _MiniTimePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _VetUi.cream,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InitialBadge extends StatelessWidget {
  const _InitialBadge({
    required this.initial,
    this.light = false,
    this.large = false,
  });

  final String initial;
  final bool light;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 72.0 : 48.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withValues(alpha: 0.18)
            : const Color(0xFFF1E6E4),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: light ? Colors.white : AppTheme.primaryColor,
          fontSize: large ? 28 : 19,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PetBadge extends StatelessWidget {
  const _PetBadge({required this.species, this.large = false});

  final String species;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 78.0 : 54.0;
    final cat = species.toLowerCase() == 'cat';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cat ? const Color(0xFFFFE0E4) : const Color(0xFFF5E5D7),
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Icon(
        cat ? Icons.sentiment_satisfied_alt_rounded : Icons.pets_rounded,
        color: AppTheme.primaryColor,
        size: large ? 34 : 25,
      ),
    );
  }
}

class _RiskPill extends StatelessWidget {
  const _RiskPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final high = label.toLowerCase().contains('high');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: high ? AppTheme.primaryColor : const Color(0xFFF4E8E1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: high ? Colors.white : AppTheme.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SmallDot extends StatelessWidget {
  const _SmallDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Patient {
  const _Patient({
    required this.petId,
    required this.consultation,
    required this.name,
    required this.species,
    required this.owner,
    required this.age,
    required this.weight,
    required this.blood,
    required this.risk,
    required this.lastVisit,
    required this.plan,
    required this.note,
    required this.timeline,
  });

  final int petId;
  final ConsultationModel consultation;
  final String name;
  final String species;
  final String owner;
  final String age;
  final String weight;
  final String blood;
  final String risk;
  final String lastVisit;
  final String plan;
  final String note;
  final List<String> timeline;
}

List<_Patient> _patientsFromConsultations(
  List<ConsultationModel> consultations,
) {
  final patients = <int, _Patient>{};
  for (final consultation in consultations) {
    // The endpoint is ordered newest first, so the first consultation for a
    // pet is the summary displayed in the patient workspace.
    patients.putIfAbsent(consultation.petId, () {
      final created = consultation.updatedAt ?? consultation.createdAt;
      final status = consultation.status.toLowerCase();
      final subject = consultation.subject?.trim().isNotEmpty == true
          ? consultation.subject!.trim()
          : consultation.notes?.trim().isNotEmpty == true
          ? consultation.notes!.trim()
          : 'Veterinary consultation';
      return _Patient(
        petId: consultation.petId,
        consultation: consultation,
        name: consultation.petName ?? 'Pet #${consultation.petId}',
        species: consultation.petSpecies ?? 'Pet',
        owner: consultation.ownerName ?? 'Owner not available',
        age: 'Not shared',
        weight: 'Not shared',
        blood: 'Not shared',
        risk: consultation.priority == 'urgent'
            ? 'Urgent'
            : status == 'pending'
            ? 'Pending'
            : consultation.status,
        lastVisit: '${created.day}/${created.month}/${created.year}',
        plan: consultation.providerName ?? 'Petto consultation',
        note: subject,
        timeline: [
          'Consultation #${consultation.id} is ${consultation.status.toLowerCase()}.',
          if (consultation.providerName != null)
            'Provider: ${consultation.providerName}.',
          'Open Messages to review only the Health Card or records explicitly shared by the owner.',
        ],
      );
    });
  }
  return patients.values.toList(growable: false);
}
