import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:petto_application/src/features/auth/data/repositories/auth_repository.dart';
import 'package:petto_application/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:petto_application/src/core/services/token_storage.dart';

import '../helpers/mock_dio.dart' show DioMockHelper;
import '../helpers/mock_dio.mocks.dart' show MockDio;
import '../helpers/test_fixtures.dart';

@GenerateMocks([TokenStorage])
import 'auth_integration_test.mocks.dart';

/// Integration Tests for Authentication Feature
///
/// Tests the full flow: Controller → Repository → Dio → Mock Response
/// Maps to UTC-01, UTC-02, STC-01, STC-02 from Test Record v1.0.0
void main() {
  late AuthRepository repository;
  late AuthController controller;
  late MockDio mockDio;
  late MockTokenStorage mockTokenStorage;

  setUp(() {
    // Setup mocks
    mockDio = MockDio();
    mockTokenStorage = MockTokenStorage();

    // Create repository with mock Dio
    repository = AuthRepositoryImpl(dio: mockDio);

    // Create controller with repository and mock storage
    controller = AuthController(
      repository: repository,
      storage: mockTokenStorage,
    );
  });

  group('Authentication Integration Tests', () {
    group('Register Flow', () {
      test('ITC-AUTH-01: Register success → Token stored', () async {
        // Arrange: Mock successful register response (like UTC-01-TC-01)
        when(
          mockDio.post(
            argThat(contains('/auth/register')),
            data: anyNamed('data'),
            options: anyNamed('options'),
          ),
        ).thenAnswer(
          (_) async => DioMockHelper.successResponse(
            data: AuthFixtures.successRegisterResponse(),
          ),
        );

        // Mock TokenStorage to capture the token
        when(mockTokenStorage.getToken()).thenAnswer((_) async => null);
        when(mockTokenStorage.getPetId()).thenAnswer((_) async => null);
        when(mockTokenStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockTokenStorage.saveUserId(any)).thenAnswer((_) async {});

        // Act: Call controller.register
        final result = await controller.register(
          AuthFixtures.validEmail,
          AuthFixtures.validPassword,
          AuthFixtures.validName,
        );

        // Assert: Verify success
        expect(result, true);
        expect(controller.status, AuthStatus.authenticated);
        expect(controller.userId, 1);
        expect(controller.token, AuthFixtures.validToken);

        // Verify Dio was called (Repository layer)
        verify(
          mockDio.post(
            argThat(contains('/auth/register')),
            data: captureAnyNamed('data'),
            options: anyNamed('options'),
          ),
        ).called(1);

        // Verify token was stored (Storage layer)
        verify(mockTokenStorage.saveToken(AuthFixtures.validToken)).called(1);
        verify(mockTokenStorage.saveUserId(1)).called(1);
      });

      test('ITC-AUTH-02: Register duplicate email → Error surfaced', () async {
        // Arrange: Mock 409 Conflict response (like UTC-01-TC-02)
        when(
          mockDio.post(
            argThat(contains('/auth/register')),
            data: anyNamed('data'),
            options: anyNamed('options'),
          ),
        ).thenThrow(
          DioMockHelper.conflictError(
            message: AuthFixtures.duplicateEmailErrorResponse()['detail'],
          ),
        );

        // Act: Try to register with duplicate email
        final result = await controller.register(
          AuthFixtures.duplicateEmail,
          AuthFixtures.validPassword,
          AuthFixtures.validName,
        );

        // Assert: Verify error
        expect(result, false);
        expect(controller.status, AuthStatus.error);
        expect(controller.error, contains('already registered'));

        // Verify token was NOT stored
        verifyNever(mockTokenStorage.saveToken(any));
        verifyNever(mockTokenStorage.saveUserId(any));
      });

      test('ITC-AUTH-02b: Register network error → Error shown', () async {
        // Arrange: Mock network timeout
        when(
          mockDio.post(
            any,
            data: anyNamed('data'),
            options: anyNamed('options'),
          ),
        ).thenThrow(DioMockHelper.timeoutError());

        // Act
        final result = await controller.register(
          AuthFixtures.validEmail,
          AuthFixtures.validPassword,
          AuthFixtures.validName,
        );

        // Assert
        expect(result, false);
        expect(controller.error, contains('timeout'));
      });
    });

    group('Login Flow', () {
      test('ITC-AUTH-03: Login success → Session started', () async {
        // Arrange: Mock successful login response (like UTC-02-TC-01, STC-02-#5)
        when(
          mockDio.post(
            argThat(contains('/auth/login')),
            data: anyNamed('data'),
            options: anyNamed('options'),
          ),
        ).thenAnswer(
          (_) async => DioMockHelper.successResponse(
            data: AuthFixtures.successLoginResponse(),
          ),
        );

        // Mock TokenStorage
        when(mockTokenStorage.getToken()).thenAnswer((_) async => null);
        when(mockTokenStorage.getPetId()).thenAnswer((_) async => null);
        when(mockTokenStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockTokenStorage.saveUserId(any)).thenAnswer((_) async {});

        // Act: Call controller.login
        final result = await controller.login(
          AuthFixtures.validEmail,
          AuthFixtures.validPassword,
        );

        // Assert: Verify success
        expect(result, true);
        expect(controller.status, AuthStatus.authenticated);
        expect(controller.userId, 1);
        expect(controller.token, AuthFixtures.validToken);

        // Verify Dio was called (Repository layer)
        verify(
          mockDio.post(
            argThat(contains('/auth/login')),
            data: captureAnyNamed('data'),
            options: anyNamed('options'),
          ),
        ).called(1);

        // Verify token was stored (Storage layer)
        verify(mockTokenStorage.saveToken(AuthFixtures.validToken)).called(1);
        verify(mockTokenStorage.saveUserId(1)).called(1);
      });

      test('ITC-AUTH-03b: Veterinarian login → Vet role restored', () async {
        when(
          mockDio.post(
            argThat(contains('/auth/login')),
            data: anyNamed('data'),
            options: anyNamed('options'),
          ),
        ).thenAnswer(
          (_) async => DioMockHelper.successResponse(
            data: AuthFixtures.veterinarianLoginResponse(),
          ),
        );
        when(mockTokenStorage.getPetId()).thenAnswer((_) async => null);
        when(mockTokenStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockTokenStorage.saveUserId(any)).thenAnswer((_) async {});

        final result = await controller.login(
          'doctor@petto.test',
          AuthFixtures.validPassword,
        );

        expect(result, isTrue);
        expect(controller.isVeterinarian, isTrue);
        expect(controller.currentUser?.name, 'Dr. Petto');
      });

      test('ITC-AUTH-04: Login wrong password → Error shown', () async {
        // Arrange: Mock 401 Unauthorized response (like UTC-02-TC-02, STC-02-#2)
        when(
          mockDio.post(
            argThat(contains('/auth/login')),
            data: anyNamed('data'),
            options: anyNamed('options'),
          ),
        ).thenThrow(
          DioMockHelper.unauthorizedError(
            message: AuthFixtures.invalidCredentialsErrorResponse()['detail'],
          ),
        );
        await controller.enterGuestMode();

        // Act: Try to login with wrong password
        final result = await controller.login(
          AuthFixtures.validEmail,
          AuthFixtures.wrongPassword,
        );

        // Assert: Verify error handled
        expect(result, false);
        expect(
          controller.status,
          AuthStatus.unauthenticated,
        ); // Login keeps unauthenticated status
        expect(controller.error, contains('Invalid email or password'));

        // Verify token was NOT stored
        verifyNever(mockTokenStorage.saveToken(any));
        verifyNever(mockTokenStorage.saveUserId(any));
      });

      test(
        'ITC-AUTH-04b: Login network error → User-friendly message',
        () async {
          // Arrange: Mock connection error
          when(
            mockDio.post(
              any,
              data: anyNamed('data'),
              options: anyNamed('options'),
            ),
          ).thenThrow(DioMockHelper.connectionError());

          // Act
          final result = await controller.login(
            AuthFixtures.validEmail,
            AuthFixtures.validPassword,
          );

          // Assert
          expect(result, false);
          expect(controller.error, contains('Cannot reach'));
        },
      );
    });

    group('Auto-Login Flow', () {
      test(
        'ITC-AUTH-05a: Auto-login with valid token → Session restored',
        () async {
          // Arrange: Mock stored token and successful getMe response
          when(
            mockTokenStorage.getToken(),
          ).thenAnswer((_) async => AuthFixtures.validToken);
          when(mockTokenStorage.getPetId()).thenAnswer((_) async => 1);

          when(
            mockDio.get(
              argThat(contains('/auth/me')),
              options: anyNamed('options'),
            ),
          ).thenAnswer(
            (_) async => DioMockHelper.successResponse(
              data: AuthFixtures.successMeResponse(),
            ),
          );

          // Act: Try auto-login
          await controller.tryAutoLogin();

          // Assert: Session restored
          expect(controller.status, AuthStatus.authenticated);
          expect(controller.userId, 1);
          expect(controller.token, AuthFixtures.validToken);
          expect(controller.petId, 1);

          // Verify getMe was called with Bearer token
          verify(
            mockDio.get(
              argThat(contains('/auth/me')),
              options: captureAnyNamed('options'),
            ),
          ).called(1);
        },
      );

      test(
        'ITC-AUTH-05b: Auto-login with invalid token → Session cleared',
        () async {
          // Arrange: Mock stored token but getMe returns 401
          when(
            mockTokenStorage.getToken(),
          ).thenAnswer((_) async => 'invalid-token');
          when(mockTokenStorage.clear()).thenAnswer((_) async {});

          when(
            mockDio.get(
              argThat(contains('/auth/me')),
              options: anyNamed('options'),
            ),
          ).thenThrow(DioMockHelper.unauthorizedError());

          // Act: Try auto-login with invalid token
          await controller.tryAutoLogin();

          // Assert: Session cleared
          expect(controller.status, AuthStatus.unauthenticated);
          expect(controller.token, null);
          expect(controller.userId, null);

          // Verify storage was cleared
          verify(mockTokenStorage.clear()).called(1);
        },
      );
    });

    group('Logout Flow', () {
      test('ITC-AUTH-05: Logout → All storage cleared', () async {
        // Arrange: Setup authenticated state
        when(mockTokenStorage.clear()).thenAnswer((_) async {});
        when(
          mockDio.post(
            any,
            data: anyNamed('data'),
            options: anyNamed('options'),
          ),
        ).thenAnswer(
          (_) async => DioMockHelper.successResponse(
            data: AuthFixtures.successLoginResponse(),
          ),
        );
        when(mockTokenStorage.getPetId()).thenAnswer((_) async => null);
        when(mockTokenStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockTokenStorage.saveUserId(any)).thenAnswer((_) async {});

        // Manually set authenticated state (simulating a logged-in user)
        await controller.login(
          AuthFixtures.validEmail,
          AuthFixtures.validPassword,
        );

        // Verify pre-logout state
        expect(controller.isAuthenticated, true);
        expect(controller.token, isNotNull);

        // Act: Logout
        await controller.logout();

        // Assert: All storage cleared
        expect(controller.status, AuthStatus.unauthenticated);
        expect(controller.token, null);
        expect(controller.userId, null);
        expect(controller.petId, null);
        expect(controller.justLoggedOut, true);

        // Verify storage.clear() was called
        verify(mockTokenStorage.clear()).called(1);
      });

      test('ITC-AUTH-05b: Logout handlers are executed', () async {
        // Arrange: Setup logout handler
        bool handlerExecuted = false;
        controller.addLogoutHandler(() {
          handlerExecuted = true;
        });

        when(mockTokenStorage.clear()).thenAnswer((_) async {});

        when(
          mockDio.post(
            any,
            data: anyNamed('data'),
            options: anyNamed('options'),
          ),
        ).thenAnswer(
          (_) async => DioMockHelper.successResponse(
            data: AuthFixtures.successLoginResponse(),
          ),
        );
        when(mockTokenStorage.getPetId()).thenAnswer((_) async => null);
        when(mockTokenStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockTokenStorage.saveUserId(any)).thenAnswer((_) async {});

        // Setup authenticated state
        await controller.login(
          AuthFixtures.validEmail,
          AuthFixtures.validPassword,
        );

        // Act: Logout
        await controller.logout();

        // Assert: Handler was executed
        expect(handlerExecuted, true);
      });
    });

    group('Pet ID Management', () {
      test(
        'ITC-AUTH-06: Set pet ID → Stored and reflected in controller',
        () async {
          // Arrange
          const testPetId = 5;
          when(mockTokenStorage.savePetId(any)).thenAnswer((_) async {});

          // Act: Set pet ID
          await controller.setPetId(testPetId);

          // Assert
          // The active id is intentionally hidden until authentication succeeds.
          expect(controller.petId, isNull);
          expect(controller.rawPetId, testPetId);
          verify(mockTokenStorage.savePetId(testPetId)).called(1);
        },
      );

      test('ITC-AUTH-07: Pet ID null when unauthenticated', () {
        // Arrange: Unauthenticated state
        expect(controller.isAuthenticated, false);

        // Assert: petId should be null even if rawPetId has value
        controller.setPetId(5);
        expect(controller.petId, null); // null because unauthenticated
        expect(controller.rawPetId, 5); // rawPetId still accessible
      });
    });

    group('Guest Mode', () {
      test(
        'ITC-AUTH-08: Enter guest mode → No token, unauthenticated',
        () async {
          // Act
          await controller.enterGuestMode();

          // Assert
          expect(controller.status, AuthStatus.unauthenticated);
          expect(controller.token, null);
          expect(controller.userId, null);
          expect(controller.petId, null);
          expect(controller.isGuest, true);
        },
      );
    });

    group('Logout Acknowledgement', () {
      test('ITC-AUTH-09: Acknowledge logout → Flag cleared', () async {
        // Arrange: Setup logged out state
        when(mockTokenStorage.clear()).thenAnswer((_) async {});
        await controller.login(
          AuthFixtures.validEmail,
          AuthFixtures.validPassword,
        );
        when(
          mockDio.post(
            any,
            data: anyNamed('data'),
            options: anyNamed('options'),
          ),
        ).thenAnswer(
          (_) async => DioMockHelper.successResponse(
            data: AuthFixtures.successLoginResponse(),
          ),
        );
        when(mockTokenStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockTokenStorage.saveUserId(any)).thenAnswer((_) async {});
        await controller.logout();

        expect(controller.justLoggedOut, true);

        // Act: Acknowledge logout
        controller.acknowledgeLogout();

        // Assert
        expect(controller.justLoggedOut, false);
      });
    });
  });
}
