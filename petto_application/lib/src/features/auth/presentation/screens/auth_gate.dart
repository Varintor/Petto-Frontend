import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../../../pet_management/presentation/screens/auth_onboarding_screen.dart';
import '../../../health_assessment/presentation/screens/home_screen.dart';

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

    switch (auth.status) {
      case AuthStatus.loading:
        return const Scaffold(
          backgroundColor: Color(0xFFFFFCF6),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PETTO',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFontFamily,
                    color: Color(0xFF4E1F22),
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF7B3034),
                  ),
                ),
              ],
            ),
          ),
        );
      case AuthStatus.authenticated:
        return const HomeScreen();
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
        return AuthOnboardingScreen(startAtLogin: startAtLogin);
    }
  }
}
