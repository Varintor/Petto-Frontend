import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/petto_transitions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/petto_loading.dart';
import '../controllers/auth_controller.dart';
import '../../../pet_management/presentation/screens/auth_onboarding_screen.dart';
import '../../../health_assessment/presentation/screens/home_screen.dart';
import '../../../vet_portal/presentation/screens/vet_portal_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    Future.microtask(() => auth.tryAutoLogin());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final Widget currentScreen;

    switch (auth.status) {
      case AuthStatus.loading:
        currentScreen = const Scaffold(
          key: ValueKey('auth-loading'),
          backgroundColor: AppTheme.backgroundColor,
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: PettoInlineProgress(
                title: 'Welcome back to Petto',
                subtitle: 'Preparing your pet care space.',
                icon: Icons.pets_rounded,
              ),
            ),
          ),
        );
        break;
      case AuthStatus.authenticated:
        currentScreen = auth.isVeterinarian
            ? const VetPortalScreen(key: ValueKey('vet-portal'))
            : const HomeScreen(key: ValueKey('owner-home'));
        break;
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        // After an explicit logout, drop the user on the login form rather
        // than the marketing intro page — they already know the app.
        final startAtLogin = auth.justLoggedOut;
        if (startAtLogin) {
          // Consume the flag once we've handed it off so a later rebuild
          // (e.g. the user tapping "back" to the intro) isn't overridden.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            auth.acknowledgeLogout();
          });
        }
        currentScreen = AuthOnboardingScreen(
          key: const ValueKey('auth-onboarding'),
          startAtLogin: startAtLogin,
        );
        break;
    }

    return AnimatedSwitcher(
      duration: AppTheme.pageTransitionDuration,
      reverseDuration: AppTheme.pageTransitionReverseDuration,
      switchInCurve: AppTheme.motionCurveSoft,
      switchOutCurve: AppTheme.motionReverseCurve,
      layoutBuilder: PettoTransitions.currentChildOnly,
      transitionBuilder: PettoTransitions.buildSectionTransition,
      child: currentScreen,
    );
  }
}
