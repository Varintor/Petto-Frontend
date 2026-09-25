import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/petto_transitions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/petto_loading.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/auth_gate.dart';
import '../../../vet_consultation/data/models/consultation_models.dart';
import '../../../vet_consultation/presentation/controllers/consultation_controller.dart';
import '../../../vet_consultation/presentation/widgets/appointment_card.dart';
import '../../../vet_consultation/presentation/widgets/shared_assessment_card.dart';
import '../../../vet_consultation/presentation/widgets/shared_health_card.dart';

part 'vet_portal_chrome.dart';
part 'vet_portal_dashboard.dart';
part 'vet_portal_conversation.dart';
part 'vet_portal_patient_profile.dart';
part 'vet_portal_schedule.dart';
part 'vet_portal_components.dart';

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
      if (!mounted) return;
      final auth = context.read<AuthController>();
      final veterinarian = auth.currentUser;
      if (veterinarian == null) {
        unawaited(
          context.read<ConsultationController>().loadVetConsultations(),
        );
        return;
      }
      unawaited(
        context.read<ConsultationController>().loadVetWorkspace(
          veterinarianId: veterinarian.id,
          realtimeAccessToken: auth.token,
        ),
      );
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
      PettoPageRoute(builder: (_) => const AuthGate()),
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
        PettoPageRoute(
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
        PettoPageRoute(builder: (_) => const _BackendConversationScreen()),
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
                              duration: AppTheme.motionNormal,
                              reverseDuration: AppTheme.motionFast,
                              switchInCurve: AppTheme.motionCurveSoft,
                              switchOutCurve: AppTheme.motionReverseCurve,
                              layoutBuilder: PettoTransitions.currentChildOnly,
                              transitionBuilder:
                                  PettoTransitions.buildSectionTransition,
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
