import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/assessment_entity.dart';
import '../controllers/health_assessment_controller.dart';
import '../../../../core/widgets/top_alert.dart';
import '../../../activity_tracking/presentation/controllers/activity_tracking_controller.dart';
import '../../../activity_tracking/presentation/screens/live_walk_screen.dart';
import '../../../missions/presentation/controllers/missions_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/auth_gate.dart';
import '../../../pet_management/data/repositories/pet_repository.dart';
import '../../../pet_management/domain/entities/pet_entity.dart';
import '../../../pet_management/presentation/screens/pet_form_screen.dart';
import '../../../activity_tracking/presentation/screens/wellness_tracking_view.dart';
import '../../../calendar/domain/calendar_event.dart';
import '../../../calendar/presentation/controllers/calendar_controller.dart';
import '../../../wardrobe/presentation/controllers/wardrobe_controller.dart';
import '../../../vet_consultation/presentation/screens/owner_consultation_screen.dart';
import '../../../health_history/health_history.dart';
import 'health_assessment_screen.dart';
import '../widgets/pet_avatar_widget.dart';
part 'home_calendar_screen_part.dart';
part 'home_consult_screen_part.dart';
part 'home_dashboard_screen_part.dart';
part 'home_history_screen_part.dart';
part 'home_profile_screen_part.dart';
part 'home_screen_modals_part.dart';
part 'home_screen_models_part.dart';
part 'home_screen_widgets_part.dart';
part 'home_wardrobe_screen_part.dart';
part 'home_wellness_screen_part.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialPet});

  final Pet? initialPet;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _View _activeView = _View.dashboard;
  int _activePetIndex = 0;
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  _VetFilter _vetFilter = _VetFilter.all;

  bool _showActionMenu = false;
  bool _showNavActionMenu = false;
  bool _showAssessment = false;
  String _assessmentModalTitle = 'Smart AI Scan';
  bool _showNotesModal = false;
  bool _showConfetti = false;
  int _confettiSeed = 0;
  Offset _confettiOrigin = const Offset(0, 0);
  String? _burstMissionId;
  _JourneyNodeData? _selectedNode;
  _VetData? _activeChatVet;

  final TextEditingController _chatMessageController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedSpecies = 'Cat';
  String _selectedColor = '#9F3E43';
  String _selectedEyeType = 'default';
  String _selectedMouthType = 'smile';
  String _selectedPattern = 'none';
  final Set<String> _draftEquippedAccessoryIds = {'acc_collar'};
  late final Map<int, _PetAppearanceData> _savedAppearances;
  late final Map<String, List<_VetChatMessageData>> _vetConversations;
  late final CalendarController _calendarController;
  late final WardrobeController _wardrobeController;
  final Map<int, Object?> _petProfileImages = {};

  static const List<_PetData> _mockPets = [
    _PetData(
      id: 1,
      name: 'Milo',
      species: 'Cat',
      breed: 'Scottish Fold',
      ageLabel: '2 Years Old',
      weightLabel: '4.5kg',
      status: 'Currently Resting',
    ),
    _PetData(
      id: 2,
      name: 'Buddy',
      species: 'Dog',
      breed: 'Golden Retriever',
      ageLabel: '4 Years Old',
      weightLabel: '18.2kg',
      status: 'Ready to Play',
    ),
  ];

  /// Pets shown in the dashboard. Authenticated users start empty (with
  /// [_petsLoading] true) until /users/{id}/pets resolves, so they never see
  /// the seed mock pets flash on top of their real data. Guest mode populates
  /// [_pets] with [_mockPets] in initState.
  List<_PetData> _pets = const [];

  /// True while the initial pet fetch is in-flight. Build shows a loading
  /// screen during this so we don't render the dashboard against an empty
  /// (or stale mock) pet list.
  bool _petsLoading = true;

  static const List<_NotificationData> _notifications = [
    _NotificationData(
      title: 'Daily mission',
      message: 'Water Log is ready for Milo.',
      time: 'Now',
      icon: Icons.flag_rounded,
      tint: AppTheme.primaryColor,
      unread: true,
    ),
    _NotificationData(
      title: 'Health reminder',
      message: 'Skin check follow-up in 2 days.',
      time: '10m',
      icon: Icons.favorite_rounded,
      tint: AppTheme.secondaryColor,
      unread: true,
    ),
    _NotificationData(
      title: 'Walk summary',
      message: 'Buddy completed a short walk.',
      time: '1h',
      icon: Icons.directions_walk_rounded,
      tint: AppTheme.accentColor,
    ),
  ];

  /// Seed events for the current month — shown until the user (a) loads their
  /// own persisted plans from SharedPreferences or (b) adds their first event.
  /// Built lazily because DateTime can't appear in a `const` expression.
  static List<CalendarEventData> _defaultCalendarEvents() {
    final now = DateTime.now();
    DateTime offsetFrom(int day, int hour, int minute) {
      // Anchor the demo events at "today + offset days" so they're always
      // visible relative to whatever month the user lands in.
      final base = DateTime(now.year, now.month, now.day, hour, minute);
      return base.add(Duration(days: day));
    }

    return [
      CalendarEventData(
        id: 'seed_med',
        title: 'Morning medication',
        timeLabel: '08:00 AM',
        type: 'medication',
        completed: false,
        date: offsetFrom(1, 8, 0),
        startsAt: offsetFrom(1, 8, 0),
        color: AppTheme.accentColor,
        icon: Icons.medication_rounded,
      ),
      CalendarEventData(
        id: 'seed_vet',
        title: 'Vet follow-up',
        timeLabel: '03:30 PM',
        type: 'vet',
        completed: false,
        date: offsetFrom(3, 15, 30),
        startsAt: offsetFrom(3, 15, 30),
        color: AppTheme.primaryColor,
        icon: Icons.medical_services_rounded,
      ),
      CalendarEventData(
        id: 'seed_groom',
        title: 'Grooming',
        timeLabel: '11:00 AM',
        type: 'grooming',
        completed: true,
        date: offsetFrom(6, 11, 0),
        startsAt: offsetFrom(6, 11, 0),
        color: AppTheme.secondaryColor,
        icon: Icons.content_cut_rounded,
      ),
      CalendarEventData(
        id: 'seed_walk',
        title: 'Outdoor walk',
        timeLabel: '06:00 PM',
        type: 'exercise',
        completed: false,
        date: offsetFrom(4, 18, 0),
        startsAt: offsetFrom(4, 18, 0),
        color: AppTheme.accentColor,
        icon: Icons.directions_walk_rounded,
      ),
    ];
  }

  static const List<_VetData> _vets = [
    _VetData(
      id: 'v1',
      name: 'Dr. Sarah',
      specialty: 'General Wellness',
      rating: '4.9',
      online: true,
    ),
    _VetData(
      id: 'v2',
      name: 'Dr. Mike',
      specialty: 'Diet Specialist',
      rating: '4.8',
      online: false,
    ),
    _VetData(
      id: 'v3',
      name: 'Dr. Emily',
      specialty: 'Behavioral',
      rating: '4.7',
      online: true,
    ),
  ];

  static const List<_HistoryData> _history = [
    _HistoryData(
      date: '15 MAY',
      title: 'Skin irritation review',
      result:
          'Monitor scratching and redness. Consider a consultation if symptoms persist for 48 hours.',
      urgency: 'Normal',
    ),
    _HistoryData(
      date: '10 MAY',
      title: 'Digestive discomfort',
      result:
          'Observation recommended. Maintain hydration and note any appetite changes.',
      urgency: 'Abnormal',
    ),
    _HistoryData(
      date: '04 MAY',
      title: 'Respiratory concern',
      result:
          'If breathing changes continue or worsen, consult a veterinarian immediately.',
      urgency: 'Critical',
    ),
  ];

  /// Every accessory the user can equip. The Golden Collar is a starter — all
  /// others are unlocked by completing the daily mission that maps to them in
  /// [_missionAccessoryMap]. The `unlocked` field here is the *default* state;
  /// runtime unlocks live in [_unlockedAccessoryIds] and the wardrobe reads
  /// availability via [_isAccessoryUnlocked].
  static const List<_AccessoryData> _accessories = [
    _AccessoryData(
      id: 'acc_collar',
      name: 'Golden Collar',
      emoji: '🎗️',
      unlocked: true,
    ),
    _AccessoryData(
      id: 'acc_hat',
      name: 'Cool Hat',
      emoji: '🎩',
      unlocked: false,
    ),
    _AccessoryData(
      id: 'acc_water_bowl',
      name: 'Crystal Bowl',
      emoji: '🥣',
      unlocked: false,
    ),
    _AccessoryData(
      id: 'acc_doctor_coat',
      name: 'Doctor Coat',
      emoji: '🩺',
      unlocked: false,
    ),
    _AccessoryData(
      id: 'acc_brush',
      name: 'Hair Brush',
      emoji: '🪮',
      unlocked: false,
    ),
    _AccessoryData(
      id: 'acc_ball',
      name: 'Toy Ball',
      emoji: '⚽',
      unlocked: false,
    ),
    _AccessoryData(
      id: 'acc_camera',
      name: 'Photo Frame',
      emoji: '📷',
      unlocked: false,
    ),
    _AccessoryData(
      id: 'acc_toothbrush',
      name: 'Pearl Toothbrush',
      emoji: '🦷',
      unlocked: false,
    ),
    _AccessoryData(
      id: 'acc_nail_file',
      name: 'Nail File',
      emoji: '💅',
      unlocked: false,
    ),
    _AccessoryData(
      id: 'acc_ear_tag',
      name: 'Ear Tag',
      emoji: '👂',
      unlocked: false,
    ),
    _AccessoryData(
      id: 'acc_scale',
      name: 'Scale Charm',
      emoji: '⚖️',
      unlocked: false,
    ),
    _AccessoryData(
      id: 'acc_heart',
      name: 'Heart Locket',
      emoji: '💖',
      unlocked: false,
    ),
    _AccessoryData(
      id: 'acc_diploma',
      name: 'Graduate Cap',
      emoji: '🎓',
      unlocked: false,
    ),
    _AccessoryData(
      id: 'acc_bowl',
      name: 'Premium Bowl',
      emoji: '🍽️',
      unlocked: false,
    ),
    _AccessoryData(
      id: 'acc_glasses',
      name: 'Funky Shades',
      emoji: '🕶️',
      unlocked: false,
    ),
    _AccessoryData(
      id: 'acc_friendship',
      name: 'Friendship Tag',
      emoji: '🤝',
      unlocked: false,
    ),
  ];

  /// Maps a backend mission_type to the cosmetic it grants on completion.
  /// Keep aligned with backend `_CORE_MISSIONS` + `_BONUS_MISSIONS` types.
  static const Map<String, String> _missionAccessoryMap = {
    'walk': 'acc_hat',
    'water': 'acc_water_bowl',
    'ai_check': 'acc_doctor_coat',
    'grooming': 'acc_brush',
    'play': 'acc_ball',
    'photo': 'acc_camera',
    'dental_check': 'acc_toothbrush',
    'nail_check': 'acc_nail_file',
    'ear_check': 'acc_ear_tag',
    'weight_log': 'acc_scale',
    'bonding': 'acc_heart',
    'training': 'acc_diploma',
    'feeding_check': 'acc_bowl',
    'eye_nose_check': 'acc_glasses',
    'social': 'acc_friendship',
  };

  /// Runtime unlock set across this app session. Seeded with the starter
  /// collar; missions add to this when completed.
  // TODO(persistence): hoist to backend/local storage so unlocks survive a
  // restart. For now they reset per session — fine for the MVP/demo flow.
  List<CalendarEventData> get _calendarEvents => _calendarController.events;

  /// Resolves the cosmetic reward for a backend mission type. Returns null
  /// when the mission type isn't mapped (caller falls back to the legacy
  /// "+X treats XP" badge).
  static _AccessoryData? _accessoryForMission(String missionType) {
    final id = _missionAccessoryMap[missionType];
    if (id == null) return null;
    for (final a in _accessories) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// True if the user has earned (or starts with) this accessory.
  bool _isAccessoryUnlocked(_AccessoryData accessory) {
    return accessory.unlocked || _wardrobeController.isUnlocked(accessory.id);
  }

  _PetData get _activePet => _pets[_activePetIndex];
  _PetAppearanceData get _activeAppearance =>
      _savedAppearances[_activePetIndex] ??
      _defaultAppearanceForSpecies(_activePet.species);

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController(
      seedEvents: _defaultCalendarEvents(),
    )..addListener(_onFeatureControllerChanged);
    _wardrobeController = WardrobeController()
      ..addListener(_onFeatureControllerChanged);
    _savedAppearances = {};
    // Vet conversations are seeded lazily in [_seedVetConversationsIfNeeded]
    // once pets have arrived — the seed text references _activePet.name and
    // would RangeError if built against the initially-empty _pets list.
    _vetConversations = {};
    // Make sure tomorrow's morning + tonight's evening mission reminders are
    // armed. Idempotent — overwrites existing schedules with the same id.
    NotificationService.instance.scheduleDailyMissionReminders();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      // Guest mode: no backend pets to fetch — fall back to the demo mock list
      // so the dashboard isn't empty.
      if (auth.isGuest || auth.userId == null) {
        setState(() {
          _pets = List<_PetData>.of(_mockPets);
          _savedAppearances.addAll({
            for (var i = 0; i < _pets.length; i++)
              i: _defaultAppearanceForSpecies(_pets[i].species),
          });
          _petsLoading = false;
        });
        _seedVetConversationsIfNeeded();
        _loadDraftForPet(_activePetIndex);
        _loadScopedHomeFeatureState();
        // Guest mode is local-only: the mission/stats endpoints now require a
        // Bearer token, so skip the backend loads — the controllers keep
        // their empty state and the demo pets stay purely cosmetic.
        return;
      }
      // Authenticated: wait for the real pet list before showing anything.
      _loadPets();
    });
  }

  /// Seeds the vet chat with intro messages once we know which pet is active.
  /// Safe to call multiple times — only seeds vets that aren't already keyed.
  void _seedVetConversationsIfNeeded() {
    if (_pets.isEmpty) return;
    for (final vet in _vets) {
      _vetConversations.putIfAbsent(vet.id, () => _seedVetConversation(vet));
    }
  }

  /// Loads the signed-in user's real pets from the backend. Authenticated users
  /// only — guest mode is handled inline in [initState].
  Future<void> _loadPets() async {
    final auth = context.read<AuthController>();
    final userId = auth.userId;
    if (userId == null || auth.isGuest) return;

    try {
      final pets = await PetRepository().getUserPets(userId);
      if (!mounted) return;
      final resolvedPets = pets.isEmpty && widget.initialPet != null
          ? [widget.initialPet!]
          : pets;

      setState(() {
        _pets = resolvedPets.map(_petDataFromBackend).toList();
        if (_activePetIndex >= _pets.length) _activePetIndex = 0;
        _savedAppearances
          ..clear()
          ..addAll({
            for (var i = 0; i < _pets.length; i++)
              i: _defaultAppearanceForSpecies(_pets[i].species),
          });
        _petsLoading = false;
      });

      // Empty list means "user has no pets" — show the empty-state CTA and
      // skip the per-pet wiring (would otherwise RangeError on _pets[0]).
      if (_pets.isEmpty) return;

      _seedVetConversationsIfNeeded();
      _loadDraftForPet(_activePetIndex);
      await _loadScopedHomeFeatureState();
      if (!mounted) return;

      // Re-key every pet-scoped feature to the user's REAL active pet. The
      // controllers skip loading until this runs — there is no seed-pet
      // fallback anymore (it used to leak one user's data to everyone).
      final activeId = _pets[_activePetIndex].id;
      await context.read<AuthController>().setPetId(activeId);
      if (!mounted) return;
      context.read<MissionsController>().loadAll(petId: activeId);
      context.read<ActivityTrackingController>().loadStats(petId: activeId);
      context.read<HealthAssessmentController>().loadPetHistory(activeId);
    } catch (e) {
      debugPrint('Failed to load pets: $e');
      if (mounted) {
        final fallbackPet = widget.initialPet;
        setState(() {
          _pets = fallbackPet == null ? [] : [_petDataFromBackend(fallbackPet)];
          _petsLoading = false;
        });
        if (fallbackPet != null) {
          _seedVetConversationsIfNeeded();
          _loadDraftForPet(_activePetIndex);
        }
      }
    }
  }

  _PetData _petDataFromBackend(Pet pet) {
    return _PetData(
      id: pet.id,
      name: pet.name,
      species: _displaySpecies(pet.species),
      breed: (pet.breed == null || pet.breed!.isEmpty) ? 'Unknown' : pet.breed!,
      ageLabel: _ageLabelFromDob(pet.dateOfBirth),
      weightLabel: pet.weightKg == null ? '—' : '${pet.weightKg}kg',
      status: 'Currently Resting',
      gender: pet.gender,
      dateOfBirth: pet.dateOfBirth,
      weightKg: pet.weightKg,
      bloodType: pet.bloodType,
      avatarUri: pet.avatarUri,
    );
  }

  _PetData _petDataFromEntity(PetEntity pet) {
    final species = _displaySpecies(pet.species ?? _activePet.species);
    return _PetData(
      id: pet.id ?? _activePet.id,
      name: pet.name,
      species: species,
      breed: (pet.breed == null || pet.breed!.isEmpty) ? 'Unknown' : pet.breed!,
      ageLabel: _ageLabelFromDob(pet.dateOfBirth),
      weightLabel: pet.weightKg == null ? '—' : '${pet.weightKg}kg',
      status: _activePet.status,
      gender: pet.gender,
      dateOfBirth: pet.dateOfBirth,
      weightKg: pet.weightKg,
      bloodType: pet.bloodType,
      avatarUri: pet.avatarUri,
    );
  }

  PetEntity _petEntityFromData(_PetData pet) {
    return PetEntity(
      id: pet.id,
      name: pet.name,
      species: pet.species.toLowerCase(),
      breed: pet.breed == 'Unknown' ? null : pet.breed,
      gender: pet.gender,
      dateOfBirth: pet.dateOfBirth,
      weightKg: pet.weightKg,
      bloodType: pet.bloodType,
      avatarUri: pet.avatarUri,
    );
  }

  String _displaySpecies(String? species) {
    return species?.toLowerCase() == 'dog' ? 'Dog' : 'Cat';
  }

  Future<void> _editActivePet() async {
    final index = _activePetIndex;
    final initial = _petEntityFromData(_activePet);
    final result = await Navigator.of(context).push<PetEntity>(
      MaterialPageRoute(builder: (_) => PetFormScreen(initial: initial)),
    );
    if (result == null || !mounted) return;

    _update(() {
      _pets[index] = _petDataFromEntity(result);
      _savedAppearances[index] = _defaultAppearanceForSpecies(
        result.species ?? _pets[index].species,
      );
    });

    final token = context.read<AuthController>().token;
    if (token == null || result.id == null) return;

    try {
      final updated = await PetRepository().updatePet(
        token: token,
        petId: result.id!,
        name: result.name,
        species: result.species,
        breed: result.breed,
        gender: result.gender,
        dateOfBirth: result.dateOfBirth,
        weightKg: result.weightKg,
        bloodType: result.bloodType,
      );
      if (!mounted) return;
      _update(() {
        _pets[index] = _petDataFromBackend(updated);
      });
    } catch (_) {
      if (!mounted) return;
      showTopAlert(
        context,
        'Profile updated on this device. Server sync failed.',
        icon: Icons.info_outline_rounded,
      );
    }
  }

  String _ageLabelFromDob(DateTime? dob) {
    if (dob == null) return '—';
    final now = DateTime.now();
    var years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years -= 1;
    }
    if (years <= 0) {
      final months = (now.year - dob.year) * 12 + now.month - dob.month;
      return '${months <= 0 ? 1 : months} Months Old';
    }
    return '$years Year${years == 1 ? '' : 's'} Old';
  }

  /// Opens the pet form, creates the pet via the backend, then refreshes Home.
  Future<void> _addPet() async {
    final messenger = ScaffoldMessenger.of(context);
    final token = context.read<AuthController>().token;
    if (token == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please log in to add a pet.')),
      );
      return;
    }
    final result = await Navigator.of(
      context,
    ).push<PetEntity>(MaterialPageRoute(builder: (_) => const PetFormScreen()));
    if (result == null || !mounted) return;
    try {
      await PetRepository().createPet(
        token: token,
        name: result.name,
        species: result.species,
        breed: result.breed,
        gender: result.gender,
        dateOfBirth: result.dateOfBirth,
        weightKg: result.weightKg,
        bloodType: result.bloodType,
      );
      if (!mounted) return;
      await _loadPets();
      messenger.showSnackBar(SnackBar(content: Text('${result.name} added!')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to add pet: $e')));
    }
  }

  @override
  void dispose() {
    _calendarController
      ..removeListener(_onFeatureControllerChanged)
      ..dispose();
    _wardrobeController
      ..removeListener(_onFeatureControllerChanged)
      ..dispose();
    _chatMessageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _update(VoidCallback action) => setState(action);

  void _onFeatureControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadScopedHomeFeatureState() async {
    if (_pets.isEmpty) return;
    final auth = context.read<AuthController>();
    final petId = _activePet.id;
    await Future.wait([
      _calendarController.load(userId: auth.userId, petId: petId),
      _wardrobeController.load(userId: auth.userId, petId: petId),
    ]);
    if (!mounted) return;
    _loadDraftForPet(_activePetIndex);

    for (final event in _calendarEvents) {
      if (event.startsAt != null && event.startsAt!.isAfter(DateTime.now())) {
        NotificationService.instance.scheduleEventReminder(
          eventId: event.id,
          when: event.startsAt!,
          title: event.title,
          body: 'Upcoming for ${_activePet.name}',
        );
      }
    }
  }

  List<_VetChatMessageData> _seedVetConversation(_VetData vet) {
    return [
      _VetChatMessageData(
        fromVet: true,
        timeLabel: '09:12',
        text:
            'Hi, I\'m ${vet.name}. You can send ${_activePet.name}\'s profile, AI health check, or recent records here anytime.',
      ),
      _VetChatMessageData(
        fromVet: false,
        timeLabel: '09:14',
        text:
            'I\'d like help reviewing ${_activePet.name}\'s recent health updates.',
      ),
    ];
  }

  List<_VetChatMessageData> _conversationForVet(String vetId) {
    return _vetConversations.putIfAbsent(vetId, () => <_VetChatMessageData>[]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    // Block the dashboard until the user's pets land. Otherwise a fresh login
    // would briefly render mock pets / blow up on _pets[0] before _loadPets
    // returns.
    if (_petsLoading) return _buildLoadingState(context);
    // Authenticated user resolved with no pets → show the "add your first pet"
    // empty state instead of trying to render the dashboard.
    if (!auth.isGuest && auth.userId != null && _pets.isEmpty) {
      return _buildEmptyState(context);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: Stack(
          children: [
            _BackgroundDecor(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                    child: _buildHeader(context),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: AppTheme.motionFast,
                      reverseDuration: AppTheme.motionFast,
                      switchInCurve: AppTheme.motionCurveSoft,
                      switchOutCurve: AppTheme.motionReverseCurve,
                      transitionBuilder: (child, animation) {
                        final curved = CurvedAnimation(
                          parent: animation,
                          curve: AppTheme.motionCurveSoft,
                          reverseCurve: AppTheme.motionReverseCurve,
                        );
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.002),
                            end: Offset.zero,
                          ).animate(curved),
                          child: child,
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(_activeView),
                        child: _buildCurrentView(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildDockedNav(context),
            ),
            if (_showAssessment) _buildAssessmentModal(context),
            if (_activeChatVet != null) _buildVetChatModal(context),
            if (_showNotesModal) _buildNotesModal(context),
            if (_selectedNode != null) _buildJourneyDetailModal(context),
            if (_showConfetti)
              _ConfettiOverlay(
                key: ValueKey(_confettiSeed),
                origin: _confettiOrigin,
                seed: _confettiSeed,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PETTO',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontSize: 28),
                ),
                Text(
                  'Healthy & Happy',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        _buildNotificationButton(context),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    final unreadCount = _notifications.where((item) => item.unread).length;
    return InkWell(
      onTap: () {
        setState(() {
          _activeView = _View.notifications;
          _showActionMenu = false;
          _showNavActionMenu = false;
        });
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: AppTheme.motionFast,
        curve: AppTheme.motionCurve,
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor.withValues(alpha: 0.96),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.primaryColor.withValues(
              alpha: _activeView == _View.notifications ? 0.22 : 0.10,
            ),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: AnimatedContainer(
                duration: AppTheme.motionFast,
                curve: AppTheme.motionCurve,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _activeView == _View.notifications
                      ? AppTheme.blushSurfaceColor.withValues(alpha: 0.78)
                      : AppTheme.creamSurfaceColor.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _activeView == _View.notifications
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$unreadCount',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockedNav(BuildContext context) {
    final leftItems = [
      _DockNavItemData(
        view: _View.dashboard,
        icon: Icons.cottage_rounded,
        label: 'Home',
      ),
      _DockNavItemData(
        view: _View.missions,
        icon: Icons.emoji_events_rounded,
        label: 'Mission',
      ),
    ];
    final rightItems = [
      _DockNavItemData(
        view: _View.consult,
        icon: Icons.medical_services_rounded,
        label: 'Assistant',
      ),
      _DockNavItemData(
        view: _View.profile,
        icon: Icons.account_circle_rounded,
        label: 'Profile',
      ),
    ];

    void selectView(_View view) {
      setState(() {
        _activeView = view;
        _showNavActionMenu = false;
        _showActionMenu = false;
      });
    }

    void openAssessment(String title) {
      setState(() {
        _showNavActionMenu = false;
        _showActionMenu = false;
        _assessmentModalTitle = title;
        _showAssessment = true;
      });
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final dockHeight = 82.0 + bottomInset;
    const centerGap = 86.0;

    return SizedBox(
      height: dockHeight + 112,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 22,
            right: 22,
            bottom: dockHeight + 12,
            child: IgnorePointer(
              ignoring: !_showNavActionMenu,
              child: AnimatedOpacity(
                duration: AppTheme.motionFast,
                opacity: _showNavActionMenu ? 1 : 0,
                child: AnimatedSlide(
                  duration: AppTheme.motionNormal,
                  curve: AppTheme.motionCurveSoft,
                  offset: _showNavActionMenu
                      ? Offset.zero
                      : const Offset(0, 0.08),
                  child: Row(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: _NavActionBubble(
                                width: math.min(164, constraints.maxWidth),
                                icon: Icons.auto_awesome_rounded,
                                label: 'Smart AI Scan',
                                color: AppTheme.secondaryColor,
                                onTap: () => openAssessment('Smart AI Scan'),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 82),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: _NavActionBubble(
                                width: math.min(164, constraints.maxWidth),
                                icon: Icons.photo_camera_back_rounded,
                                label: 'Photo Analyze',
                                color: AppTheme.primaryColor,
                                onTap: () => openAssessment('Photo Analyze'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: dockHeight,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.26),
                  blurRadius: 22,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
          ),
          ClipPath(
            clipper: const _DockNotchClipper(),
            child: Container(
              height: dockHeight,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1.1,
                ),
              ),
            ),
          ),
          Container(
            height: dockHeight,
            padding: EdgeInsets.fromLTRB(16, 8, 16, 10 + bottomInset),
            child: Row(
              children: [
                for (final item in leftItems)
                  Expanded(
                    child: _DockNavItem(
                      item: item,
                      selected: _activeView == item.view,
                      onTap: () => selectView(item.view),
                    ),
                  ),
                const SizedBox(width: centerGap),
                for (final item in rightItems)
                  Expanded(
                    child: _DockNavItem(
                      item: item,
                      selected: _activeView == item.view,
                      onTap: () => selectView(item.view),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 48 + bottomInset,
            child: _DockCenterButton(
              expanded: _showNavActionMenu,
              onTap: () {
                setState(() {
                  _showNavActionMenu = !_showNavActionMenu;
                  _showActionMenu = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView(BuildContext context) {
    switch (_activeView) {
      case _View.dashboard:
        return _buildDashboardView(context);
      case _View.missions:
        return _buildMissionsView(context);
      case _View.calendar:
        return _buildCalendarView(context);
      case _View.wellness:
        return _buildWellnessView(context);
      case _View.consult:
        return _buildConsultView(context);
      case _View.notifications:
        return _buildNotificationsView(context);
      case _View.profile:
        return _buildProfileView(context);
      case _View.wardrobe:
        return _buildWardrobeView(context);
      case _View.history:
        return _buildHistoryView(context);
    }
  }

  Widget _buildNotificationsView(BuildContext context) {
    final unreadCount = _notifications.where((item) => item.unread).length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SoftReveal(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.glassCardDecoration(
                color: AppTheme.surfaceColor.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(32),
                borderColor: AppTheme.primaryColor.withValues(alpha: 0.12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notice',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$unreadCount new updates for ${_activePet.name}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.mutedText),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.blushSurfaceColor.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$unreadCount new',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 5,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Recent Notices',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in _notifications.indexed) ...[
            _SoftReveal(
              delay: 0.08 + (entry.$1 * 0.05),
              child: _NotificationTile(item: entry.$2, large: true),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  void _showPreviewSnackBar(String label) {
    showTopAlert(context, '$label is shown as UI-only preview.');
  }

  _PetAppearanceData _defaultAppearanceForSpecies(String species) {
    return species.toLowerCase() == 'dog'
        ? const _PetAppearanceData(
            species: 'Dog',
            colorHex: '#D88F62',
            eyeType: 'default',
            mouthType: 'smile',
            pattern: 'none',
            equipped: {'acc_collar'},
          )
        : const _PetAppearanceData(
            species: 'Cat',
            colorHex: '#D87986',
            eyeType: 'default',
            mouthType: 'smile',
            pattern: 'none',
            equipped: {'acc_collar'},
          );
  }

  Color _colorFromHex(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  /// Splash shown while the user's pets are still loading. Matches the
  /// dashboard background so the transition feels seamless.
  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: const SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading your pets...',
                  style: TextStyle(
                    fontFamily: AppTheme.sansFontFamily,
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Empty state screen when authenticated user has no pets yet.
  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pet illustration
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No pets yet',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add your first pet to get started with health tracking, daily missions, and more!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _addPet,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Your First Pet'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(
                        context,
                        rootNavigator: true,
                      );
                      await context.read<AuthController>().logout();
                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthGate()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log out'),
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
