import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/auth_gate.dart';
import '../../../vet_consultation/data/models/consultation_models.dart';
import '../../../vet_consultation/presentation/controllers/consultation_controller.dart';

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
    if (compact) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _PatientDetailsScreen(patient: _patients[index]),
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
    unawaited(controller.openConsultation(controller.consultations[index]));
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
                              duration: const Duration(milliseconds: 180),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          const _InitialBadge(initial: 'S'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.label,
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontFamily: AppTheme.displayFontFamily,
                  ),
                ),
                Text(
                  vetName,
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            color: AppTheme.primaryColor,
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
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
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          item.icon,
          color: selected ? Colors.white : AppTheme.mutedText,
          size: 22,
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
    return _VetScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageTitle(
            title: 'Good afternoon, $vetName',
            subtitle: 'A calm workspace for today\'s patient care.',
          ),
          const SizedBox(height: 18),
          _HeroPanel(
            title: 'Today\'s Clinic',
            subtitle: '3 appointments, 2 active chats, 1 high-risk follow-up.',
            actionText: 'Open messages',
            onAction: onOpenMessages,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: compact ? 2 : 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: compact ? 1.42 : 1.55,
            children: const [
              _MetricCard(
                label: 'Patients',
                value: '24',
                icon: Icons.pets_rounded,
              ),
              _MetricCard(
                label: 'Consults',
                value: '8',
                icon: Icons.event_note_rounded,
              ),
              _MetricCard(
                label: 'Unread',
                value: '5',
                icon: Icons.mark_chat_unread_rounded,
              ),
              _MetricCard(
                label: 'Alerts',
                value: '2',
                icon: Icons.monitor_heart_rounded,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Priority Patients',
            action: 'View all',
            onAction: onOpenPatients,
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < 2; i++)
            _PatientRow(patient: _patients[i], onTap: () => onOpenPatient(i)),
          const SizedBox(height: 14),
          _SectionHeader(
            title: 'Care Team Inbox',
            action: 'Open',
            onAction: onOpenMessages,
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < 2; i++)
            _ThreadRow(thread: _threads[i], onTap: () => onOpenMessage(i)),
        ],
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
    if (compact) {
      return _VetScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PageTitle(
              title: 'Patients',
              subtitle: 'Recent cases and active care plans.',
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < _patients.length; i++)
              _PatientRow(patient: _patients[i], onTap: () => onSelect(i)),
          ],
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 390,
          child: _VetScroll(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PageTitle(
                  title: 'Patients',
                  subtitle: 'Recent cases and active care plans.',
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < _patients.length; i++)
                  _PatientRow(
                    patient: _patients[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelect(i),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _VetScroll(
            child: _PatientDetails(patient: _patients[selectedIndex]),
          ),
        ),
      ],
    );
  }
}

class _MessagesView extends StatelessWidget {
  const _MessagesView({
    required this.selectedIndex,
    required this.compact,
    required this.onSelect,
  });

  final int selectedIndex;
  final bool compact;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _VetScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PageTitle(
              title: 'Messages',
              subtitle: 'Owner updates and follow-up conversations.',
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < _threads.length; i++)
              _ThreadRow(thread: _threads[i], onTap: () => onSelect(i)),
          ],
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 390,
          child: _VetScroll(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PageTitle(
                  title: 'Messages',
                  subtitle: 'Owner updates and follow-up conversations.',
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < _threads.length; i++)
                  _ThreadRow(
                    thread: _threads[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelect(i),
                  ),
              ],
            ),
          ),
        ),
        Expanded(child: _ConversationPanel(thread: _threads[selectedIndex])),
      ],
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
      child: Material(
        color: selected ? const Color(0xFFF4E8E6) : const Color(0xFFFFFCF9),
        borderRadius: BorderRadius.circular(22),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          leading: const _InitialBadge(initial: 'P'),
          title: Text(
            consultation.petName ?? 'Pet #${consultation.petId}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            consultation.notes?.trim().isNotEmpty == true
                ? consultation.notes!
                : 'Veterinary consultation',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: AppTheme.mutedText,
              fontWeight: FontWeight.w800,
            ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
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
  Timer? _refreshTimer;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        context.read<ConsultationController>().refreshNewMessages();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _message.dispose();
    super.dispose();
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
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                children: [
                  if (widget.showBack) ...[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      consultation.petName ?? 'Pet #${consultation.petId}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh messages',
                    onPressed: controller.loading
                        ? null
                        : controller.refreshMessages,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  controller.error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            Expanded(
              child: controller.loading && controller.messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(18),
                      itemCount: controller.messages.length,
                      itemBuilder: (context, index) {
                        final message = controller.messages[index];
                        return _ChatBubble(
                          text: message.content ?? 'Attachment',
                          mine: message.isFromVet,
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      enabled: !_sending,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Type a reply...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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

class _ConversationScreen extends StatelessWidget {
  const _ConversationScreen({required this.thread});

  final _Thread thread;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: _VetBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          thread.owner,
                          style: const TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontFamily: AppTheme.displayFontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _ConversationPanel(thread: thread)),
              ],
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
    return _Panel(
      highlighted: true,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.monitor_heart_rounded,
              color: AppTheme.primaryColor,
              size: 31,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontFamily: AppTheme.displayFontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFF3DDDF),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            child: Text(actionText),
          ),
        ],
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TintIcon(icon: icon),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              fontFamily: AppTheme.displayFontFamily,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.mutedText,
              fontWeight: FontWeight.w800,
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
        TextButton(onPressed: onAction, child: Text(action)),
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

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({
    required this.thread,
    required this.onTap,
    this.selected = false,
  });

  final _Thread thread;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return _ListCard(
      selected: selected,
      onTap: onTap,
      leading: _TintIcon(icon: Icons.forum_rounded),
      title: thread.owner,
      subtitle: '${thread.petName} • ${thread.time}',
      trailing: thread.unread
          ? const _SmallDot()
          : const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.primaryColor,
            ),
      footer: thread.preview,
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
            color: selected ? const Color(0xFFFFF4F0) : const Color(0xFFFFFCF9),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryColor.withValues(alpha: 0.42)
                  : AppTheme.primaryColor.withValues(alpha: 0.1),
              width: selected ? 1.7 : 1,
            ),
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
                      children: [
                        Expanded(
                          child: Text(
                            title,
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
          child: Row(
            children: [
              _PetBadge(species: patient.species, large: true),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        fontFamily: AppTheme.displayFontFamily,
                      ),
                    ),
                    Text(
                      '${patient.species} • ${patient.age} • ${patient.owner}',
                      style: TextStyle(
                        color: AppTheme.mutedText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _RiskPill(label: patient.risk),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width < 720 ? 2 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.7,
          children: [
            _InfoTile(label: 'Weight', value: patient.weight),
            _InfoTile(label: 'Blood', value: patient.blood),
            _InfoTile(label: 'Last visit', value: patient.lastVisit),
            _InfoTile(label: 'Care plan', value: patient.plan),
          ],
        ),
        const SizedBox(height: 14),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Clinical Notes',
                style: TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontFamily: AppTheme.displayFontFamily,
                ),
              ),
              const SizedBox(height: 12),
              for (final note in patient.timeline)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SmallDot(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          note,
                          style: TextStyle(
                            color: AppTheme.mutedText,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConversationPanel extends StatelessWidget {
  const _ConversationPanel({required this.thread});

  final _Thread thread;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _VetScroll(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PageTitle(
                  title: thread.owner,
                  subtitle: '${thread.petName} • ${thread.topic}',
                ),
                const SizedBox(height: 18),
                _ChatBubble(text: thread.preview, mine: false),
                _ChatBubble(
                  text:
                      'Thanks for the update. I will review the recent notes.',
                  mine: true,
                ),
                _ChatBubble(
                  text: 'Please send a photo if the symptom changes today.',
                  mine: false,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Type a reply...',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton.filled(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_forward_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.mine});

  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFF4E8E6) : const Color(0xFFFFFCF9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.secondaryText,
            fontSize: 16,
            height: 1.35,
          ),
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
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.mutedText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 21,
              fontWeight: FontWeight.w900,
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
        color: highlighted ? AppTheme.primaryColor : const Color(0xFFFFFCF9),
        borderRadius: BorderRadius.circular(30),
        border: highlighted
            ? null
            : Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.055),
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
  const _TintIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: AppTheme.primaryColor),
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: species == 'Cat'
            ? const Color(0xFFF6DCDD)
            : const Color(0xFFF5E5D7),
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Icon(
        species == 'Cat' ? Icons.cruelty_free_rounded : Icons.pets_rounded,
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

class _Thread {
  const _Thread({
    required this.owner,
    required this.petName,
    required this.topic,
    required this.preview,
    required this.time,
    required this.unread,
  });

  final String owner;
  final String petName;
  final String topic;
  final String preview;
  final String time;
  final bool unread;
}

const _patients = [
  _Patient(
    name: 'Milo',
    species: 'Cat',
    owner: 'Warit',
    age: '4 years',
    weight: '4.8 kg',
    blood: 'A',
    risk: 'High risk',
    lastVisit: 'Today',
    plan: 'Skin care',
    note: 'Skin irritation review with persistent scratching.',
    timeline: [
      'AI check flagged redness and scratching around the left ear.',
      'Owner reports appetite remains normal with mild sleep changes.',
      'Recommended follow-up photo in 24 hours if redness persists.',
    ],
  ),
  _Patient(
    name: 'Buddy',
    species: 'Dog',
    owner: 'Aom',
    age: '2 years',
    weight: '9.2 kg',
    blood: 'DEA 1.1',
    risk: 'Normal',
    lastVisit: 'Yesterday',
    plan: 'Activity',
    note: 'Short walk completed. Resting heart pattern looks calm.',
    timeline: [
      'Walk summary reviewed with stable pace and normal recovery.',
      'Hydration reminder sent after activity.',
      'Next wellness check scheduled for next week.',
    ],
  ),
  _Patient(
    name: 'Luna',
    species: 'Cat',
    owner: 'Mint',
    age: '1 year',
    weight: '3.9 kg',
    blood: 'B',
    risk: 'Watch',
    lastVisit: '2 days',
    plan: 'Diet',
    note: 'Digestive discomfort follow-up after diet change.',
    timeline: [
      'No vomiting reported today.',
      'Recommend smaller meals and water tracking.',
      'Escalate if appetite drops or lethargy appears.',
    ],
  ),
];

const _threads = [
  _Thread(
    owner: 'Warit',
    petName: 'Milo',
    topic: 'Skin follow-up',
    preview:
        'Milo is still scratching near the ear. Should I send another photo?',
    time: '09:24',
    unread: true,
  ),
  _Thread(
    owner: 'Aom',
    petName: 'Buddy',
    topic: 'Walk recovery',
    preview: 'Buddy finished the short walk and is resting now.',
    time: '10:10',
    unread: true,
  ),
  _Thread(
    owner: 'Mint',
    petName: 'Luna',
    topic: 'Diet check',
    preview: 'She ate half of the new food this morning.',
    time: 'Yesterday',
    unread: false,
  ),
];
