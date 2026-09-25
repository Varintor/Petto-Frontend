part of 'vet_portal_screen.dart';

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.vetName,
    required this.compact,
    required this.onOpenPatients,
    required this.onOpenMessages,
    required this.onOpenPatient,
    required this.onOpenMessage,
  });

  final String vetName;
  final bool compact;
  final VoidCallback onOpenPatients;
  final VoidCallback onOpenMessages;
  final ValueChanged<int> onOpenPatient;
  final ValueChanged<int> onOpenMessage;

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsultationController>(
      builder: (context, controller, _) {
        final consultations = controller.consultations;
        final patients = _patientsFromConsultations(consultations);
        final activeCount = consultations
            .where((item) => !item.isClosed)
            .length;
        final pendingCount = consultations
            .where((item) => item.status.toUpperCase() == 'PENDING')
            .length;
        final urgentCount = consultations
            .where(
              (item) =>
                  item.priority.toLowerCase() == 'urgent' && !item.isClosed,
            )
            .length;
        return _VetScroll(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageTitle(
                title: 'Good afternoon, $vetName',
                subtitle: 'Assigned Petto consultations and shared records.',
              ),
              const SizedBox(height: 18),
              if (urgentCount > 0) ...[
                _UrgentInboxBanner(count: urgentCount, onOpen: onOpenMessages),
                const SizedBox(height: 14),
              ],
              _HeroPanel(
                title: 'Consultation Workspace',
                subtitle: consultations.isEmpty
                    ? 'No owner has started a consultation with you yet.'
                    : '$activeCount open consultation${activeCount == 1 ? '' : 's'} '
                          'across ${patients.length} patient${patients.length == 1 ? '' : 's'}.',
                actionText: 'Open messages',
                onAction: onOpenMessages,
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: compact ? 2 : 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: compact ? 1.62 : 1.82,
                children: [
                  _MetricCard(
                    label: 'Patients',
                    value: '${patients.length}',
                    icon: Icons.pets_rounded,
                  ),
                  _MetricCard(
                    label: 'Assigned',
                    value: '${consultations.length}',
                    icon: Icons.event_note_rounded,
                  ),
                  _MetricCard(
                    label: 'Open',
                    value: '$activeCount',
                    icon: Icons.forum_rounded,
                  ),
                  _MetricCard(
                    label: 'Pending',
                    value: '$pendingCount',
                    icon: Icons.hourglass_top_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionHeader(
                title: 'Assigned Patients',
                action: 'View all',
                onAction: onOpenPatients,
              ),
              const SizedBox(height: 10),
              if (controller.loading && consultations.isEmpty)
                const Column(
                  children: [
                    PettoCardSkeleton(height: 88, compact: true),
                    SizedBox(height: 10),
                    PettoCardSkeleton(height: 88, compact: true),
                  ],
                )
              else if (controller.error != null && consultations.isEmpty)
                _VetLoadState(
                  message: controller.error!,
                  onRetry: controller.loadVetConsultations,
                )
              else if (patients.isEmpty)
                const _VetLoadState(message: 'No assigned patients yet.')
              else
                for (var i = 0; i < patients.length && i < 2; i++)
                  _PatientRow(
                    patient: patients[i],
                    onTap: () => onOpenPatient(i),
                  ),
              if (consultations.isNotEmpty) ...[
                const SizedBox(height: 14),
                _SectionHeader(
                  title: 'Recent Consultations',
                  action: 'Open',
                  onAction: onOpenMessages,
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < consultations.length && i < 2; i++)
                  _ConsultationRow(
                    consultation: consultations[i],
                    selected: false,
                    onTap: () => onOpenMessage(i),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _UrgentInboxBanner extends StatelessWidget {
  const _UrgentInboxBanner({required this.count, required this.onOpen});

  final int count;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFECEC),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        key: const Key('vet-urgent-inbox-banner'),
        borderRadius: BorderRadius.circular(22),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.sos_rounded, color: Color(0xFFB42318)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$count urgent request${count == 1 ? '' : 's'} waiting',
                  style: const TextStyle(
                    color: Color(0xFF7A271A),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Color(0xFFB42318)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientsView extends StatelessWidget {
  const _PatientsView({
    required this.selectedIndex,
    required this.compact,
    required this.onSelect,
  });

  final int selectedIndex;
  final bool compact;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsultationController>(
      builder: (context, controller, _) {
        final patients = _patientsFromConsultations(controller.consultations);
        if (controller.loading && patients.isEmpty) {
          return const PettoPageSkeleton(itemCount: 4, compact: true);
        }
        if (controller.error != null && patients.isEmpty) {
          return _VetLoadState(
            message: controller.error!,
            onRetry: controller.loadVetConsultations,
          );
        }
        if (patients.isEmpty) {
          return const _VetLoadState(
            message:
                'No assigned patients yet. Patients appear after an owner starts a consultation.',
          );
        }
        final safeIndex = selectedIndex.clamp(0, patients.length - 1);
        final list = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PageTitle(
              title: 'Patients',
              subtitle: 'Pets assigned through Petto consultations.',
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < patients.length; i++)
              _PatientRow(
                patient: patients[i],
                selected: !compact && i == safeIndex,
                onTap: () => onSelect(i),
              ),
          ],
        );
        if (compact) return _VetScroll(child: list);
        return Row(
          children: [
            SizedBox(width: 390, child: _VetScroll(child: list)),
            Expanded(
              child: _VetScroll(
                child: _PatientDetails(patient: patients[safeIndex]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BackendMessagesView extends StatelessWidget {
  const _BackendMessagesView({
    required this.selectedIndex,
    required this.compact,
    required this.onSelect,
  });

  final int selectedIndex;
  final bool compact;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsultationController>(
      builder: (context, controller, _) {
        if (controller.loading && controller.consultations.isEmpty) {
          return const PettoPageSkeleton(itemCount: 4, compact: true);
        }
        if (controller.error != null && controller.consultations.isEmpty) {
          return _VetLoadState(
            message: controller.error!,
            onRetry: controller.loadVetConsultations,
          );
        }
        if (controller.consultations.isEmpty) {
          return const _VetLoadState(
            message: 'No consultations have been assigned yet.',
          );
        }

        final safeIndex = selectedIndex.clamp(
          0,
          controller.consultations.length - 1,
        );
        final list = _ConsultationList(
          consultations: controller.consultations,
          selectedIndex: safeIndex,
          onSelect: onSelect,
        );
        if (compact) return _VetScroll(child: list);
        return Row(
          children: [
            SizedBox(width: 390, child: _VetScroll(child: list)),
            const Expanded(child: _BackendConversationPanel()),
          ],
        );
      },
    );
  }
}

class _ConsultationList extends StatelessWidget {
  const _ConsultationList({
    required this.consultations,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<ConsultationModel> consultations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PageTitle(
          title: 'Messages',
          subtitle: 'Owner updates and follow-up conversations.',
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < consultations.length; index++)
          _ConsultationRow(
            consultation: consultations[index],
            selected: index == selectedIndex,
            onTap: () => onSelect(index),
          ),
      ],
    );
  }
}

class _ConsultationRow extends StatelessWidget {
  const _ConsultationRow({
    required this.consultation,
    required this.selected,
    required this.onTap,
  });

  final ConsultationModel consultation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timestamp = consultation.updatedAt ?? consultation.createdAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: Key('vet-consultation-${consultation.id}'),
        borderRadius: BorderRadius.circular(25),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? _VetUi.blush : _VetUi.surface,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryColor.withValues(alpha: 0.38)
                  : _VetUi.border,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              consultation.priority == 'urgent'
                  ? const _TintIcon(
                      icon: Icons.sos_rounded,
                      filled: true,
                      compact: true,
                    )
                  : const _InitialBadge(initial: 'P'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            consultation.petName ??
                                'Pet #${consultation.petId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MiniTimePill(
                          text:
                              '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      consultation.subject?.trim().isNotEmpty == true
                          ? consultation.subject!
                          : consultation.notes?.trim().isNotEmpty == true
                          ? consultation.notes!
                          : 'Veterinary consultation',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.mutedText,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VetLoadState extends StatelessWidget {
  const _VetLoadState({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _Panel(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _TintIcon(
                icon: Icons.health_and_safety_rounded,
                filled: true,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
