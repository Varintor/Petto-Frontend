import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:petto_application/src/features/pet_management/data/repositories/pet_repository.dart';

import '../helpers/mock_dio.dart';
import '../helpers/test_fixtures.dart';

@GenerateMocks([Dio])
import 'pet_integration_test.mocks.dart';

/// Integration Tests for Pet Management Feature
///
/// Tests the full flow: Repository → Dio → Mock Response
/// Maps to UTC-03, UTC-04, STC-03 from Test Record v1.0.0
void main() {
  late PetRepository repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = PetRepository(dio: mockDio);
  });

  group('Pet Management Integration Tests', () {
    group('Create Pet', () {
      test('ITC-PET-01: Create pet → Pet returned', () async {
        // Arrange: Mock successful pet creation (like UTC-03-TC-01, STC-03-#4)
        when(
          mockDio.post(
            argThat(contains('/pets')),
            data: anyNamed('data'),
            options: anyNamed('options'),
          ),
        ).thenAnswer(
          (_) async => DioMockHelper.successResponse(
            data: PetFixtures.validPetResponse(),
          ),
        );

        // Act: Create pet
        final result = await repository.createPet(
          token: AuthFixtures.validToken,
          name: PetFixtures.validName,
          species: PetFixtures.validSpecies,
          breed: PetFixtures.validBreed,
          gender: PetFixtures.validGender,
          weightKg: PetFixtures.validWeight,
        );

        // Assert: Verify pet returned
        expect(result.id, PetFixtures.validPetId);
        expect(result.name, PetFixtures.validName);
        expect(result.species, PetFixtures.validSpecies);
        expect(result.weightKg, PetFixtures.validWeight);

        // Verify Dio was called
        final capturedOptions =
            verify(
                  mockDio.post(
                    argThat(contains('/pets')),
                    data: captureAnyNamed('data'),
                    options: captureAnyNamed('options'),
                  ),
                ).captured.last
                as Options;

        // Verify Authorization header was attached
        expect(
          capturedOptions.headers?['Authorization'],
          contains(AuthFixtures.validToken),
        );
      });

      test(
        'ITC-PET-01b: Create pet without optional fields → Success',
        () async {
          // Arrange: Mock success with minimal data
          when(
            mockDio.post(
              argThat(contains('/pets')),
              data: anyNamed('data'),
              options: anyNamed('options'),
            ),
          ).thenAnswer(
            (_) async => DioMockHelper.successResponse(
              data: {
                ...PetFixtures.validPetResponse(),
                'breed': null,
                'gender': null,
              },
            ),
          );

          // Act: Create pet with minimal data
          final result = await repository.createPet(
            token: AuthFixtures.validToken,
            name: PetFixtures.validName,
            species: PetFixtures.validSpecies,
          );

          // Assert
          expect(result.name, PetFixtures.validName);
          expect(result.breed, null);
          expect(result.gender, null);
        },
      );

      test(
        'ITC-PET-01c: Create pet network error → User-friendly message',
        () async {
          // Arrange: Mock network error
          when(
            mockDio.post(
              any,
              data: anyNamed('data'),
              options: anyNamed('options'),
            ),
          ).thenThrow(DioMockHelper.connectionError());

          // Act & Assert
          expect(
            () => repository.createPet(
              token: AuthFixtures.validToken,
              name: PetFixtures.validName,
              species: PetFixtures.validSpecies,
            ),
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

    group('Update Pet', () {
      test('ITC-PET-03: Update pet → Changes persisted', () async {
        // Arrange: Mock successful update (like UTC-04-TC-01)
        when(
          mockDio.put(
            argThat(contains('/pets/${PetFixtures.validPetId}')),
            data: anyNamed('data'),
            options: anyNamed('options'),
          ),
        ).thenAnswer(
          (_) async => DioMockHelper.successResponse(
            data: PetFixtures.updatedPetResponse(),
          ),
        );

        // Act: Update pet
        final result = await repository.updatePet(
          token: AuthFixtures.validToken,
          petId: PetFixtures.validPetId,
          name: 'Max',
          weightKg: 10.5,
        );

        // Assert: Verify changes persisted
        expect(result.id, PetFixtures.validPetId);
        expect(result.name, 'Max');
        expect(result.weightKg, 10.5);

        // Verify Dio was called
        verify(
          mockDio.put(
            argThat(contains('/pets/${PetFixtures.validPetId}')),
            data: captureAnyNamed('data'),
            options: anyNamed('options'),
          ),
        ).called(1);
      });

      test('ITC-PET-03b: Update pet not found → Error', () async {
        // Arrange: Mock 404 response
        when(
          mockDio.put(
            argThat(contains('/pets/999')),
            data: anyNamed('data'),
            options: anyNamed('options'),
          ),
        ).thenThrow(DioMockHelper.notFoundError());

        // Act & Assert
        expect(
          () => repository.updatePet(
            token: AuthFixtures.validToken,
            petId: 999,
            name: 'Test',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('not found'),
            ),
          ),
        );
      });
    });

    group('Fetch User Pets', () {
      test('ITC-PET-05: Get user pets → List returned', () async {
        // Arrange: Mock successful fetch
        when(
          mockDio.get(
            argThat(contains('/users/${PetFixtures.validUserId}/pets')),
          ),
        ).thenAnswer(
          (_) async => DioMockHelper.successResponse(
            data: PetFixtures.multiplePetsResponse(),
          ),
        );

        // Act: Get user's pets
        final result = await repository.getUserPets(PetFixtures.validUserId);

        // Assert: Verify list returned
        expect(result.length, 2);
        expect(result[0].name, PetFixtures.validName);
        expect(result[0].species, PetFixtures.validSpecies);
        expect(result[1].name, 'Milo');
        expect(result[1].species, 'Cat');

        // Verify Dio was called
        verify(
          mockDio.get(
            argThat(contains('/users/${PetFixtures.validUserId}/pets')),
          ),
        ).called(1);
      });

      test(
        'ITC-PET-05b: Get user pets empty list → Empty list returned',
        () async {
          // Arrange: Mock empty list
          when(mockDio.get(any)).thenAnswer(
            (_) async => DioMockHelper.successResponse(data: <dynamic>[]),
          );

          // Act
          final result = await repository.getUserPets(999);

          // Assert
          expect(result, isEmpty);
        },
      );

      test(
        'ITC-PET-05c: Get user pets network error → User-friendly message',
        () async {
          // Arrange: Mock network error
          when(mockDio.get(any)).thenThrow(DioMockHelper.timeoutError());

          // Act & Assert
          expect(
            () => repository.getUserPets(PetFixtures.validUserId),
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

    group('Error Handling', () {
      test('ITC-PET-06: 401 Unauthorized → Proper error message', () async {
        // Arrange: Mock 401 response
        when(
          mockDio.post(
            any,
            data: anyNamed('data'),
            options: anyNamed('options'),
          ),
        ).thenThrow(DioMockHelper.unauthorizedError());

        // Act & Assert
        expect(
          () => repository.createPet(
            token: 'invalid-token',
            name: 'Test',
            species: 'Dog',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('ITC-PET-07: 500 Server Error → Proper error message', () async {
        // Arrange: Mock 500 response
        when(
          mockDio.post(
            any,
            data: anyNamed('data'),
            options: anyNamed('options'),
          ),
        ).thenThrow(
          DioMockHelper.errorResponse(
            statusCode: 500,
            message: 'Internal server error',
          ),
        );

        // Act & Assert
        expect(
          () => repository.createPet(
            token: AuthFixtures.validToken,
            name: 'Test',
            species: 'Dog',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Server error 500'),
            ),
          ),
        );
      });
    });

    group('Date Handling', () {
      test(
        'ITC-PET-08: Create pet with date of birth → Date parsed correctly',
        () async {
          // Arrange: Mock success with date
          when(
            mockDio.post(
              argThat(contains('/pets')),
              data: anyNamed('data'),
              options: anyNamed('options'),
            ),
          ).thenAnswer(
            (_) async => DioMockHelper.successResponse(
              data: PetFixtures.validPetResponse(),
            ),
          );

          // Act: Create pet with date of birth
          final dob = DateTime(2020, 1, 1);
          final result = await repository.createPet(
            token: AuthFixtures.validToken,
            name: PetFixtures.validName,
            species: PetFixtures.validSpecies,
            dateOfBirth: dob,
          );

          // Assert: Date sent correctly (YYYY-MM-DD format)
          final capturedData =
              verify(
                    mockDio.post(
                      any,
                      data: captureAnyNamed('data'),
                      options: anyNamed('options'),
                    ),
                  ).captured.single
                  as Map<String, dynamic>;
          expect(capturedData['date_of_birth'], '2020-01-01');

          // Assert: Date parsed correctly
          expect(result.dateOfBirth, isNotNull);
          expect(result.dateOfBirth!.year, 2020);
          expect(result.dateOfBirth!.month, 1);
          expect(result.dateOfBirth!.day, 1);
        },
      );

      test('ITC-PET-09: Update pet with null date → Handled correctly', () async {
        // Arrange: Mock success
        when(
          mockDio.put(
            any,
            data: anyNamed('data'),
            options: anyNamed('options'),
          ),
        ).thenAnswer(
          (_) async => DioMockHelper.successResponse(
            data: PetFixtures.validPetResponse(),
          ),
        );

        // Act: Update pet without date
        await repository.updatePet(
          token: AuthFixtures.validToken,
          petId: PetFixtures.validPetId,
          name: 'Test',
          dateOfBirth: null,
        );

        // Assert: Date field is omitted so an unrelated update does not clear it.
        final capturedData =
            verify(
                  mockDio.put(
                    any,
                    data: captureAnyNamed('data'),
                    options: anyNamed('options'),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(capturedData.containsKey('date_of_birth'), false);
      });
    });
  });
}
