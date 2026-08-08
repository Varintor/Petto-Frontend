import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:petto_application/src/features/missions/data/repositories/missions_repository.dart';

import '../helpers/mock_dio.dart';
import '../helpers/test_fixtures.dart';

@GenerateMocks([Dio])
import 'missions_integration_test.mocks.dart';

/// Integration Tests for Daily Missions Feature
///
/// Tests the full flow: Repository → Dio → Mock Response
/// Maps to UTC-06, UTC-08, UTC-10, STC-05 from Test Record v1.0.0
void main() {
  late MissionsRepository repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = MissionsRepositoryImpl(dio: mockDio);
  });

  group('Missions Integration Tests', () {
    group('Seed Missions', () {
      test(
        'ITC-MISSION-01: Seed today\'s missions → 5 missions returned',
        () async {
          // Arrange: Mock successful seeding (like UTC-06-TC-01, STC-05-#1)
          when(
            mockDio.post(
              argThat(
                contains(
                  '/pets/${MissionFixtures.validPetId}/missions/seed-today',
                ),
              ),
            ),
          ).thenAnswer(
            (_) async => DioMockHelper.successResponse(
              data: MissionFixtures.todayMissionsResponse(),
            ),
          );

          // Act: Seed today's missions
          final result = await repository.seedTodayMissions(
            MissionFixtures.validPetId,
          );

          // Assert: Verify 5 missions returned
          expect(result.length, 5);
          expect(result[0].id, MissionFixtures.validMissionId);
          expect(result[0].missionType, MissionFixtures.walkType);
          expect(result[0].isCompleted, false);
          expect(result[1].missionType, MissionFixtures.waterType);
          expect(result[2].missionType, MissionFixtures.aiCheckType);

          // Verify Dio was called
          verify(
            mockDio.post(
              argThat(
                contains(
                  '/pets/${MissionFixtures.validPetId}/missions/seed-today',
                ),
              ),
            ),
          ).called(1);
        },
      );

      test('ITC-MISSION-02: Re-seed is idempotent → No duplicates', () async {
        // Arrange: Mock same 5 missions on re-seed (like UTC-06-TC-02)
        when(
          mockDio.post(
            argThat(
              contains(
                '/pets/${MissionFixtures.validPetId}/missions/seed-today',
              ),
            ),
          ),
        ).thenAnswer(
          (_) async => DioMockHelper.successResponse(
            data: MissionFixtures.todayMissionsResponse(),
          ),
        );

        // Act: Seed first time
        final result1 = await repository.seedTodayMissions(
          MissionFixtures.validPetId,
        );
        expect(result1.length, 5);

        // Act: Seed again (re-seed)
        final result2 = await repository.seedTodayMissions(
          MissionFixtures.validPetId,
        );

        // Assert: Still 5 missions, no duplicates
        expect(result2.length, 5);
        verify(
          mockDio.post(
            argThat(
              contains(
                '/pets/${MissionFixtures.validPetId}/missions/seed-today',
              ),
            ),
          ),
        ).called(2);
      });

      test(
        'ITC-MISSION-03: Seed network error → User-friendly message',
        () async {
          // Arrange: Mock network error
          when(
            mockDio.post(argThat(contains('/missions/seed-today'))),
          ).thenThrow(DioMockHelper.connectionError());

          // Act & Assert
          expect(
            () => repository.seedTodayMissions(MissionFixtures.validPetId),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Cannot reach'),
              ),
            ),
          );
        },
      );
    });

    group('Fetch Today\'s Missions', () {
      test('ITC-MISSION-04: Get today\'s missions → List returned', () async {
        // Arrange: Mock successful fetch
        when(
          mockDio.get(
            argThat(
              contains('/pets/${MissionFixtures.validPetId}/missions/today'),
            ),
          ),
        ).thenAnswer(
          (_) async => DioMockHelper.successResponse(
            data: MissionFixtures.todayMissionsResponse(),
          ),
        );

        // Act: Fetch today's missions
        final result = await repository.getTodayMissions(
          MissionFixtures.validPetId,
        );

        // Assert: Verify list returned
        expect(result.length, 5);
        expect(result[0].title, 'Morning Walk');
        expect(result[1].title, 'Stay Hydrated');
        expect(result[2].title, 'Health Check');

        // Verify Dio was called
        verify(
          mockDio.get(
            argThat(
              contains('/pets/${MissionFixtures.validPetId}/missions/today'),
            ),
          ),
        ).called(1);
      });

      test('ITC-MISSION-05: Empty missions → Empty list returned', () async {
        // Arrange: Mock empty list
        when(mockDio.get(argThat(contains('/missions/today')))).thenAnswer(
          (_) async => DioMockHelper.successResponse(data: <dynamic>[]),
        );

        // Act
        final result = await repository.getTodayMissions(
          MissionFixtures.validPetId,
        );

        // Assert
        expect(result, isEmpty);
      });
    });

    group('Complete Mission', () {
      test('ITC-MISSION-06: Complete mission → Status updated', () async {
        // Arrange: Mock successful completion (like UTC-06-TC-03, STC-05-#2)
        when(
          mockDio.put(
            argThat(
              contains('/missions/${MissionFixtures.validMissionId}/complete'),
            ),
            queryParameters: anyNamed('queryParameters'),
          ),
        ).thenAnswer(
          (_) async => DioMockHelper.successResponse(
            data: MissionFixtures.completedMissionResponse(),
          ),
        );

        // Act: Complete mission
        final result = await repository.completeMission(
          MissionFixtures.validMissionId,
          isCompleted: true,
        );

        // Assert: Verify mission completed
        expect(result.id, MissionFixtures.validMissionId);
        expect(result.isCompleted, true);
        expect(result.completedAt, isNotNull);

        // Verify Dio was called
        verify(
          mockDio.put(
            argThat(
              contains('/missions/${MissionFixtures.validMissionId}/complete'),
            ),
            queryParameters: {'is_completed': true},
          ),
        ).called(1);
      });

      test(
        'ITC-MISSION-07: Complete mission network error → User-friendly message',
        () async {
          // Arrange: Mock network error
          when(
            mockDio.put(
              argThat(
                contains(
                  '/missions/${MissionFixtures.validMissionId}/complete',
                ),
              ),
              queryParameters: anyNamed('queryParameters'),
            ),
          ).thenThrow(DioMockHelper.timeoutError());

          // Act & Assert
          expect(
            () => repository.completeMission(MissionFixtures.validMissionId),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('timeout'),
              ),
            ),
          );
        },
      );
    });

    group('Dashboard Stats', () {
      test(
        'ITC-MISSION-08: Fetch dashboard stats → Stats aggregated correctly',
        () async {
          // Arrange: Mock successful stats fetch (like UTC-08-TC-01, UTC-10-TC-01)
          when(
            mockDio.get(
              argThat(
                contains('/pets/${MissionFixtures.validPetId}/stats/dashboard'),
              ),
            ),
          ).thenAnswer(
            (_) async => DioMockHelper.successResponse(
              data: MissionFixtures.dashboardStatsResponse(),
            ),
          );

          // Act: Fetch dashboard stats
          final result = await repository.getDashboardStats(
            MissionFixtures.validPetId,
          );

          // Assert: Verify stats returned (like UTC-10-TC-01)
          expect(result.healthScore, 80);
          expect(result.missionsCompletedThisWeek, 3);
          expect(result.totalDurationMinutes, 150.0);
          expect(result.vaccinationStatus, 'up_to_date');

          // Verify Dio was called
          verify(
            mockDio.get(
              argThat(
                contains('/pets/${MissionFixtures.validPetId}/stats/dashboard'),
              ),
            ),
          ).called(1);
        },
      );

      test(
        'ITC-MISSION-09: Empty pet stats → Zero values with defaults',
        () async {
          // Arrange: Mock empty stats response (like UTC-08-TC-02, UTC-10-TC-02)
          when(
            mockDio.get(
              argThat(
                contains('/pets/${MissionFixtures.validPetId}/stats/dashboard'),
              ),
            ),
          ).thenAnswer(
            (_) async => DioMockHelper.successResponse(
              data: MissionFixtures.emptyStatsResponse(),
            ),
          );

          // Act: Fetch stats for pet with no data
          final result = await repository.getDashboardStats(
            MissionFixtures.validPetId,
          );

          // Assert: Verify zero/default values (like UTC-10-TC-02)
          expect(result.healthScore, 0);
          expect(result.missionsCompletedThisWeek, 0);
          expect(result.vaccinationStatus, 'no_records');
          expect(result.recentRiskLevel, null);
        },
      );

      test(
        'ITC-MISSION-10: Stats fetch network error → User-friendly message',
        () async {
          // Arrange: Mock connection error
          when(
            mockDio.get(argThat(contains('/stats/dashboard'))),
          ).thenThrow(DioMockHelper.connectionError());

          // Act & Assert
          expect(
            () => repository.getDashboardStats(MissionFixtures.validPetId),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Cannot reach'),
              ),
            ),
          );
        },
      );
    });

    group('Mission Model Mapping', () {
      test(
        'ITC-MISSION-11: Mission JSON mapping → All fields parsed',
        () async {
          // Arrange: Mock successful fetch
          when(mockDio.get(argThat(contains('/missions/today')))).thenAnswer(
            (_) async => DioMockHelper.successResponse(
              data: [MissionFixtures.todayMissionsResponse().first],
            ),
          );

          // Act: Fetch missions
          final result = await repository.getTodayMissions(
            MissionFixtures.validPetId,
          );

          // Assert: Verify field mapping (like UTC-09-TC-01)
          final mission = result.first;
          expect(mission.id, MissionFixtures.validMissionId);
          expect(mission.petId, MissionFixtures.validPetId);
          expect(mission.missionDate, DateTime(2026, 6, 17));
          expect(mission.title, 'Morning Walk');
          expect(mission.targetValue, 15.0);
          expect(mission.isCompleted, false);
          expect(mission.createdAt, isNotNull);
        },
      );

      test(
        'ITC-MISSION-12: Mission with null fields → Defaults applied',
        () async {
          // Arrange: Mock mission with null optional fields
          when(
            mockDio.post(argThat(contains('/missions/seed-today'))),
          ).thenAnswer(
            (_) async => DioMockHelper.successResponse(
              data: [
                {
                  ...MissionFixtures.todayMissionsResponse().first,
                  'unit': null,
                  'target_value': null,
                },
              ],
            ),
          );

          // Act
          final result = await repository.seedTodayMissions(
            MissionFixtures.validPetId,
          );

          // Assert: Verify null handling (like UTC-09-TC-02)
          final mission = result.first;
          expect(mission.unit, null);
          expect(mission.targetValue, null);
        },
      );
    });
  });
}
