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
}
