import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/health_assessment/presentation/controllers/health_assessment_controller.dart';
import 'src/features/health_assessment/data/repositories/health_assessment_repository.dart';
import 'src/features/activity_tracking/presentation/controllers/activity_tracking_controller.dart';
import 'src/features/activity_tracking/data/repositories/activity_repository.dart';
import 'src/features/vaccinations/presentation/controllers/vaccination_controller.dart';
import 'src/features/vaccinations/data/repositories/vaccination_repository.dart';
import 'src/features/pet_management/presentation/screens/auth_onboarding_screen.dart';

void main() {
  runApp(const PettoApp());
}

class PettoApp extends StatelessWidget {
  const PettoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HealthAssessmentController(
            repository: HealthAssessmentRepositoryImpl(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ActivityTrackingController(repository: ActivityRepositoryImpl()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              VaccinationController(repository: VaccinationRepositoryImpl()),
        ),
      ],
      child: MaterialApp(
        title: 'Petto - Pet Health Assessment',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const AuthOnboardingScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
