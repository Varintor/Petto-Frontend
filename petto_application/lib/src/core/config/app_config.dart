/// Application configuration for talking to the Petto FastAPI backend.
///
/// The backend mounts every router under the `/api/v1` prefix
/// (see app/main.py + each router's `prefix="/api/v1"`), so all endpoints
/// here are expressed relative to [apiBaseUrl].
class AppConfig {
  // ============================================================
  // Base URL
  // ============================================================

  /// Ngrok URL - Local FastAPI Development (Tunneling)
  static const String _ngrokUrl =
      'https://egging-sculptor-operator.ngrok-free.dev';

  /// Railway Production URL (HTTPS)
  static const String _railwayUrl =
      'https://petto-backend-production.up.railway.app';

  /// LAN URL - Local Development (Android device on same Wi-Fi, etc.)
  static const String _lanUrl = 'http://192.168.1.22:8000';

  /// Local URL - same-machine development. Works for Flutter web in Chrome
  /// and iOS simulator. Android emulator must use http://10.0.2.2:8000.
  static const String _localUrl = 'http://localhost:8000';

  /// Root URL of the backend (no trailing slash, no path).
  /// Currently: Railway production FastAPI.
  static const String apiBaseUrl = _railwayUrl;

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
