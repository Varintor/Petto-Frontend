import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([Dio])
import 'mock_dio.mocks.dart';

/// Mock TokenStorage for integration tests
/// Custom mock implementation matching TokenStorage interface
class MockTokenStorage extends Mock {
  String? _token;
  int? _userId;
  int? _petId;

  Future<String?> getToken() async => _token;

  Future<void> setToken(String token) async {
    _token = token;
  }

  Future<void> setUserId(int userId) async {
    _userId = userId;
  }

  Future<void> setPetId(int petId) async {
    _petId = petId;
  }

  Future<int?> getUserId() async => _userId;

  Future<int?> getPetId() async => _petId;

  Future<void> clear() async {
    _token = null;
    _userId = null;
    _petId = null;
  }

  /// Helper to set up a logged-in state
  void setupLoggedIn({
    String? token,
    int? userId,
    int? petId,
  }) {
    _token = token ?? 'test-token';
    _userId = userId ?? 1;
    _petId = petId;
  }

  /// Helper to set up a guest state (no token)
  void setupGuest() {
    _token = null;
    _userId = null;
    _petId = null;
  }

  /// Verify token was set
  bool get hasToken => _token != null;

  /// Verify user ID was set
  bool get hasUser => _userId != null;

  /// Verify pet ID was set
  bool get hasPet => _petId != null;
}

/// Dio mocking helpers for integration tests
class DioMockHelper {
  /// Create a successful response with JSON data
  static Response successResponse({
    required dynamic data,
    int statusCode = 200,
  }) {
    return Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: statusCode,
      data: data,
    );
  }

  /// Create an error response (4xx, 5xx)
  static DioException errorResponse({
    int statusCode = 400,
    String message = 'Bad Request',
    DioExceptionType type = DioExceptionType.badResponse,
  }) {
    return DioException(
      requestOptions: RequestOptions(path: ''),
      response: Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: statusCode,
        data: {'detail': message},
      ),
      type: type,
    );
  }

  /// Create a 401 Unauthorized error
  static DioException unauthorizedError({String message = 'Invalid email or password'}) {
    return errorResponse(statusCode: 401, message: message);
  }

  /// Create a 404 Not Found error
  static DioException notFoundError({String message = 'Resource not found'}) {
    return errorResponse(statusCode: 404, message: message);
  }

  /// Create a 409 Conflict error
  static DioException conflictError({String message = 'Resource already exists'}) {
    return errorResponse(statusCode: 409, message: message);
  }

  /// Create a network timeout error
  static DioException timeoutError() {
    return DioException(
      requestOptions: RequestOptions(path: ''),
      type: DioExceptionType.connectionTimeout,
    );
  }

  /// Create a receive timeout error
  static DioException receiveTimeoutError() {
    return DioException(
      requestOptions: RequestOptions(path: ''),
      type: DioExceptionType.receiveTimeout,
    );
  }

  /// Create a network connection error
  static DioException connectionError() {
    return DioException(
      requestOptions: RequestOptions(path: ''),
      type: DioExceptionType.connectionError,
    );
  }

  /// Verify a Dio POST call was made with specific data
  static void verifyPostCalled(MockDio mockDio, String path, {Map<String, dynamic>? data}) {
    final captured = verify(mockDio.post(
      argThat(contains(path)),
      data: captureAnyNamed('data'),
      options: anyNamed('options'),
    )).captured;

    if (data != null) {
      expect(captured.first, data);
    }
  }

  /// Verify a Dio GET call was made
  static void verifyGetCalled(MockDio mockDio, String path) {
    verify(mockDio.get(
      argThat(contains(path)),
      options: anyNamed('options'),
    )).called(1);
  }

  /// Verify a Dio PUT call was made
  static void verifyPutCalled(MockDio mockDio, String path) {
    verify(mockDio.put(
      argThat(contains(path)),
      data: anyNamed('data'),
      options: anyNamed('options'),
    )).called(1);
  }

  /// Verify a Dio DELETE call was made
  static void verifyDeleteCalled(MockDio mockDio, String path) {
    verify(mockDio.delete(
      argThat(contains(path)),
      options: anyNamed('options'),
    )).called(1);
  }
}
