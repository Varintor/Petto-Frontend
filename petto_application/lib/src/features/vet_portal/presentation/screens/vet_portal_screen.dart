import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/auth_gate.dart';
import '../../../vet_consultation/data/models/consultation_models.dart';
import '../../../vet_consultation/presentation/controllers/consultation_controller.dart';
import '../../../vet_consultation/presentation/widgets/appointment_card.dart';
import '../../../vet_consultation/presentation/widgets/shared_assessment_card.dart';
import '../../../vet_consultation/presentation/widgets/shared_health_card.dart';

enum _VetSection { dashboard, patients, messages, profile }

class VetPortalScreen extends StatefulWidget {
  const VetPortalScreen({super.key});

  @override
  State<VetPortalScreen> createState() => _VetPortalScreenState();
}

class _VetPortalScreenState extends State<VetPortalScreen> {
  _VetSection _section = _VetSection.dashboard;
  int _selectedPatient = 0;
  int _selectedMessage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ConsultationController>().loadVetConsultations();
      }
    });
  }

  String get _vetName {
    final name = context.read<AuthController>().currentUser?.name?.trim();
    return name == null || name.isEmpty ? 'Dr. Sarah' : name;
  }

  Future<void> _logout() async {
    await context.read<AuthController>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  void _openPatient(int index, bool compact) {
    final patients = _patientsFromConsultations(
      context.read<ConsultationController>().consultations,
    );
    if (index < 0 || index >= patients.length) return;
    if (compact) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _PatientDetailsScreen(patient: patients[index]),
        ),
      );
      return;
    }
    setState(() {
      _selectedPatient = index;
      _section = _VetSection.patients;
    });
  }

  void _openMessage(int index, bool compact) {
    final controller = context.read<ConsultationController>();
    if (index < 0 || index >= controller.consultations.length) return;
    unawaited(
      controller.openConsultation(
        controller.consultations[index],
        realtimeAccessToken: context.read<AuthController>().token,
      ),
    );
    if (compact) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const _BackendConversationScreen()),
      );
      return;
    }
    setState(() {
      _selectedMessage = index;
      _section = _VetSection.messages;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 920;
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Stack(
            children: [
              const Positioned.fill(child: _VetBackground()),
              SafeArea(
                child: Row(
                  children: [
                    if (desktop)
                      _VetSidebar(
                        section: _section,
                        vetName: _vetName,
                        onSelect: (value) => setState(() => _section = value),
                        onLogout: _logout,
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          if (!desktop)
                            _MobileHeader(
                              section: _section,
                              vetName: _vetName,
                              onLogout: _logout,
                            ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeOutCubic,
                              transitionBuilder: (child, animation) {
                                final curved = CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                );
                                return FadeTransition(
                                  opacity: curved,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.018, 0),
                                      end: Offset.zero,
                                    ).animate(curved),
                                    child: child,
                                  ),
                                );
                              },
                              child: KeyedSubtree(
                                key: ValueKey(_section),
                                child: switch (_section) {
                                  _VetSection.dashboard => _DashboardView(
                                    vetName: _vetName,
                                    compact: !desktop,
                                    onOpenPatients: () => setState(
                                      () => _section = _VetSection.patients,
                                    ),
                                    onOpenMessages: () => setState(
                                      () => _section = _VetSection.messages,
                                    ),
                                    onOpenPatient: (index) =>
                                        _openPatient(index, !desktop),
                                    onOpenMessage: (index) =>
                                        _openMessage(index, !desktop),
                                  ),
                                  _VetSection.patients => _PatientsView(
                                    selectedIndex: _selectedPatient,
                                    compact: !desktop,
                                    onSelect: (index) =>
                                        _openPatient(index, !desktop),
                                  ),
                                  _VetSection.messages => _BackendMessagesView(
                                    selectedIndex: _selectedMessage,
                                    compact: !desktop,
                                    onSelect: (index) =>
                                        _openMessage(index, !desktop),
                                  ),
                                  _VetSection.profile => _ProfileView(
                                    vetName: _vetName,
                                    email:
                                        context
                                            .read<AuthController>()
                                            .currentUser
                                            ?.email ??
                                        'Veterinarian account',
                                    onLogout: _logout,
                                  ),
                                },
                              ),
                            ),
                          ),
                          if (!desktop)
                            _VetBottomNav(
                              section: _section,
                              onSelect: (value) =>
                                  setState(() => _section = value),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VetUi {
  static const surface = Color(0xFFFFFCF8);
  static const cream = Color(0xFFFFF4EA);
  static const blush = Color(0xFFFFECE8);
  static const gold = Color(0xFFD3A33B);
  static final border = AppTheme.primaryColor.withValues(alpha: 0.13);
  static final softShadow = AppTheme.primaryColor.withValues(alpha: 0.06);
}

extension on _VetSection {
  String get label => switch (this) {
    _VetSection.dashboard => 'Dashboard',
    _VetSection.patients => 'Patients',
    _VetSection.messages => 'Messages',
    _VetSection.profile => 'Profile',
  };

  IconData get icon => switch (this) {
    _VetSection.dashboard => Icons.space_dashboard_rounded,
    _VetSection.patients => Icons.pets_rounded,
    _VetSection.messages => Icons.forum_rounded,
    _VetSection.profile => Icons.person_rounded,
  };
}

class _VetBackground extends StatelessWidget {
  const _VetBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotPainter(),
      child: const ColoredBox(color: AppTheme.backgroundColor),
    );
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.035);
    for (double y = 22; y < size.height; y += 36) {
      for (double x = 22; x < size.width; x += 36) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VetSidebar extends StatelessWidget {
  const _VetSidebar({
    required this.section,
    required this.vetName,
    required this.onSelect,
    required this.onLogout,
  });

  final _VetSection section;
  final String vetName;
  final ValueChanged<_VetSection> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 246,
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ClinicLogo(),
          const SizedBox(height: 28),
          for (final item in _VetSection.values)
            _SideNavItem(
              item: item,
              selected: item == section,
              onTap: () => onSelect(item),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const _InitialBadge(initial: 'S', light: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vetName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Veterinarian',
                        style: TextStyle(
                          color: Color(0xFFE8CBCD),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicLogo extends StatelessWidget {
  const _ClinicLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PETTO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontFamily: AppTheme.displayFontFamily,
              ),
            ),
            Text(
              'CLINICAL',
              style: TextStyle(
                color: Color(0xFFE8CBCD),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _VetSection item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: selected ? AppTheme.primaryColor : Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  color: selected ? AppTheme.primaryColor : Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.section,
    required this.vetName,
    required this.onLogout,
  });

  final _VetSection section;
  final String vetName;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: _Panel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _TintIcon(icon: section.icon, filled: true, compact: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.label,
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: AppTheme.displayFontFamily,
                    ),
                  ),
                  Text(
                    vetName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Log out',
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              color: AppTheme.primaryColor,
              style: IconButton.styleFrom(
                backgroundColor: _VetUi.blush,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VetBottomNav extends StatelessWidget {
  const _VetBottomNav({required this.section, required this.onSelect});

  final _VetSection section;
  final ValueChanged<_VetSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 7, 16, 12),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: _VetUi.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _VetUi.border),
        boxShadow: [
          BoxShadow(
            color: _VetUi.softShadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final item in _VetSection.values)
            Expanded(
              child: _BottomItem(
                item: item,
                selected: item == section,
                onTap: () => onSelect(item),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _VetSection item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: selected ? Colors.white : AppTheme.mutedText,
              size: 21,
            ),
            const SizedBox(height: 3),
            FittedBox(
              child: Text(
                item.label,
                style: TextStyle(
                  color: selected ? Colors.white : AppTheme.mutedText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        return _VetScroll(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageTitle(
                title: 'Good afternoon, $vetName',
                subtitle: 'Assigned Petto consultations and shared records.',
              ),
              const SizedBox(height: 18),
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
                const Center(child: CircularProgressIndicator())
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
          return const Center(child: CircularProgressIndicator());
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
          return const Center(child: CircularProgressIndicator());
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

class _BackendConversationScreen extends StatelessWidget {
  const _BackendConversationScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(child: _BackendConversationPanel(showBack: true)),
    );
  }
}

class _BackendConversationPanel extends StatefulWidget {
  const _BackendConversationPanel({this.showBack = false});

  final bool showBack;

  @override
  State<_BackendConversationPanel> createState() =>
      _BackendConversationPanelState();
}

class _BackendConversationPanelState extends State<_BackendConversationPanel> {
  final _message = TextEditingController();
  final _conversationScrollController = ScrollController();
  int? _visibleConsultationId;
  int _visibleConversationItemCount = -1;
  bool _sending = false;
  bool _proposingAppointment = false;
  int? _changingAppointmentId;

  @override
  void dispose() {
    _conversationScrollController.dispose();
    _message.dispose();
    super.dispose();
  }

  void _scheduleScrollToLatest(int consultationId, int itemCount) {
    if (_visibleConsultationId == consultationId &&
        _visibleConversationItemCount == itemCount) {
      return;
    }
    _visibleConsultationId = consultationId;
    _visibleConversationItemCount = itemCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_conversationScrollController.hasClients) return;
      _conversationScrollController.animateTo(
        _conversationScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final sent = await context.read<ConsultationController>().sendMessage(text);
    if (!mounted) return;
    if (sent) _message.clear();
    setState(() => _sending = false);
  }

  Future<void> _proposeAppointment() async {
    if (_proposingAppointment) return;
    final now = DateTime.now();
    final schedule = await _showVetScheduleDialog(
      initialDateTime: now.add(const Duration(days: 1)),
      title: 'Plan appointment',
      subtitle: 'Pick a gentle follow-up time for this pet.',
      actionLabel: 'Propose',
    );
    if (schedule == null || !mounted) return;
    if (!schedule.startsAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose an appointment time in the future.'),
        ),
      );
      return;
    }

    setState(() => _proposingAppointment = true);
    await context.read<ConsultationController>().proposeAppointment(
      startsAt: schedule.startsAt,
      reason: schedule.reason,
    );
    if (!mounted) return;
    setState(() => _proposingAppointment = false);
  }

  Future<void> _rescheduleAppointment(AppointmentModel appointment) async {
    if (_changingAppointmentId != null) return;
    final now = DateTime.now();
    final schedule = await _showVetScheduleDialog(
      initialDateTime: appointment.startsAt.isAfter(now)
          ? appointment.startsAt
          : now.add(const Duration(days: 1)),
      initialReason: appointment.reason ?? '',
      title: 'Reschedule visit',
      subtitle: 'Move this appointment to a clearer time.',
      actionLabel: 'Update',
    );
    if (schedule == null || !mounted) return;
    if (!schedule.startsAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a time in the future.')),
      );
      return;
    }

    setState(() => _changingAppointmentId = appointment.id);
    await context.read<ConsultationController>().updateAppointment(
      appointment.id,
      startsAt: schedule.startsAt,
      reason: schedule.reason,
    );
    if (!mounted) return;
    setState(() => _changingAppointmentId = null);
  }

  Future<_VetScheduleResult?> _showVetScheduleDialog({
    required DateTime initialDateTime,
    required String title,
    required String subtitle,
    required String actionLabel,
    String initialReason = '',
  }) {
    return showDialog<_VetScheduleResult>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (dialogContext) => _VetScheduleDialog(
        initialDateTime: initialDateTime,
        initialReason: initialReason,
        title: title,
        subtitle: subtitle,
        actionLabel: actionLabel,
      ),
    );
  }

  Future<void> _cancelAppointment(AppointmentModel appointment) async {
    if (_changingAppointmentId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text(
          'If accepted, it will also be removed from the owner’s Calendar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep appointment'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _changingAppointmentId = appointment.id);
    await context.read<ConsultationController>().cancelAppointment(
      appointment.id,
    );
    if (!mounted) return;
    setState(() => _changingAppointmentId = null);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsultationController>(
      builder: (context, controller, _) {
        final consultation = controller.active;
        if (consultation == null) {
          return const _VetLoadState(
            message: 'Select a consultation to read its messages.',
          );
        }
        _scheduleScrollToLatest(
          consultation.id,
          controller.messages.length +
              controller.appointments.length +
              controller.sharedAssessments.length +
              controller.sharedHealthCards.length,
        );
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: _Panel(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (widget.showBack) ...[
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppTheme.primaryColor,
                        style: IconButton.styleFrom(
                          backgroundColor: _VetUi.blush,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _PetBadge(species: consultation.petSpecies ?? 'Pet'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            consultation.petName ??
                                'Pet #${consultation.petId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: AppTheme.displayFontFamily,
                            ),
                          ),
                          const SizedBox(height: 3),
                          _ConnectionPill(
                            connected: controller.realtimeConnected,
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Propose appointment',
                      onPressed: _proposingAppointment || consultation.isClosed
                          ? null
                          : _proposeAppointment,
                      icon: _proposingAppointment
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.event_available_rounded),
                      color: AppTheme.primaryColor,
                      style: IconButton.styleFrom(
                        backgroundColor: _VetUi.blush,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      tooltip: 'Refresh messages',
                      onPressed: controller.loading
                          ? null
                          : controller.refreshMessages,
                      icon: const Icon(Icons.refresh_rounded),
                      color: AppTheme.primaryColor,
                      style: IconButton.styleFrom(
                        backgroundColor: _VetUi.cream,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: _InlineAlert(message: controller.error!),
              ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _VetUi.border),
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    controller.loading &&
                        controller.messages.isEmpty &&
                        controller.appointments.isEmpty
                    ? const _AssistantLoading()
                    : _ConversationList(
                        controller: controller,
                        scrollController: _conversationScrollController,
                        changingAppointmentId: _changingAppointmentId,
                        onRescheduleAppointment: _rescheduleAppointment,
                        onCancelAppointment: _cancelAppointment,
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                10,
                18,
                18 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: consultation.isClosed
                  ? _Panel(
                      padding: const EdgeInsets.all(14),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: AppTheme.primaryColor,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This consultation is closed. Messages are read-only.',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _ChatComposer(
                      controller: _message,
                      sending: _sending,
                      onSend: _send,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({
    required this.controller,
    required this.scrollController,
    required this.changingAppointmentId,
    required this.onRescheduleAppointment,
    required this.onCancelAppointment,
  });

  final ConsultationController controller;
  final ScrollController scrollController;
  final int? changingAppointmentId;
  final ValueChanged<AppointmentModel> onRescheduleAppointment;
  final ValueChanged<AppointmentModel> onCancelAppointment;

  @override
  Widget build(BuildContext context) {
    final empty =
        controller.messages.isEmpty &&
        controller.appointments.isEmpty &&
        controller.sharedAssessments.isEmpty &&
        controller.sharedHealthCards.isEmpty;
    if (empty) {
      return const _ChatEmptyState();
    }
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        for (final assessment in controller.sharedAssessments)
          SharedAssessmentPanel(assessment: assessment),
        for (final sharedCard in controller.sharedHealthCards)
          SharedHealthCardPanel(card: sharedCard),
        for (final appointment in controller.appointments)
          ConsultationAppointmentCard(
            appointment: appointment,
            busy: changingAppointmentId == appointment.id,
            onReschedule: appointment.canBeChanged
                ? () => onRescheduleAppointment(appointment)
                : null,
            onCancel: appointment.canBeChanged
                ? () => onCancelAppointment(appointment)
                : null,
          ),
        for (final message in controller.messages)
          _ChatBubble(
            text: message.content ?? 'Attachment',
            mine: message.isFromVet,
            time: message.createdAt,
          ),
      ],
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: _VetUi.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _VetUi.blush,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppTheme.primaryColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !sending,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Type a reply...',
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            height: 50,
            child: IconButton.filled(
              tooltip: 'Send message',
              onPressed: sending ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _TintIcon(icon: Icons.forum_rounded, filled: true),
            const SizedBox(height: 12),
            const Text(
              'No messages yet',
              style: TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontFamily: AppTheme.displayFontFamily,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start with a quick update or propose a follow-up appointment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineAlert extends StatelessWidget {
  const _InlineAlert({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFEF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final color = connected ? const Color(0xFF6E8A54) : _VetUi.gold;
    return Container(
      key: const Key('vet-chat-connection-status'),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? 'Realtime connected' : 'Reconnecting',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantLoading extends StatefulWidget {
  const _AssistantLoading();

  @override
  State<_AssistantLoading> createState() => _AssistantLoadingState();
}

class _AssistantLoadingState extends State<_AssistantLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final lift = 1 - (_controller.value - 0.5).abs() * 2;
          return Transform.translate(
            offset: Offset(0, -5 * lift),
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _TintIcon(icon: Icons.support_agent_rounded, filled: true),
            const SizedBox(height: 12),
            const Text(
              'Loading conversation',
              style: TextStyle(
                color: AppTheme.secondaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.vetName,
    required this.email,
    required this.onLogout,
  });

  final String vetName;
  final String email;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return _VetScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PageTitle(
            title: 'Profile',
            subtitle: 'Clinic account and working preferences.',
          ),
          const SizedBox(height: 18),
          _Panel(
            child: Row(
              children: [
                const _InitialBadge(initial: 'S', large: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vetName,
                        style: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          fontFamily: AppTheme.displayFontFamily,
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          color: AppTheme.mutedText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _ProfileTile(
            icon: Icons.medical_services_rounded,
            title: 'Specialty',
            value: 'General wellness',
          ),
          const _ProfileTile(
            icon: Icons.schedule_rounded,
            title: 'Clinic hours',
            value: '09:00 - 18:00',
          ),
          const _ProfileTile(
            icon: Icons.verified_rounded,
            title: 'Status',
            value: 'Available for care team chat',
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
  }
}

class _PatientDetailsScreen extends StatelessWidget {
  const _PatientDetailsScreen({required this.patient});

  final _Patient patient;

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
                  _PatientDetails(patient: patient),
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
  const _PatientDetails({required this.patient});

  final _Patient patient;

  @override
  Widget build(BuildContext context) {
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
                        const _CareTag(label: 'Shared record'),
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
                      const _CareTag(label: 'Shared record'),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        _PatientInfoGrid(patient: patient),
        const SizedBox(height: 14),
        _ClinicalNotesPanel(patient: patient),
      ],
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

class _VetScheduleResult {
  const _VetScheduleResult({required this.startsAt, required this.reason});

  final DateTime startsAt;
  final String reason;
}

class _VetScheduleDialog extends StatefulWidget {
  const _VetScheduleDialog({
    required this.initialDateTime,
    required this.initialReason,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
  });

  final DateTime initialDateTime;
  final String initialReason;
  final String title;
  final String subtitle;
  final String actionLabel;

  @override
  State<_VetScheduleDialog> createState() => _VetScheduleDialogState();
}

class _VetScheduleDialogState extends State<_VetScheduleDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late final TextEditingController _reasonController;

  static const _timeSlots = [
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 10, minute: 30),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 14, minute: 30),
    TimeOfDay(hour: 16, minute: 0),
    TimeOfDay(hour: 18, minute: 0),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDateTime.year,
      widget.initialDateTime.month,
      widget.initialDateTime.day,
    );
    _selectedTime = TimeOfDay.fromDateTime(widget.initialDateTime);
    _reasonController = TextEditingController(text: widget.initialReason);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  DateTime get _startsAt => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );

  List<TimeOfDay> get _availableSlots {
    final exists = _timeSlots.any(
      (slot) =>
          slot.hour == _selectedTime.hour &&
          slot.minute == _selectedTime.minute,
    );
    if (exists) return _timeSlots;
    final slots = [..._timeSlots, _selectedTime];
    slots.sort(
      (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
    );
    return slots;
  }

  void _submit() {
    Navigator.of(context).pop(
      _VetScheduleResult(
        startsAt: _startsAt,
        reason: _reasonController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dates = List.generate(
      10,
      (index) => DateTime(now.year, now.month, now.day + index + 1),
    );
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _VetUi.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.14),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(21),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: AppTheme.secondaryText,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                fontFamily: AppTheme.displayFontFamily,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                color: AppTheme.mutedText,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _VetUi.blush.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.09),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _weekdayLabel(_selectedDate),
                                style: TextStyle(
                                  color: AppTheme.mutedText,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_monthLabel(_selectedDate.month)} ${_selectedDate.day}',
                                style: const TextStyle(
                                  color: AppTheme.secondaryText,
                                  fontSize: 29,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: AppTheme.displayFontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            _timeLabel(_selectedTime),
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select date',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: dates.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 9),
                      itemBuilder: (context, index) {
                        final date = dates[index];
                        final selected = _sameDay(date, _selectedDate);
                        return _ScheduleDateChip(
                          date: date,
                          selected: selected,
                          onTap: () => setState(() => _selectedDate = date),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Available time',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      for (final slot in _availableSlots)
                        _ScheduleTimeChip(
                          time: slot,
                          selected:
                              slot.hour == _selectedTime.hour &&
                              slot.minute == _selectedTime.minute,
                          onTap: () => setState(() => _selectedTime = slot),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonController,
                    minLines: 2,
                    maxLines: 3,
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Short note for the owner',
                      hintStyle: TextStyle(
                        color: AppTheme.mutedText.withValues(alpha: 0.68),
                        fontWeight: FontWeight.w700,
                      ),
                      prefixIcon: const Icon(
                        Icons.edit_note_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.72),
                      contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(color: _VetUi.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(color: _VetUi.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: BorderSide(color: _VetUi.border),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.check_rounded, size: 19),
                          label: Text(widget.actionLabel),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _weekdayLabel(DateTime date) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[date.weekday - 1];
  }

  static String _monthLabel(int month) {
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
    return labels[month - 1];
  }

  static String _timeLabel(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _ScheduleDateChip extends StatelessWidget {
  const _ScheduleDateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 66,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(
                alpha: selected ? 0.14 : 0.04,
              ),
              blurRadius: selected ? 14 : 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _VetScheduleDialogState._weekdayLabel(date),
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${date.day}',
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.secondaryText,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleTimeChip extends StatelessWidget {
  const _ScheduleTimeChip({
    required this.time,
    required this.selected,
    required this.onTap,
  });

  final TimeOfDay time;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? _VetUi.blush : _VetUi.cream,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor.withValues(alpha: 0.36)
                : const Color(0xFFEAD7BD),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.schedule_rounded,
              color: selected ? AppTheme.primaryColor : const Color(0xFFD3A33B),
              size: 17,
            ),
            const SizedBox(width: 6),
            Text(
              _VetScheduleDialogState._timeLabel(time),
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
