import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/core/config/app_config.dart';
import 'src/core/network/api_client.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/auth/data/repositories/auth_repository.dart';
import 'src/features/auth/presentation/controllers/auth_controller.dart';
import 'src/features/auth/presentation/screens/auth_gate.dart';
import 'src/features/auth/presentation/screens/password_recovery_screen.dart';
import 'src/features/health_assessment/presentation/controllers/health_assessment_controller.dart';
import 'src/features/health_assessment/data/repositories/health_assessment_repository.dart';
import 'src/features/activity_tracking/presentation/controllers/activity_tracking_controller.dart';
import 'src/features/activity_tracking/data/repositories/activity_repository.dart';
import 'src/features/activity_tracking/data/repositories/device_repository.dart';
import 'src/features/activity_tracking/presentation/controllers/device_tracking_controller.dart';
import 'src/features/vaccinations/presentation/controllers/vaccination_controller.dart';
import 'src/features/vaccinations/data/repositories/vaccination_repository.dart';
import 'src/features/missions/presentation/controllers/missions_controller.dart';
import 'src/features/missions/data/repositories/missions_repository.dart';
import 'src/core/services/notification_service.dart';
import 'src/features/vet_consultation/presentation/controllers/consultation_controller.dart';
import 'src/features/vet_consultation/data/repositories/consultation_repository.dart';
import 'src/features/health_history/health_history.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Staging is the default. Production values must be supplied with
  // --dart-define when a production build is intentionally created.
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );

  runApp(const PettoApp());

  // Start waking Railway while the user is still on Welcome/Login. This
  // hides most Hobby/Serverless cold-start latency without blocking startup.
  unawaited(ApiClient.warmUp());

  // Notification setup is not required for the first frame. Initialize it in
  // the background so a slow platform channel cannot delay app startup.
  unawaited(_initializeNotifications());
}

Future<void> _initializeNotifications() async {
  try {
    await NotificationService.instance.init();
  } catch (_) {
    // A missing channel or denied permission must not stop the app.
  }
}

class PettoApp extends StatefulWidget {
  const PettoApp({super.key});

  @override
  State<PettoApp> createState() => _PettoAppState();
}

class _PettoAppState extends State<PettoApp> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _recoveringPassword = false;

  @override
  void initState() {
    super.initState();
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((state) {
            if (state.event == AuthChangeEvent.passwordRecovery && mounted) {
              setState(() => _recoveringPassword = true);
            }
          });
    } catch (_) {
      // Widget tests can render PettoApp without running the async main().
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(repository: AuthRepositoryImpl()),
        ),
        ChangeNotifierProxyProvider<AuthController, DeviceTrackingController>(
          create: (_) =>
              DeviceTrackingController(repository: DeviceRepositoryImpl()),
          update: (_, auth, controller) {
            final c =
                controller ??
                DeviceTrackingController(repository: DeviceRepositoryImpl());
            auth.addLogoutHandler(c.clearForAccount);
            return c;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => HealthAssessmentController(
            repository: HealthAssessmentRepositoryImpl(),
          ),
        ),
        // ActivityTracking + Missions register a logout handler on the
        // AuthController so signing out wipes the previous account's cached
        // stats — otherwise the next user briefly sees stale numbers.
        ChangeNotifierProxyProvider<AuthController, ActivityTrackingController>(
          create: (_) =>
              ActivityTrackingController(repository: ActivityRepositoryImpl()),
          update: (_, auth, controller) {
            final c =
                controller ??
                ActivityTrackingController(
                  repository: ActivityRepositoryImpl(),
                );
            auth.addLogoutHandler(c.clearForAccount);
            return c;
          },
        ),
        ChangeNotifierProvider(
          create: (_) =>
              VaccinationController(repository: VaccinationRepositoryImpl()),
        ),
        ChangeNotifierProxyProvider<AuthController, ConsultationController>(
          create: (_) => ConsultationController(
            repository: ConsultationRepositoryImpl(),
            healthCardRepository: HealthCardSharingRepositoryImpl(),
          ),
          update: (_, auth, controller) {
            final c =
                controller ??
                ConsultationController(
                  repository: ConsultationRepositoryImpl(),
                  healthCardRepository: HealthCardSharingRepositoryImpl(),
                );
            auth.addLogoutHandler(c.clearForAccount);
            return c;
          },
        ),
        ChangeNotifierProxyProvider<AuthController, MissionsController>(
          create: (_) =>
              MissionsController(repository: MissionsRepositoryImpl()),
          update: (_, auth, controller) {
            final c =
                controller ??
                MissionsController(repository: MissionsRepositoryImpl());
            auth.addLogoutHandler(c.clearForAccount);
            return c;
          },
        ),
        ChangeNotifierProxyProvider<AuthController, HealthHistoryController>(
          create: (_) => HealthHistoryController(),
          update: (_, auth, controller) {
            final c = controller ?? HealthHistoryController();
            auth.addLogoutHandler(c.clearForAccount);
            return c;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Petto - Pet Health Assessment',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: _recoveringPassword
            ? PasswordRecoveryScreen(
                onComplete: () {
                  if (mounted) setState(() => _recoveringPassword = false);
                },
              )
            : const AuthGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
