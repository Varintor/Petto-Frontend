class AppConfig {
  // API Base URL
  static const String apiBaseUrl = 'http://192.168.1.22:8000';

  // API Endpoints
  static const String healthAssessmentEndpoint = '/api/health-assessment';

  // App Settings - Extended timeout for AI processing (Gemini may take 10-15s)
  static const Duration connectionTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 60);
}
