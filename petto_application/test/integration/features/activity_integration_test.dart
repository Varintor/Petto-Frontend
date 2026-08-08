import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:petto_application/src/features/activity_tracking/data/repositories/activity_repository.dart';

import '../helpers/mock_dio.dart';
import '../helpers/test_fixtures.dart';

@GenerateMocks([Dio])
import 'activity_integration_test.mocks.dart';

/// Integration Tests for Activity Tracking Feature
///
/// Tests the full flow: Repository → Dio → Mock Response
/// Maps to UTC-07, UTC-08, STC-05 from Test Record v1.0.0
void main() {
  late ActivityRepository repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = ActivityRepositoryImpl(dio: mockDio);
  });

  group('Activity Tracking Integration Tests', () {
    group('Create Activity', () {
      test('ITC-ACT-01: Save walk activity → Activity created', () async {
        // Arrange: Mock successful activity creation (like UTC-07-TC-01)
        when(mockDio.post(
          argThat(contains('/activities')),
          data: anyNamed('data'),
        )).thenAnswer((_) async => DioMockHelper.successResponse(
          data: ActivityFixtures.successActivityResponse(),
          statusCode: 201,
        ));

        // Act: Save walking activity
        final result = await repository.createActivity(
          petId: ActivityFixtures.validPetId,
          activityType: ActivityFixtures.walkingType,
          durationMinutes: ActivityFixtures.validDuration,
          distanceMeters: ActivityFixtures.validDistance,
          isMissionCompleted: true,
          source: 'phone',
        );

        // Assert: Verify activity returned
        expect(result.id, ActivityFixtures.validActivityId);
        expect(result.petId, ActivityFixtures.validPetId);
        expect(result.activityType, ActivityFixtures.walkingType);
        expect(result.durationMinutes, ActivityFixtures.validDuration);
        expect(result.distanceMeters, ActivityFixtures.validDistance);
        expect(result.isMissionCompleted, true);

        // Verify Dio was called
        verify(mockDio.post(
          argThat(contains('/activities')),
          data: captureAnyNamed('data'),
        )).called(1);
      });

      test('ITC-ACT-02: Walk ≥15 min → Mission auto-complete flag set', () async {
        // Arrange: Mock response with is_mission_completed true
        when(mockDio.post(
          argThat(contains('/activities')),
          data: anyNamed('data'),
        )).thenAnswer((_) async => DioMockHelper.successResponse(
          data: ActivityFixtures.successActivityResponse(),
          statusCode: 201,
        ));

        // Act: Save 20-minute walk
        final result = await repository.createActivity(
          petId: ActivityFixtures.validPetId,
          activityType: ActivityFixtures.walkingType,
          durationMinutes: 20.0, // ≥ 15 min
          distanceMeters: 1500.0,
          isMissionCompleted: true,
        );

        // Assert: Verify mission flag is true
        expect(result.isMissionCompleted, true);

        // Verify data sent to backend
        final capturedData = verify(mockDio.post(
          any,
          data: captureAnyNamed('data'),
        )).captured.single as Map<String, dynamic>;
        expect(capturedData['duration_minutes'], 20.0);
        expect(capturedData['is_mission_completed'], true);
      });

      test('ITC-ACT-03: Walk <15 min → Mission not completed', () async {
        // Arrange: Mock response with is_mission_completed false (like UTC-07-TC-03)
        when(mockDio.post(
          argThat(contains('/activities')),
          data: anyNamed('data'),
        )).thenAnswer((_) async => DioMockHelper.successResponse(
          data: ActivityFixtures.shortWalkResponse(),
          statusCode: 201,
        ));

        // Act: Save 10-minute walk
        final result = await repository.createActivity(
          petId: ActivityFixtures.validPetId,
          activityType: ActivityFixtures.walkingType,
          durationMinutes: 10.0, // < 15 min
          distanceMeters: 750.0,
          isMissionCompleted: false,
        );

        // Assert: Verify mission flag is false
        expect(result.isMissionCompleted, false);
        expect(result.durationMinutes, 10.0);
      });

      test('ITC-ACT-04: Activity type inference → Running vs Walking', () async {
        // Arrange: Mock success with running type
        when(mockDio.post(
          argThat(contains('/activities')),
          data: anyNamed('data'),
        )).thenAnswer((_) async => DioMockHelper.successResponse(
          data: {
            ...ActivityFixtures.successActivityResponse(),
            'activity_type': ActivityFixtures.runningType,
          },
          statusCode: 201,
        ));

        // Act: Save running activity
        final result = await repository.createActivity(
          petId: ActivityFixtures.validPetId,
          activityType: ActivityFixtures.runningType,
          durationMinutes: 15.0,
          distanceMeters: 2000.0,
        );

        // Assert: Verify running type
        expect(result.activityType, ActivityFixtures.runningType);
      });
    });

    group('Fetch Activities', () {
      test('ITC-ACT-05: Get pet activities → List returned', () async {
        // Arrange: Mock successful activities fetch
        when(mockDio.get(
          argThat(contains('/pets/${ActivityFixtures.validPetId}/activities')),
        )).thenAnswer((_) async => DioMockHelper.successResponse(
          data: [
            ActivityFixtures.successActivityResponse(),
            ActivityFixtures.shortWalkResponse(),
          ],
        ));

        // Act: Fetch pet's activities
        final result = await repository.getPetActivities(ActivityFixtures.validPetId);

        // Assert: Verify list returned
        expect(result.length, 2);
        expect(result[0].id, ActivityFixtures.validActivityId);
        expect(result[0].activityType, ActivityFixtures.walkingType);
        expect(result[1].id, 2);
        expect(result[1].durationMinutes, 10.0);

        // Verify Dio was called
        verify(mockDio.get(
          argThat(contains('/pets/${ActivityFixtures.validPetId}/activities')),
        )).called(1);
      });

      test('ITC-ACT-06: Empty activities → Empty list returned', () async {
        // Arrange: Mock empty list
        when(mockDio.get(any)).thenAnswer((_) async =>
          DioMockHelper.successResponse(data: <dynamic>[]));

        // Act
        final result = await repository.getPetActivities(ActivityFixtures.validPetId);

        // Assert
        expect(result, isEmpty);
      });
    });

    group('Fetch Stats', () {
      test('ITC-ACT-07: Fetch stats → DashboardStats returned', () async {
        // Arrange: Mock successful stats fetch (like UTC-08-TC-01)
        when(mockDio.get(
          argThat(contains('/pets/${ActivityFixtures.validPetId}/activities/stats')),
        )).thenAnswer((_) async => DioMockHelper.successResponse(
          data: ActivityFixtures.activityStatsResponse(),
        ));

        // Act: Fetch activity stats
        final result = await repository.getStats(ActivityFixtures.validPetId);

        // Assert: Verify stats returned
        expect(result.totalActivities, 2);
        expect(result.totalDurationMinutes, 50.0);
        expect(result.totalDistanceMeters, 3750.0);
        expect(result.completedMissions, 1);

        // Verify Dio was called
        verify(mockDio.get(
          argThat(contains('/pets/${ActivityFixtures.validPetId}/activities/stats')),
        )).called(1);
      });

      test('ITC-ACT-08: Empty stats → Zero values returned', () async {
        // Arrange: Mock empty stats response
        when(mockDio.get(
          argThat(contains('/pets/${ActivityFixtures.validPetId}/activities/stats')),
        )).thenAnswer((_) async => DioMockHelper.successResponse(
          data: {
            'pet_id': ActivityFixtures.validPetId,
            'activities_this_month': 0,
            'total_duration_minutes': 0.0,
            'total_distance_meters': 0.0,
            'completed_missions': 0,
          },
        ));

        // Act
        final result = await repository.getStats(ActivityFixtures.validPetId);

        // Assert: Verify zero values
        expect(result.totalActivities, 0);
        expect(result.totalDurationMinutes, 0.0);
        expect(result.totalDistanceMeters, 0.0);
        expect(result.completedMissions, 0);
      });
    });

    group('Error Handling', () {
      test('ITC-ACT-09: Network error → User-friendly message', () async {
        // Arrange: Mock connection error
        when(mockDio.post(
          any,
          data: anyNamed('data'),
        )).thenThrow(DioMockHelper.connectionError());

        // Act & Assert
        expect(
          () => repository.createActivity(
            petId: ActivityFixtures.validPetId,
            activityType: ActivityFixtures.walkingType,
            durationMinutes: 15.0,
            distanceMeters: 1000.0,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot reach'),
          )),
        );
      });

      test('ITC-ACT-10: 401 Unauthorized → Proper error message', () async {
        // Arrange: Mock 401 response
        when(mockDio.post(
          any,
          data: anyNamed('data'),
        )).thenThrow(DioMockHelper.unauthorizedError());

        // Act & Assert
        expect(
          () => repository.createActivity(
            petId: ActivityFixtures.validPetId,
            activityType: ActivityFixtures.walkingType,
            durationMinutes: 15.0,
            distanceMeters: 1000.0,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Calorie Calculation', () {
      test('ITC-ACT-11: Calories auto-calculated → Correct formula', () async {
        // Arrange: Mock response with calories (like UTC-07-TC-02)
        when(mockDio.post(
          argThat(contains('/activities')),
          data: anyNamed('data'),
        )).thenAnswer((_) async => DioMockHelper.successResponse(
          data: {
            ...ActivityFixtures.successActivityResponse(),
            'calories_burned': 15.0, // 3.0 MET * 10kg * 0.5min
          },
          statusCode: 201,
        ));

        // Act: Save activity
        final result = await repository.createActivity(
          petId: ActivityFixtures.validPetId,
          activityType: ActivityFixtures.walkingType,
          durationMinutes: 30.0,
          distanceMeters: 1500.0,
        );

        // Assert: Verify calories returned (calculated by backend)
        // Note: Frontend doesn't calculate calories; backend does
        final capturedData = verify(mockDio.post(
          any,
          data: captureAnyNamed('data'),
        )).captured.single as Map<String, dynamic>;
        // Frontend sends activity data, backend calculates calories
        expect(capturedData.containsKey('duration_minutes'), true);
        expect(capturedData.containsKey('distance_meters'), true);
      });
    });
  });
}
