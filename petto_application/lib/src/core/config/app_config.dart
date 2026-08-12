/// Application configuration for talking to the Petto FastAPI backend.
///
/// The backend mounts every router under the `/api/v1` prefix
/// (see app/main.py + each router's `prefix="/api/v1"`), so all endpoints
/// here are expressed relative to [apiBaseUrl].
class AppConfig {
  // ============================================================
  // Environment
  // ============================================================

  /// Staging is the default environment for development and Progress 2 demos.
  /// Override these values at build time when targeting another environment:
  ///
  /// flutter run \
  ///   --dart-define=API_BASE_URL=https://api.example.com \
  ///   --dart-define=SUPABASE_URL=https://project.supabase.co \
  ///   --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'staging',
  );

  /// Root URL of the FastAPI backend (no trailing slash or API path).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://petto-backend-staging-staging.up.railway.app',
  );

  /// Supabase project used by Auth, Realtime, and Storage.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ctffimdivmbempiiztsp.supabase.co',
  );

  /// Public client key only. Service-role and database credentials must never
  /// be included in the Flutter application.
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_PbpNNAXjigAzOCF9n3UEUQ_VEeNrABr',
  );

  /// Shared API version prefix.
  static const String apiPrefix = '/api/v1';

  // ============================================================
  // Endpoints
  // ============================================================

  /// Health Assessment (Feature 2) -> POST/GET /api/v1/assessments
  static const String assessmentsEndpoint = '$apiPrefix/assessments';

  /// Backwards-compatible alias (older code referenced this name).
  static const String healthAssessmentEndpoint = assessmentsEndpoint;

  /// Activities (Feature 4 - Mode A walk tracking) -> /api/v1/activities
  static const String activitiesEndpoint = '$apiPrefix/activities';

  /// All activities of a pet -> /api/v1/pets/{petId}/activities
  static String petActivitiesEndpoint(int petId) =>
      '$apiPrefix/pets/$petId/activities';

  /// Aggregated activity stats -> /api/v1/pets/{petId}/activities/stats
  static String petActivityStatsEndpoint(int petId) =>
      '$apiPrefix/pets/$petId/activities/stats';

  /// Today's activities -> /api/v1/pets/{petId}/activities/today
  static String petTodayActivitiesEndpoint(int petId) =>
      '$apiPrefix/pets/$petId/activities/today';

  /// Single activity detail -> /api/v1/activities/{activityId}
  static String activityDetailEndpoint(int activityId) =>
      '$apiPrefix/activities/$activityId';

  /// Assessments for a specific pet -> /api/v1/pets/{petId}/assessments
  static String petAssessmentsEndpoint(int petId) =>
      '$apiPrefix/pets/$petId/assessments';

  // ---- Missions (Daily Missions) ----

  /// Today's missions -> /api/v1/pets/{petId}/missions/today
  static String petTodayMissionsEndpoint(int petId) =>
      '$apiPrefix/pets/$petId/missions/today';

  /// Seed today's missions -> /api/v1/pets/{petId}/missions/seed-today
  static String petSeedTodayMissionsEndpoint(int petId) =>
      '$apiPrefix/pets/$petId/missions/seed-today';

  /// Complete a mission -> /api/v1/missions/{missionId}/complete
  static String completeMissionEndpoint(int missionId) =>
      '$apiPrefix/missions/$missionId/complete';

  // ---- Dashboard Stats ----

  /// Dashboard stats -> /api/v1/pets/{petId}/stats/dashboard
  static String petDashboardStatsEndpoint(int petId) =>
      '$apiPrefix/pets/$petId/stats/dashboard';

  // ---- Auth ----

  static const String registerEndpoint = '$apiPrefix/auth/register';
  static const String loginEndpoint = '$apiPrefix/auth/login';
  static const String meEndpoint = '$apiPrefix/auth/me';
  static const String checkEmailEndpoint = '$apiPrefix/auth/check-email';

  /// Create pet (authenticated) -> POST /api/v1/pets
  static const String petsEndpoint = '$apiPrefix/pets';

  /// Single pet profile -> /api/v1/pets/{petId}
  static String petEndpoint(int petId) => '$apiPrefix/pets/$petId';

  /// My pets -> GET /api/v1/users/{userId}/pets
  static String userPetsEndpoint(int userId) => '$apiPrefix/users/$userId/pets';

  /// Vaccinations -> /api/v1/vaccinations
  static const String vaccinationsEndpoint = '$apiPrefix/vaccinations';

  /// Pet vaccinations -> /api/v1/pets/{petId}/vaccinations
  static String petVaccinationsEndpoint(int petId) =>
      '$apiPrefix/pets/$petId/vaccinations';

  // ============================================================
  // Timeouts (AI processing can take 10-15s, keep these generous)
  // ============================================================

  static const Duration connectionTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 60);
}
