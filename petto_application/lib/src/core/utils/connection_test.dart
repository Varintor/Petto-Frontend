import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// Helper class สำหรับทดสอบการเชื่อมต่อกับ Backend
class ConnectionTest {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// ทดสอบการเชื่อมต่อกับ Backend
  static Future<ConnectionTestResult> testConnection() async {
    try {
      if (kDebugMode) {
        print('🔍 Testing connection to: ${AppConfig.apiBaseUrl}');
      }

      final response = await _dio.get(
        AppConfig.healthCheckEndpoint,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      if (kDebugMode) {
        print('✅ Connection successful!');
        print('Response: ${response.data}');
      }

      return ConnectionTestResult(
        success: true,
        message: 'Connected successfully',
        data: response.data,
      );
    } on DioException catch (e) {
      String errorMessage;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = 'Connection timeout (10s)';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Cannot reach server\n'
              'URL: ${AppConfig.apiBaseUrl}\n\n'
              'Possible causes:\n'
              '• Server is not running\n'
              '• Wrong IP address\n'
              '• Firewall blocking connection';
          break;
        default:
          errorMessage = 'Network error: ${e.message}';
      }

      if (kDebugMode) {
        print('❌ Connection failed: $errorMessage');
      }

      return ConnectionTestResult(
        success: false,
        message: errorMessage,
        error: e,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error: $e');
      }

      return ConnectionTestResult(
        success: false,
        message: 'Unexpected error: $e',
        error: e,
      );
    }
  }

  /// ทดสอบ CORS Preflight Request
  static Future<bool> testCORS() async {
    try {
      if (kDebugMode) {
        print('🔍 Testing CORS...');
      }

      final response = await _dio.head(
        AppConfig.healthCheckEndpoint,
      );

      if (kDebugMode) {
        print('CORS Headers: ${response.headers}');
      }

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (kDebugMode) {
        print('CORS Test failed: $e');
      }
      return false;
    }
  }
}

/// ผลลัพธ์การทดสอบการเชื่อมต่อ
class ConnectionTestResult {
  final bool success;
  final String message;
  final dynamic data;
  final dynamic error;

  ConnectionTestResult({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  @override
  String toString() {
    return 'ConnectionTestResult(success: $success, message: $message)';
  }
}
