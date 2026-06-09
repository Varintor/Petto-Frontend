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
  static const String _ngrokUrl = 'https://egging-sculptor-operator.ngrok-free.dev';

  /// Railway Production URL (HTTPS)
  static const String _railwayUrl = 'https://petto-backend-production.up.railway.app';

  /// LAN URL - Local Development
  static const String _lanUrl = 'http://192.168.1.22:8000';

  /// Root URL of the backend (no trailing slash, no path).
  /// Production: Railway (stable HTTPS, always-on — no ngrok/dev machine).
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

  /// Vaccinations (สมุดวัคซีน) -> /api/v1/vaccinations
  static const String vaccinationsEndpoint = '$apiPrefix/vaccinations';

  /// Pet vaccinations -> /api/v1/pets/{petId}/vaccinations
  static String petVaccinationsEndpoint(int petId) =>
      '$apiPrefix/pets/$petId/vaccinations';

  // ============================================================
  // Defaults
  // ============================================================

  /// Until real auth + pet management exists, both the assessment and the
  /// activity features submit against this pet id (the mock pet created by
  /// the backend's /api/v1/setup-mock-data endpoint).
  static const int defaultPetId = 1;

  // ============================================================
  // Timeouts (AI processing can take 10-15s, keep these generous)
  // ============================================================

  static const Duration connectionTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 60);
}
