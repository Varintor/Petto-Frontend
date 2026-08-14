import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:petto_application/src/features/auth/data/repositories/auth_repository.dart';
import 'package:petto_application/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:petto_application/src/features/pet_management/data/repositories/pet_repository.dart';
import 'package:petto_application/src/features/pet_management/presentation/screens/auth_onboarding_screen.dart';

class _CapturingAuthRepository implements AuthRepository {
  Map<String, dynamic>? registeredPet;

  @override
  Future<bool> checkEmailAvailability(String email) async => true;

  @override
  Future<AuthUser> getMe(String token) => throw UnimplementedError();

  @override
  Future<AuthResult> login(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<AuthResult> register(
    String email,
    String password,
    String name, {
    Map<String, dynamic>? pet,
  }) async {
    registeredPet = Map<String, dynamic>.from(pet!);
    return AuthResult(
      accessToken: 'test-token',
      user: AuthUser(id: 7, email: email, name: name),
      petJson: {'id': 11, 'user_id': 7, ...registeredPet!},
    );
  }
}

Future<void> _advance(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void _configurePhoneCanvas(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 3200);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('A RenderFlex overflowed')) return;
    originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);
}

Future<_CapturingAuthRepository> _pumpRegistration(
  WidgetTester tester, {
  ValueChanged<Pet>? onRegistrationComplete,
}) async {
  SharedPreferences.setMockInitialValues({});
  final repository = _CapturingAuthRepository();
  final auth = AuthController(repository: repository);
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthController>.value(
      value: auth,
      child: MaterialApp(
        home: AuthOnboardingScreen(
          startAtLogin: true,
          onRegistrationComplete: onRegistrationComplete,
        ),
      ),
    ),
  );
  await _advance(tester);
  return repository;
}

Future<void> _reachPetName(WidgetTester tester) async {
  await tester.tap(find.text('REGISTER'));
  await _advance(tester);
  await tester.enterText(
    find.widgetWithText(TextField, 'Email address'),
    'owner@example.com',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Password'),
    'secret123',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Confirm password'),
    'secret123',
  );
  await tester.tap(find.text('CONTINUE'));
  await _advance(tester);

  await tester.enterText(
    find.widgetWithText(TextField, 'Enter your name here...'),
    'Pet Owner',
  );
  await tester.tap(find.text('NEXT'));
  await _advance(tester);
  await tester.tap(find.text('NEXT'));
  await _advance(tester);

  await tester.tap(find.text('DOG'));
  await tester.tap(find.text('NEXT'));
  await _advance(tester);
  expect(find.text('Name Your Pet'), findsOneWidget);
}

void main() {
  testWidgets('pet name is required before leaving the Name step', (
    tester,
  ) async {
    _configurePhoneCanvas(tester);
    await _pumpRegistration(tester);
    await _reachPetName(tester);

    await tester.tap(find.text('NEXT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Name Your Pet'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
    'registration with only name and species sends no silent defaults',
    (tester) async {
      _configurePhoneCanvas(tester);
      Pet? completedPet;
      final repository = await _pumpRegistration(
        tester,
        onRegistrationComplete: (pet) => completedPet = pet,
      );
      await _reachPetName(tester);

      await tester.enterText(find.byType(TextField).last, 'Buddy');
      await tester.tap(find.text('NEXT'));
      await _advance(tester);

      // Additional Info is genuinely optional. Its empty fields must remain
      // empty and the unset gender must not become Male.
      await tester.tap(find.text('NEXT'));
      await _advance(tester);

      // Birthday is also optional. NOT SURE must preserve null rather than the
      // date currently visible in the picker.
      await tester.tap(find.text('NOT SURE'));
      await _advance(tester);

      expect(find.text('All Set!'), findsOneWidget);
      expect(find.text('Not set'), findsNWidgets(6));
      expect(find.text('Male'), findsNothing);
      expect(find.text('0 years'), findsNothing);
      expect(find.text('0.0 kg'), findsNothing);

      await tester.tap(find.text('START'));
      await _advance(tester);

      expect(completedPet, isNotNull);
      expect(repository.registeredPet, {'name': 'Buddy', 'species': 'Dog'});
      expect(repository.registeredPet, isNot(contains('gender')));
      expect(repository.registeredPet, isNot(contains('date_of_birth')));
      expect(repository.registeredPet, isNot(contains('weight_kg')));
    },
  );

  testWidgets('entered weight must be greater than zero', (tester) async {
    _configurePhoneCanvas(tester);
    await _pumpRegistration(tester);
    await _reachPetName(tester);
    await tester.enterText(find.byType(TextField).last, 'Buddy');
    await tester.tap(find.text('NEXT'));
    await _advance(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Weight'), '0');
    await tester.tap(find.text('NEXT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Weight must be greater than 0'), findsOneWidget);
    expect(find.text('Additional Info'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('FINISH does not accept an untouched birthday picker default', (
    tester,
  ) async {
    _configurePhoneCanvas(tester);
    final repository = await _pumpRegistration(tester);
    await _reachPetName(tester);
    await tester.enterText(find.byType(TextField).last, 'Buddy');
    await tester.tap(find.text('NEXT'));
    await _advance(tester);
    await tester.tap(find.text('NEXT'));
    await _advance(tester);

    await tester.tap(find.text('FINISH'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Select a birthday or tap NOT SURE'), findsOneWidget);
    expect(find.text('Birthday'), findsOneWidget);
    expect(repository.registeredPet, isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}
