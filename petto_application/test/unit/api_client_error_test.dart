import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petto_application/src/core/network/api_client.dart';

void main() {
  RequestOptions request() => RequestOptions(path: '/api/v1/consultations/1');

  test('401 is presented as an expired session instead of Dio internals', () {
    final error = DioException.badResponse(
      statusCode: 401,
      requestOptions: request(),
      response: Response<dynamic>(
        requestOptions: request(),
        statusCode: 401,
        data: const {'detail': 'Not authenticated'},
      ),
    );

    expect(
      ApiClient.describeError(error),
      'Your session has expired. Please sign in again.',
    );
  });

  test('backend detail is preserved for non-authentication errors', () {
    final error = DioException.badResponse(
      statusCode: 409,
      requestOptions: request(),
      response: Response<dynamic>(
        requestOptions: request(),
        statusCode: 409,
        data: const {'detail': 'Appointment is no longer available'},
      ),
    );

    expect(
      ApiClient.describeError(error),
      'Appointment is no longer available',
    );
  });

  test('timeout is presented as a retryable message', () {
    final error = DioException(
      requestOptions: request(),
      type: DioExceptionType.receiveTimeout,
    );

    expect(
      ApiClient.describeError(error),
      'The server is taking longer than expected. Please retry.',
    );
  });

  test('idempotent GET retries a transient mobile network failure once', () {
    final options = RequestOptions(
      path: '/api/v1/pets/1/history',
      method: 'GET',
    );
    final error = DioException(
      requestOptions: options,
      type: DioExceptionType.connectionTimeout,
    );

    expect(ApiClient.shouldRetryRead(error), isTrue);
    options.extra['petto_network_retry'] = true;
    expect(ApiClient.shouldRetryRead(error), isFalse);
  });

  test('mutating requests are never retried automatically', () {
    final error = DioException(
      requestOptions: RequestOptions(
        path: '/api/v1/consultations/1/messages',
        method: 'POST',
      ),
      type: DioExceptionType.receiveTimeout,
    );

    expect(ApiClient.shouldRetryRead(error), isFalse);
  });

  test('wrapped friendly repository message is preserved without prefix', () {
    expect(
      ApiClient.describeError(
        Exception('Network timeout talking to the backend.'),
      ),
      'Network timeout talking to the backend.',
    );
  });
}
