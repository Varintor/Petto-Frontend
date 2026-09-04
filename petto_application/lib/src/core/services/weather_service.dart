import 'package:dio/dio.dart';

enum WeatherKind { clear, cloudy, rainy, stormy }

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.kind,
    required this.isDay,
    required this.temperatureCelsius,
  });

  final WeatherKind kind;
  final bool isDay;
  final double temperatureCelsius;

  String get conditionLabel => switch (kind) {
    WeatherKind.clear => 'Clear',
    WeatherKind.cloudy => 'Cloudy',
    WeatherKind.rainy => 'Rainy',
    WeatherKind.stormy => 'Stormy',
  };
}

class WeatherService {
  WeatherService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<WeatherSnapshot?> currentWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current': 'temperature_2m,weather_code,is_day',
          'timezone': 'auto',
          'forecast_days': 1,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      );

      final current = response.data?['current'];
      if (current is! Map<String, dynamic>) return null;

      final code = (current['weather_code'] as num?)?.toInt() ?? 0;
      final temperature = (current['temperature_2m'] as num?)?.toDouble() ?? 0;
      final isDay = (current['is_day'] as num?)?.toInt() == 1;

      return WeatherSnapshot(
        kind: _kindFromWmoCode(code),
        isDay: isDay,
        temperatureCelsius: temperature,
      );
    } on DioException {
      return null;
    }
  }

  WeatherKind _kindFromWmoCode(int code) {
    if (code == 0) return WeatherKind.clear;
    if (code <= 48) return WeatherKind.cloudy;
    if (code >= 95) return WeatherKind.stormy;
    return WeatherKind.rainy;
  }
}
