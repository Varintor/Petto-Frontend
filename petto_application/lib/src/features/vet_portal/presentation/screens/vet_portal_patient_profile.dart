// Kept for the compact patient-profile layout used in design validation.
// ignore_for_file: unused_element

part of 'vet_portal_screen.dart';

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.vetId,
    required this.vetName,
    required this.email,
    required this.onLogout,
  });

  final int? vetId;
  final String vetName;
  final String email;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsultationController>(
      builder: (context, controller, _) {
        VetModel? profile;
        for (final vet in controller.vets) {
          if (vet.id == vetId) {
            profile = vet;
            break;
          }
        }
        final displayName = profile?.name.trim().isNotEmpty == true
            ? profile!.name.trim()
            : vetName;
        final displayEmail = profile?.email?.trim().isNotEmpty == true
            ? profile!.email!.trim()
            : email;
        final initial = displayName.trim().isEmpty
            ? 'V'
            : displayName.trim().characters.first.toUpperCase();
        String valueOrNotSet(String? value) =>
            value == null || value.trim().isEmpty ? 'Not set' : value.trim();

        return _VetScroll(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PageTitle(
                title: 'Profile',
                subtitle: 'Verified veterinarian account information.',
              ),
              const SizedBox(height: 18),
              _Panel(
                child: Row(
                  children: [
                    _InitialBadge(initial: initial, large: true),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              fontFamily: AppTheme.displayFontFamily,
                            ),
                          ),
                          Text(
                            displayEmail,
                            style: TextStyle(
                              color: AppTheme.mutedText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ProfileStatusChip(
                                icon: Icons.verified_rounded,
                                label: profile == null
                                    ? 'Profile unavailable'
                                    : profile.verificationStatus == 'approved'
                                    ? 'Verified'
                                    : profile.verificationStatus,
                                active:
                                    profile?.verificationStatus == 'approved',
                              ),
                              _ProfileStatusChip(
                                icon: Icons.circle,
                                label: profile?.isOnline == true
                                    ? 'Online'
                                    : 'Offline',
                                active: profile?.isOnline == true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ProfileTile(
                icon: Icons.medical_services_rounded,
                title: 'Specialty',
                value: valueOrNotSet(profile?.specialty),
              ),
              _ProfileTile(
                icon: Icons.local_hospital_rounded,
                title: 'Clinic / Hospital',
                value: valueOrNotSet(profile?.clinicName),
              ),
              _ProfileTile(
                icon: Icons.badge_rounded,
                title: 'Professional license',
                value: valueOrNotSet(profile?.licenseNumber),
              ),
              _ProfileTile(
                icon: Icons.forum_rounded,
                title: 'Consultation status',
                value: profile?.isAcceptingConsultations == true
                    ? 'Accepting new consultations'
                    : 'Not accepting new consultations',
              ),
              const SizedBox(height: 8),
              Text(
                'Professional details are verified and managed by the Petto administrator.',
                style: TextStyle(
                  color: AppTheme.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: 220,
                height: 58,
                child: FilledButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileStatusChip extends StatelessWidget {
  const _ProfileStatusChip({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF3B7A4A) : AppTheme.mutedText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientDetailsScreen extends StatelessWidget {
  const _PatientDetailsScreen({
    required this.patient,
    required this.onRequestHealthCard,
    required this.onOpenConsultation,
  });

  final _Patient patient;
  final VoidCallback onRequestHealthCard;
  final VoidCallback onOpenConsultation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: _VetBackground()),
          SafeArea(
            child: _VetScroll(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  _PatientDetails(
                    patient: patient,
                    onRequestHealthCard: onRequestHealthCard,
                    onOpenConsultation: onOpenConsultation,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VetScroll extends StatelessWidget {
  const _VetScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: child,
        ),
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.secondaryText,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            fontFamily: AppTheme.displayFontFamily,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.mutedText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxWidth < 620;
        return _Panel(
          highlighted: true,
          padding: const EdgeInsets.all(18),
          child: tight
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroPanelCopy(title: title, subtitle: subtitle),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 48,
                      child: _HeroPanelButton(
                        text: actionText,
                        onPressed: onAction,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _HeroPanelCopy(title: title, subtitle: subtitle),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      height: 48,
                      child: _HeroPanelButton(
                        text: actionText,
                        onPressed: onAction,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _HeroPanelCopy extends StatelessWidget {
  const _HeroPanelCopy({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(21),
          ),
          child: const Icon(
            Icons.monitor_heart_rounded,
            color: AppTheme.primaryColor,
            size: 29,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFamily: AppTheme.displayFontFamily,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFF6E3E4),
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroPanelButton extends StatelessWidget {
  const _HeroPanelButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.forum_rounded, size: 18),
      label: Text(text),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TintIcon(icon: icon, compact: true),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontFamily: AppTheme.displayFontFamily,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: AppTheme.displayFontFamily,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.arrow_forward_rounded, size: 17),
          label: Text(action),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _PatientRow extends StatelessWidget {
  const _PatientRow({
    required this.patient,
    required this.onTap,
    this.selected = false,
  });

  final _Patient patient;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return _ListCard(
      selected: selected,
      onTap: onTap,
      leading: _PetBadge(species: patient.species),
      title: patient.name,
      subtitle: '${patient.species} • ${patient.owner}',
      trailing: _RiskPill(label: patient.risk),
      footer: patient.note,
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.onTap,
    this.trailing,
    this.selected = false,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final String footer;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? _VetUi.blush : _VetUi.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryColor.withValues(alpha: 0.42)
                  : _VetUi.border,
              width: selected ? 1.7 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _VetUi.softShadow,
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        ?trailing,
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.mutedText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      footer,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 14,
                        height: 1.35,
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

class _PatientDetails extends StatelessWidget {
  const _PatientDetails({
    required this.patient,
    required this.onRequestHealthCard,
    required this.onOpenConsultation,
  });

  final _Patient patient;
  final VoidCallback onRequestHealthCard;
  final VoidCallback onOpenConsultation;

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsultationController>(
      builder: (context, controller, _) {
        final activeMatches = controller.active?.id == patient.consultation.id;
        SharedHealthCardModel? sharedCard;
        if (activeMatches) {
          for (final card in controller.sharedHealthCards) {
            if (card.petId == patient.petId && card.revokedAt == null) {
              sharedCard = card;
              break;
            }
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Panel(
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 520;
                  final identity = Row(
                    children: [
                      _PetBadge(species: patient.species, large: true),
                      const SizedBox(width: 16),
                      Expanded(child: _PatientIdentity(patient: patient)),
                    ],
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        identity,
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _RiskPill(label: patient.risk),
                            const _CareTag(label: 'Assigned consultation'),
                          ],
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: identity),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _RiskPill(label: patient.risk),
                          const SizedBox(height: 8),
                          const _CareTag(label: 'Assigned consultation'),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            if (controller.loading && activeMatches)
              const PettoCardSkeleton(height: 210)
            else if (sharedCard != null) ...[
              _MedicalAlertPanel(card: sharedCard),
              const SizedBox(height: 10),
              SharedHealthCardPanel(
                key: const Key('vet-patient-health-card'),
                card: sharedCard,
                initiallyExpanded: true,
              ),
            ] else
              _HealthCardAccessPanel(
                patient: patient,
                requestAlreadySent: controller.messages.any(
                  (message) =>
                      message.senderType.toLowerCase() == 'vet' &&
                      (message.content ?? '').contains(
                        "share ${patient.name}'s Pet Health Card",
                      ),
                ),
                onRequest: onRequestHealthCard,
                onOpenConsultation: onOpenConsultation,
              ),
            const SizedBox(height: 14),
            _ClinicalNotesPanel(patient: patient),
          ],
        );
      },
    );
  }
}

class _HealthCardAccessPanel extends StatelessWidget {
  const _HealthCardAccessPanel({
    required this.patient,
    required this.requestAlreadySent,
    required this.onRequest,
    required this.onOpenConsultation,
  });

  final _Patient patient;
  final bool requestAlreadySent;
  final VoidCallback onRequest;
  final VoidCallback onOpenConsultation;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _TintIcon(icon: Icons.health_and_safety_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pet Health Card not shared',
                      style: TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: AppTheme.displayFontFamily,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${patient.owner} controls access to this medical summary.',
                      style: const TextStyle(
                        color: AppTheme.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Request the card to review allergies, conditions, medication, vaccination, activity, and the latest assessment.',
            style: TextStyle(
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const Key('vet-patient-request-health-card'),
                onPressed: requestAlreadySent ? null : onRequest,
                icon: Icon(
                  requestAlreadySent
                      ? Icons.mark_email_read_rounded
                      : Icons.mark_email_unread_rounded,
                ),
                label: Text(
                  requestAlreadySent ? 'Request sent' : 'Request Health Card',
                ),
              ),
              OutlinedButton.icon(
                onPressed: onOpenConsultation,
                icon: const Icon(Icons.forum_rounded),
                label: const Text('Open consultation'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedicalAlertPanel extends StatelessWidget {
  const _MedicalAlertPanel({required this.card});

  final SharedHealthCardModel card;

  @override
  Widget build(BuildContext context) {
    final latestAssessment = card.snapshot['latest_assessment'] as Map?;
    final risk = (latestAssessment?['risk_level'] as String? ?? '').trim();
    final alerts = <String>[
      if (card.allergies.isNotEmpty) 'Allergies: ${card.allergies.join(', ')}',
      if (card.chronicConditions.isNotEmpty)
        'Conditions: ${card.chronicConditions.join(', ')}',
      if (risk.toLowerCase() == 'high' || risk.toLowerCase() == 'high risk')
        'Latest assessment: $risk',
    ];
    final hasAlerts = alerts.isNotEmpty;
    final foreground = hasAlerts
        ? const Color(0xFF8A1C1C)
        : const Color(0xFF356140);
    final background = hasAlerts
        ? const Color(0xFFFFECEC)
        : const Color(0xFFEAF6ED);
    return Container(
      key: const Key('vet-patient-medical-alerts'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasAlerts
                ? Icons.warning_amber_rounded
                : Icons.verified_user_rounded,
            color: foreground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAlerts ? 'Medical alerts' : 'No critical alerts recorded',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (hasAlerts) ...[
                  const SizedBox(height: 6),
                  for (final alert in alerts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '• $alert',
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientIdentity extends StatelessWidget {
  const _PatientIdentity({required this.patient});

  final _Patient patient;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          patient.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.secondaryText,
            fontSize: 33,
            fontWeight: FontWeight.w900,
            fontFamily: AppTheme.displayFontFamily,
          ),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 7,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _MiniTimePill(text: patient.species),
            Text(
              patient.owner,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              patient.age,
              style: TextStyle(
                color: AppTheme.mutedText.withValues(alpha: 0.82),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PatientInfoGrid extends StatelessWidget {
  const _PatientInfoGrid({required this.patient});

  final _Patient patient;

  @override
  Widget build(BuildContext context) {
    final items = [
      _InfoItem(
        icon: Icons.monitor_weight_rounded,
        label: 'Weight',
        value: patient.weight,
        accent: const Color(0xFFD3A33B),
      ),
      _InfoItem(
        icon: Icons.bloodtype_rounded,
        label: 'Blood',
        value: patient.blood,
        accent: AppTheme.primaryColor,
      ),
      _InfoItem(
        icon: Icons.event_available_rounded,
        label: 'Last visit',
        value: patient.lastVisit,
        accent: const Color(0xFF8F6F4E),
      ),
      _InfoItem(
        icon: Icons.task_alt_rounded,
        label: 'Care plan',
        value: patient.plan,
        accent: const Color(0xFF71875A),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 620 ? 2 : 4;
        final spacing = 10.0;
        final tileWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: tileWidth.clamp(138.0, constraints.maxWidth).toDouble(),
                child: _InfoTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _InfoItem {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
}

class _CareTag extends StatelessWidget {
  const _CareTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E7),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFE8CFA9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_rounded,
            color: Color(0xFFD3A33B),
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalNotesPanel extends StatelessWidget {
  const _ClinicalNotesPanel({required this.patient});

  final _Patient patient;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _TintIcon(icon: Icons.notes_rounded, compact: true),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Clinical Notes',
                  style: TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: AppTheme.displayFontFamily,
                  ),
                ),
              ),
              _MiniTimePill(text: '${patient.timeline.length} notes'),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < patient.timeline.length; i++)
            _ClinicalNoteRow(
              text: patient.timeline[i],
              last: i == patient.timeline.length - 1,
            ),
        ],
      ),
    );
  }
}

class _ClinicalNoteRow extends StatelessWidget {
  const _ClinicalNoteRow({required this.text, required this.last});

  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: last ? _VetUi.cream : _VetUi.blush.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.07),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SmallDot(),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: AppTheme.mutedText,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
