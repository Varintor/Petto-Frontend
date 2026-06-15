import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/assessment_entity.dart';
import '../controllers/health_assessment_controller.dart';
import '../../../activity_tracking/presentation/controllers/activity_tracking_controller.dart';
import '../../../activity_tracking/presentation/screens/live_walk_screen.dart';
import '../../../missions/presentation/controllers/missions_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../activity_tracking/presentation/screens/wellness_tracking_view.dart';
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
  const HomeScreen({super.key});

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
  final Map<int, Object?> _petProfileImages = {};

  static const List<_PetData> _pets = [
    _PetData(
      name: 'Milo',
      species: 'Cat',
      breed: 'Scottish Fold',
      ageLabel: '2 Years Old',
      weightLabel: '4.5kg',
      status: 'Currently Resting',
    ),
    _PetData(
      name: 'Buddy',
      species: 'Dog',
      breed: 'Golden Retriever',
      ageLabel: '4 Years Old',
      weightLabel: '18.2kg',
      status: 'Ready to Play',
    ),
  ];

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

  static const List<_CalendarEventData> _calendarEvents = [
    _CalendarEventData(
      id: 'e1',
      title: 'Morning medication',
      timeLabel: '08:00 AM',
      type: 'medication',
      completed: false,
      day: 19,
      color: AppTheme.accentColor,
      icon: Icons.medication_rounded,
    ),
    _CalendarEventData(
      id: 'e2',
      title: 'Vet follow-up',
      timeLabel: '03:30 PM',
      type: 'vet',
      completed: false,
      day: 21,
      color: AppTheme.primaryColor,
      icon: Icons.medical_services_rounded,
    ),
    _CalendarEventData(
      id: 'e3',
      title: 'Grooming',
      timeLabel: '11:00 AM',
      type: 'grooming',
      completed: true,
      day: 25,
      color: AppTheme.secondaryColor,
      icon: Icons.content_cut_rounded,
    ),
    _CalendarEventData(
      id: 'e4',
      title: 'Outdoor walk',
      timeLabel: '06:00 PM',
      type: 'exercise',
      completed: false,
      day: 22,
      color: AppTheme.accentColor,
      icon: Icons.directions_walk_rounded,
    ),
  ];

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

  static const List<_AccessoryData> _accessories = [
    _AccessoryData(
      id: 'acc_hat',
      name: 'Cool Hat',
      emoji: '🎩',
      unlocked: true,
    ),
    _AccessoryData(
      id: 'acc_collar',
      name: 'Golden Collar',
      emoji: '🎗️',
      unlocked: true,
    ),
    _AccessoryData(
      id: 'acc_glasses',
      name: 'Funky Shades',
      emoji: '🕶️',
      unlocked: false,
    ),
  ];

  _PetData get _activePet => _pets[_activePetIndex];
  _PetAppearanceData get _activeAppearance =>
      _savedAppearances[_activePetIndex] ??
      _defaultAppearanceForSpecies(_activePet.species);

  @override
  void initState() {
    super.initState();
    _savedAppearances = {
      for (var i = 0; i < _pets.length; i++)
        i: _defaultAppearanceForSpecies(_pets[i].species),
    };
    _vetConversations = {
      for (final vet in _vets) vet.id: _seedVetConversation(vet),
    };
    _loadDraftForPet(_activePetIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ActivityTrackingController>().loadStats();
      context.read<MissionsController>().loadAll();
    });
  }

  @override
  void dispose() {
    _chatMessageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _update(VoidCallback action) => setState(action);

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
    return Scaffold(
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
                      duration: const Duration(milliseconds: 320),
                      reverseDuration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final curved = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                          reverseCurve: Curves.easeInCubic,
                        );
                        return FadeTransition(
                          opacity: curved,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.018),
                              end: Offset.zero,
                            ).animate(curved),
                            child: ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.992,
                                end: 1,
                              ).animate(curved),
                              child: child,
                            ),
                          ),
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
        duration: const Duration(milliseconds: 180),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
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
                duration: const Duration(milliseconds: 180),
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
                duration: const Duration(milliseconds: 180),
                opacity: _showNavActionMenu ? 1 : 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  offset: _showNavActionMenu
                      ? Offset.zero
                      : const Offset(0, 0.12),
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
                  color: AppTheme.secondaryText.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
          ),
          ClipPath(
            clipper: const _DockNotchClipper(),
            child: Container(
              height: dockHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.10),
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
                color: Colors.white.withValues(alpha: 0.97),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is shown as UI-only preview.')),
    );
  }

  _PetAppearanceData _defaultAppearanceForSpecies(String species) {
    return species.toLowerCase() == 'dog'
        ? const _PetAppearanceData(
            species: 'Dog',
            colorHex: '#C47A45',
            eyeType: 'default',
            mouthType: 'smile',
            pattern: 'none',
            equipped: {'acc_collar'},
          )
        : const _PetAppearanceData(
            species: 'Cat',
            colorHex: '#9F3E43',
            eyeType: 'default',
            mouthType: 'smile',
            pattern: 'none',
            equipped: {'acc_collar'},
          );
  }

  Color _colorFromHex(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
}
