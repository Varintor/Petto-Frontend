part of 'home_screen.dart';

const _homeCreamSurface = Color(0xFFFFFAF5);
const _homeRoseSurface = Color(0xFFF6E4E2);
const _homeSageSurface = Color(0xFFEEF0E5);
const _homeSageAccent = Color(0xFF6F7E5A);
const _homeGoldAccent = Color(0xFFB18636);

extension _HomeDashboardScreenPart on _HomeScreenState {
  Future<void> _triggerMission(int missionId, Offset origin) async {
    final controller = context.read<MissionsController>();
    if (controller.isMissionCompleted(missionId)) return;
    // Look up the mission so we know which cosmetic to unlock.
    final mission = controller.missions.firstWhere(
      (m) => m.id == missionId,
      orElse: () => controller.missions.first,
    );
    _update(() {
      _showConfetti = true;
      _confettiOrigin = origin;
      _confettiSeed++;
      _burstMissionId = missionId.toString();
    });
    Timer(const Duration(milliseconds: 950), () {
      if (!mounted) return;
      _update(() {
        _showConfetti = false;
        _burstMissionId = null;
      });
    });

    // Grant the wardrobe reward only after the backend confirms completion —
    // if the PUT fails the mission stays open and no accessory is unlocked
    // (UD-09 E1). Persisted so the cosmetic survives app restarts (URS-F4-03).
    await controller.completeMission(missionId);
    if (!mounted || !controller.isMissionCompleted(missionId)) return;

    final reward = _HomeScreenState._accessoryForMission(mission.missionType);
    if (reward != null && await _wardrobeController.unlock(reward.id)) {
      if (!mounted) return;
      showTopAlert(
        context,
        'Unlocked ${reward.emoji} ${reward.name}!',
        icon: Icons.celebration_rounded,
      );
    }
  }

  Future<void> _selectPet(int index) async {
    if (index < 0 || index >= _pets.length || index == _activePetIndex) return;
    _update(() {
      _activePetIndex = index;
      _loadDraftForPet(index);
    });

    // Sync petId with AuthController for other features (health assessment, etc.)
    final selectedPet = _pets[index];
    await context.read<AuthController>().setPetId(selectedPet.id);
    if (!mounted) return;
    await _loadScopedHomeFeatureState();
    if (!mounted) return;

    // Reload health assessment history for the newly selected pet
    context.read<HealthAssessmentController>().loadPetHistory(selectedPet.id);

    // Reload missions and stats for the newly selected pet
    context.read<MissionsController>().loadAll(petId: selectedPet.id);
    context.read<ActivityTrackingController>().loadStats(petId: selectedPet.id);
  }

  Widget _buildDashboardView(BuildContext context) {
    return Consumer<MissionsController>(
      builder: (context, mc, _) {
        final missions = mc.missions;
        final now = DateTime.now();
        final upcomingPlans =
            (_calendarEvents.where((event) {
              final occurrence = event.startsAt ?? event.date;
              return !event.completed && !occurrence.isBefore(now);
            }).toList()..sort((a, b) {
              final aTime = a.startsAt ?? a.date;
              final bTime = b.startsAt ?? b.date;
              return aTime.compareTo(bTime);
            }));
        final nextPlan = upcomingPlans.isEmpty ? null : upcomingPlans.first;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 148),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeWeatherGardenHero(
                pet: _activePet,
                appearance: _activeAppearance,
                petColor: _colorFromHex(_activeAppearance.colorHex),
              ),
              Transform.translate(
                offset: const Offset(0, -18),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(painter: _HomeContentDotPainter()),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HomePetSwitcher(
                              pets: _pets,
                              appearances: [
                                for (
                                  var index = 0;
                                  index < _pets.length;
                                  index++
                                )
                                  _savedAppearances[index] ??
                                      _defaultAppearanceForSpecies(
                                        _pets[index].species,
                                      ),
                              ],
                              activeIndex: _activePetIndex,
                              onSelect: _selectPet,
                              onAdd: _addPet,
                            ),
                            const SizedBox(height: 18),
                            _HomeTodayOverview(
                              pet: _activePet,
                              nextPlan: nextPlan,
                              completedMissions: mc.completedCount,
                              totalMissions: mc.totalCount,
                            ),
                            const SizedBox(height: 24),
                            _HomeSectionTitle(title: 'Shortcuts'),
                            const SizedBox(height: 14),
                            _HomeQuickCareMenu(
                              onTapCalendar: () =>
                                  _update(() => _activeView = _View.calendar),
                              onTapAssessment: () {
                                _update(() {
                                  _assessmentModalTitle = 'Smart AI Scan';
                                  _showAssessment = true;
                                });
                              },
                              onTapAssistant: () =>
                                  _update(() => _activeView = _View.consult),
                              onTapWardrobe: () => _update(_openWardrobe),
                              onTapHistory: () =>
                                  _update(() => _activeView = _View.history),
                            ),
                            const SizedBox(height: 26),
                            _buildHomeCalendarSection(context),
                            const SizedBox(height: 26),
                            _HomeMissionBoard(
                              petName: _activePet.name,
                              completed: mc.completedCount,
                              total: mc.totalCount,
                              loading: mc.missionsLoading && missions.isEmpty,
                              missions: missions,
                              burstMissionId: _burstMissionId,
                              onOpen: () =>
                                  _update(() => _activeView = _View.missions),
                              onMissionTap: _triggerMission,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMissionsView(BuildContext context) {
    return Consumer<MissionsController>(
      builder: (context, mc, _) {
        final completedCount = mc.completedCount;
        final totalCount = mc.totalCount;
        final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;
        final missions = mc.missions;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.10),
                      blurRadius: 22,
                      spreadRadius: -12,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: const _SoftPulse(
                            child: Icon(
                              Icons.flag_rounded,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Mission',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Small care goals for ${_activePet.name}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text(
                            '$completedCount/$totalCount',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 720),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.20,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.blushSurfaceColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _buildMissionActivityPanel(context),
              const SizedBox(height: 24),
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
                      "Today's Missions",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.secondaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1E2E0),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '$completedCount/$totalCount done',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF8E555A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (mc.missionsLoading && missions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      PettoCardSkeleton(height: 92, compact: true),
                      SizedBox(height: 10),
                      PettoCardSkeleton(height: 92, compact: true),
                    ],
                  ),
                )
              else
                for (final mission in missions) ...[
                  _HomeMissionLine(
                    mission: mission,
                    bursting: _burstMissionId == mission.id.toString(),
                    onTap: (origin) => _triggerMission(mission.id, origin),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMissionActivityPanel(BuildContext context) {
    int? activePetId() {
      final auth = context.read<AuthController>();
      // Guests use the seed pet (their only pet); signed-in users must have
      // their own real pet — never fall back to the seed pet, or stats from
      // pet #1 leak into every empty account.
      return auth.isGuest ? auth.petId : auth.rawPetId;
    }

    void startWalk() {
      final controller = context.read<ActivityTrackingController>();
      final petId = activePetId();
      Navigator.of(context)
          .push(
            PettoPageRoute(
              builder: (_) => LiveWalkScreen(petName: _activePet.name),
            ),
          )
          .then((_) {
            if (petId == null) return;
            controller.loadStats(petId: petId);
          });
    }

    return Consumer<ActivityTrackingController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    'Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.secondaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                InkWell(
                  onTap: controller.statsLoading
                      ? null
                      : () {
                          final petId = activePetId();
                          if (petId == null) return;
                          controller.loadStats(petId: petId);
                        },
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: controller.statsLoading
                          ? AppTheme.mutedText.withValues(alpha: 0.16)
                          : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      controller.statsLoading ? 'Loading' : 'Refresh',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: BoxDecoration(
                color: _homeCreamSurface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    blurRadius: 22,
                    spreadRadius: -14,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.directions_walk_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Walk Summary',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.14,
                            ),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'Today',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _ActivityStatTile(
                        value: stats.distanceText,
                        label: 'Total distance',
                      ),
                      _ActivityDivider(),
                      _ActivityStatTile(
                        value: stats.durationText,
                        label: 'Total time',
                      ),
                      _ActivityDivider(),
                      _ActivityStatTile(
                        value: '${stats.totalActivities}',
                        label: 'Sessions',
                      ),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: controller.statsLoading
                        ? Padding(
                            key: const ValueKey('activity_loading'),
                            padding: const EdgeInsets.only(top: 14),
                            child: const PettoSkeletonBox(
                              height: 6,
                              radius: 999,
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('activity_loaded'),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _MissionActivityCard(
              icon: Icons.directions_walk_rounded,
              iconColor: AppTheme.primaryColor,
              surfaceColor: _homeCreamSurface,
              title: 'Start a Walk',
              subtitle:
                  'Live GPS tracking - distance, time and pace for ${_activePet.name}.',
              actionLabel: 'Start',
              onTap: startWalk,
            ),
            const SizedBox(height: 12),
            _MissionActivityCard(
              icon: Icons.sensors_rounded,
              iconColor: AppTheme.primaryColor,
              surfaceColor: _homeCreamSurface,
              title: 'Live Pet Tracking',
              subtitle:
                  'Pair a device for activity, rest detection and alerts.',
              actionLabel: 'Open',
              onTap: () => _update(() => _activeView = _View.wellness),
            ),
          ],
        );
      },
    );
  }
}

class _HomeContentDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.045);
    const gap = 34.0;
    for (double y = 16; y < size.height + gap; y += gap) {
      for (double x = 16; x < size.width + gap; x += gap) {
        canvas.drawCircle(Offset(x, y), 2.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomePetSwitcher extends StatelessWidget {
  const _HomePetSwitcher({
    required this.pets,
    required this.appearances,
    required this.activeIndex,
    required this.onSelect,
    required this.onAdd,
  });

  final List<_PetData> pets;
  final List<_PetAppearanceData> appearances;
  final int activeIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: pets.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == pets.length) {
            return _AddPetChip(onTap: onAdd);
          }
          final pet = pets[index];
          final appearance = appearances[index];
          return _HomePetSwitcherItem.pet(
            pet: pet,
            appearance: appearance,
            selected: index == activeIndex,
            onTap: () => onSelect(index),
          );
        },
      ),
    );
  }
}

class _HomePetSwitcherItem extends StatelessWidget {
  const _HomePetSwitcherItem.pet({
    required this.pet,
    required this.appearance,
    required this.selected,
    required this.onTap,
  });

  final _PetData pet;
  final _PetAppearanceData appearance;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PetChip(
      pet: pet,
      appearance: appearance,
      selected: selected,
      onTap: onTap,
    );
  }
}

enum _GardenWeather { clear, cloudy, rainy, stormy }

class _HomeWeatherGardenHero extends StatefulWidget {
  const _HomeWeatherGardenHero({
    required this.pet,
    required this.appearance,
    required this.petColor,
  });

  final _PetData pet;
  final _PetAppearanceData appearance;
  final Color petColor;

  @override
  State<_HomeWeatherGardenHero> createState() => _HomeWeatherGardenHeroState();
}

class _HomeWeatherGardenHeroState extends State<_HomeWeatherGardenHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();
  bool _checkingLocation = false;
  WeatherSnapshot? _weatherSnapshot;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6200),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _useLocationWeather();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _useLocationWeather() async {
    if (_checkingLocation) return;
    setState(() => _checkingLocation = true);

    final readiness = await _locationService.ensureReady();
    if (!mounted) return;
    if (readiness != LocationReadiness.ready) {
      setState(() {
        _checkingLocation = false;
      });
      return;
    }

    final position = await _locationService.currentPosition();
    if (!mounted) return;
    if (position == null) {
      setState(() {
        _checkingLocation = false;
      });
      return;
    }

    final weather = await _weatherService.currentWeather(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (!mounted) return;
    setState(() {
      _checkingLocation = false;
      _weatherSnapshot = weather;
    });
  }

  _GardenWeather _gardenWeather(DateTime now) {
    return switch (_weatherSnapshot?.kind) {
      WeatherKind.clear => _GardenWeather.clear,
      WeatherKind.cloudy => _GardenWeather.cloudy,
      WeatherKind.rainy => _GardenWeather.rainy,
      WeatherKind.stormy => _GardenWeather.stormy,
      null =>
        now.hour < 6 || now.hour >= 18
            ? _GardenWeather.cloudy
            : _GardenWeather.clear,
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final height = (constraints.maxWidth * 0.54).clamp(270.0, 340.0);
        final now = DateTime.now();
        final isNight =
            _weatherSnapshot?.isDay == false ||
            (_weatherSnapshot == null && (now.hour < 6 || now.hour >= 18));
        final weather = _gardenWeather(now);
        final avatarSize = compact ? 132.0 : 150.0;
        final grassBaseline = height * 0.75;
        final avatarTop = grassBaseline - avatarSize * 0.88;

        return ClipRect(
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                final drift = math.sin(t * math.pi * 2);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: _GardenScenePainter(
                          progress: t,
                          isNight: isNight,
                          weather: weather,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              (weather == _GardenWeather.stormy
                                      ? const Color(0xFF203945)
                                      : Colors.black)
                                  .withValues(alpha: isNight ? 0.09 : 0),
                              Colors.transparent,
                              const Color(
                                0xFF2D201B,
                              ).withValues(alpha: isNight ? 0.08 : 0.035),
                            ],
                            stops: const [0, 0.56, 1],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _GardenAtmospherePainter(
                            progress: t,
                            isNight: isNight,
                            weather: weather,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: compact ? 14 : 18,
                      top: compact ? 16 : 20,
                      child: _GardenMiniInfoCard(
                        isNight: isNight,
                        weather: weather,
                        snapshot: _weatherSnapshot,
                        checkingLocation: _checkingLocation,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: avatarTop,
                      child: Center(
                        child: RepaintBoundary(
                          child: Transform.translate(
                            offset: Offset(0, drift * 1.8),
                            child: SizedBox(
                              width: avatarSize,
                              height: avatarSize,
                              child: PetAvatarWidget(
                                species: widget.appearance.species,
                                color: widget.petColor,
                                pattern: widget.appearance.pattern,
                                equipped: widget.appearance.equipped.toList(
                                  growable: false,
                                ),
                                mouthType: widget.appearance.mouthType,
                                eyeType: widget.appearance.eyeType,
                                isRotating: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _GardenAtmospherePainter extends CustomPainter {
  const _GardenAtmospherePainter({
    required this.progress,
    required this.isNight,
    required this.weather,
  });

  final double progress;
  final bool isNight;
  final _GardenWeather weather;

  @override
  void paint(Canvas canvas, Size size) {
    if (weather == _GardenWeather.rainy || weather == _GardenWeather.stormy) {
      _drawRain(canvas, size);
      if (weather == _GardenWeather.stormy) {
        final pulse = math.pow(
          math.max(0, math.sin(progress * math.pi * 6 - 1.2)),
          18,
        );
        if (pulse > 0.01) {
          canvas.drawRect(
            Offset.zero & size,
            Paint()
              ..color = const Color(0xFFDDECF4).withValues(alpha: pulse * 0.16),
          );
        }
      }
      return;
    }

    final particleColor = isNight
        ? const Color(0xFFFFE39A)
        : const Color(0xFFFFC96D);
    for (var i = 0; i < 9; i++) {
      final phase = progress * math.pi * 2 + i * 1.17;
      final x = size.width * (0.08 + i * 0.105) + math.sin(phase) * 7;
      final y = size.height * (0.28 + (i % 4) * 0.10) + math.cos(phase) * 6;
      final alpha =
          (0.18 + (math.sin(phase * 1.7) + 1) * 0.12) * (isNight ? 1.55 : 1);
      final center = Offset(x, y);
      canvas.drawCircle(
        center,
        5.5 + (i.isEven ? 1.5 : 0),
        Paint()
          ..shader = ui.Gradient.radial(center, 7, [
            particleColor.withValues(alpha: alpha),
            particleColor.withValues(alpha: 0),
          ]),
      );
    }
  }

  void _drawRain(Canvas canvas, Size size) {
    for (var layer = 0; layer < 3; layer++) {
      final depth = layer / 2;
      final rain = Paint()
        ..color = const Color(0xFFEAF5F7).withValues(
          alpha:
              (weather == _GardenWeather.stormy ? 0.24 : 0.18) + depth * 0.22,
        )
        ..strokeWidth = 0.75 + depth * 0.75
        ..strokeCap = StrokeCap.round;
      final count = 13 + layer * 6;
      final speed = 135.0 + layer * 62;
      for (var i = 0; i < count; i++) {
        final x =
            (i * (67.0 - layer * 13) + progress * (62 + layer * 34)) %
                (size.width + 52) -
            26;
        final y =
            (i * (79.0 - layer * 9) + progress * speed) % (size.height + 36) -
            18;
        final length = 7.5 + depth * 9 + (i % 3) * 1.2;
        final drop = Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(
            x - 1.8 - depth,
            y + length * 0.48,
            x - 4.0 - depth * 1.8,
            y + length,
          );
        canvas.drawPath(drop, rain);
      }
    }

    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = const Color(0xFFEAF5F7).withValues(alpha: 0.24);
    for (var i = 0; i < 7; i++) {
      final phase = (progress * 1.7 + i * 0.173) % 1;
      final x = size.width * (0.08 + ((i * 31) % 83) / 100);
      final y = size.height * (0.74 + (i % 3) * 0.075);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 3 + phase * 16,
          height: 1.2 + phase * 4.2,
        ),
        ripplePaint
          ..color = ripplePaint.color.withValues(alpha: 0.28 * (1 - phase)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GardenAtmospherePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isNight != isNight ||
        oldDelegate.weather != weather;
  }
}

class _GardenMiniInfoCard extends StatelessWidget {
  const _GardenMiniInfoCard({
    required this.isNight,
    required this.weather,
    required this.snapshot,
    required this.checkingLocation,
  });

  final bool isNight;
  final _GardenWeather weather;
  final WeatherSnapshot? snapshot;
  final bool checkingLocation;

  @override
  Widget build(BuildContext context) {
    final condition = snapshot?.conditionLabel;
    final temperature = snapshot == null
        ? null
        : '${snapshot!.temperatureCelsius.round()}°';
    final label = checkingLocation
        ? 'Checking sky'
        : temperature != null && condition != null
        ? '$temperature $condition'
        : switch (weather) {
            _GardenWeather.clear => isNight ? 'Night mode' : 'Day mode',
            _GardenWeather.cloudy => 'Cloudy',
            _GardenWeather.rainy => 'Rainy',
            _GardenWeather.stormy => 'Stormy',
          };
    final icon = switch (weather) {
      _GardenWeather.clear =>
        isNight ? Icons.nightlight_round_rounded : Icons.wb_sunny_rounded,
      _GardenWeather.cloudy => Icons.cloud_rounded,
      _GardenWeather.rainy => Icons.water_drop_rounded,
      _GardenWeather.stormy => Icons.thunderstorm_rounded,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 44,
          padding: const EdgeInsets.fromLTRB(12, 7, 14, 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isNight ? 0.16 : 0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: isNight ? 0.26 : 0.64),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(
                    alpha: isNight ? 0.50 : 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: isNight ? Colors.white : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isNight ? Colors.white : AppTheme.secondaryText,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GardenScenePainter extends CustomPainter {
  const _GardenScenePainter({
    required this.progress,
    required this.isNight,
    required this.weather,
  });

  final double progress;
  final bool isNight;
  final _GardenWeather weather;

  @override
  void paint(Canvas canvas, Size size) {
    final skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        weather == _GardenWeather.stormy
            ? const [Color(0xFF34474D), Color(0xFF68777A), Color(0xFFB1B7A9)]
            : isNight
            ? const [Color(0xFF272235), Color(0xFF4B3B52), Color(0xFF8B6669)]
            : weather == _GardenWeather.cloudy ||
                  weather == _GardenWeather.rainy
            ? const [Color(0xFFDCE6E3), Color(0xFFF0E5D8), Color(0xFFC8D3AF)]
            : const [Color(0xFFCBE5E7), Color(0xFFF8DBC7), Color(0xFFE3E5C9)],
        const [0.0, 0.52, 1.0],
      );
    canvas.drawRect(Offset.zero & size, skyPaint);

    _drawSkyGlow(canvas, size);
    _drawSunOrMoon(canvas, size);
    _drawCloudLayer(canvas, size);
    _drawHorizonMist(canvas, size);
    _drawDistantTreeLine(canvas, size);
    _drawFence(canvas, size);

    _drawHill(
      canvas,
      size,
      color: isNight
          ? const Color(0xFF876E57).withValues(alpha: 0.96)
          : weather == _GardenWeather.stormy
          ? const Color(0xFFB2B08D)
          : const Color(0xFFD8D29F),
      y1: 0.61,
      c1y: 0.53,
      c2y: 0.68,
      y2: 0.54,
    );
    _drawHill(
      canvas,
      size,
      color: isNight
          ? const Color(0xFF536F50)
          : weather == _GardenWeather.stormy
          ? const Color(0xFF718866)
          : const Color(0xFF91AE78),
      y1: 0.70,
      c1y: 0.62,
      c2y: 0.76,
      y2: 0.64,
    );
    _drawGardenTrees(canvas, size);
    _drawBushLine(canvas, size);

    final path = Path()
      ..moveTo(size.width * 0.35, size.height)
      ..cubicTo(
        size.width * 0.40,
        size.height * 0.88,
        size.width * 0.46,
        size.height * 0.73,
        size.width * 0.485,
        size.height * 0.645,
      )
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.625,
        size.width * 0.515,
        size.height * 0.645,
      )
      ..cubicTo(
        size.width * 0.55,
        size.height * 0.74,
        size.width * 0.61,
        size.height * 0.88,
        size.width * 0.67,
        size.height,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = isNight
            ? const Color(0xFFFFD2A9).withValues(alpha: 0.62)
            : const Color(0xFFFFDFAA).withValues(alpha: 0.90),
    );
    canvas.drawPath(
      path.shift(const Offset(0, 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: isNight ? 0.12 : 0.24),
    );
    _drawPathPebbles(canvas, size);
    _drawGrassTexture(canvas, size);
    _drawFlowerMeadow(canvas, size);
    _drawGardenProps(canvas, size);
    _drawGardenLife(canvas, size);

    _drawAvatarStage(canvas, size);
  }

  void _drawSkyGlow(Canvas canvas, Size size) {
    final warm = weather == _GardenWeather.stormy
        ? const Color(0xFFE8DDBD)
        : isNight
        ? const Color(0xFFFFD7B0)
        : const Color(0xFFFFCF7C);
    final center = Offset(size.width * 0.64, size.height * 0.20);
    canvas.drawCircle(
      center,
      size.width * 0.18,
      Paint()
        ..shader = ui.Gradient.radial(center, size.width * 0.18, [
          warm.withValues(
            alpha: weather == _GardenWeather.stormy
                ? 0.11
                : isNight
                ? 0.18
                : 0.26,
          ),
          warm.withValues(alpha: 0),
        ]),
    );
  }

  void _drawSunOrMoon(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.64, size.height * 0.18);
    final radius = isNight ? 19.0 : 22.0;
    canvas.drawCircle(
      center,
      radius + 12,
      Paint()
        ..shader = ui.Gradient.radial(center, radius + 12, [
          (isNight ? const Color(0xFFFFF3D2) : const Color(0xFFFFC65C))
              .withValues(alpha: 0.20),
          Colors.transparent,
        ]),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isNight
            ? const Color(0xFFFFF4D8).withValues(alpha: 0.90)
            : const Color(0xFFFFC65C).withValues(
                alpha: weather == _GardenWeather.stormy ? 0.62 : 0.86,
              ),
    );
    if (isNight) {
      canvas.drawCircle(
        center.translate(-7, -4),
        radius * 0.72,
        Paint()..color = const Color(0xFF7B3034).withValues(alpha: 0.18),
      );
    }
  }

  void _drawCloudLayer(Canvas canvas, Size size) {
    final cloudCount = switch (weather) {
      _GardenWeather.clear => 1,
      _GardenWeather.cloudy => 3,
      _GardenWeather.rainy => 3,
      _GardenWeather.stormy => 4,
    };
    for (var i = 0; i < cloudCount; i++) {
      final baseX = switch (i) {
        0 => 0.20,
        1 => 0.62,
        2 => 0.42,
        _ => 0.88,
      };
      final direction = i.isEven ? 1.0 : -1.0;
      final x =
          size.width * baseX +
          math.sin(progress * math.pi * 2 + i * 1.4) * 6 * direction;
      final y = size.height * (i == 2 ? 0.26 : 0.15 + (i % 2) * 0.075);
      final scale = i == 0 ? 0.72 : (i == 1 ? 0.56 : 0.62);
      _drawCloud(canvas, Offset(x, y), scale, i);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double scale, int index) {
    final width = 118 * scale;
    final height = 40 * scale;
    final path = Path()
      ..moveTo(center.dx - width * 0.52, center.dy + height * 0.18)
      ..cubicTo(
        center.dx - width * 0.56,
        center.dy - height * 0.08,
        center.dx - width * 0.42,
        center.dy - height * 0.34,
        center.dx - width * 0.24,
        center.dy - height * 0.27,
      )
      ..cubicTo(
        center.dx - width * 0.13,
        center.dy - height * 0.72,
        center.dx + width * 0.15,
        center.dy - height * 0.72,
        center.dx + width * 0.25,
        center.dy - height * 0.31,
      )
      ..cubicTo(
        center.dx + width * 0.43,
        center.dy - height * 0.36,
        center.dx + width * 0.57,
        center.dy - height * 0.07,
        center.dx + width * 0.50,
        center.dy + height * 0.18,
      )
      ..cubicTo(
        center.dx + width * 0.29,
        center.dy + height * 0.36,
        center.dx - width * 0.33,
        center.dy + height * 0.37,
        center.dx - width * 0.52,
        center.dy + height * 0.18,
      )
      ..close();
    final bounds = path.getBounds();
    final opacity = weather == _GardenWeather.clear
        ? (isNight ? 0.22 : 0.42)
        : weather == _GardenWeather.stormy
        ? 0.70
        : (isNight ? 0.36 : 0.62);
    final topColor = weather == _GardenWeather.stormy
        ? const Color(0xFFA9B7BC)
        : Colors.white;
    final bottomColor = weather == _GardenWeather.stormy
        ? const Color(0xFF75898F)
        : isNight
        ? const Color(0xFFC4BED3)
        : const Color(0xFFE8F1ED);

    canvas.drawPath(
      path.shift(Offset(0, 4 * scale)),
      Paint()
        ..color = const Color(
          0xFF20313A,
        ).withValues(alpha: weather == _GardenWeather.stormy ? 0.13 : 0.045)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 * scale),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(bounds.topCenter, bounds.bottomCenter, [
          topColor.withValues(alpha: isNight ? opacity * 0.64 : opacity),
          bottomColor.withValues(alpha: isNight ? opacity * 0.42 : opacity),
        ])
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.45),
    );

    canvas.save();
    canvas.clipPath(path);
    final highlightAlpha = weather == _GardenWeather.stormy ? 0.12 : 0.24;
    final puffCenters = [
      center.translate(-width * 0.23, -height * 0.20),
      center.translate(width * 0.02, -height * 0.37),
      center.translate(width * 0.25, -height * 0.15),
    ];
    for (var i = 0; i < puffCenters.length; i++) {
      final puff = puffCenters[i];
      canvas.drawOval(
        Rect.fromCenter(
          center: puff,
          width: width * (i == 1 ? 0.46 : 0.38),
          height: height * (i == 1 ? 0.82 : 0.66),
        ),
        Paint()
          ..shader = ui.Gradient.radial(
            puff.translate(-3 * scale, -4 * scale),
            width * 0.25,
            [
              Colors.white.withValues(
                alpha: isNight ? highlightAlpha * 0.35 : highlightAlpha,
              ),
              Colors.white.withValues(alpha: 0),
            ],
          ),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, height * 0.19),
        width: width * 0.86,
        height: height * 0.28,
      ),
      Paint()
        ..color =
            (weather == _GardenWeather.stormy
                    ? const Color(0xFF536A73)
                    : const Color(0xFFCADDDC))
                .withValues(alpha: isNight ? 0.16 : 0.22),
    );
    canvas.restore();
    canvas.drawPath(
      path.shift(Offset(0, -1.1 * scale)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = scale
        ..color = Colors.white.withValues(
          alpha: isNight ? 0.07 : (0.18 + (index.isEven ? 0.03 : 0)),
        ),
    );
  }

  void _drawHorizonMist(Canvas canvas, Size size) {
    final top = size.height * 0.48;
    final rect = Rect.fromLTWH(0, top, size.width, size.height * 0.24);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, top),
          Offset(0, top + rect.height),
          [
            Colors.white.withValues(alpha: isNight ? 0.04 : 0.14),
            Colors.white.withValues(alpha: isNight ? 0.13 : 0.22),
            Colors.white.withValues(alpha: 0),
          ],
          const [0, 0.42, 1],
        ),
    );
  }

  void _drawDistantTreeLine(Canvas canvas, Size size) {
    final baseY = size.height * 0.61;
    final back = isNight
        ? const Color(0xFF263F38)
        : weather == _GardenWeather.stormy
        ? const Color(0xFF587364)
        : const Color(0xFF4F7C5D);
    final front = isNight
        ? const Color(0xFF315248)
        : weather == _GardenWeather.stormy
        ? const Color(0xFF668C70)
        : const Color(0xFF65976D);

    Path makePineLine({required double y, required bool foreground}) {
      final path = Path()..moveTo(-24, y + 20);
      final treeCount = foreground ? 13 : 11;
      final spacing = (size.width + 48) / (treeCount - 1);
      for (var i = 0; i < treeCount; i++) {
        final center = -24 + spacing * i;
        final height = (foreground ? 38.0 : 31.0) + ((i * 9) % 13);
        final halfWidth = spacing * (foreground ? 0.58 : 0.62);
        path
          ..lineTo(center - halfWidth, y + 8)
          ..quadraticBezierTo(
            center - halfWidth * 0.54,
            y - height * 0.18,
            center - halfWidth * 0.26,
            y - height * 0.33,
          )
          ..lineTo(center - halfWidth * 0.48, y - height * 0.30)
          ..quadraticBezierTo(
            center - halfWidth * 0.23,
            y - height * 0.56,
            center,
            y - height,
          )
          ..quadraticBezierTo(
            center + halfWidth * 0.23,
            y - height * 0.56,
            center + halfWidth * 0.48,
            y - height * 0.30,
          )
          ..lineTo(center + halfWidth * 0.26, y - height * 0.33)
          ..quadraticBezierTo(
            center + halfWidth * 0.54,
            y - height * 0.18,
            center + halfWidth,
            y + 8,
          );
      }
      return path
        ..lineTo(size.width + 24, y + 30)
        ..lineTo(-24, y + 30)
        ..close();
    }

    canvas.drawPath(
      makePineLine(y: baseY - 5, foreground: false),
      Paint()..color = back.withValues(alpha: isNight ? 0.52 : 0.66),
    );
    canvas.drawPath(
      makePineLine(y: baseY + 11, foreground: true),
      Paint()..color = front.withValues(alpha: isNight ? 0.62 : 0.76),
    );

    final haze = Paint()
      ..color = Colors.white.withValues(alpha: isNight ? 0.04 : 0.12)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, baseY + 10),
      Offset(size.width, baseY + 10),
      haze,
    );
  }

  void _drawGardenTrees(Canvas canvas, Size size) {
    void drawPine({
      required Offset root,
      required double scale,
      required bool isForeground,
      required double phase,
    }) {
      final storm = weather == _GardenWeather.stormy;
      final sway =
          math.sin(progress * math.pi * 2 + phase) * (storm ? 0.018 : 0.007);
      canvas.save();
      canvas.translate(root.dx, root.dy);
      canvas.rotate(sway);
      canvas.scale(scale);

      final trunkTop = isNight
          ? const Color(0xFF745D50)
          : const Color(0xFFAF8060);
      final trunkBottom = isNight
          ? const Color(0xFF493B36)
          : const Color(0xFF76503D);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-7, -62, 14, 66),
          const Radius.circular(7),
        ),
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(-7, -62),
            const Offset(7, 4),
            [trunkTop, trunkBottom],
          ),
      );

      final deep = isForeground
          ? isNight
                ? const Color(0xFF416E57)
                : storm
                ? const Color(0xFF5F8D67)
                : const Color(0xFF5F9B67)
          : isNight
          ? const Color(0xFF2E5448)
          : storm
          ? const Color(0xFF52745E)
          : const Color(0xFF527D62);
      final mid = isForeground
          ? isNight
                ? const Color(0xFF5F8868)
                : storm
                ? const Color(0xFF79A873)
                : const Color(0xFF78B276)
          : isNight
          ? const Color(0xFF466A58)
          : storm
          ? const Color(0xFF668A6C)
          : const Color(0xFF66926E);
      final bright = isForeground
          ? isNight
                ? const Color(0xFF7FA07A)
                : storm
                ? const Color(0xFF9AC786)
                : const Color(0xFFA2D187)
          : isNight
          ? const Color(0xFF617D67)
          : storm
          ? const Color(0xFF7F9F78)
          : const Color(0xFF7EA57A);

      Path pineTier(double top, double bottom, double halfWidth) {
        return Path()
          ..moveTo(0, top)
          ..cubicTo(
            -halfWidth * 0.14,
            top + (bottom - top) * 0.22,
            -halfWidth * 0.58,
            bottom - 12,
            -halfWidth,
            bottom - 2,
          )
          ..quadraticBezierTo(-halfWidth * 0.88, bottom + 5, 0, bottom)
          ..quadraticBezierTo(
            halfWidth * 0.88,
            bottom + 5,
            halfWidth,
            bottom - 2,
          )
          ..cubicTo(
            halfWidth * 0.58,
            bottom - 12,
            halfWidth * 0.14,
            top + (bottom - top) * 0.22,
            0,
            top,
          )
          ..close();
      }

      final tiers = [
        (pineTier(-154, -88, 38), bright),
        (pineTier(-126, -50, 53), mid),
        (pineTier(-92, -10, 67), deep),
      ];
      canvas.drawOval(
        const Rect.fromLTWH(-58, -7, 116, 14),
        Paint()..color = Colors.black.withValues(alpha: isNight ? 0.13 : 0.07),
      );
      for (final tier in tiers) {
        canvas.drawPath(
          tier.$1,
          Paint()
            ..shader = ui.Gradient.linear(
              tier.$1.getBounds().topCenter,
              tier.$1.getBounds().bottomCenter,
              [
                Color.lerp(tier.$2, Colors.white, isNight ? 0.04 : 0.10)!,
                tier.$2,
              ],
            ),
        );
      }
      canvas.drawPath(
        Path()
          ..moveTo(-5, -143)
          ..quadraticBezierTo(-17, -112, -22, -99),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: isNight ? 0.06 : 0.13),
      );
      canvas.restore();
    }

    drawPine(
      root: Offset(size.width * 0.10, size.height * 0.72),
      scale: math.min(size.width / 570, 0.88),
      isForeground: false,
      phase: 0.3,
    );
    drawPine(
      root: Offset(size.width * 0.92, size.height * 0.71),
      scale: math.min(size.width / 520, 0.96),
      isForeground: true,
      phase: 1.4,
    );
  }

  void _drawFence(Canvas canvas, Size size) {
    final y = size.height * 0.54;
    final paint = Paint()
      ..color = (isNight ? const Color(0xFFFFF2DC) : const Color(0xFFFFF8EA))
          .withValues(alpha: isNight ? 0.12 : 0.42)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(-8, y), Offset(size.width + 8, y), paint);
    canvas.drawLine(
      Offset(-8, y + 20),
      Offset(size.width + 8, y + 20),
      paint..strokeWidth = 1.8,
    );

    final postPaint = Paint()
      ..color = paint.color.withValues(alpha: isNight ? 0.18 : 0.54)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i <= 10; i++) {
      final x = -6 + (size.width + 12) * i / 10;
      canvas.drawLine(Offset(x, y - 18), Offset(x, y + 28), postPaint);
      final cap = Path()
        ..moveTo(x - 5, y - 18)
        ..quadraticBezierTo(x, y - 25, x + 5, y - 18);
      canvas.drawPath(
        cap,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = postPaint.color,
      );
    }
  }

  void _drawHill(
    Canvas canvas,
    Size size, {
    required Color color,
    required double y1,
    required double c1y,
    required double c2y,
    required double y2,
  }) {
    final startY = size.height * y1;
    final endY = size.height * y2;
    final path = Path()
      ..moveTo(0, startY)
      ..cubicTo(
        size.width * 0.18,
        size.height * c1y,
        size.width * 0.34,
        size.height * (y1 + 0.03),
        size.width * 0.52,
        size.height * (y1 - 0.01),
      )
      ..cubicTo(
        size.width * 0.70,
        size.height * c2y,
        size.width * 0.84,
        size.height * (y2 + 0.06),
        size.width,
        endY,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      Path()
        ..moveTo(0, startY)
        ..cubicTo(
          size.width * 0.18,
          size.height * c1y,
          size.width * 0.34,
          size.height * (y1 + 0.03),
          size.width * 0.52,
          size.height * (y1 - 0.01),
        )
        ..cubicTo(
          size.width * 0.70,
          size.height * c2y,
          size.width * 0.84,
          size.height * (y2 + 0.06),
          size.width,
          endY,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: isNight ? 0.10 : 0.22),
    );
  }

  void _drawBushLine(Canvas canvas, Size size) {
    final baseY = size.height * 0.66;
    final meadow = Path()
      ..moveTo(0, baseY + 6)
      ..cubicTo(
        size.width * 0.18,
        baseY - 16,
        size.width * 0.38,
        baseY + 3,
        size.width * 0.55,
        baseY - 8,
      )
      ..cubicTo(
        size.width * 0.72,
        baseY - 20,
        size.width * 0.86,
        baseY + 4,
        size.width,
        baseY - 10,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      meadow,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, baseY - 18),
          Offset(0, size.height),
          isNight
              ? const [Color(0xFF427B52), Color(0xFF2E5945)]
              : const [Color(0xFF91D276), Color(0xFF63B461)],
        ),
    );

    final backColor = isNight
        ? const Color(0xFF345F49)
        : weather == _GardenWeather.stormy
        ? const Color(0xFF668E65)
        : const Color(0xFF57945E);
    final frontColor = isNight
        ? const Color(0xFF4F7F5B)
        : weather == _GardenWeather.stormy
        ? const Color(0xFF7AAA6D)
        : const Color(0xFF7FC775);

    void drawShrub({
      required Offset center,
      required double width,
      required double height,
      required Color color,
      required int seed,
    }) {
      final base = center.translate(0, height * 0.30);
      final branchPaint = Paint()
        ..color = const Color(
          0xFF6C7250,
        ).withValues(alpha: isNight ? 0.30 : 0.48)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      for (final branch in [
        Offset(-width * 0.18, -height * 0.22),
        Offset(width * 0.02, -height * 0.34),
        Offset(width * 0.21, -height * 0.18),
      ]) {
        canvas.drawLine(base, center + branch, branchPaint);
      }

      final leafClusters = [
        (-0.31, 0.02, 0.34, 0.52),
        (-0.20, -0.18, 0.40, 0.62),
        (0.01, -0.28, 0.43, 0.70),
        (0.22, -0.16, 0.39, 0.60),
        (0.33, 0.04, 0.31, 0.48),
        (0.02, 0.03, 0.50, 0.56),
      ];
      for (var i = 0; i < leafClusters.length; i++) {
        final cluster = leafClusters[i];
        final jitterX = math.sin(seed * 0.73 + i * 1.91) * width * 0.025;
        final jitterY = math.cos(seed * 0.61 + i * 1.37) * height * 0.035;
        final clusterColor = Color.lerp(
          color,
          i < 3 ? Colors.white : const Color(0xFF28533E),
          isNight ? 0.035 + (i % 3) * 0.018 : 0.07 + (i % 3) * 0.025,
        )!;
        canvas.drawOval(
          Rect.fromCenter(
            center: center.translate(
              width * cluster.$1 + jitterX,
              height * cluster.$2 + jitterY,
            ),
            width: width * cluster.$3,
            height: height * cluster.$4,
          ),
          Paint()..color = clusterColor,
        );
      }

      final leafPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: isNight ? 0.07 : 0.15);
      for (var i = 0; i < 3; i++) {
        final detail = center.translate(
          width * (-0.18 + i * 0.18),
          height * (-0.15 + (i % 2) * 0.10),
        );
        canvas.drawArc(
          Rect.fromCenter(center: detail, width: 7, height: 4.5),
          i.isEven ? math.pi * 0.08 : math.pi * 0.92,
          math.pi * 0.82,
          false,
          leafPaint,
        );
      }
    }

    final backShrubs = [
      (0.18, 0.26, 39.0, 11, 10.0),
      (0.80, 0.28, 37.0, 23, 12.0),
    ];
    for (final shrub in backShrubs) {
      drawShrub(
        center: Offset(size.width * shrub.$1, baseY + shrub.$5),
        width: size.width * shrub.$2,
        height: shrub.$3,
        color: backColor,
        seed: shrub.$4,
      );
    }
    final frontShrubs = [
      (0.34, 0.19, 31.0, 6, 26.0),
      (0.65, 0.17, 29.0, 31, 28.0),
    ];
    for (final shrub in frontShrubs) {
      drawShrub(
        center: Offset(size.width * shrub.$1, baseY + shrub.$5),
        width: size.width * shrub.$2,
        height: shrub.$3,
        color: frontColor,
        seed: shrub.$4,
      );
    }
  }

  void _drawGrassTexture(Canvas canvas, Size size) {
    final grass = Paint()
      ..color = (isNight ? const Color(0xFFB0C69A) : const Color(0xFF4F914E))
          .withValues(alpha: isNight ? 0.18 : 0.25)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 22; i++) {
      final x = size.width * ((i * 29 % 101) / 100);
      final y = size.height * (0.67 + ((i * 11) % 26) / 100);
      final lean = math.sin(i * 1.7) * 2.5;
      canvas.drawLine(Offset(x, y), Offset(x + lean, y - 7), grass);
      if (i.isEven) {
        canvas.drawLine(Offset(x, y), Offset(x - lean * 0.7, y - 5), grass);
      }
    }
  }

  void _drawFlowerMeadow(Canvas canvas, Size size) {
    final flowerColors = [
      const Color(0xFFFFCA67),
      const Color(0xFFFF9FB0),
      const Color(0xFFFFF7EA),
      const Color(0xFFC86973),
    ];
    const flowerSpots = [
      (0.045, 0.73),
      (0.27, 0.79),
      (0.34, 0.71),
      (0.39, 0.84),
      (0.64, 0.74),
      (0.72, 0.85),
      (0.77, 0.70),
      (0.96, 0.79),
    ];
    for (var i = 0; i < flowerSpots.length; i++) {
      final x = size.width * flowerSpots[i].$1;
      final y = size.height * flowerSpots[i].$2;
      final sway = math.sin(progress * math.pi * 2 + i) * 1.8;
      final stem = Paint()
        ..color = (isNight ? const Color(0xFFEAF5DD) : const Color(0xFF557A46))
            .withValues(alpha: isNight ? 0.34 : 0.42)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, y + 8), Offset(x + sway, y), stem);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x - 1.8, y + 5.8),
          width: 4.5,
          height: 2.2,
        ),
        Paint()..color = stem.color.withValues(alpha: 0.72),
      );
      final bloom = Offset(x + sway, y);
      final bloomPaint = Paint()
        ..color = flowerColors[i % flowerColors.length].withValues(alpha: 0.86);
      canvas.drawCircle(bloom.translate(-1.6, 0), 1.9, bloomPaint);
      canvas.drawCircle(bloom.translate(1.6, 0), 1.9, bloomPaint);
      canvas.drawCircle(bloom.translate(0, -1.7), 1.9, bloomPaint);
      canvas.drawCircle(bloom, 1.1, Paint()..color = const Color(0xFFFFD36A));
    }
  }

  void _drawGardenProps(Canvas canvas, Size size) {
    final leafA = isNight ? const Color(0xFFB6D09A) : const Color(0xFF70AA5D);
    final leafB = isNight ? const Color(0xFFF1D299) : const Color(0xFF9ECE74);
    final pot = isNight ? const Color(0xFFBE7968) : const Color(0xFFFFB88C);
    final potDeep = isNight ? const Color(0xFF8F574D) : const Color(0xFFE78970);
    final potShadow = AppTheme.primaryColor.withValues(
      alpha: isNight ? 0.18 : 0.10,
    );

    void drawGroundPatch(Offset base, double width) {
      final patchColor = isNight
          ? const Color(0xFF4D7955)
          : const Color(0xFF72B96B);
      canvas.drawOval(
        Rect.fromCenter(
          center: base.translate(0, 19),
          width: width,
          height: 13,
        ),
        Paint()..color = patchColor.withValues(alpha: isNight ? 0.36 : 0.42),
      );
    }

    void drawBaseGrass(Offset base, double scale, List<double> offsets) {
      final grassPaint = Paint()
        ..color = (isNight ? const Color(0xFF83A878) : const Color(0xFF4F9655))
            .withValues(alpha: isNight ? 0.54 : 0.72)
        ..strokeWidth = 1.45 * scale
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < offsets.length; i++) {
        final x = base.dx + offsets[i] * scale;
        final groundY = base.dy + 23 * scale;
        final height = (6 + (i * 3) % 5) * scale;
        final lean = (i.isEven ? -2.2 : 2.4) * scale;
        canvas.drawLine(
          Offset(x, groundY),
          Offset(x + lean, groundY - height),
          grassPaint,
        );
        if (i % 3 == 0) {
          canvas.drawLine(
            Offset(x, groundY),
            Offset(x - lean * 0.65, groundY - height * 0.72),
            grassPaint,
          );
        }
      }
    }

    void drawLeaf(Offset center, double angle, double scale, Color color) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 9 * scale,
          height: 20 * scale,
        ),
        Paint()..color = color.withValues(alpha: isNight ? 0.62 : 0.86),
      );
      canvas.restore();
    }

    void drawPlanter(Offset base, double scale, {required bool flip}) {
      final sign = flip ? -1.0 : 1.0;
      canvas.drawOval(
        Rect.fromCenter(
          center: base.translate(0, 21 * scale),
          width: 54 * scale,
          height: 8 * scale,
        ),
        Paint()..color = Colors.black.withValues(alpha: isNight ? 0.12 : 0.07),
      );
      final bodyPath = Path()
        ..moveTo(base.dx - 23 * scale, base.dy - 6 * scale)
        ..cubicTo(
          base.dx - 21 * scale,
          base.dy + 7 * scale,
          base.dx - 18 * scale,
          base.dy + 18 * scale,
          base.dx - 11 * scale,
          base.dy + 21 * scale,
        )
        ..quadraticBezierTo(
          base.dx,
          base.dy + 25 * scale,
          base.dx + 11 * scale,
          base.dy + 21 * scale,
        )
        ..cubicTo(
          base.dx + 18 * scale,
          base.dy + 18 * scale,
          base.dx + 21 * scale,
          base.dy + 7 * scale,
          base.dx + 23 * scale,
          base.dy - 6 * scale,
        )
        ..close();
      canvas.drawPath(
        bodyPath.shift(Offset(0, 2 * scale)),
        Paint()..color = potShadow,
      );
      canvas.drawPath(
        bodyPath,
        Paint()
          ..shader = ui.Gradient.linear(
            base.translate(0, -12 * scale),
            base.translate(0, 22 * scale),
            [pot.withValues(alpha: 0.96), potDeep.withValues(alpha: 0.94)],
          ),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: base.translate(0, -9 * scale),
            width: 52 * scale,
            height: 12 * scale,
          ),
          Radius.circular(10 * scale),
        ),
        Paint()..color = pot.withValues(alpha: 0.98),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: base.translate(0, -9 * scale),
          width: 42 * scale,
          height: 6 * scale,
        ),
        Paint()..color = const Color(0xFF5F4B3D).withValues(alpha: 0.72),
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: base.translate(-3 * scale, 3 * scale),
          width: 31 * scale,
          height: 29 * scale,
        ),
        math.pi * 0.57,
        math.pi * 0.70,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * scale
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: isNight ? 0.10 : 0.22),
      );

      final stemPaint = Paint()
        ..color = leafA.withValues(alpha: isNight ? 0.62 : 0.82)
        ..strokeWidth = 1.8 * scale
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        base.translate(0, -9 * scale),
        base.translate(sign * -14 * scale, -28 * scale),
        stemPaint,
      );
      canvas.drawLine(
        base.translate(0, -9 * scale),
        base.translate(sign * -2 * scale, -40 * scale),
        stemPaint,
      );
      canvas.drawLine(
        base.translate(0, -9 * scale),
        base.translate(sign * 14 * scale, -27 * scale),
        stemPaint,
      );

      drawLeaf(
        base.translate(sign * -14 * scale, -26 * scale),
        sign * -0.55,
        scale,
        leafA,
      );
      drawLeaf(
        base.translate(sign * -2 * scale, -35 * scale),
        sign * -0.08,
        scale * 1.05,
        leafB,
      );
      drawLeaf(
        base.translate(sign * 14 * scale, -25 * scale),
        sign * 0.55,
        scale,
        leafA,
      );
      final bloomColor = flip
          ? const Color(0xFFFFD16E)
          : const Color(0xFFFF9FAE);
      canvas.drawCircle(
        base.translate(sign * -2 * scale, -46 * scale),
        4.2 * scale,
        Paint()..color = bloomColor.withValues(alpha: isNight ? 0.70 : 0.92),
      );
    }

    void drawDogHouse(Offset base, double scale) {
      final shadow = Paint()
        ..color = Colors.black.withValues(alpha: isNight ? 0.14 : 0.08);
      canvas.drawOval(
        Rect.fromCenter(
          center: base.translate(0, 23 * scale),
          width: 70 * scale,
          height: 9 * scale,
        ),
        shadow,
      );

      final wallColor = isNight
          ? const Color(0xFF8D4E48)
          : const Color(0xFFFFEEE2);
      final sideColor = isNight
          ? const Color(0xFF6F3A3B)
          : const Color(0xFFF8BFA6);
      final roofColor = isNight
          ? const Color(0xFF7B3034)
          : AppTheme.primaryColor;
      final trimColor = isNight
          ? const Color(0xFFFFD8C6).withValues(alpha: 0.72)
          : const Color(0xFFFFD8C6);

      final body = Path()
        ..moveTo(base.dx - 28 * scale, base.dy - 10 * scale)
        ..lineTo(base.dx, base.dy - 34 * scale)
        ..lineTo(base.dx + 28 * scale, base.dy - 10 * scale)
        ..lineTo(base.dx + 28 * scale, base.dy + 20 * scale)
        ..quadraticBezierTo(
          base.dx + 28 * scale,
          base.dy + 24 * scale,
          base.dx + 23 * scale,
          base.dy + 24 * scale,
        )
        ..lineTo(base.dx - 23 * scale, base.dy + 24 * scale)
        ..quadraticBezierTo(
          base.dx - 28 * scale,
          base.dy + 24 * scale,
          base.dx - 28 * scale,
          base.dy + 20 * scale,
        )
        ..close();
      canvas.drawPath(
        body.shift(Offset(0, 2 * scale)),
        Paint()..color = Colors.black.withValues(alpha: isNight ? 0.10 : 0.05),
      );
      canvas.drawPath(body, Paint()..color = wallColor);
      final sideShade = Path()
        ..moveTo(base.dx - 28 * scale, base.dy - 10 * scale)
        ..lineTo(base.dx, base.dy - 34 * scale)
        ..lineTo(base.dx, base.dy + 24 * scale)
        ..lineTo(base.dx - 23 * scale, base.dy + 24 * scale)
        ..quadraticBezierTo(
          base.dx - 28 * scale,
          base.dy + 24 * scale,
          base.dx - 28 * scale,
          base.dy + 19 * scale,
        )
        ..close();
      canvas.drawPath(
        sideShade,
        Paint()..color = sideColor.withValues(alpha: 0.42),
      );

      final roof = Path()
        ..moveTo(base.dx - 38 * scale, base.dy - 12 * scale)
        ..quadraticBezierTo(
          base.dx,
          base.dy - 50 * scale,
          base.dx + 38 * scale,
          base.dy - 12 * scale,
        )
        ..quadraticBezierTo(
          base.dx + 36 * scale,
          base.dy - 7 * scale,
          base.dx + 31 * scale,
          base.dy - 8 * scale,
        )
        ..lineTo(base.dx - 31 * scale, base.dy - 8 * scale)
        ..quadraticBezierTo(
          base.dx - 36 * scale,
          base.dy - 7 * scale,
          base.dx - 38 * scale,
          base.dy - 12 * scale,
        )
        ..close();
      canvas.drawPath(roof, Paint()..color = roofColor);
      canvas.drawPath(
        roof,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * scale
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white.withValues(alpha: isNight ? 0.14 : 0.34),
      );
      canvas.drawPath(
        roof.shift(Offset(0, 2 * scale)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * scale
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: isNight ? 0.12 : 0.20),
      );

      final doorTop = base.dy - 3 * scale;
      final doorBottom = base.dy + 24 * scale;
      final door = Path()
        ..moveTo(base.dx - 13 * scale, doorBottom)
        ..lineTo(base.dx - 13 * scale, doorTop + 11 * scale)
        ..cubicTo(
          base.dx - 13 * scale,
          doorTop - 4 * scale,
          base.dx + 13 * scale,
          doorTop - 4 * scale,
          base.dx + 13 * scale,
          doorTop + 11 * scale,
        )
        ..lineTo(base.dx + 13 * scale, doorBottom)
        ..close();
      canvas.drawPath(
        door,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(base.dx, doorTop),
            Offset(base.dx, doorBottom),
            isNight
                ? const [Color(0xFF3C2730), Color(0xFF251D22)]
                : const [Color(0xFF7B3034), Color(0xFF522327)],
          ),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: base.translate(0, 21 * scale),
            width: 66 * scale,
            height: 7 * scale,
          ),
          Radius.circular(5 * scale),
        ),
        Paint()..color = trimColor.withValues(alpha: isNight ? 0.58 : 0.92),
      );
    }

    void drawGardenLight(Offset top, double scale) {
      final glow = isNight
          ? const Color(0xFFFFF0C4).withValues(alpha: 0.34)
          : const Color(0xFFFFCA67).withValues(alpha: 0.16);
      canvas.drawCircle(
        top,
        18 * scale,
        Paint()
          ..shader = ui.Gradient.radial(top, 18 * scale, [
            glow,
            glow.withValues(alpha: 0),
          ]),
      );
      canvas.drawLine(
        top.translate(0, 5 * scale),
        top.translate(0, 31 * scale),
        Paint()
          ..color = Colors.white.withValues(alpha: isNight ? 0.35 : 0.52)
          ..strokeWidth = 1.4 * scale
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        top,
        4.4 * scale,
        Paint()..color = const Color(0xFFFFD36A).withValues(alpha: 0.88),
      );
    }

    final dogHouseBase = Offset(size.width * 0.15, size.height * 0.805);
    final planterBase = Offset(size.width * 0.86, size.height * 0.815);
    drawGardenLight(Offset(size.width * 0.08, size.height * 0.68), 0.90);
    drawGardenLight(Offset(size.width * 0.91, size.height * 0.67), 0.82);
    drawGroundPatch(dogHouseBase, 82);
    drawGroundPatch(planterBase, 64);
    drawDogHouse(dogHouseBase, 0.80);
    drawPlanter(planterBase, 0.84, flip: true);
    drawBaseGrass(dogHouseBase, 0.80, const [-35, -29, 29, 36]);
    drawBaseGrass(planterBase, 0.84, const [-29, -24, 25, 31]);
  }

  void _drawGardenLife(Canvas canvas, Size size) {
    if (isNight) {
      final firefly = const Color(0xFFFFE7A3);
      final anchors = [
        Offset(size.width * 0.24, size.height * 0.58),
        Offset(size.width * 0.74, size.height * 0.60),
        Offset(size.width * 0.35, size.height * 0.73),
      ];
      for (var i = 0; i < anchors.length; i++) {
        final phase = progress * math.pi * 2 + i * 1.8;
        final center = anchors[i].translate(
          math.sin(phase) * 7,
          math.cos(phase * 0.9) * 5,
        );
        canvas.drawCircle(
          center,
          10,
          Paint()
            ..shader = ui.Gradient.radial(center, 10, [
              firefly.withValues(alpha: 0.30),
              firefly.withValues(alpha: 0),
            ]),
        );
        canvas.drawCircle(
          center,
          2.2,
          Paint()..color = firefly.withValues(alpha: 0.72),
        );
      }
      return;
    }

    final wingPaint = Paint()
      ..color = const Color(0xFFFFA7B5).withValues(alpha: 0.72);
    final bodyPaint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.40);
    final butterflies = [
      Offset(size.width * 0.20, size.height * 0.57),
      Offset(size.width * 0.78, size.height * 0.55),
    ];
    for (var i = 0; i < butterflies.length; i++) {
      final phase = progress * math.pi * 2 + i * 2.2;
      final center = butterflies[i].translate(
        math.sin(phase) * 5,
        math.cos(phase * 1.2) * 4,
      );
      final flap = 1 + math.sin(phase * 3) * 0.18;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(math.sin(phase) * 0.20);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-3.8, -1), width: 6.5 * flap, height: 8),
        wingPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(3.8, -1), width: 6.5 * flap, height: 8),
        wingPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 1.7), width: 2.2, height: 7),
        bodyPaint,
      );
      canvas.restore();
    }
  }

  void _drawPathPebbles(Canvas canvas, Size size) {
    final pebblePaint = Paint()
      ..color = (isNight ? const Color(0xFF8C5B54) : const Color(0xFFD79C7D))
          .withValues(alpha: isNight ? 0.24 : 0.32);
    for (var i = 0; i < 8; i++) {
      final y = size.height * (0.66 + i * 0.033);
      final spread = 10 + i * 3.2;
      final x = size.width * 0.50 + (i.isEven ? -spread * 0.55 : spread * 0.56);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 8, height: 4),
        pebblePaint,
      );
    }
  }

  void _drawAvatarStage(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.50, size.height * 0.56);
    final ground = Offset(size.width * 0.50, size.height * 0.75);
    canvas.drawOval(
      Rect.fromCenter(center: ground, width: size.width * 0.24, height: 16),
      Paint()
        ..shader = ui.Gradient.radial(ground, size.width * 0.16, [
          Colors.black.withValues(alpha: isNight ? 0.20 : 0.13),
          Colors.transparent,
        ]),
    );
    canvas.drawCircle(
      center,
      96,
      Paint()
        ..shader = ui.Gradient.radial(center, 96, [
          Colors.white.withValues(alpha: isNight ? 0.12 : 0.18),
          Colors.white.withValues(alpha: 0),
        ]),
    );
  }

  @override
  bool shouldRepaint(covariant _GardenScenePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isNight != isNight ||
        oldDelegate.weather != weather;
  }
}

class _GardenStatusPill extends StatelessWidget {
  const _GardenStatusPill({required this.label, required this.isNight});

  final String label;
  final bool isNight;

  String get _shortLabel {
    final normalized = label.trim().toLowerCase();
    if (normalized.contains('rest')) return 'RESTING';
    if (normalized.contains('walk')) return 'WALKING';
    if (normalized.contains('active')) return 'ACTIVE';
    if (normalized.contains('sleep')) return 'SLEEPING';
    return label.trim().isEmpty ? 'READY' : label.trim().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 124),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: isNight
            ? const Color(0xFFFFF5DD).withValues(alpha: 0.22)
            : const Color(0xFFE9F2E2).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: isNight ? 0.16 : 0.62),
        ),
      ),
      child: Text(
        _shortLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isNight ? Colors.white : const Color(0xFF5E764F),
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _GardenInfoChip extends StatelessWidget {
  const _GardenInfoChip({
    required this.icon,
    required this.label,
    required this.isNight,
  });

  final IconData icon;
  final String label;
  final bool isNight;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isNight
            ? Colors.white.withValues(alpha: 0.18)
            : AppTheme.surfaceColor.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: isNight ? 0.24 : 0.72),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: isNight ? Colors.white : AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isNight ? Colors.white : AppTheme.secondaryText,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GardenWalkButton extends StatelessWidget {
  const _GardenWalkButton({required this.onTap, required this.isNight});

  final VoidCallback onTap;
  final bool isNight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 56,
        height: 46,
        decoration: BoxDecoration(
          color: isNight ? const Color(0xFFFFD0A8) : AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.18),
              blurRadius: 18,
              spreadRadius: -12,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Icon(
          Icons.directions_walk_rounded,
          color: isNight ? AppTheme.primaryColor : Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class _HomeDailyHero extends StatelessWidget {
  const _HomeDailyHero({
    required this.pet,
    required this.appearance,
    required this.petColor,
    required this.distance,
    required this.sessions,
    required this.onProfile,
    required this.onWalk,
  });

  final _PetData pet;
  final _PetAppearanceData appearance;
  final Color petColor;
  final String distance;
  final int sessions;
  final VoidCallback onProfile;
  final VoidCallback onWalk;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 370;
        final avatarSize = compact ? 112.0 : 126.0;
        final breed = pet.breed.trim().isEmpty ? 'Unknown breed' : pet.breed;
        final weight = pet.weightLabel.trim().isEmpty ? '-' : pet.weightLabel;

        return Container(
          height: compact ? 230 : 244,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF7),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.10),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryText.withValues(alpha: 0.05),
                blurRadius: 24,
                spreadRadius: -18,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Container(
                width: compact ? 126 : 142,
                height: double.infinity,
                decoration: const BoxDecoration(color: AppTheme.primaryColor),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: -30,
                      top: 18,
                      child: _HomeSoftCircle(
                        size: compact ? 86 : 104,
                        color: const Color(0xFFFFB8A7),
                        alpha: 0.18,
                      ),
                    ),
                    Positioned(
                      right: -32,
                      bottom: 22,
                      child: _HomeSoftCircle(
                        size: compact ? 78 : 92,
                        color: const Color(0xFFFFE4B8),
                        alpha: 0.16,
                      ),
                    ),
                    Container(
                      width: avatarSize + 22,
                      height: avatarSize + 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFEFB),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 22,
                            spreadRadius: -14,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _SoftFloat(
                          offset: 2,
                          child: SizedBox(
                            width: avatarSize,
                            height: avatarSize,
                            child: PetAvatarWidget(
                              species: appearance.species,
                              color: petColor,
                              pattern: appearance.pattern,
                              equipped: appearance.equipped.toList(
                                growable: false,
                              ),
                              mouthType: appearance.mouthType,
                              eyeType: appearance.eyeType,
                              isRotating: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 14 : 18,
                    compact ? 15 : 18,
                    compact ? 12 : 16,
                    compact ? 13 : 15,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pet.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: AppTheme.secondaryText,
                                        fontSize: compact ? 28 : 32,
                                        fontWeight: FontWeight.w900,
                                        height: 0.96,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${pet.species} • $breed',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: AppTheme.mutedText,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _HomeTinyAction(
                            icon: Icons.person_rounded,
                            onTap: onProfile,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1ED),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          pet.status.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: const Color(0xFF627A55),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: _HomeHeroMetric(
                              icon: Icons.cake_rounded,
                              value: pet.ageLabel,
                              label: 'age',
                              color: const Color(0xFFC9932E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _HomeHeroMetric(
                              icon: Icons.monitor_weight_rounded,
                              value: weight,
                              label: 'weight',
                              color: const Color(0xFF7A8B69),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.blushSurfaceColor.withValues(
                                  alpha: 0.72,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.route_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      '$distance • $sessions walks',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppTheme.secondaryText,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onWalk,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.directions_walk_rounded,
                                color: Colors.white,
                                size: 21,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _HomeSoftCircle extends StatelessWidget {
  const _HomeSoftCircle({
    required this.size,
    required this.color,
    required this.alpha,
  });

  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HomeHeroMetric extends StatelessWidget {
  const _HomeHeroMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.mutedText,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
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

class _HomeSectionTitle extends StatelessWidget {
  const _HomeSectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 30,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (trailing != null) const SizedBox(width: 10),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.16),
                  blurRadius: 16,
                  spreadRadius: -10,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              trailing!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeTodayOverview extends StatelessWidget {
  const _HomeTodayOverview({
    required this.pet,
    required this.nextPlan,
    required this.completedMissions,
    required this.totalMissions,
  });

  final _PetData pet;
  final CalendarEventData? nextPlan;
  final int completedMissions;
  final int totalMissions;

  @override
  Widget build(BuildContext context) {
    final nextPlanTitle = nextPlan?.title ?? 'No plan today';
    final nextPlanMeta = nextPlan?.timeLabel ?? 'Add a care plan when needed';
    final identityBits = <String>[
      pet.species,
      if (pet.gender != null && pet.gender!.trim().isNotEmpty) pet.gender!,
    ];
    final detailBits = <String>[
      if (pet.ageLabel.trim().isNotEmpty && pet.ageLabel != '—')
        pet.ageLabel
            .replaceAll(' Years Old', ' yrs')
            .replaceAll(' Year Old', ' yr'),
      if (pet.weightLabel.trim().isNotEmpty && pet.weightLabel != '—')
        pet.weightLabel,
    ];
    final profileDetails = [...identityBits, ...detailBits].join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HomeSectionTitle(title: 'Today'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                blurRadius: 22,
                spreadRadius: -14,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _HomeTodayPetPanel(
                      name: pet.name,
                      details: profileDetails,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _HomeTodayMissionPanel(
                    completed: completedMissions,
                    total: totalMissions,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _HomeTodayPlanStrip(
                icon: nextPlan?.icon ?? Icons.event_available_rounded,
                title: nextPlanTitle,
                meta: nextPlanMeta,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeTodayPetPanel extends StatelessWidget {
  const _HomeTodayPetPanel({required this.name, required this.details});

  final String name;
  final String details;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBDD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFA94755),
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFFA94755),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    details.isEmpty ? 'Pet profile' : details,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFA94755).withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      height: 1,
                      fontSize: 10,
                    ),
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

class _HomeTodayMissionPanel extends StatelessWidget {
  const _HomeTodayMissionPanel({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    return Container(
      width: 96,
      height: 72,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0E3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: _homeSageAccent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                total == 0 ? '0/0' : '$completed/$total',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _homeSageAccent,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation(_homeSageAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTodayPlanStrip extends StatelessWidget {
  const _HomeTodayPlanStrip({
    required this.icon,
    required this.title,
    required this.meta,
  });

  final IconData icon;
  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF8ECD0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(icon, color: _homeGoldAccent, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _homeGoldAccent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    meta,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _homeGoldAccent.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: _homeGoldAccent.withValues(alpha: 0.78),
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _HomeQuickCareMenu extends StatelessWidget {
  const _HomeQuickCareMenu({
    required this.onTapCalendar,
    required this.onTapAssessment,
    required this.onTapAssistant,
    required this.onTapWardrobe,
    required this.onTapHistory,
  });

  final VoidCallback onTapCalendar;
  final VoidCallback onTapAssessment;
  final VoidCallback onTapAssistant;
  final VoidCallback onTapWardrobe;
  final VoidCallback onTapHistory;

  @override
  Widget build(BuildContext context) {
    final items = [
      _HomeQuickCareData(
        'AI Scan',
        Icons.health_and_safety_rounded,
        const Color(0xFFFFDCD6),
        AppTheme.primaryColor,
        -0.025,
        onTapAssessment,
      ),
      _HomeQuickCareData(
        'Calendar',
        Icons.calendar_month_rounded,
        const Color(0xFFFFE9B8),
        const Color(0xFFB98422),
        0.018,
        onTapCalendar,
      ),
      _HomeQuickCareData(
        'Assistant',
        Icons.medical_services_rounded,
        const Color(0xFFE4F0DA),
        const Color(0xFF657B4F),
        -0.012,
        onTapAssistant,
      ),
      _HomeQuickCareData(
        'Records',
        Icons.folder_copy_rounded,
        const Color(0xFFDDF1F4),
        const Color(0xFF4D7B86),
        0.022,
        onTapHistory,
      ),
      _HomeQuickCareData(
        'Style',
        Icons.checkroom_rounded,
        const Color(0xFFEFE1F5),
        const Color(0xFF7E638F),
        -0.018,
        onTapWardrobe,
      ),
    ];

    return SizedBox(
      height: 116,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _HomeQuickCareTile(data: items[index]),
      ),
    );
  }
}

class _HomeQuickCareData {
  const _HomeQuickCareData(
    this.label,
    this.icon,
    this.background,
    this.foreground,
    this.tilt,
    this.onTap,
  );

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final double tilt;
  final VoidCallback onTap;
}

class _HomeQuickCareTile extends StatelessWidget {
  const _HomeQuickCareTile({required this.data});

  final _HomeQuickCareData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        width: 82,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: data.tilt,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: data.background,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(22),
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(30),
                  ),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: data.foreground.withValues(alpha: 0.16),
                      blurRadius: 18,
                      spreadRadius: -10,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: -data.tilt,
                  child: Icon(data.icon, color: data.foreground, size: 31),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeMissionBoard extends StatelessWidget {
  const _HomeMissionBoard({
    required this.petName,
    required this.completed,
    required this.total,
    required this.loading,
    required this.missions,
    required this.burstMissionId,
    required this.onOpen,
    required this.onMissionTap,
  });

  final String petName;
  final int completed;
  final int total;
  final bool loading;
  final List<MissionModel> missions;
  final String? burstMissionId;
  final VoidCallback onOpen;
  final void Function(int missionId, Offset origin) onMissionTap;

  @override
  Widget build(BuildContext context) {
    return _SoftReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeSectionTitle(
            title: "Today's Missions",
            trailing: total == 0 ? 'Open' : '$completed/$total done',
          ),
          const SizedBox(height: 12),
          if (loading)
            const PettoCardSkeleton(height: 92, compact: true)
          else if (missions.isEmpty)
            _HomeMissionEmptyCard(petName: petName, onOpen: onOpen)
          else
            Column(
              children: [
                for (var index = 0; index < missions.length; index++) ...[
                  _HomeMissionLine(
                    mission: missions[index],
                    bursting: burstMissionId == missions[index].id.toString(),
                    onTap: (origin) => onMissionTap(missions[index].id, origin),
                  ),
                  if (index != missions.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _HomeMissionLine extends StatelessWidget {
  const _HomeMissionLine({
    required this.mission,
    required this.bursting,
    required this.onTap,
  });

  final MissionModel mission;
  final bool bursting;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = switch (mission.id % 3) {
      0 => (const Color(0xFF9B666A), const Color(0xFFF3E7E5)),
      1 => (const Color(0xFFA58043), const Color(0xFFF4ECD5)),
      _ => (const Color(0xFF748066), const Color(0xFFEBEEE5)),
    };
    final color = mission.isCompleted ? const Color(0xFF8E555A) : palette.$1;
    final surface = mission.isCompleted ? const Color(0xFFF1E2E0) : palette.$2;
    return AnimatedScale(
      scale: bursting ? 1.02 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: Container(
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 20,
              spreadRadius: -15,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: Icon(mission.icon, color: Colors.white, size: 25),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.secondaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        mission.rewardDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Builder(
              builder: (checkboxContext) => Semantics(
                button: true,
                checked: mission.isCompleted,
                label: mission.isCompleted
                    ? '${mission.title} completed'
                    : 'Complete ${mission.title}',
                child: InkWell(
                  onTap: mission.isCompleted
                      ? null
                      : () {
                          final box =
                              checkboxContext.findRenderObject() as RenderBox?;
                          final origin = box == null
                              ? Offset.zero
                              : box.localToGlobal(box.size.center(Offset.zero));
                          onTap(origin);
                        },
                  borderRadius: BorderRadius.circular(15),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: mission.isCompleted
                          ? color
                          : Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: mission.isCompleted
                            ? color
                            : color.withValues(alpha: 0.42),
                        width: 2,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: mission.isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              key: ValueKey(true),
                              color: Colors.white,
                              size: 24,
                            )
                          : const SizedBox(
                              key: ValueKey(false),
                              width: 24,
                              height: 24,
                            ),
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
}

class _HomeMissionEmptyCard extends StatelessWidget {
  const _HomeMissionEmptyCard({required this.petName, required this.onOpen});

  final String petName;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _homeSageSurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: _homeSageAccent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No missions yet',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.secondaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$petName has a calm care day.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Open',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePetOverviewCard extends StatelessWidget {
  const _HomePetOverviewCard({
    required this.pet,
    required this.appearance,
    required this.petColor,
    required this.onTapProfile,
  });

  final _PetData pet;
  final _PetAppearanceData appearance;
  final Color petColor;
  final VoidCallback onTapProfile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final avatarSize = compact ? 126.0 : 148.0;
        final species = pet.species.trim().isEmpty ? 'Pet' : pet.species;
        final breed = pet.breed.trim().isEmpty ? 'Unknown breed' : pet.breed;
        final weight = pet.weightLabel.trim().isEmpty ? '-' : pet.weightLabel;

        return InkWell(
          onTap: onTapProfile,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 15 : 18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.14),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryText.withValues(alpha: 0.05),
                  blurRadius: 24,
                  spreadRadius: -16,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: avatarSize + 16,
                  height: avatarSize + 18,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECE4),
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                      ),
                      _SoftFloat(
                        offset: 3,
                        child: SizedBox(
                          width: avatarSize * 0.88,
                          height: avatarSize * 0.88,
                          child: PetAvatarWidget(
                            species: appearance.species,
                            color: petColor,
                            pattern: appearance.pattern,
                            equipped: appearance.equipped.toList(
                              growable: false,
                            ),
                            mouthType: appearance.mouthType,
                            eyeType: appearance.eyeType,
                            isRotating: true,
                          ),
                        ),
                      ),
                      Positioned(
                        right: compact ? 2 : 0,
                        bottom: compact ? 10 : 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          child: Text(
                            species,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: compact ? 10 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pet.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: AppTheme.secondaryText,
                                    fontSize: compact ? 29 : 34,
                                    fontWeight: FontWeight.w900,
                                    height: 0.95,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _HomeTinyAction(
                            icon: Icons.arrow_forward_rounded,
                            onTap: onTapProfile,
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        breed,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mutedText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HomePetFact(
                            icon: Icons.cake_rounded,
                            label: 'Age',
                            value: pet.ageLabel,
                            color: const Color(0xFFC9932E),
                          ),
                          _HomePetFact(
                            icon: Icons.monitor_weight_rounded,
                            label: 'Weight',
                            value: weight,
                            color: const Color(0xFF7C8A63),
                          ),
                          _HomePetFact(
                            icon: Icons.favorite_rounded,
                            label: 'Status',
                            value: pet.status,
                            color: const Color(0xFFC66078),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomePetFact extends StatelessWidget {
  const _HomePetFact({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedText,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTinyAction extends StatelessWidget {
  const _HomeTinyAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _SoftFloat extends StatefulWidget {
  const _SoftFloat({required this.child, this.offset = 4});

  final Widget child;
  final double offset;

  @override
  State<_SoftFloat> createState() => _SoftFloatState();
}

class _SoftFloatState extends State<_SoftFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _dy;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _dy = Tween<double>(
      begin: -widget.offset,
      end: widget.offset,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dy,
      child: widget.child,
      builder: (context, child) {
        return Transform.translate(offset: Offset(0, _dy.value), child: child);
      },
    );
  }
}

class _HomeShortcutMenu extends StatelessWidget {
  const _HomeShortcutMenu({
    required this.onTapCalendar,
    required this.onTapAssessment,
    required this.onTapAssistant,
    required this.onTapWardrobe,
    required this.onTapHistory,
  });

  final VoidCallback onTapCalendar;
  final VoidCallback onTapAssessment;
  final VoidCallback onTapAssistant;
  final VoidCallback onTapWardrobe;
  final VoidCallback onTapHistory;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _HomeShortcutButton(
              width: itemWidth,
              label: 'Calendar',
              subtitle: 'Plans',
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFFC9932E),
              tint: const Color(0xFFFFF4D6),
              onTap: onTapCalendar,
            ),
            _HomeShortcutButton(
              width: itemWidth,
              label: 'AI Scan',
              subtitle: 'Photo check',
              icon: Icons.health_and_safety_rounded,
              color: AppTheme.primaryColor,
              tint: const Color(0xFFFFE5E1),
              onTap: onTapAssessment,
            ),
            _HomeShortcutButton(
              width: itemWidth,
              label: 'Assistant',
              subtitle: 'Care team',
              icon: Icons.medical_services_rounded,
              color: const Color(0xFF7C8A63),
              tint: const Color(0xFFEFF3E7),
              onTap: onTapAssistant,
            ),
            _HomeShortcutButton(
              width: itemWidth,
              label: 'Records',
              subtitle: 'History',
              icon: Icons.history_rounded,
              color: const Color(0xFFC66078),
              tint: const Color(0xFFFFEAF0),
              onTap: onTapHistory,
            ),
            _HomeShortcutButton(
              width: itemWidth,
              label: 'Style',
              subtitle: 'Wardrobe',
              icon: Icons.checkroom_rounded,
              color: const Color(0xFF9A6A45),
              tint: const Color(0xFFFFEFE1),
              onTap: onTapWardrobe,
            ),
          ],
        );
      },
    );
  }
}

class _HomeShortcutButton extends StatelessWidget {
  const _HomeShortcutButton({
    required this.width,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tint,
    required this.onTap,
  });

  final double width;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: width,
        height: 84,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.16), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.secondaryText,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeMissionPreviewCard extends StatelessWidget {
  const _HomeMissionPreviewCard({
    required this.title,
    required this.reward,
    required this.icon,
    required this.completed,
    required this.bursting,
    required this.onTap,
  });

  final String title;
  final String reward;
  final IconData icon;
  final bool completed;
  final bool bursting;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    final accent = completed ? const Color(0xFF7C8A63) : AppTheme.primaryColor;

    return Builder(
      builder: (context) {
        return AnimatedScale(
          scale: bursting ? 1.025 : 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: InkWell(
            onTap: () {
              final box = context.findRenderObject() as RenderBox?;
              final origin = box == null
                  ? Offset.zero
                  : box.localToGlobal(box.size.center(Offset.zero));
              onTap(origin);
            },
            borderRadius: BorderRadius.circular(26),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFFF1F4EA)
                    : AppTheme.surfaceColor.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: accent.withValues(alpha: 0.14)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: accent, size: 24),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppTheme.secondaryText,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reward,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: completed ? accent : AppTheme.mutedText,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: completed ? accent : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      completed ? Icons.check_rounded : Icons.add_task_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeEmptyPreviewCard extends StatelessWidget {
  const _HomeEmptyPreviewCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.secondaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              actionLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({
    required this.title,
    required this.icon,
    required this.actionLabel,
    required this.actionColor,
    this.onAction,
  });

  final String title;
  final IconData icon;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: actionColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: actionColor, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onAction,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: actionColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              actionLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SoftPulse extends StatefulWidget {
  const _SoftPulse({required this.child});

  final Widget child;

  @override
  State<_SoftPulse> createState() => _SoftPulseState();
}

class _SoftPulseState extends State<_SoftPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ).drive(Tween(begin: 0.96, end: 1.04));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      child: widget.child,
      builder: (context, child) {
        return Transform.scale(scale: _scale.value, child: child);
      },
    );
  }
}

class _SoftNudge extends StatefulWidget {
  const _SoftNudge({required this.child});

  final Widget child;

  @override
  State<_SoftNudge> createState() => _SoftNudgeState();
}

class _SoftNudgeState extends State<_SoftNudge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _offset = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ).drive(Tween(begin: 0, end: 3));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      child: widget.child,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_offset.value, 0),
          child: child,
        );
      },
    );
  }
}

class _ActivityStatTile extends StatelessWidget {
  const _ActivityStatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 28,
                color: AppTheme.secondaryText,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedText.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: AppTheme.secondaryText.withValues(alpha: 0.08),
    );
  }
}

class _MissionActivityCard extends StatelessWidget {
  const _MissionActivityCard({
    required this.icon,
    required this.iconColor,
    required this.surfaceColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color surfaceColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.10),
            blurRadius: 20,
            spreadRadius: -15,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: _SoftPulse(
                      child: Icon(icon, color: Colors.white, size: 23),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(width: 5),
                        const _SoftNudge(
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
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
