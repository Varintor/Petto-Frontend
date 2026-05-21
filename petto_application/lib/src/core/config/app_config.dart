import 'package:flutter/foundation.dart' show kIsWeb;

/// Application Configuration
/// ตั้งค่า URL และ Timeout สำหรับเชื่อมต่อกับ FastAPI Backend
///
/// Railway Production URL: https://petto-backend-production.up.railway.app
class AppConfig {
  // ============================================================
  // API URLs - Railway Production
  // ============================================================

  /// Ngrok URL - Local FastAPI Development (Tunneling)
  /// หมายเหตุ: ต้องมี / ท้ายสุดเพื่อให้ Dio ต่อ path ถูกต้อง
  static const String _ngrokUrl = 'https://egging-sculptor-operator.ngrok-free.dev/api/v1/';

  /// Railway Production URL (HTTPS)
  static const String _railwayUrl = 'https://petto-backend-production.up.railway.app';

  /// URL สำหรับ Local Development (ถ้าต้องการ test กับ local backend)
  static const String _localUrl = 'http://localhost:8000';
  static const String _emulatorUrl = 'http://10.0.2.2:8000';
  static const String _lanUrl = 'http://192.168.1.22:8000';

  /// 🌟 ใช้ Ngrok URL (Local FastAPI Development)
  static const String apiBaseUrl = _ngrokUrl;

  /// สำหรับ Development - ใช้ URL นี้ถ้าต้องการรัน local
  static const String developmentUrl = _localUrl;

  /// สำหรับ Real Device - ใช้ LAN URL ถ้าต้องการ test
  static const String realDeviceUrl = _lanUrl;

  // ============================================================
  // API Endpoints
  // ============================================================
  // หมายเหตุ: ไม่มี / นำหน้า เพราะ Dio จะ append เข้ากับ baseUrl
  // ถ้าใส่ / นำหน้า Dio จะ replace path ทั้งหมด
  // หมายเหตุ: Base URL มี /api/v1 อยู่แล้ว จึงไม่ต้องใส่ซ้ำ
  // หมายเหตุ: Health endpoint อยู่ที่ root level ไม่ใช่ /api/v1/health

  static const String assessmentsEndpoint = 'assessments';
  static const String healthCheckEndpoint = '/health';  // / นำหน้าเพื่อ replace baseUrl

  /// Full URL สำหรับ debugging (baseUrl มี / ท้ายสุดอยู่แล้ว)
  static String get fullAssessmentsUrl => '$apiBaseUrl$assessmentsEndpoint';
  static String get fullHealthCheckUrl => apiBaseUrl.replaceFirst('/api/v1/', '') + healthCheckEndpoint;

  // ============================================================
  // Timeout Settings (60 วินาทีสำหรับ AI Processing บน Cloud)
  // ============================================================

  static const Duration connectionTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 60);

  // ============================================================
  // Environment Info
  // ============================================================

  static String get currentEnvironment {
    if (apiBaseUrl.contains('ngrok')) return 'Ngrok Development (Local Tunnel)';
    if (apiBaseUrl.contains('railway')) return 'Railway Production';
    if (apiBaseUrl.contains('localhost')) return 'Local Development';
    if (apiBaseUrl.contains('10.0.2.2')) return 'Android Emulator';
    return 'Unknown';
  }

  static bool get isProduction => apiBaseUrl.contains('railway');
  static bool get isDevelopment => !isProduction;

  /// แสดงค่า config ทั้งหมดใน console (สำหรับ debugging)
  static void printConfig() {
    print('');
    print('═══════════════════════════════════════════════════════════════');
    print('🔧 Petto App Configuration');
    print('═══════════════════════════════════════════════════════════════');
    print('Environment: $currentEnvironment');
    print('Platform: ${kIsWeb ? "Flutter Web" : "Android/Mobile"}');
    print('');
    print('🌐 API Configuration:');
    print('   Base URL: $apiBaseUrl');
    print('   Assessments: $fullAssessmentsUrl');
    print('   Health Check: $fullHealthCheckUrl');
    print('');
    print('⏱️  Timeout Settings:');
    print('   Connection: ${connectionTimeout.inSeconds}s');
    print('   Receive: ${receiveTimeout.inSeconds}s');
    print('   Send: ${sendTimeout.inSeconds}s');
    print('═══════════════════════════════════════════════════════════════');
    print('');
  }
}
