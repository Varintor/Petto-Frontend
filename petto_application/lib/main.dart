import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/core/config/app_config.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/auth/data/repositories/auth_repository.dart';
import 'src/features/auth/presentation/controllers/auth_controller.dart';
import 'src/features/auth/presentation/screens/auth_gate.dart';
import 'src/features/health_assessment/presentation/controllers/health_assessment_controller.dart';
import 'src/features/health_assessment/data/repositories/health_assessment_repository.dart';
import 'src/features/activity_tracking/presentation/controllers/activity_tracking_controller.dart';
import 'src/features/activity_tracking/data/repositories/activity_repository.dart';
import 'src/features/vaccinations/presentation/controllers/vaccination_controller.dart';
import 'src/features/vaccinations/data/repositories/vaccination_repository.dart';
import 'src/features/missions/presentation/controllers/missions_controller.dart';
import 'src/features/missions/data/repositories/missions_repository.dart';
import 'src/core/services/notification_service.dart';
import 'src/features/vet_consultation/presentation/controllers/consultation_controller.dart';
import 'src/features/vet_consultation/data/repositories/consultation_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Staging is the default. Production values must be supplied with
  // --dart-define when a production build is intentionally created.
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );

  // Prepare OS-level notifications (no-op on web). Failures are swallowed so a
  // missing channel or denied permission can't block the app from starting.
  try {
    await NotificationService.instance.init();
  } catch (_) {}

  runApp(const PettoApp());
}

class PettoApp extends StatelessWidget {
  const PettoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(repository: AuthRepositoryImpl()),
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
          create: (_) =>
              ConsultationController(repository: ConsultationRepositoryImpl()),
          update: (_, auth, controller) {
            final c =
                controller ??
                ConsultationController(
                  repository: ConsultationRepositoryImpl(),
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
      ],
      child: MaterialApp(
        title: 'Petto - Pet Health Assessment',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const AuthGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
