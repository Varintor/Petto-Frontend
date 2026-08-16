import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/top_alert.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../health_assessment/presentation/screens/home_screen.dart';
import '../../../health_assessment/presentation/widgets/pet_avatar_widget.dart';
import '../../data/repositories/pet_repository.dart';

enum _AuthScreen {
  intro,
  gateway,
  forgotPassword,
  registerAccount,
  register,
  summary,
}

enum _RegisterStep {
  owner,
  credentials,
  petType,
  petName,
  petDetails,
  birthday,
}

class AuthOnboardingScreen extends StatefulWidget {
  const AuthOnboardingScreen({
    super.key,
    this.startAtLogin = false,
    this.onRegistrationComplete,
    this.passwordResetRepository,
  });

  /// When true, skip the marketing intro and open directly on the login
  /// form. Used by [AuthGate] right after a logout.
  final bool startAtLogin;

  /// Test/host hook that avoids coupling registration tests to Home's provider
  /// tree. Production leaves this null and follows the normal Home navigation.
  final ValueChanged<Pet>? onRegistrationComplete;
  final PasswordResetRepository? passwordResetRepository;

  @override
  State<AuthOnboardingScreen> createState() => _AuthOnboardingScreenState();
}

class _AuthOnboardingScreenState extends State<AuthOnboardingScreen> {
  static const _deepRed = Color(0xFF4E1F22);
  static const _red = Color(0xFF7B3034);
  static const _catColor = Color(0xFFC83F4E);
  static const _dogColor = Color(0xFF7A3F24);
  static const _rose = Color(0xFFB88A96);
  static const _paleRose = Color(0xFFE7D4D9);
  static const _cream = Color(0xFFF6F4F1);

  late _AuthScreen _screen = widget.startAtLogin
      ? _AuthScreen.gateway
      : _AuthScreen.intro;
  _RegisterStep _step = _RegisterStep.owner;
  int _transitionDirection = 1;
  String? _species;
  String? _gender;

  final _ownerName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _petName = TextEditingController();
  final _breed = TextEditingController();
  final _bloodType = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  int _birthDay = 1;
  int _birthMonth = 1;
  int _birthYear = DateTime.now().year - 1;
  DateTime? _birthday;
  bool _hasSelectedBirthday = false;

  bool _isLoading = false;
  String? _errorMessage;
  late final PasswordResetRepository _passwordResetRepository =
      widget.passwordResetRepository ?? PasswordResetRepositoryImpl();

  /// Per-field login errors, so each field can turn red and show its own hint
  /// (e.g. "Email is required", "Password is required", "Wrong password").
  /// Cleared when the user edits that field or starts a new attempt.
  String? _loginEmailError;
  String? _loginPasswordError;

  String? _eagerError;
  Pet? _registeredPet;

  /// Set when the eager register fails with HTTP 409 (email already in use).
  /// Drives a friendlier "go back and use another email / log in instead" UX
  /// instead of a generic error toast.
  bool _emailTaken = false;

  @override
  void dispose() {
    _ownerName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _petName.dispose();
    _breed.dispose();
    _bloodType.dispose();
    _age.dispose();
    _weight.dispose();
    super.dispose();
  }

  Color get _petColor => _species == 'Dog' ? _dogColor : _catColor;

  String get _birthdayLabel {
    final date = _birthday;
    if (date == null) return 'Not set';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _setBirthDay(int value) {
    setState(() {
      _birthDay = value;
      _hasSelectedBirthday = true;
    });
  }

  void _setBirthMonth(int value) {
    setState(() {
      _birthMonth = value;
      _birthDay = math.min(_birthDay, _daysInMonth(_birthYear, _birthMonth));
      _hasSelectedBirthday = true;
    });
  }

  void _setBirthYear(int value) {
    setState(() {
      _birthYear = value;
      _birthDay = math.min(_birthDay, _daysInMonth(_birthYear, _birthMonth));
      _hasSelectedBirthday = true;
    });
  }

  void _confirmBirthday() {
    if (!_hasSelectedBirthday) {
      showTopAlert(
        context,
        'Select a birthday or tap NOT SURE',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    setState(() {
      _birthday = DateTime(_birthYear, _birthMonth, _birthDay);
    });
    _openSummary();
  }

  void _skipBirthday() {
    setState(() {
      _birthday = null;
      _hasSelectedBirthday = false;
    });
    _openSummary();
  }

  void _openHome({Pet? initialPet}) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (initialPet != null && widget.onRegistrationComplete != null) {
      widget.onRegistrationComplete!(initialPet);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(initialPet: initialPet)),
    );
  }

  Future<void> _handleLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final email = _loginEmail.text.trim();
    final password = _loginPassword.text;
    final emailEmpty = email.isEmpty;
    final passwordEmpty = password.isEmpty;
    if (emailEmpty || passwordEmpty) {
      // Flag each empty field individually so both required-field messages show.
      setState(() {
        _loginEmailError = emailEmpty ? 'Email is required' : null;
        _loginPasswordError = passwordEmpty ? 'Password is required' : null;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loginEmailError = null;
      _loginPasswordError = null;
    });
    final auth = context.read<AuthController>();
    final success = await auth.login(email, password);
    if (!mounted) return;
    if (success) {
      // AuthGate owns post-login routing. It sends owners to Home and
      // veterinarians to the dedicated Vet portal based on the role returned
      // by the backend. Pushing Home here would bypass that authorization-aware
      // routing and incorrectly ask veterinarians to create a pet.
      return;
    } else {
      // Highlight the password field in red with an inline hint, and keep the
      // banner carrying the backend's message ("Invalid email or password").
      setState(() {
        _isLoading = false;
        _loginPasswordError = 'Wrong password';
      });
      if (mounted) {
        showTopAlert(
          context,
          auth.error ?? 'Login failed. Please try again.',
          icon: Icons.info_outline_rounded,
        );
      }
    }
  }

  Future<void> _handleGuestMode() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await context.read<AuthController>().enterGuestMode();
    if (!mounted) return;
    _openHome();
  }

  /// Registers user + pet in ONE backend call (single DB transaction), so a
  /// pet-side failure can't leave an orphan "registered but no pet" account.
  /// The auth session is only applied after the pet exists, so AuthGate
  /// cannot jump to Home's empty pet state.
  Future<void> _runRegistrationAndCreatePet() async {
    final auth = context.read<AuthController>();
    try {
      final species = _species;
      final petName = _petName.text.trim();
      if (species == null || petName.isEmpty) {
        throw StateError('Pet name and species are required');
      }
      final breed = _breed.text.trim();
      final bloodType = _bloodType.text.trim();
      final weight = _optionalPositiveNumber(_weight.text, fieldName: 'Weight');
      final result = await auth.repository.register(
        _email.text.trim(),
        _password.text,
        _ownerName.text.trim(),
        pet: {
          'name': petName,
          'species': species,
          if (breed.isNotEmpty) 'breed': breed,
          if (_gender != null) 'gender': _gender,
          if (_birthday != null)
            'date_of_birth': _birthday!.toIso8601String().split('T').first,
          if (weight != null) 'weight_kg': weight,
          if (bloodType.isNotEmpty) 'blood_type': bloodType,
        },
      );
      final token = result.accessToken;
      if (token.isEmpty) {
        throw Exception('Missing auth token after registration');
      }
      // Backends without atomic register+pet (older deploys) ignore the pet
      // payload and return no pet — fall back to the two-step createPet.
      final newPet = result.petJson != null
          ? Pet.fromJson(result.petJson!)
          : await PetRepository().createPet(
              token: token,
              name: petName,
              species: species,
              breed: breed.isEmpty ? null : breed,
              gender: _gender,
              dateOfBirth: _birthday,
              weightKg: weight,
              bloodType: bloodType.isEmpty ? null : bloodType,
            );
      _registeredPet = newPet;
      await auth.applyCompletedRegistration(result, petId: newPet.id);
    } catch (e) {
      final raw = e.toString().replaceFirst('Exception: ', '');
      // Backend returns 409 + detail "Email already registered" for duplicate
      // signups. Map to a friendly message + flag so the Continue handler can
      // bounce the user back to the credentials step instead of getting stuck.
      if (raw.toLowerCase().contains('already registered') ||
          raw.contains('409')) {
        _emailTaken = true;
        _eagerError =
            'This email is already registered. Try logging in or use a different email.';
      } else {
        _eagerError = raw;
      }
      rethrow;
    }
  }

  double? _optionalPositiveNumber(String raw, {required String fieldName}) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) {
      throw FormatException('$fieldName must be greater than 0');
    }
    return parsed;
  }

  Future<void> _handleRegisterAndCreatePet() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _runRegistrationAndCreatePet();
      if (!mounted) return;
      _openHome(initialPet: _registeredPet);
    } catch (_) {
      if (!mounted) return;
      final message = _eagerError ?? 'Could not complete sign-up.';

      if (_emailTaken) {
        // Bounce the user back to the credentials step so they can pick a
        // different email (or go log in) without re-walking the whole flow.
        setState(() {
          _isLoading = false;
          _errorMessage = message;
          _transitionDirection = -1;
          _screen = _AuthScreen.register;
          _step = _RegisterStep.credentials;
        });
        showTopAlert(context, message, icon: Icons.info_outline_rounded);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
        showTopAlert(context, message, icon: Icons.info_outline_rounded);
      }
    }
  }

  void _openRegisterFlow() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _transitionDirection = 1;
      _screen = _AuthScreen.registerAccount;
    });
  }

  void _openPetOnboarding() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _transitionDirection = 1;
      _screen = _AuthScreen.register;
      _step = _RegisterStep.owner;
    });
  }

  void _completeAccountRegister() {
    FocusManager.instance.primaryFocus?.unfocus();
    final email = _email.text.trim();
    final password = _password.text;
    final confirm = _confirmPassword.text;
    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      showTopAlert(
        context,
        'Please fill in email and password.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    // Enforce the password-strength rule promised by the on-screen hint before
    // letting the user leave this screen — a weak password must block here, not
    // silently pass through to the later steps.
    if (password.length < 6) {
      showTopAlert(
        context,
        'Password must be at least 6 characters',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    if (password != confirm) {
      showTopAlert(
        context,
        'Passwords do not match.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    // Basic email format validation
    if (!_isValidEmail(email)) {
      showTopAlert(
        context,
        'Please enter a valid email address.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    // Check email availability before proceeding
    _checkEmailAndProceed(email);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _checkEmailAndProceed(String email) async {
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthController>();
      final isAvailable = await auth.repository.checkEmailAvailability(email);

      if (!mounted) return;

      if (!isAvailable) {
        setState(() => _isLoading = false);
        showTopAlert(
          context,
          'This email is already registered. Please log in instead.',
          icon: Icons.error_outline_rounded,
        );
        return;
      }

      // Email is available, proceed to pet onboarding
      setState(() => _isLoading = false);
      _openPetOnboarding();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // On error, allow proceeding (will catch duplicate on actual registration)
      _openPetOnboarding();
    }
  }

  void _openForgotPassword() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _transitionDirection = 1;
      _screen = _AuthScreen.forgotPassword;
    });
  }

  Future<void> _sendPasswordReset() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final email = _loginEmail.text.trim();
    if (!_isValidEmail(email)) {
      showTopAlert(
        context,
        'Enter a valid email address.',
        icon: Icons.error_outline_rounded,
      );
      return;
    }
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final message = await _passwordResetRepository.requestReset(email);
      if (!mounted) return;
      showTopAlert(context, message);
    } catch (error) {
      if (!mounted) return;
      showTopAlert(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        icon: Icons.error_outline_rounded,
      );
      setState(() => _isLoading = false);
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _transitionDirection = -1;
      _screen = _AuthScreen.gateway;
    });
  }

  void _back() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_screen == _AuthScreen.gateway) {
      setState(() {
        _transitionDirection = -1;
        _screen = _AuthScreen.intro;
      });
      return;
    }
    if (_screen == _AuthScreen.forgotPassword) {
      setState(() {
        _transitionDirection = -1;
        _screen = _AuthScreen.gateway;
      });
      return;
    }
    if (_screen == _AuthScreen.registerAccount) {
      setState(() {
        _transitionDirection = -1;
        _screen = _AuthScreen.gateway;
      });
      return;
    }
    if (_screen != _AuthScreen.register) return;

    final index = _RegisterStep.values.indexOf(_step);
    if (index == 0) {
      setState(() {
        _transitionDirection = -1;
        _screen = _AuthScreen.gateway;
      });
      return;
    }
    setState(() {
      _transitionDirection = -1;
      _step = _RegisterStep.values[index - 1];
    });
  }

  void _nextStep() {
    FocusManager.instance.primaryFocus?.unfocus();
    final index = _RegisterStep.values.indexOf(_step);
    if (index == _RegisterStep.values.length - 1) {
      _openSummary();
      return;
    }
    setState(() {
      _transitionDirection = 1;
      _step = _RegisterStep.values[index + 1];
    });
  }

  /// Owner step (step 1) submit. The display name is required — advancing with
  /// an empty name would leave the profile with no owner label, so block the
  /// step and nudge the user instead of silently continuing.
  void _submitOwnerName() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_ownerName.text.trim().isEmpty) {
      showTopAlert(
        context,
        'Enter a display name',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    _nextStep();
  }

  void _submitSpecies() {
    if (_species == null) {
      showTopAlert(
        context,
        'Please select a species',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    _nextStep();
  }

  void _submitPetName() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_petName.text.trim().isEmpty) {
      showTopAlert(
        context,
        'Name is required',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    _nextStep();
  }

  void _submitAdditionalInfo() {
    FocusManager.instance.primaryFocus?.unfocus();
    final ageText = _age.text.trim();
    final age = int.tryParse(ageText);
    if (ageText.isNotEmpty && (age == null || age <= 0)) {
      showTopAlert(
        context,
        'Age must be greater than 0',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    final weightText = _weight.text.trim();
    final weight = double.tryParse(weightText);
    if (weightText.isNotEmpty && (weight == null || weight <= 0)) {
      showTopAlert(
        context,
        'Weight must be greater than 0',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    _nextStep();
  }

  void _openSummary() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _transitionDirection = 1;
      _screen = _AuthScreen.summary;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _cream,
      body: Stack(
        children: [
          const Positioned.fill(child: _ReferenceBackground()),
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: AppTheme.motionFast,
              reverseDuration: AppTheme.motionFast,
              switchInCurve: AppTheme.motionCurveSoft,
              switchOutCurve: AppTheme.motionReverseCurve,
              transitionBuilder: _buildAuthTransition,
              layoutBuilder: _buildLockedTransitionLayout,
              child: _currentView,
            ),
          ),
        ],
      ),
    );
  }

  Widget get _currentView {
    switch (_screen) {
      case _AuthScreen.intro:
        return _PanelFrame(
          key: ValueKey(_AuthScreen.intro.name),
          child: _IntroPage(
            onStart: () {
              setState(() {
                _transitionDirection = 1;
                _screen = _AuthScreen.gateway;
              });
            },
          ),
        );
      case _AuthScreen.gateway:
        return _PanelFrame(
          key: ValueKey(_AuthScreen.gateway.name),
          child: _GatewayPage(
            emailController: _loginEmail,
            passwordController: _loginPassword,
            emailError: _loginEmailError,
            passwordError: _loginPasswordError,
            onEmailChanged: (_) {
              if (_loginEmailError != null) {
                setState(() => _loginEmailError = null);
              }
            },
            onPasswordChanged: (_) {
              if (_loginPasswordError != null) {
                setState(() => _loginPasswordError = null);
              }
            },
            onBack: _back,
            onLogin: _handleLogin,
            onRegister: _openRegisterFlow,
            onForgotPassword: _openForgotPassword,
            onGuest: _handleGuestMode,
          ),
        );
      case _AuthScreen.forgotPassword:
        return _PanelFrame(
          key: ValueKey(_AuthScreen.forgotPassword.name),
          child: _ForgotPasswordPage(
            emailController: _loginEmail,
            onBack: _back,
            onSubmit: _sendPasswordReset,
            isLoading: _isLoading,
          ),
        );
      case _AuthScreen.registerAccount:
        return _PanelFrame(
          key: ValueKey(_AuthScreen.registerAccount.name),
          child: _RegisterAccountPage(
            emailController: _email,
            passwordController: _password,
            confirmPasswordController: _confirmPassword,
            onBack: _back,
            onSubmit: _completeAccountRegister,
          ),
        );
      case _AuthScreen.register:
        return _PanelFrame(
          key: ValueKey(_AuthScreen.register.name),
          child: _RegisterStepShell(
            step: _RegisterStep.values.indexOf(_step) + 1,
            child: AnimatedSwitcher(
              duration: AppTheme.motionFast,
              reverseDuration: AppTheme.motionFast,
              switchInCurve: AppTheme.motionCurveSoft,
              switchOutCurve: AppTheme.motionReverseCurve,
              transitionBuilder: _buildAuthTransition,
              layoutBuilder: _buildLockedTransitionLayout,
              child: KeyedSubtree(
                key: ValueKey(_step.name),
                child: _registerView,
              ),
            ),
          ),
        );
      case _AuthScreen.summary:
        return _PanelFrame(
          key: const ValueKey('summary'),
          child: Stack(
            children: [
              _ProfileSummaryPage(
                ownerName: _ownerName.text.trim(),
                petName: _petName.text.trim(),
                species: _species!,
                petColor: _petColor,
                gender: _gender,
                age: _age.text.trim(),
                weight: _weight.text.trim(),
                breed: _breed.text.trim(),
                bloodType: _bloodType.text.trim(),
                birthday: _birthdayLabel,
                errorMessage: _errorMessage,
                onBack: () {
                  setState(() {
                    _transitionDirection = -1;
                    _errorMessage = null;
                    _screen = _AuthScreen.register;
                    _step = _RegisterStep.birthday;
                  });
                },
                onContinue: _handleRegisterAndCreatePet,
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: _cream.withValues(alpha: 0.85),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: _red,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Creating your account...',
                            style: TextStyle(
                              fontFamily: AppTheme.sansFontFamily,
                              color: _deepRed,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
    }
  }

  Widget _buildLockedTransitionLayout(
    Widget? currentChild,
    List<Widget> previousChildren,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (currentChild != null) Positioned.fill(child: currentChild),
      ],
    );
  }

  Widget _buildAuthTransition(Widget child, Animation<double> animation) {
    final startOffset = Offset(0.003 * _transitionDirection, 0);
    final slideCurve = CurvedAnimation(
      parent: animation,
      curve: AppTheme.motionCurveSoft,
      reverseCurve: AppTheme.motionReverseCurve,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: startOffset,
        end: Offset.zero,
      ).animate(slideCurve),
      child: child,
    );
  }

  Widget get _registerView {
    switch (_step) {
      case _RegisterStep.owner:
        return _StepPage(
          step: 1,
          showHeader: false,
          topPet: const _WelcomePetMini(),
          title: 'Welcome!',
          subtitle: 'To get started, please tell us your name!',
          body: _LabeledInput(
            label: 'YOUR NAME',
            controller: _ownerName,
            hint: 'Enter your name here...',
            maxWidth: 380,
            autofocus: true,
            showLabel: false,
            onChanged: (_) => setState(() {}),
          ),
          primaryLabel: 'NEXT',
          onPrimary: _submitOwnerName,
        );
      case _RegisterStep.credentials:
        return _StepPage(
          step: 2,
          showHeader: false,
          topPet: const _AccountStepCharm(),
          title: 'Your Account',
          subtitle: 'Create login credentials for your Petto account.',
          body: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              children: [
                _IconInputField(
                  icon: Icons.email_rounded,
                  hint: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _IconInputField(
                  icon: Icons.lock_rounded,
                  hint: 'Password',
                  controller: _password,
                  obscure: true,
                ),
                const SizedBox(height: 14),
                _IconInputField(
                  icon: Icons.lock_outline_rounded,
                  hint: 'Confirm Password',
                  controller: _confirmPassword,
                  obscure: true,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontFamily: AppTheme.sansFontFamily,
                      color: Color(0xFFB33A3A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          secondaryLabel: 'BACK',
          onSecondary: _back,
          primaryLabel: 'NEXT',
          onPrimary: () {
            final email = _email.text.trim();
            final pass = _password.text;
            final confirm = _confirmPassword.text;
            if (email.isEmpty || !email.contains('@')) {
              setState(() => _errorMessage = 'Please enter a valid email');
              return;
            }
            if (pass.length < 6) {
              setState(
                () => _errorMessage = 'Password must be at least 6 characters',
              );
              return;
            }
            if (pass != confirm) {
              setState(() => _errorMessage = 'Passwords do not match');
              return;
            }
            // The user just (re)entered credentials, so clear any stale error
            // before continuing to the pet steps.
            _eagerError = null;
            _emailTaken = false;
            setState(() => _errorMessage = null);
            _nextStep();
          },
        );
      case _RegisterStep.petType:
        return _PetTypeStep(
          showHeader: false,
          species: _species,
          petColor: _petColor,
          onSelect: (value) {
            setState(() => _species = value);
          },
          onBack: _back,
          onNext: _submitSpecies,
        );
      case _RegisterStep.petName:
        return _StepPage(
          step: 3,
          showHeader: false,
          topPet: _PetNameStage(species: _species!, color: _petColor),
          title: 'Name Your Pet',
          subtitle: 'What is their name?',
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: _BigInput(
                controller: _petName,
                hint: _species == 'Cat'
                    ? 'e.g. Milo, Garfield...'
                    : 'e.g. Buddy, Charlie...',
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          secondaryLabel: 'BACK',
          onSecondary: _back,
          primaryLabel: 'NEXT',
          onPrimary: _submitPetName,
        );
      case _RegisterStep.petDetails:
        return _DetailsStep(
          showHeader: false,
          name: _petName.text.trim(),
          gender: _gender,
          age: _age,
          weight: _weight,
          breed: _breed,
          bloodType: _bloodType,
          onGenderChanged: (value) => setState(() => _gender = value),
          onBack: _back,
          onNext: _submitAdditionalInfo,
        );
      case _RegisterStep.birthday:
        return _BirthdayStep(
          showHeader: false,
          name: _petName.text.trim(),
          day: _birthDay,
          month: _birthMonth,
          year: _birthYear,
          onDayChanged: _setBirthDay,
          onMonthChanged: _setBirthMonth,
          onYearChanged: _setBirthYear,
          onBack: _back,
          onSkip: _skipBirthday,
          onFinish: _confirmBirthday,
        );
    }
  }
}

class _PanelFrame extends StatelessWidget {
  const _PanelFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 384),
          child: _MotionIn(
            offsetY: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  children: [
                    const _PettoMark(),
                    const SizedBox(height: 24),
                    const _IntroReveal(
                      delay: Duration(milliseconds: 120),
                      child: Text(
                        'PETTO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.displayFontFamily,
                          color: _AuthOnboardingScreenState._deepRed,
                          fontSize: 60,
                          height: 0.95,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _IntroReveal(
                      delay: Duration(milliseconds: 210),
                      child: Text(
                        'AI PET GUARDIAN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.sansFontFamily,
                          color: _AuthOnboardingScreenState._red,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                const _IntroReveal(
                  delay: Duration(milliseconds: 320),
                  child: Text(
                    'Keep your pet happy and healthy with cutting-edge AI technology.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.sansFontFamily,
                      color: Color(0x994E1F22),
                      fontSize: 18,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _IntroReveal(
                  delay: const Duration(milliseconds: 430),
                  child: _ReferenceButton(
                    label: 'GET STARTED',
                    icon: Icons.arrow_forward_rounded,
                    onTap: onStart,
                    fullWidth: true,
                    animatedIcon: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroBrandPill extends StatelessWidget {
  const _IntroBrandPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 14, 7),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _AuthOnboardingScreenState._red.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: _AuthOnboardingScreenState._red,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Daily pet care',
            style: TextStyle(
              fontFamily: AppTheme.sansFontFamily,
              color: _AuthOnboardingScreenState._deepRed,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroBrandLockup extends StatelessWidget {
  const _IntroBrandLockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'PETTO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.displayFontFamily,
            color: _AuthOnboardingScreenState._deepRed,
            fontSize: 52,
            height: 0.94,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'pet wellness companion',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.sansFontFamily,
            color: _AuthOnboardingScreenState._rose,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'AI PET GUARDIAN',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.sansFontFamily,
            color: _AuthOnboardingScreenState._red.withValues(alpha: 0.58),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.4,
          ),
        ),
      ],
    );
  }
}

class _IntroFeatureRow extends StatelessWidget {
  const _IntroFeatureRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: const [
        _IntroFeatureChip(icon: Icons.auto_awesome_rounded, label: 'AI care'),
        _IntroFeatureChip(icon: Icons.flag_rounded, label: 'Missions'),
        _IntroFeatureChip(icon: Icons.calendar_month_rounded, label: 'Plans'),
      ],
    );
  }
}

class _IntroFeatureChip extends StatelessWidget {
  const _IntroFeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _AuthOnboardingScreenState._red.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _AuthOnboardingScreenState._red, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _AuthOnboardingScreenState._deepRed,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline validation message shown beneath a login field (red icon + text).
class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: AppTheme.dangerColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: AppTheme.sansFontFamily,
                color: AppTheme.dangerColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GatewayPage extends StatelessWidget {
  const _GatewayPage({
    required this.emailController,
    required this.passwordController,
    required this.emailError,
    required this.passwordError,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onBack,
    required this.onLogin,
    required this.onRegister,
    required this.onForgotPassword,
    required this.onGuest,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;

  /// When non-null, the matching field is shown in its error state and this
  /// message is rendered beneath it (e.g. "Email is required", "Wrong password").
  final String? emailError;
  final String? passwordError;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onBack;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;
  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: _MotionIn(
              initialScale: 0.95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Login / Register',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFontFamily,
                      color: _AuthOnboardingScreenState._deepRed,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _GatewayAuthField(
                    controller: emailController,
                    hint: 'Email address',
                    icon: Icons.mail_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    hasError: emailError != null,
                    onChanged: onEmailChanged,
                  ),
                  if (emailError != null) _FieldError(emailError!),
                  const SizedBox(height: 12),
                  _GatewayAuthField(
                    controller: passwordController,
                    hint: 'Password',
                    icon: Icons.lock_rounded,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    hasError: passwordError != null,
                    onChanged: onPasswordChanged,
                    onSubmitted: (_) => onLogin(),
                  ),
                  if (passwordError != null) _FieldError(passwordError!),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onForgotPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: _AuthOnboardingScreenState._red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        textStyle: const TextStyle(
                          fontFamily: AppTheme.sansFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ReferenceButton(
                          label: 'LOGIN',
                          onTap: onLogin,
                          icon: Icons.arrow_forward_rounded,
                          animatedIcon: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _RegisterActionButton(onTap: onRegister)),
                    ],
                  ),
                  if (AppConfig.environment != 'production') ...[
                    const SizedBox(height: 18),
                    const _OrDivider(),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 184,
                        child: _ReferenceButton(label: 'GUEST', onTap: onGuest),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  TextButton.icon(
                    onPressed: onBack,
                    label: const Text('VIEW SECURITY DETAILS'),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    iconAlignment: IconAlignment.end,
                    style: TextButton.styleFrom(
                      foregroundColor: _AuthOnboardingScreenState._red,
                      textStyle: const TextStyle(
                        fontFamily: AppTheme.sansFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordPage extends StatelessWidget {
  const _ForgotPasswordPage({
    required this.emailController,
    required this.onBack,
    required this.onSubmit,
    required this.isLoading,
  });

  final TextEditingController emailController;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: _MotionIn(
              initialScale: 0.95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _AuthOnboardingScreenState._red.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: _AuthOnboardingScreenState._red,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Forgot password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFontFamily,
                      color: _AuthOnboardingScreenState._deepRed,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your email and we will send a reset link.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.sansFontFamily,
                      color: Color(0x664E1F22),
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _GatewayAuthField(
                    controller: emailController,
                    hint: 'Email address',
                    icon: Icons.mail_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onSubmit(),
                  ),
                  const SizedBox(height: 16),
                  _ReferenceButton(
                    label: isLoading ? 'SENDING...' : 'SEND RESET LINK',
                    onTap: isLoading ? null : onSubmit,
                    icon: Icons.arrow_forward_rounded,
                    fullWidth: true,
                    animatedIcon: true,
                  ),
                  const SizedBox(height: 16),
                  _GhostButton(label: 'BACK TO LOGIN', onTap: onBack),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterAccountPage extends StatelessWidget {
  const _RegisterAccountPage({
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onBack,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: _MotionIn(
              initialScale: 0.95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _AuthOnboardingScreenState._red.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: _AuthOnboardingScreenState._red,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Create account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFontFamily,
                      color: _AuthOnboardingScreenState._deepRed,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set up your login before creating your pet profile.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.sansFontFamily,
                      color: Color(0x664E1F22),
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _GatewayAuthField(
                    controller: emailController,
                    hint: 'Email address',
                    icon: Icons.mail_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  _GatewayAuthField(
                    controller: passwordController,
                    hint: 'Password',
                    icon: Icons.lock_rounded,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  _GatewayAuthField(
                    controller: confirmPasswordController,
                    hint: 'Confirm password',
                    icon: Icons.verified_user_rounded,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onSubmit(),
                  ),
                  const SizedBox(height: 10),
                  const _RegisterPasswordHint(),
                  const SizedBox(height: 18),
                  _ReferenceButton(
                    label: 'CONTINUE',
                    onTap: onSubmit,
                    icon: Icons.arrow_forward_rounded,
                    fullWidth: true,
                    animatedIcon: true,
                  ),
                  const SizedBox(height: 14),
                  _GhostButton(label: 'BACK TO LOGIN', onTap: onBack),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterPasswordHint extends StatelessWidget {
  const _RegisterPasswordHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _AuthOnboardingScreenState._paleRose.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _AuthOnboardingScreenState._red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Password needs at least 6 characters',
            style: TextStyle(
              fontFamily: AppTheme.sansFontFamily,
              color: _AuthOnboardingScreenState._deepRed,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountStepCharm extends StatelessWidget {
  const _AccountStepCharm();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Center(
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: _AuthOnboardingScreenState._paleRose.withValues(alpha: 0.44),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            color: _AuthOnboardingScreenState._red,
            size: 32,
          ),
        ),
      ),
    );
  }
}

class _RegisterActionButton extends StatelessWidget {
  const _RegisterActionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppTheme.surfaceColor,
            border: Border.all(
              color: _AuthOnboardingScreenState._red.withValues(alpha: 0.34),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: _AuthOnboardingScreenState._deepRed.withValues(
                  alpha: 0.07,
                ),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'REGISTER',
                    style: TextStyle(
                      fontFamily: AppTheme.sansFontFamily,
                      color: _AuthOnboardingScreenState._red,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.person_add_alt_1_rounded,
                color: _AuthOnboardingScreenState._red,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterStepShell extends StatelessWidget {
  const _RegisterStepShell({required this.step, required this.child});

  final int step;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: MediaQuery.paddingOf(context).top + 50,
          left: 0,
          right: 0,
          child: IgnorePointer(child: _RegisterStepHeader(step: step)),
        ),
      ],
    );
  }
}

class _RegisterStepHeader extends StatelessWidget {
  const _RegisterStepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepIndicator(step: step),
        const SizedBox(height: 18),
        Text(
          'STEP $step OF 6',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTheme.sansFontFamily,
            color: _AuthOnboardingScreenState._red,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 7,
          ),
        ),
      ],
    );
  }
}

class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.topPet,
    this.secondaryLabel,
    this.onSecondary,
    this.showHeader = true,
  });

  final int step;
  final String title;
  final String subtitle;
  final Widget body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final Widget? topPet;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final isOwnerStep = step == 1 && secondaryLabel == null;
    final inlineActions = step == 3;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        36,
        MediaQuery.paddingOf(context).top + 126,
        36,
        isOwnerStep ? 118 : 78,
      ),
      child: Column(
        children: [
          if (showHeader) _RegisterStepHeader(step: step),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (topPet != null) ...[
                    topPet!,
                    const SizedBox(height: 24),
                  ] else
                    const SizedBox(height: 84),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTheme.displayFontFamily,
                      color: _AuthOnboardingScreenState._deepRed,
                      fontSize: 38,
                      height: 1.02,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTheme.sansFontFamily,
                      color: _AuthOnboardingScreenState._rose,
                      fontSize: 18,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: isOwnerStep ? 26 : 28),
                  body,
                  if (inlineActions) ...[
                    const SizedBox(height: 30),
                    _buildActions(),
                  ],
                ],
              ),
            ),
          ),
          if (!inlineActions) ...[
            SizedBox(height: isOwnerStep ? 18 : 28),
            _buildActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    if (secondaryLabel == null) {
      return Center(
        child: _ReferenceButton(
          label: primaryLabel,
          icon: Icons.arrow_forward_rounded,
          onTap: onPrimary,
          rounded: step == 1,
          width: step == 1 ? 380 : null,
          fullWidth: step != 1,
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Row(
          children: [
            Expanded(
              child: _GhostButton(label: secondaryLabel!, onTap: onSecondary),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _ReferenceButton(
                label: primaryLabel,
                icon: Icons.arrow_forward_rounded,
                onTap: onPrimary,
                quiet: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetTypeStep extends StatelessWidget {
  const _PetTypeStep({
    required this.showHeader,
    required this.species,
    required this.petColor,
    required this.onSelect,
    required this.onBack,
    required this.onNext,
  });

  final bool showHeader;
  final String? species;
  final Color petColor;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 660;
        final titleSize = compact ? 31.0 : 36.0;
        final subtitleSize = compact ? 16.0 : 18.0;
        final avatarStageHeight = compact ? 148.0 : 176.0;
        final avatarSize = compact ? 122.0 : 150.0;
        final topPadding = compact
            ? MediaQuery.paddingOf(context).top + 88
            : MediaQuery.paddingOf(context).top + 112;
        final bottomPadding = compact ? 38.0 : 68.0;
        return SingleChildScrollView(
          physics: compact
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.fromLTRB(38, topPadding, 38, bottomPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Meet Your\nCompanion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.displayFontFamily,
                          color: _AuthOnboardingScreenState._deepRed,
                          fontSize: titleSize,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: compact ? 10 : 14),
                      Text(
                        'What kind of pet do you have?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.sansFontFamily,
                          color: _AuthOnboardingScreenState._rose,
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: compact ? 14 : 22),
                      SizedBox(
                        height: avatarStageHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: _PetThoughtBubble(
                                  species: species ?? 'Cat',
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Center(
                                child: _PetAvatar(
                                  species: species ?? 'Cat',
                                  color: petColor,
                                  size: avatarSize,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: compact ? 16 : 20),
                      Row(
                        children: [
                          Expanded(
                            child: _PetChoice(
                              label: 'DOG',
                              species: 'Dog',
                              color: _AuthOnboardingScreenState._dogColor,
                              pattern: 'patches',
                              selected: species == 'Dog',
                              onTap: () => onSelect('Dog'),
                              compact: compact,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _PetChoice(
                              label: 'CAT',
                              species: 'Cat',
                              color: _AuthOnboardingScreenState._catColor,
                              pattern: 'none',
                              selected: species == 'Cat',
                              onTap: () => onSelect('Cat'),
                              compact: compact,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 20 : 28),
                      Row(
                        children: [
                          Expanded(
                            child: _GhostButton(label: 'BACK', onTap: onBack),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ReferenceButton(
                              label: 'NEXT',
                              icon: Icons.arrow_forward_rounded,
                              onTap: onNext,
                              quiet: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PetThoughtBubble extends StatelessWidget {
  const _PetThoughtBubble({required this.species});

  final String species;

  @override
  Widget build(BuildContext context) {
    final isDog = species == 'Dog';
    final text = isDog ? 'DOG MODE!' : 'CAT MODE!';

    return AnimatedSwitcher(
      duration: AppTheme.motionFast,
      reverseDuration: AppTheme.motionFast,
      switchInCurve: AppTheme.motionCurve,
      switchOutCurve: AppTheme.motionReverseCurve,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.84, end: 1).animate(animation),
          child: child,
        );
      },
      child: Stack(
        key: ValueKey(species),
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 112, maxWidth: 128),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _AuthOnboardingScreenState._paleRose.withValues(
                  alpha: 0.68,
                ),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _AuthOnboardingScreenState._deepRed.withValues(
                    alpha: 0.085,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.72),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: AppTheme.sansFontFamily,
                  color: _AuthOnboardingScreenState._red,
                  fontSize: 12,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: -6,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _AuthOnboardingScreenState._paleRose.withValues(
                    alpha: 0.62,
                  ),
                  width: 0.9,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _AuthOnboardingScreenState._deepRed.withValues(
                      alpha: 0.06,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 1,
            bottom: -10,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: _AuthOnboardingScreenState._paleRose.withValues(
                  alpha: 0.86,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.showHeader,
    required this.name,
    required this.gender,
    required this.age,
    required this.weight,
    required this.breed,
    required this.bloodType,
    required this.onGenderChanged,
    required this.onBack,
    required this.onNext,
  });

  final bool showHeader;
  final String name;
  final String? gender;
  final TextEditingController age;
  final TextEditingController weight;
  final TextEditingController breed;
  final TextEditingController bloodType;
  final ValueChanged<String> onGenderChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        36,
        MediaQuery.paddingOf(context).top + 118,
        36,
        66,
      ),
      child: Column(
        children: [
          if (showHeader) const _RegisterStepHeader(step: 4),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Additional Info',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFontFamily,
                      color: _AuthOnboardingScreenState._deepRed,
                      fontSize: 36,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tell us more about $name.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTheme.sansFontFamily,
                      color: _AuthOnboardingScreenState._rose,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _SegmentButton(
                                label: 'Male',
                                selected: gender == 'Male',
                                onTap: () => onGenderChanged('Male'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SegmentButton(
                                label: 'Female',
                                selected: gender == 'Female',
                                onTap: () => onGenderChanged('Female'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _IconInputField(
                                icon: Icons.cake_rounded,
                                hint: 'Age',
                                controller: age,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _IconInputField(
                                icon: Icons.monitor_weight_rounded,
                                hint: 'Weight',
                                controller: weight,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _IconInputField(
                          icon: Icons.badge_rounded,
                          hint: 'Breed',
                          controller: breed,
                        ),
                        const SizedBox(height: 14),
                        _IconInputField(
                          icon: Icons.bloodtype_rounded,
                          hint: 'Blood type',
                          controller: bloodType,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Row(
              children: [
                Expanded(
                  child: _GhostButton(label: 'BACK', onTap: onBack),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _ReferenceButton(
                    label: 'NEXT',
                    icon: Icons.arrow_forward_rounded,
                    onTap: onNext,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthdayStep extends StatelessWidget {
  const _BirthdayStep({
    required this.showHeader,
    required this.name,
    required this.day,
    required this.month,
    required this.year,
    required this.onDayChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onBack,
    required this.onSkip,
    required this.onFinish,
  });

  final bool showHeader;
  final String name;
  final int day;
  final int month;
  final int year;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List<int>.generate(31, (index) => currentYear - index);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        36,
        MediaQuery.paddingOf(context).top + 118,
        36,
        66,
      ),
      child: Column(
        children: [
          if (showHeader) const _RegisterStepHeader(step: 5),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _BirthdayCake(),
                  const SizedBox(height: 18),
                  const Text(
                    'Birthday',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFontFamily,
                      color: _AuthOnboardingScreenState._deepRed,
                      fontSize: 38,
                      height: 1.02,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'When is $name\'s special day?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTheme.sansFontFamily,
                      color: _AuthOnboardingScreenState._rose,
                      fontSize: 18,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: _BirthdayPicker(
                      day: day,
                      month: month,
                      year: year,
                      years: years,
                      monthLabels: months,
                      onDayChanged: onDayChanged,
                      onMonthChanged: onMonthChanged,
                      onYearChanged: onYearChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _GhostButton(label: 'NOT SURE', onTap: onSkip),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _GhostButton(label: 'BACK', onTap: onBack),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _ReferenceButton(label: 'FINISH', onTap: onFinish),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthdayPicker extends StatelessWidget {
  const _BirthdayPicker({
    required this.day,
    required this.month,
    required this.year,
    required this.years,
    required this.monthLabels,
    required this.onDayChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  final int day;
  final int month;
  final int year;
  final List<int> years;
  final List<String> monthLabels;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  @override
  Widget build(BuildContext context) {
    final totalDays = DateTime(year, month + 1, 0).day;
    final days = List<int>.generate(totalDays, (index) => index + 1);

    return Container(
      height: 178,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _AuthOnboardingScreenState._paleRose.withValues(alpha: 0.46),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: _AuthOnboardingScreenState._deepRed.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: _AuthOnboardingScreenState._paleRose.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _AuthOnboardingScreenState._paleRose.withValues(
                  alpha: 0.16,
                ),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _AuthOnboardingScreenState._deepRed.withValues(
                    alpha: 0.035,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                Container(
                  width: 1,
                  height: 88,
                  color: _AuthOnboardingScreenState._paleRose.withValues(
                    alpha: 0.18,
                  ),
                ),
                const Expanded(child: SizedBox()),
                Container(
                  width: 1,
                  height: 88,
                  color: _AuthOnboardingScreenState._paleRose.withValues(
                    alpha: 0.18,
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _BirthdayWheel<int>(
                  values: days,
                  selected: day,
                  labelBuilder: (value) => value.toString().padLeft(2, '0'),
                  onChanged: onDayChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BirthdayWheel<int>(
                  values: List<int>.generate(12, (index) => index + 1),
                  selected: month,
                  labelBuilder: (value) => monthLabels[value - 1],
                  onChanged: onMonthChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BirthdayWheel<int>(
                  values: years,
                  selected: year,
                  labelBuilder: (value) => '$value',
                  onChanged: onYearChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BirthdayWheel<T> extends StatefulWidget {
  const _BirthdayWheel({
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  State<_BirthdayWheel<T>> createState() => _BirthdayWheelState<T>();
}

class _BirthdayWheelState<T> extends State<_BirthdayWheel<T>> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: widget.values
          .indexOf(widget.selected)
          .clamp(0, widget.values.length - 1),
    );
  }

  @override
  void didUpdateWidget(covariant _BirthdayWheel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = widget.values.indexOf(widget.selected);
    if (index >= 0 && _controller.selectedItem != index) {
      _controller.animateToItem(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: 44,
      diameterRatio: 1.8,
      perspective: 0.002,
      physics: const FixedExtentScrollPhysics(),
      overAndUnderCenterOpacity: 0.36,
      onSelectedItemChanged: (index) => widget.onChanged(widget.values[index]),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.values.length,
        builder: (context, index) {
          final value = widget.values[index];
          final selected = value == widget.selected;
          return Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontFamily: AppTheme.sansFontFamily,
                color: selected
                    ? _AuthOnboardingScreenState._deepRed
                    : _AuthOnboardingScreenState._rose.withValues(alpha: 0.45),
                fontSize: selected ? 18.5 : 14.5,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
              child: Text(widget.labelBuilder(value)),
            ),
          );
        },
      ),
    );
  }
}

class _BirthdayCake extends StatefulWidget {
  const _BirthdayCake();

  @override
  State<_BirthdayCake> createState() => _BirthdayCakeState();
}

class _BirthdayCakeState extends State<_BirthdayCake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final phase = _controller.value * math.pi * 2;
        final cakeMotion = math.sin(phase * 0.55);
        final cakeLift = cakeMotion * 1.1;
        final cakeScale = 1 + (cakeMotion * 0.006);
        final cakeTilt = math.sin((phase * 0.55) + 0.7) * 0.006;
        return Transform.translate(
          offset: Offset(0, cakeLift),
          child: Transform.rotate(
            angle: cakeTilt,
            alignment: Alignment.bottomCenter,
            child: Transform.scale(
              scale: cakeScale,
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 150,
                height: 118,
                child: CustomPaint(painter: _BirthdayCakePainter(phase: phase)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BirthdayCakePainter extends CustomPainter {
  const _BirthdayCakePainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final flicker =
        (math.sin(phase * 1.4) * 0.65) + (math.sin(phase * 2.7 + 0.8) * 0.35);
    final flameLean = flicker * 1.4;
    final flameScaleX = 1 + (flicker * 0.035);
    final flameScaleY = 1 - (flicker * 0.025);
    final glowAlpha = 0.08 + (flicker.abs() * 0.025);
    final shadow = Paint()
      ..color = _AuthOnboardingScreenState._deepRed.withValues(alpha: 0.045)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final outline = Paint()
      ..color = _AuthOnboardingScreenState._deepRed.withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final plate = Paint()..color = Colors.white.withValues(alpha: 0.96);
    final plateLip = Paint()
      ..color = _AuthOnboardingScreenState._paleRose.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final cakeSide = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF5D7D9), Color(0xFFD49AA0)],
      ).createShader(Rect.fromLTWH(25, 50, 100, 45));
    final cream = Paint()..color = const Color(0xFFFFFFFC);
    final creamStroke = Paint()
      ..color = _AuthOnboardingScreenState._paleRose.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final softRed = Paint()
      ..color = _AuthOnboardingScreenState._red.withValues(alpha: 0.74);
    final gold = Paint()..color = const Color(0xFFC99B4A);
    final candle = Paint()..color = const Color(0xFFFFF7F2);
    final candleStripe = Paint()
      ..color = _AuthOnboardingScreenState._red.withValues(alpha: 0.58)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final wick = Paint()
      ..color = _AuthOnboardingScreenState._deepRed
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final flame = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF7D46A), Color(0xFFC99B4A)],
      ).createShader(Rect.fromLTWH(68, 0, 18, 28));
    final innerFlame = Paint()..color = const Color(0xFFFFF2B8);
    final glow = Paint()
      ..color = const Color(0xFFC99B4A).withValues(alpha: glowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 9),
        width: 118,
        height: 18,
      ),
      shadow,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(16, size.height - 27, size.width - 32, 18),
        const Radius.circular(99),
      ),
      plate,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(16, size.height - 27, size.width - 32, 18),
        const Radius.circular(99),
      ),
      plateLip,
    );

    final baseRect = Rect.fromLTWH(26, 59, 98, 39);
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(17)),
      cakeSide,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(17)),
      outline,
    );

    final baseCream = RRect.fromRectAndRadius(
      const Rect.fromLTWH(22, 47, 106, 24),
      const Radius.circular(18),
    );
    canvas.drawRRect(baseCream, cream);
    canvas.drawRRect(baseCream, creamStroke);

    for (final drip in const [
      Rect.fromLTWH(44, 61, 10, 14),
      Rect.fromLTWH(89, 60, 11, 16),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(drip, const Radius.circular(8)),
        cream,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(40, 83, 70, 5),
        const Radius.circular(99),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.26),
    );

    canvas.drawCircle(const Offset(52, 66), 3.1, softRed);
    canvas.drawCircle(const Offset(75, 63), 2.7, gold);
    canvas.drawCircle(const Offset(98, 66), 3.1, softRed);

    for (final sprinkle in const [
      (Offset(45, 53), -0.25, Color(0xFF9B3E45)),
      (Offset(72, 52), 0.22, Color(0xFFC99B4A)),
      (Offset(103, 54), -0.18, Color(0xFF9B3E45)),
    ]) {
      canvas.save();
      canvas.translate(sprinkle.$1.dx, sprinkle.$1.dy);
      canvas.rotate(sprinkle.$2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -1.4, 8, 2.8),
          const Radius.circular(3),
        ),
        Paint()..color = sprinkle.$3,
      );
      canvas.restore();
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width / 2 - 5, 24, 10, 24),
        const Radius.circular(5),
      ),
      candle,
    );
    canvas.drawLine(const Offset(70, 29), const Offset(77, 36), candleStripe);
    canvas.drawLine(const Offset(70, 39), const Offset(76, 45), candleStripe);
    canvas.drawLine(
      Offset(size.width / 2, 21),
      Offset(size.width / 2, 26),
      wick,
    );

    final flameCenter = Offset((size.width / 2) + flameLean, 19);
    canvas.drawOval(
      Rect.fromCenter(center: flameCenter, width: 24, height: 24),
      glow,
    );

    canvas.save();
    canvas.translate(flameCenter.dx, flameCenter.dy);
    canvas.scale(flameScaleX, flameScaleY);
    final flamePath = Path()
      ..moveTo(0, -10)
      ..cubicTo(8, -3, 5, 8, 0, 9)
      ..cubicTo(-6, 6, -6, -2, 0, -10)
      ..close();
    canvas.drawPath(flamePath, flame);
    final innerPath = Path()
      ..moveTo(0, -4)
      ..cubicTo(4, 0, 2.4, 5, 0, 5.5)
      ..cubicTo(-3, 4, -2.5, 0, 0, -4)
      ..close();
    canvas.drawPath(innerPath, innerFlame);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BirthdayCakePainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

class _ProfileSummaryPage extends StatelessWidget {
  const _ProfileSummaryPage({
    required this.ownerName,
    required this.petName,
    required this.species,
    required this.petColor,
    required this.gender,
    required this.age,
    required this.weight,
    required this.breed,
    required this.bloodType,
    required this.birthday,
    this.errorMessage,
    required this.onBack,
    required this.onContinue,
  });

  final String ownerName;
  final String petName;
  final String species;
  final Color petColor;
  final String? gender;
  final String age;
  final String weight;
  final String breed;
  final String bloodType;
  final String birthday;
  final String? errorMessage;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  String get _ownerLabel => ownerName.isEmpty ? 'Pet Parent' : ownerName;
  String get _breedLabel => breed.isEmpty ? 'Not set' : breed;
  String get _bloodTypeLabel => bloodType.isEmpty ? 'Not set' : bloodType;
  String get _ageLabel => age.isEmpty ? 'Not set' : '$age years';
  String get _weightLabel => weight.isEmpty ? 'Not set' : '$weight kg';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        32,
        MediaQuery.paddingOf(context).top + 32,
        32,
        36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 372),
          child: _MotionIn(
            offsetY: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        color: petColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                    _PetAvatar(species: species, color: petColor, size: 132),
                    Positioned(
                      right: 7,
                      bottom: 12,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _AuthOnboardingScreenState._deepRed
                                  .withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: _AuthOnboardingScreenState._red,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'All Set!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.displayFontFamily,
                    color: _AuthOnboardingScreenState._deepRed,
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here is ${petName.trim().isEmpty ? 'your pet' : petName}\'s little profile.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTheme.sansFontFamily,
                    color: _AuthOnboardingScreenState._rose,
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor.withValues(alpha: 0.97),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _AuthOnboardingScreenState._paleRose.withValues(
                        alpha: 0.34,
                      ),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _AuthOnboardingScreenState._deepRed.withValues(
                          alpha: 0.045,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _AuthOnboardingScreenState._red.withValues(
                                alpha: 0.09,
                              ),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: _AuthOnboardingScreenState._red,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Profile Details',
                              style: TextStyle(
                                fontFamily: AppTheme.displayFontFamily,
                                color: _AuthOnboardingScreenState._deepRed,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _AuthOnboardingScreenState._cream,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              species,
                              style: const TextStyle(
                                fontFamily: AppTheme.sansFontFamily,
                                color: _AuthOnboardingScreenState._red,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _SummaryRow(
                        icon: Icons.person_rounded,
                        label: 'Parent',
                        value: _ownerLabel,
                      ),
                      const _SummaryDivider(),
                      _SummaryRow(
                        icon: Icons.favorite_rounded,
                        label: 'Pet',
                        value: petName,
                      ),
                      const _SummaryDivider(),
                      _SummaryRow(
                        icon: species == 'Dog'
                            ? Icons.pets_rounded
                            : Icons.face_3_rounded,
                        label: 'Type',
                        value: species,
                      ),
                      const _SummaryDivider(),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryMiniTile(
                              label: 'Gender',
                              value: gender ?? 'Not set',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryMiniTile(
                              label: 'Breed',
                              value: _breedLabel,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryMiniTile(
                              label: 'Blood',
                              value: _bloodTypeLabel,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryMiniTile(
                              label: 'Age',
                              value: _ageLabel,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryMiniTile(
                              label: 'Weight',
                              value: _weightLabel,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryMiniTile(
                              label: 'Birthday',
                              value: birthday,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTheme.sansFontFamily,
                      color: Color(0xFFB33A3A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _GhostButton(label: 'BACK', onTap: onBack),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ReferenceButton(
                        label: 'START',
                        icon: Icons.arrow_forward_rounded,
                        onTap: onContinue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: _AuthOnboardingScreenState._paleRose.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _AuthOnboardingScreenState._paleRose.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              border: Border.all(
                color: _AuthOnboardingScreenState._paleRose.withValues(
                  alpha: 0.22,
                ),
                width: 1,
              ),
            ),
            child: Icon(icon, color: _AuthOnboardingScreenState._red, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: AppTheme.sansFontFamily,
                    color: _AuthOnboardingScreenState._rose,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value.trim().isEmpty ? 'Not set' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.displayFontFamily,
                    color: _AuthOnboardingScreenState._deepRed,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMiniTile extends StatelessWidget {
  const _SummaryMiniTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _AuthOnboardingScreenState._paleRose.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.sansFontFamily,
              color: _AuthOnboardingScreenState._rose,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: AppTheme.sansFontFamily,
                color: _AuthOnboardingScreenState._deepRed,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 2,
        child: Center(
          child: Container(
            width: 34,
            height: 2,
            decoration: BoxDecoration(
              color: _AuthOnboardingScreenState._paleRose.withValues(
                alpha: 0.18,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroPetHero extends StatefulWidget {
  const _IntroPetHero();

  @override
  State<_IntroPetHero> createState() => _IntroPetHeroState();
}

class _IntroPetHeroState extends State<_IntroPetHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final phase = _controller.value * math.pi * 2;
        final floatY = math.sin(phase) * 2.2;
        final scale = 1 + (math.sin(phase + 0.7) * 0.006);

        return SizedBox(
          width: 286,
          height: 206,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 20,
                right: 20,
                top: 14,
                bottom: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(44),
                    border: Border.all(
                      color: _AuthOnboardingScreenState._paleRose.withValues(
                        alpha: 0.22,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _AuthOnboardingScreenState._deepRed.withValues(
                          alpha: 0.06,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 28,
                child: Container(
                  width: 154,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _AuthOnboardingScreenState._deepRed.withValues(
                      alpha: 0.045,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                child: Transform.translate(
                  offset: Offset(0, floatY),
                  child: Transform.scale(
                    scale: scale,
                    child: SizedBox(
                      width: 176,
                      height: 176,
                      child: PetAvatarWidget(
                        species: 'Cat',
                        color: _AuthOnboardingScreenState._catColor,
                        pattern: 'none',
                        eyeType: 'default',
                        mouthType: 'smile',
                        equipped: const ['acc_collar'],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomePetMini extends StatefulWidget {
  const _WelcomePetMini();

  @override
  State<_WelcomePetMini> createState() => _WelcomePetMiniState();
}

class _WelcomePetMiniState extends State<_WelcomePetMini>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _tapSeed = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _greet() {
    setState(() {
      _tapSeed++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final phase = _controller.value * math.pi * 2;

        return SizedBox(
          width: 286,
          height: 174,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _WelcomePetBackdropPainter(phase: phase),
                ),
              ),
              _WelcomePetHead(
                species: 'Dog',
                color: _AuthOnboardingScreenState._dogColor,
                pattern: 'patches',
                size: 152,
                phase: phase,
                phaseOffset: 1.7,
                restingAngle: 0.11,
                tapSeed: _tapSeed,
                offset: const Offset(45, 8),
                onTap: _greet,
              ),
              _WelcomePetHead(
                species: 'Cat',
                color: _AuthOnboardingScreenState._catColor,
                pattern: 'none',
                size: 152,
                phase: phase,
                phaseOffset: 0,
                restingAngle: -0.11,
                tapSeed: _tapSeed,
                offset: const Offset(-58, 8),
                onTap: _greet,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomePetBackdropPainter extends CustomPainter {
  const _WelcomePetBackdropPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final glowPulse = 0.05 + (math.sin(phase * 0.7) * 0.008);
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.36),
              _AuthOnboardingScreenState._paleRose.withValues(alpha: glowPulse),
              Colors.transparent,
            ],
            stops: const [0, 0.42, 1],
          ).createShader(
            Rect.fromCircle(center: center.translate(0, 10), radius: 124),
          );
    final shadowPaint = Paint()
      ..color = _AuthOnboardingScreenState._deepRed.withValues(alpha: 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    final softPlatePaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.62),
              _AuthOnboardingScreenState._paleRose.withValues(alpha: 0.10),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCenter(
              center: Offset(size.width / 2, size.height - 28),
              width: 206,
              height: 42,
            ),
          )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(center.translate(0, 8), 124, glowPaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 22),
        width: 212,
        height: 30,
      ),
      shadowPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 28),
        width: 184,
        height: 24,
      ),
      softPlatePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WelcomePetBackdropPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

class _WelcomeSparkle extends StatelessWidget {
  const _WelcomeSparkle({
    required this.phase,
    required this.offset,
    required this.size,
    required this.delay,
  });

  final double phase;
  final Offset offset;
  final double size;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final pulse = (math.sin((phase * 0.9) + delay) + 1) / 2;
    final shimmer = Curves.easeInOut.transform(pulse);
    final scale = 0.82 + (shimmer * 0.22);
    final opacity = 0.28 + (shimmer * 0.28);
    final driftY = math.sin((phase * 0.72) + delay) * 2.2;

    return Positioned(
      left: 136 + offset.dx,
      top: 83 + offset.dy,
      child: Transform.translate(
        offset: Offset(0, driftY),
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.50),
                border: Border.all(
                  color: _AuthOnboardingScreenState._paleRose.withValues(
                    alpha: 0.46,
                  ),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _AuthOnboardingScreenState._red.withValues(
                      alpha: 0.08,
                    ),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.72),
                    blurRadius: 4,
                    spreadRadius: -1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomePetHead extends StatelessWidget {
  const _WelcomePetHead({
    required this.species,
    required this.color,
    required this.pattern,
    required this.size,
    required this.phase,
    required this.phaseOffset,
    required this.restingAngle,
    required this.tapSeed,
    required this.offset,
    required this.onTap,
  });

  final String species;
  final Color color;
  final String pattern;
  final double size;
  final double phase;
  final double phaseOffset;
  final double restingAngle;
  final int tapSeed;
  final Offset offset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final floatY = math.sin((phase * 0.72) + phaseOffset) * 1.35;
    final cuddleX = math.sin((phase * 0.58) + phaseOffset) * 0.8;
    final tilt =
        restingAngle + (math.sin((phase * 0.62) + phaseOffset) * 0.012);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      left: 64 + offset.dx,
      top: 10 + offset.dy,
      child: GestureDetector(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          key: ValueKey('$species-$tapSeed'),
          tween: Tween(begin: 0.94, end: 1),
          duration: const Duration(milliseconds: 540),
          curve: Curves.elasticOut,
          builder: (context, pop, child) {
            return Transform.translate(
              offset: Offset(cuddleX, floatY),
              child: Transform.rotate(
                angle: tilt,
                child: Transform.scale(scale: pop, child: child),
              ),
            );
          },
          child: SizedBox(
            width: size,
            height: size,
            child: IgnorePointer(
              child: PetAvatarWidget(
                species: species,
                color: color,
                headOnly: true,
                pattern: pattern,
                eyeType: 'happy',
                mouthType: 'smile',
                equipped: const <String>[],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PettoMark extends StatefulWidget {
  const _PettoMark();

  @override
  State<_PettoMark> createState() => _PettoMarkState();
}

class _PettoMarkState extends State<_PettoMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 720),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        final rotation = (-20 + (26 * value)) * 3.141592653589793 / 180;
        return Transform.rotate(
          angle: rotation,
          child: Transform.scale(scale: value.clamp(0, 1), child: child),
        );
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final wave = math.sin(_controller.value * math.pi * 2);
          final softWave = math.sin((_controller.value + 0.2) * math.pi * 2);
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _MarkSparkle(
                controllerValue: _controller.value,
                size: 7,
                top: 6,
                right: -18,
                delay: 0,
              ),
              _MarkSparkle(
                controllerValue: _controller.value,
                size: 5,
                bottom: 10,
                left: -20,
                delay: 0.36,
              ),
              _MarkSparkle(
                controllerValue: _controller.value,
                size: 4,
                top: -14,
                left: 18,
                delay: 0.68,
              ),
              Transform.translate(
                offset: Offset(0, wave * 2.2),
                child: Transform.rotate(
                  angle: softWave * 0.025,
                  child: Transform.scale(
                    scale: 1 + (wave * 0.018),
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: _AuthOnboardingScreenState._red,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: _AuthOnboardingScreenState._red.withValues(alpha: 0.28),
                blurRadius: 50,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: const Color(0xFFE7D4D9).withValues(alpha: 0.42),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final beat = math.sin(_controller.value * math.pi * 4);
              return Transform.scale(
                scale: 1 + math.max(0, beat) * 0.055,
                child: child,
              );
            },
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkSparkle extends StatelessWidget {
  const _MarkSparkle({
    required this.controllerValue,
    required this.size,
    required this.delay,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  final double controllerValue;
  final double size;
  final double delay;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  @override
  Widget build(BuildContext context) {
    final progress = ((controllerValue + delay) % 1.0);
    final glow = math.sin(progress * math.pi).clamp(0.0, 1.0);
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Opacity(
        opacity: 0.24 + (glow * 0.46),
        child: Transform.translate(
          offset: Offset(0, -5 * progress),
          child: Transform.scale(
            scale: 0.82 + (glow * 0.28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _AuthOnboardingScreenState._paleRose.withValues(
                  alpha: 0.88,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _AuthOnboardingScreenState._red.withValues(
                      alpha: 0.10,
                    ),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SizedBox(width: size, height: size),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroReveal extends StatefulWidget {
  const _IntroReveal({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_IntroReveal> createState() => _IntroRevealState();
}

class _IntroRevealState extends State<_IntroReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final totalMs = widget.delay.inMilliseconds + 520;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        widget.delay.inMilliseconds / totalMs,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - _animation.value)),
            child: Transform.scale(
              scale: 0.97 + (_animation.value * 0.03),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _MotionIn extends StatelessWidget {
  const _MotionIn({
    required this.child,
    this.offsetY = 0,
    this.initialScale = 1,
  });

  final Widget child;
  final double offsetY;
  final double initialScale;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final dy = offsetY * (1 - value);
        final scale = initialScale + ((1 - initialScale) * value);
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: child,
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: step.toDouble()),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return CustomPaint(
          size: const Size(184, 10),
          painter: _StepIndicatorPainter(progress: value),
        );
      },
    );
  }
}

class _StepIndicatorPainter extends CustomPainter {
  const _StepIndicatorPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const totalSteps = 5;
    const segmentWidth = 28.0;
    const dotWidth = 10.0;
    const gap = 8.0;
    const height = 9.0;

    final palePaint = Paint()
      ..color = _AuthOnboardingScreenState._paleRose.withValues(alpha: 0.62);
    final activePaint = Paint()..color = _AuthOnboardingScreenState._red;

    final totalWidth = (segmentWidth * totalSteps) + (gap * (totalSteps - 1));
    final startX = (size.width - totalWidth) / 2;
    final top = (size.height - height) / 2;

    for (var index = 0; index < totalSteps; index++) {
      final slotX = startX + (index * (segmentWidth + gap));
      final dotX = slotX + ((segmentWidth - dotWidth) / 2);
      final pale = RRect.fromRectAndRadius(
        Rect.fromLTWH(dotX, top, dotWidth, height),
        const Radius.circular(999),
      );
      canvas.drawRRect(pale, palePaint);

      final amount = (progress - index).clamp(0.0, 1.0);
      if (amount <= 0) continue;

      final activeWidth = dotWidth + ((segmentWidth - dotWidth) * amount);
      final activeX = dotX + ((slotX - dotX) * amount);
      final active = RRect.fromRectAndRadius(
        Rect.fromLTWH(activeX, top, activeWidth, height),
        const Radius.circular(999),
      );
      canvas.drawRRect(active, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StepIndicatorPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.label,
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.onChanged,
    this.maxWidth,
    this.showLabel = true,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final double? maxWidth;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[_FieldLabel(label), const SizedBox(height: 8)],
        _BigInput(
          controller: controller,
          hint: hint,
          autofocus: autofocus,
          onChanged: onChanged,
        ),
      ],
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: field,
      ),
    );
  }
}

class _BigInput extends StatelessWidget {
  const _BigInput({
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _AuthOnboardingScreenState._deepRed.withValues(
                alpha: 0.035,
              ),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          autofocus: autofocus,
          onChanged: onChanged,
          scrollPadding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom + 140,
          ),
          cursorColor: _AuthOnboardingScreenState._red,
          style: const TextStyle(
            fontFamily: AppTheme.sansFontFamily,
            color: _AuthOnboardingScreenState._deepRed,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: AppTheme.sansFontFamily,
              color: _AuthOnboardingScreenState._rose,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Container(
              width: 42,
              height: 42,
              margin: const EdgeInsets.fromLTRB(14, 18, 8, 18),
              decoration: BoxDecoration(
                color: _AuthOnboardingScreenState._paleRose.withValues(
                  alpha: 0.48,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: _AuthOnboardingScreenState._red,
                size: 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 68,
              minHeight: 78,
            ),
            filled: true,
            fillColor: AppTheme.surfaceColor.withValues(alpha: 0.96),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 21,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(
                color: _AuthOnboardingScreenState._paleRose.withValues(
                  alpha: 0.72,
                ),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(
                color: _AuthOnboardingScreenState._red.withValues(alpha: 0.32),
                width: 1.7,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconInputField extends StatelessWidget {
  const _IconInputField({
    required this.icon,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscure = false,
  });

  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        scrollPadding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom + 140,
        ),
        cursorColor: _AuthOnboardingScreenState._red,
        style: const TextStyle(
          fontFamily: AppTheme.sansFontFamily,
          color: _AuthOnboardingScreenState._deepRed,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: AppTheme.sansFontFamily,
            color: _AuthOnboardingScreenState._rose,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.fromLTRB(13, 14, 8, 14),
            decoration: BoxDecoration(
              color: _AuthOnboardingScreenState._paleRose.withValues(
                alpha: 0.42,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _AuthOnboardingScreenState._red, size: 18),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 56,
            minHeight: 62,
          ),
          filled: true,
          fillColor: AppTheme.surfaceColor.withValues(alpha: 0.96),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: _AuthOnboardingScreenState._paleRose.withValues(
                alpha: 0.48,
              ),
              width: 1.4,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: _AuthOnboardingScreenState._red.withValues(alpha: 0.32),
              width: 1.7,
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTheme.sansFontFamily,
          color: Color(0xFFD0A0AA),
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

class _PetChoice extends StatefulWidget {
  const _PetChoice({
    required this.label,
    required this.species,
    required this.color,
    required this.pattern,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final String species;
  final Color color;
  final String pattern;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_PetChoice> createState() => _PetChoiceState();
}

class _PetChoiceState extends State<_PetChoice> {
  void _handleTap() {
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.selected
        ? Colors.white
        : _AuthOnboardingScreenState._rose.withValues(alpha: 0.92);
    return Material(
      color: widget.selected
          ? _AuthOnboardingScreenState._red
          : Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: widget.compact ? 66 : 82,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: widget.selected
                ? null
                : Border.all(
                    color: _AuthOnboardingScreenState._paleRose.withValues(
                      alpha: 0.28,
                    ),
                    width: 1.2,
                  ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: _AuthOnboardingScreenState._red.withValues(
                        alpha: 0.12,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 9),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: _AuthOnboardingScreenState._deepRed.withValues(
                        alpha: 0.025,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: widget.compact ? 40 : 46,
                height: widget.compact ? 40 : 46,
                decoration: BoxDecoration(
                  color: widget.selected
                      ? Colors.white
                      : _AuthOnboardingScreenState._red.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                  boxShadow: widget.selected
                      ? [
                          BoxShadow(
                            color: _AuthOnboardingScreenState._deepRed
                                .withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: _ChoicePetHead(
                  species: widget.species,
                  color: widget.color,
                  pattern: widget.pattern,
                  selected: widget.selected,
                  size: widget.compact ? 44 : 50,
                ),
              ),
              SizedBox(width: widget.compact ? 10 : 14),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: AppTheme.sansFontFamily,
                  color: foreground,
                  fontSize: widget.compact ? 12 : 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoicePetHead extends StatefulWidget {
  const _ChoicePetHead({
    required this.species,
    required this.color,
    required this.pattern,
    required this.selected,
    required this.size,
  });

  final String species;
  final Color color;
  final String pattern;
  final bool selected;
  final double size;

  @override
  State<_ChoicePetHead> createState() => _ChoicePetHeadState();
}

class _ChoicePetHeadState extends State<_ChoicePetHead>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    if (widget.selected) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _ChoicePetHead oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.selected && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final phase = _controller.value * math.pi * 2;
        final selectedMotion = widget.selected ? 1.0 : 0.0;
        final bob = math.sin(phase) * 1.4 * selectedMotion;
        final tilt = math.sin(phase * 0.85) * 0.045 * selectedMotion;
        final scale = 1 + (math.sin(phase * 1.1) * 0.025 * selectedMotion);

        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.rotate(
            angle: tilt,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: IgnorePointer(
          child: PetAvatarWidget(
            species: widget.species,
            color: widget.color,
            headOnly: true,
            pattern: widget.pattern,
            eyeType: widget.selected ? 'default' : 'happy',
            mouthType: 'smile',
            equipped: const <String>[],
          ),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = label == 'Male' ? Icons.male_rounded : Icons.female_rounded;
    final foreground = selected
        ? Colors.white
        : _AuthOnboardingScreenState._rose.withValues(alpha: 0.92);
    return Material(
      color: selected ? _AuthOnboardingScreenState._red : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: selected
                ? null
                : Border.all(
                    color: _AuthOnboardingScreenState._paleRose.withValues(
                      alpha: 0.42,
                    ),
                    width: 1.4,
                  ),
            boxShadow: [
              BoxShadow(
                color:
                    (selected
                            ? _AuthOnboardingScreenState._red
                            : _AuthOnboardingScreenState._deepRed)
                        .withValues(alpha: selected ? 0.13 : 0.035),
                blurRadius: selected ? 16 : 12,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.sansFontFamily,
                  color: foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GatewayAuthField extends StatefulWidget {
  const _GatewayAuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onSubmitted,
    this.onChanged,
    this.hasError = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool hasError;

  @override
  State<_GatewayAuthField> createState() => _GatewayAuthFieldState();
}

class _GatewayAuthFieldState extends State<_GatewayAuthField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: TextField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        obscureText: _obscured,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        scrollPadding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom + 140,
        ),
        cursorColor: _AuthOnboardingScreenState._red,
        style: const TextStyle(
          fontFamily: AppTheme.sansFontFamily,
          color: _AuthOnboardingScreenState._deepRed,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            fontFamily: AppTheme.sansFontFamily,
            color: _AuthOnboardingScreenState._rose.withValues(alpha: 0.78),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.fromLTRB(13, 13, 8, 13),
            decoration: BoxDecoration(
              color: _AuthOnboardingScreenState._red.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              color: _AuthOnboardingScreenState._red,
              size: 18,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 62,
            minHeight: 62,
          ),
          suffixIcon: widget.obscureText
              ? Center(
                  widthFactor: 1,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _obscured = !_obscured),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: AnimatedSwitcher(
                        duration: AppTheme.motionFast,
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: CurvedAnimation(
                              parent: animation,
                              curve: AppTheme.motionCurveSoft,
                            ),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          _obscured
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          key: ValueKey(_obscured),
                          color: _AuthOnboardingScreenState._red.withValues(
                            alpha: 0.72,
                          ),
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 50,
            minHeight: 62,
          ),
          filled: true,
          fillColor: AppTheme.surfaceColor.withValues(alpha: 0.98),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: widget.hasError
                  ? AppTheme.dangerColor
                  : _AuthOnboardingScreenState._paleRose.withValues(
                      alpha: 0.62,
                    ),
              width: widget.hasError ? 1.7 : 1.4,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: widget.hasError
                  ? AppTheme.dangerColor
                  : _AuthOnboardingScreenState._red.withValues(alpha: 0.34),
              width: 1.7,
            ),
          ),
        ),
      ),
    );
  }
}

// Kept ready for the deferred Google Login scope; intentionally not rendered
// in Progress 2 builds.
// ignore: unused_element
class _GoogleButton extends StatelessWidget {
  // ignore: unused_element_parameter
  const _GoogleButton({required this.onTap, this.compact = false});

  static const _googleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#FFC107" d="M43.6 20.5H42V20H24v8h11.3C33.7 32.7 29.2 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.9 1.2 8 3.1l5.7-5.7C34.1 6.1 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20 20-8.9 20-20c0-1.3-.1-2.4-.4-3.5z"/>
  <path fill="#FF3D00" d="m6.3 14.7 6.6 4.8C14.7 15.1 19 12 24 12c3.1 0 5.9 1.2 8 3.1l5.7-5.7C34.1 6.1 29.3 4 24 4 16.3 4 9.6 8.3 6.3 14.7z"/>
  <path fill="#4CAF50" d="M24 44c5.2 0 9.9-2 13.4-5.2l-6.2-5.2C29.2 35.1 26.7 36 24 36c-5.2 0-9.6-3.3-11.3-7.9l-6.5 5C9.5 39.6 16.2 44 24 44z"/>
  <path fill="#1976D2" d="M43.6 20.5H42V20H24v8h11.3c-.8 2.3-2.3 4.2-4.1 5.6l6.2 5.2C36.9 39.3 44 34 44 24c0-1.3-.1-2.4-.4-3.5z"/>
</svg>
''';

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 56.0 : 64.0;
    final radius = compact ? 24.0 : 16.0;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: _AuthOnboardingScreenState._paleRose.withValues(
                alpha: 0.34,
              ),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: _AuthOnboardingScreenState._deepRed.withValues(
                  alpha: 0.06,
                ),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: compact ? 34 : 38,
                height: compact ? 34 : 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(compact ? 999 : 12),
                  border: Border.all(color: const Color(0xFFF2ECEA), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: _AuthOnboardingScreenState._deepRed.withValues(
                        alpha: 0.08,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.string(
                    _googleLogoSvg,
                    width: compact ? 20 : 23,
                    height: compact ? 20 : 23,
                  ),
                ),
              ),
              SizedBox(width: compact ? 10 : 18),
              Flexible(
                child: Text(
                  compact ? 'GOOGLE' : 'Continue with Google',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.sansFontFamily,
                    color: _AuthOnboardingScreenState._deepRed,
                    fontSize: compact ? 12 : 15,
                    letterSpacing: compact ? 1.2 : 0.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE9DAD5))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Text(
            'OR',
            style: TextStyle(
              fontFamily: AppTheme.sansFontFamily,
              color: _AuthOnboardingScreenState._paleRose.withValues(
                alpha: 0.95,
              ),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE9DAD5))),
      ],
    );
  }
}

class _ReferenceButton extends StatelessWidget {
  const _ReferenceButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.fullWidth = false,
    this.width,
    this.rounded = false,
    this.quiet = false,
    this.animatedIcon = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool fullWidth;
  final double? width;
  final bool rounded;
  final bool quiet;
  final bool animatedIcon;

  @override
  Widget build(BuildContext context) {
    final baseColor = quiet
        ? _AuthOnboardingScreenState._red.withValues(alpha: 0.9)
        : _AuthOnboardingScreenState._red;
    final color = onTap == null ? baseColor.withValues(alpha: 0.45) : baseColor;
    final radius = BorderRadius.circular(rounded ? 28 : (quiet ? 22 : 16));
    return SizedBox(
      width: width ?? (fullWidth ? double.infinity : null),
      child: Material(
        color: color,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            height: quiet ? 52 : (rounded ? 62 : 56),
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(
                    alpha: quiet ? 0.12 : (rounded ? 0.2 : 0.24),
                  ),
                  blurRadius: quiet ? 14 : (rounded ? 20 : 24),
                  offset: Offset(0, quiet ? 6 : 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.sansFontFamily,
                    color: Colors.white,
                    fontSize: rounded ? 14 : 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 12),
                  animatedIcon
                      ? _AnimatedButtonIcon(icon: icon!)
                      : Icon(icon, color: Colors.white, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedButtonIcon extends StatefulWidget {
  const _AnimatedButtonIcon({required this.icon});

  final IconData icon;

  @override
  State<_AnimatedButtonIcon> createState() => _AnimatedButtonIconState();
}

class _AnimatedButtonIconState extends State<_AnimatedButtonIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = Curves.easeInOutCubic.transform(_controller.value);
        return Transform.translate(
          offset: Offset(3.5 * value, 0),
          child: child,
        );
      },
      child: Icon(widget.icon, color: Colors.white, size: 20),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFAF3EF).withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _AuthOnboardingScreenState._deepRed.withValues(
                  alpha: 0.035,
                ),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.sansFontFamily,
              color: _AuthOnboardingScreenState._deepRed,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({
    required this.species,
    required this.color,
    required this.size,
  });

  final String species;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: PetAvatarWidget(species: species, color: color, isRotating: true),
    );
  }
}

class _PetNameStage extends StatefulWidget {
  const _PetNameStage({required this.species, required this.color});

  final String species;
  final Color color;

  @override
  State<_PetNameStage> createState() => _PetNameStageState();
}

class _PetNameStageState extends State<_PetNameStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 218,
      height: 176,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final wave = math.sin(_controller.value * math.pi * 2);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 22,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.color.withValues(alpha: 0.12),
                        _AuthOnboardingScreenState._cream.withValues(
                          alpha: 0.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 22 + wave * 2,
                left: 22,
                child: _NameStageDot(size: 9, color: widget.color),
              ),
              Positioned(
                top: 58 - wave * 1.6,
                right: 18,
                child: _NameStageDot(
                  size: 7,
                  color: _AuthOnboardingScreenState._rose,
                ),
              ),
              Positioned(
                top: 112 + wave,
                left: 30,
                child: _NameStageDot(size: 5, color: AppTheme.accentColor),
              ),
              Transform.translate(
                offset: Offset(0, wave * 3),
                child: _PetAvatar(
                  species: widget.species,
                  color: widget.color,
                  size: 156,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NameStageDot extends StatelessWidget {
  const _NameStageDot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ReferenceBackground extends StatelessWidget {
  const _ReferenceBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _AuthOnboardingScreenState._cream,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFC), Color(0xFFF6F4F1), Color(0xFFFAF7F1)],
        ),
      ),
      child: CustomPaint(painter: _ReferenceBackgroundPainter()),
    );
  }
}

class _ReferenceBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()
      ..color = _AuthOnboardingScreenState._red.withValues(alpha: 0.045);
    for (double y = 18; y < size.height; y += 32) {
      for (double x = 18; x < size.width; x += 32) {
        canvas.drawCircle(Offset(x, y), 2.1, dot);
      }
    }

    final primaryGlow = Paint()
      ..color = _AuthOnboardingScreenState._red.withValues(alpha: 0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.2),
      size.shortestSide * 0.30,
      primaryGlow,
    );

    final secondaryGlow = Paint()
      ..color = _AuthOnboardingScreenState._deepRed.withValues(alpha: 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 140);
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.82),
      size.shortestSide * 0.35,
      secondaryGlow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
