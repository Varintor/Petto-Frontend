import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:petto_application/src/features/health_assessment/data/repositories/health_assessment_repository.dart';

import '../helpers/mock_dio.dart';
import '../helpers/test_fixtures.dart';

@GenerateMocks([Dio])
import 'assessment_integration_test.mocks.dart';

/// Integration Tests for Health Assessment Feature
///
/// Tests the full flow: Repository → Dio → Mock Response
/// Maps to UTC-05, STC-04 from Test Record v1.0.0
void main() {
  late HealthAssessmentRepository repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = HealthAssessmentRepositoryImpl(dio: mockDio);
  });

  group('Health Assessment Integration Tests', () {
    group('Submit Assessment', () {
      test('ITC-ASSESS-01: Submit with image → Risk returned', () async {
        // Arrange: Mock successful assessment (like UTC-05-TC-01, STC-04-#3)
        when(
          mockDio.post(
            argThat(contains('/assessments')),
            data: anyNamed('data'),
          ),
        ).thenAnswer(
          (_) async => DioMockHelper.successResponse(
            data: AssessmentFixtures.successAssessmentResponse(),
            statusCode: 201,
          ),
        );

        // Act: Submit assessment with image data
        final imageData = Uint8List.fromList([
          0xff,
          0xd8,
          0xff,
          0xe0,
        ]); // Minimal JPEG signature for MIME detection
        final result = await repository.submitAssessment(
          petName: PetFixtures.validName,
          petType: PetFixtures.validSpecies,
          symptoms: AssessmentFixtures.validSymptoms,
          imageData: imageData,
          petId: AssessmentFixtures.validPetId,
        );

        // Assert: Verify assessment returned
        expect(result.id, AssessmentFixtures.validAssessmentId);
        expect(result.petId, AssessmentFixtures.validPetId);
        expect(result.petName, PetFixtures.validName);
        expect(result.petType, PetFixtures.validSpecies);
        expect(result.riskLevel, AssessmentFixtures.highRisk);
        expect(result.symptoms, AssessmentFixtures.validSymptoms);

        // Verify Dio was called with FormData
        final capturedData = verify(
          mockDio.post(
            argThat(contains('/assessments')),
            data: captureAnyNamed('data'),
          ),
        ).captured.single;
        expect(capturedData, isA<FormData>());
      });

      test('ITC-ASSESS-02: No image → Submission blocked', () async {
        // Act: Try to submit without image
        final result = repository.submitAssessment(
          petName: PetFixtures.validName,
          petType: PetFixtures.validSpecies,
          symptoms: AssessmentFixtures.validSymptoms,
          imageData: null,
          petId: AssessmentFixtures.validPetId,
        );

        // Assert: Exception thrown before Dio call
        expect(
          () => result,
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Please add a pet photo'),
            ),
          ),
        );

        // Verify Dio was NOT called
        verifyNever(mockDio.post(any, data: anyNamed('data')));
      });

      test('ITC-ASSESS-02b: No pet ID → Submission blocked', () async {
        // Act: Try to submit without pet ID
        final imageData = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]);
        final result = repository.submitAssessment(
          petName: PetFixtures.validName,
          petType: PetFixtures.validSpecies,
          imageData: imageData,
          petId: null,
        );

        // Assert
        expect(
          () => result,
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Please sign in and add a pet'),
            ),
          ),
        );

        // Verify Dio was NOT called
        verifyNever(mockDio.post(any, data: anyNamed('data')));
      });

      test('ITC-ASSESS-03: AI unavailable → Explicit failed state', () async {
        // Arrange: Mock response with AI unavailable (like UTC-05-TC-01)
        when(
          mockDio.post(
            argThat(contains('/assessments')),
            data: anyNamed('data'),
          ),
        ).thenAnswer(
          (_) async => DioMockHelper.successResponse(
            data: AssessmentFixtures.aiUnavailableResponse(),
            statusCode: 201,
          ),
        );

        // Act: Submit assessment
        final imageData = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]);
        final result = await repository.submitAssessment(
          petName: 'Milo',
          petType: 'Cat',
          symptoms: 'Limping on front paw',
          imageData: imageData,
          petId: AssessmentFixtures.validPetId,
        );

        // Assert: Failure is retryable and never invents a medical risk.
        expect(result.isFailed, true);
        expect(result.riskLevel, isEmpty);
        expect(result.aiResponse, isEmpty);
        expect(result.errorCode, 'AI_SERVICE_UNAVAILABLE');
        expect(result.symptoms, 'Limping on front paw');
      });

      test(
        'ITC-ASSESS-03b: Submit with empty symptoms → Default text used',
        () async {
          // Arrange: Mock success
          when(
            mockDio.post(
              argThat(contains('/assessments')),
              data: anyNamed('data'),
            ),
          ).thenAnswer(
            (_) async => DioMockHelper.successResponse(
              data: AssessmentFixtures.successAssessmentResponse(),
              statusCode: 201,
            ),
          );

          // Act: Submit with empty symptoms
          final imageData = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]);
          await repository.submitAssessment(
            petName: PetFixtures.validName,
            petType: PetFixtures.validSpecies,
            symptoms: '', // Empty
            imageData: imageData,
            petId: AssessmentFixtures.validPetId,
          );

          // Assert: Verify default symptom text was sent
          final capturedData =
              verify(
                    mockDio.post(any, data: captureAnyNamed('data')),
                  ).captured.single
                  as FormData;
          // The repository should send 'No additional symptoms described'
          final symptomField = capturedData.fields.firstWhere(
            (entry) => entry.key == 'symptom_description',
          );
          expect(symptomField.value, contains('No additional'));
        },
      );

      test('ITC-ASSESS-04: Network error → User-friendly message', () async {
        // Arrange: Mock network timeout
        when(
          mockDio.post(
            argThat(contains('/assessments')),
            data: anyNamed('data'),
          ),
        ).thenThrow(DioMockHelper.receiveTimeoutError());

        // Act: Try to submit
        final imageData = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]);
        final result = repository.submitAssessment(
          petName: PetFixtures.validName,
          petType: PetFixtures.validSpecies,
          imageData: imageData,
          petId: AssessmentFixtures.validPetId,
        );

        // Assert
        expect(
          () => result,
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('timeout'),
            ),
          ),
        );
      });
    });

    group('Fetch Assessment History', () {
      test('ITC-ASSESS-05: Fetch history → List returned', () async {
        // Arrange: Mock successful history fetch
        when(mockDio.get(argThat(contains('/assessments')))).thenAnswer(
          (_) async => DioMockHelper.successResponse(
            data: AssessmentFixtures.assessmentHistoryResponse(),
          ),
        );

        // Act: Fetch all assessments
        final result = await repository.getAssessmentHistory();

        // Assert: Verify list returned
        expect(result.length, 2);
        expect(result[0].id, 1);
        expect(result[0].riskLevel, AssessmentFixtures.highRisk);
        expect(result[1].id, 2);
        expect(result[1].riskLevel, AssessmentFixtures.highRisk);

        // Verify Dio was called
        verify(mockDio.get(argThat(contains('/assessments')))).called(1);
      });

      test(
        'ITC-ASSESS-06: Fetch pet assessment history → Filtered list',
        () async {
          // Arrange: Mock successful pet-specific fetch
          when(
            mockDio.get(
              argThat(
                contains('/pets/${AssessmentFixtures.validPetId}/assessments'),
              ),
            ),
          ).thenAnswer(
            (_) async => DioMockHelper.successResponse(
              data: AssessmentFixtures.assessmentHistoryResponse(),
            ),
          );

          // Act: Fetch pet's assessments
          final result = await repository.getPetAssessmentHistory(
            AssessmentFixtures.validPetId,
          );

          // Assert: Verify list returned
          expect(result.length, 2);
          expect(result[0].petId, AssessmentFixtures.validPetId);
          expect(result[1].petId, AssessmentFixtures.validPetId);

          // Verify Dio was called with pet endpoint
          verify(
            mockDio.get(
              argThat(
                contains('/pets/${AssessmentFixtures.validPetId}/assessments'),
              ),
            ),
          ).called(1);
        },
      );

      test('ITC-ASSESS-07: Empty history → Empty list returned', () async {
        // Arrange: Mock empty list
        when(mockDio.get(argThat(contains('/assessments')))).thenAnswer(
          (_) async => DioMockHelper.successResponse(data: <dynamic>[]),
        );

        // Act
        final result = await repository.getAssessmentHistory();

        // Assert
        expect(result, isEmpty);
      });

      test(
        'ITC-ASSESS-08: Fetch history network error → User-friendly message',
        () async {
          // Arrange: Mock connection error
          when(
            mockDio.get(argThat(contains('/assessments'))),
          ).thenThrow(DioMockHelper.connectionError());

          // Act & Assert
          expect(
            () => repository.getAssessmentHistory(),
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

    group('Error Handling', () {
      test('ITC-ASSESS-09: 401 Unauthorized → Proper error message', () async {
        // Arrange: Mock 401 response
        when(
          mockDio.post(any, data: anyNamed('data')),
        ).thenThrow(DioMockHelper.unauthorizedError());

        // Act & Assert
        final imageData = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]);
        expect(
          () => repository.submitAssessment(
            petName: PetFixtures.validName,
            petType: PetFixtures.validSpecies,
            imageData: imageData,
            petId: AssessmentFixtures.validPetId,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('ITC-ASSESS-10: 500 Server Error → Proper error message', () async {
        // Arrange: Mock 500 response with detail
        when(mockDio.post(any, data: anyNamed('data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 500,
              data: {'detail': 'AI service temporarily unavailable'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        // Act & Assert
        final imageData = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]);
        expect(
          () => repository.submitAssessment(
            petName: PetFixtures.validName,
            petType: PetFixtures.validSpecies,
            imageData: imageData,
            petId: AssessmentFixtures.validPetId,
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
  });
}
