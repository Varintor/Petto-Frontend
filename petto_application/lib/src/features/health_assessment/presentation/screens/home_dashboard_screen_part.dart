part of 'home_screen.dart';

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
        final previewMissions = missions.take(2).toList(growable: false);
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
                              petName: _activePet.name,
                              status: _activePet.status,
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
                              missions: previewMissions,
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
                  border: Border.all(
                    color: AppTheme.blushSurfaceColor,
                    width: 2,
                  ),
                  boxShadow: AppTheme.cardShadow,
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
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$completedCount/$totalCount done',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (mc.missionsLoading && missions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                for (final mission in missions) ...[
                  _MissionCard(
                    mission: _MissionData(
                      id: mission.id.toString(),
                      title: mission.title,
                      reward: mission.rewardDisplay,
                      icon: mission.icon,
                    ),
                    rewardAccessory: _HomeScreenState._accessoryForMission(
                      mission.missionType,
                    ),
                    completed: mission.isCompleted,
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
            MaterialPageRoute(
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
              decoration: AppTheme.glassCardDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                borderColor: AppTheme.primaryColor.withValues(alpha: 0.22),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.directions_walk_rounded,
                          color: AppTheme.primaryColor,
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
                          color: AppTheme.blushSurfaceColor.withValues(
                            alpha: 0.74,
                          ),
                          borderRadius: BorderRadius.circular(999),
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: const LinearProgressIndicator(
                                minHeight: 3,
                              ),
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
              title: 'Start a Walk',
              subtitle:
                  'Live GPS tracking - distance, time and pace for ${_activePet.name}.',
              actionLabel: 'Start',
              onTap: startWalk,
            ),
            const SizedBox(height: 12),
            _MissionActivityCard(
              icon: Icons.sensors_rounded,
              iconColor: AppTheme.secondaryColor,
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
      height: 56,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: pets.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == pets.length) {
            return _HomePetSwitcherItem.add(onTap: onAdd);
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
  }) : isAdd = false;

  const _HomePetSwitcherItem.add({required this.onTap})
    : pet = null,
      appearance = null,
      selected = false,
      isAdd = true;

  final _PetData? pet;
  final _PetAppearanceData? appearance;
  final bool selected;
  final bool isAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 52,
        constraints: BoxConstraints(minWidth: isAdd ? 54 : 114),
        padding: EdgeInsets.fromLTRB(isAdd ? 0 : 6, 6, isAdd ? 0 : 16, 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : const Color(0xFFFFFEFB),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withValues(alpha: 0.12),
            width: 1.3,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.16),
                    blurRadius: 18,
                    spreadRadius: -10,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: isAdd
            ? Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.blushSurfaceColor.withValues(alpha: 0.82),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : AppTheme.blushSurfaceColor,
                      shape: BoxShape.circle,
                    ),
                    child: _SpeciesAvatarIcon(
                      species: appearance!.species,
                      appearance: appearance!,
                      size: 35,
                      dimmed: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 82),
                    child: Text(
                      pet!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected ? Colors.white : AppTheme.secondaryText,
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
                              Colors.black.withValues(
                                alpha: isNight ? 0.12 : 0,
                              ),
                              Colors.transparent,
                              const Color(0xFF2D201B).withValues(alpha: 0.14),
                            ],
                            stops: const [0, 0.48, 1],
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
    for (var layer = 0; layer < 2; layer++) {
      final foreground = layer == 1;
      final rain = Paint()
        ..color = Colors.white.withValues(
          alpha: foreground
              ? (weather == _GardenWeather.stormy ? 0.58 : 0.43)
              : 0.22,
        )
        ..strokeWidth = foreground ? 1.45 : 0.85
        ..strokeCap = StrokeCap.round;
      final count = foreground ? 24 : 18;
      final speed = foreground ? 250.0 : 170.0;
      for (var i = 0; i < count; i++) {
        final x =
            (i * (foreground ? 43.0 : 61.0) +
                    progress * (foreground ? 105 : 70)) %
                (size.width + 40) -
            20;
        final y =
            (i * (foreground ? 59.0 : 71.0) + progress * speed) %
            (size.height + 30);
        final length = foreground ? 15.0 : 10.0;
        canvas.drawLine(Offset(x, y), Offset(x - 5, y + length), rain);
      }
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
            ? const [Color(0xFF253C4A), Color(0xFF51666E), Color(0xFF9AA9A1)]
            : isNight
            ? const [Color(0xFF2D2545), Color(0xFF51466B), Color(0xFFB38C84)]
            : weather == _GardenWeather.cloudy ||
                  weather == _GardenWeather.rainy
            ? const [Color(0xFFD9E5E7), Color(0xFFE9E0D2), Color(0xFFB9D4B0)]
            : const [Color(0xFFBFE6F2), Color(0xFFFFE3C2), Color(0xFFDFF1D3)],
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
          ? const Color(0xFF9D7F58).withValues(alpha: 0.96)
          : const Color(0xFFD9D89A),
      y1: 0.61,
      c1y: 0.53,
      c2y: 0.68,
      y2: 0.54,
    );
    _drawHill(
      canvas,
      size,
      color: isNight ? const Color(0xFF5C8A56) : const Color(0xFF8BCE73),
      y1: 0.70,
      c1y: 0.62,
      c2y: 0.76,
      y2: 0.64,
    );
    _drawGardenTrees(canvas, size);
    _drawBushLine(canvas, size);

    final path = Path()
      ..moveTo(size.width * 0.38, size.height)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.82,
        size.width * 0.50,
        size.height * 0.65,
      )
      ..quadraticBezierTo(
        size.width * 0.56,
        size.height * 0.82,
        size.width * 0.63,
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
    final warm = isNight ? const Color(0xFFFFD7B0) : const Color(0xFFFFCF7C);
    final center = Offset(size.width * 0.64, size.height * 0.20);
    canvas.drawCircle(
      center,
      size.width * 0.18,
      Paint()
        ..shader = ui.Gradient.radial(center, size.width * 0.18, [
          warm.withValues(alpha: isNight ? 0.18 : 0.26),
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
            : const Color(0xFFFFC65C).withValues(alpha: 0.86),
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
      final y = size.height * (i == 2 ? 0.25 : 0.15 + (i % 2) * 0.08);
      final scale = i == 0 ? 0.68 : (i == 1 ? 0.52 : 0.58);
      _drawCloud(canvas, Offset(x, y), scale);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double scale) {
    final width = 112 * scale;
    final height = 38 * scale;
    final path = Path()
      ..moveTo(center.dx - width * 0.52, center.dy + height * 0.20)
      ..cubicTo(
        center.dx - width * 0.56,
        center.dy - height * 0.04,
        center.dx - width * 0.42,
        center.dy - height * 0.28,
        center.dx - width * 0.25,
        center.dy - height * 0.22,
      )
      ..cubicTo(
        center.dx - width * 0.16,
        center.dy - height * 0.66,
        center.dx + width * 0.14,
        center.dy - height * 0.70,
        center.dx + width * 0.25,
        center.dy - height * 0.29,
      )
      ..cubicTo(
        center.dx + width * 0.43,
        center.dy - height * 0.31,
        center.dx + width * 0.55,
        center.dy - height * 0.08,
        center.dx + width * 0.49,
        center.dy + height * 0.17,
      )
      ..cubicTo(
        center.dx + width * 0.29,
        center.dy + height * 0.34,
        center.dx - width * 0.33,
        center.dy + height * 0.36,
        center.dx - width * 0.52,
        center.dy + height * 0.20,
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
      path.shift(Offset(0, 3 * scale)),
      Paint()
        ..color = const Color(
          0xFF202D35,
        ).withValues(alpha: weather == _GardenWeather.stormy ? 0.10 : 0.035)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * scale),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(bounds.topCenter, bounds.bottomCenter, [
          topColor.withValues(alpha: isNight ? opacity * 0.64 : opacity),
          bottomColor.withValues(alpha: isNight ? opacity * 0.42 : opacity),
        ])
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.7),
    );
    canvas.drawPath(
      path.shift(Offset(0, -1.1 * scale)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = scale
        ..color = Colors.white.withValues(alpha: isNight ? 0.07 : 0.22),
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
    final back = isNight ? const Color(0xFF405E50) : const Color(0xFF9CCB91);
    final front = isNight ? const Color(0xFF315344) : const Color(0xFF72AE70);

    for (var row = 0; row < 2; row++) {
      final paint = Paint()
        ..color = (row == 0 ? back : front).withValues(
          alpha: row == 0 ? 0.48 : 0.64,
        );
      final path = Path()..moveTo(0, baseY + row * 9);
      for (var i = 0; i <= 18; i++) {
        final x = size.width * i / 18;
        final crown = 20.0 + ((i * 17 + row * 11) % 26);
        final y = baseY - crown + row * 10;
        path
          ..lineTo(x - 8, baseY + row * 9)
          ..quadraticBezierTo(x - 5, y + 8, x, y)
          ..quadraticBezierTo(x + 7, y + 9, x + 10, baseY + row * 9);
      }
      path
        ..lineTo(size.width, baseY + 34)
        ..lineTo(0, baseY + 34)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawGardenTrees(Canvas canvas, Size size) {
    void drawTree({
      required Offset root,
      required double scale,
      required bool mirror,
    }) {
      final sign = mirror ? -1.0 : 1.0;
      final trunkColor = isNight
          ? const Color(0xFF5A4B45)
          : const Color(0xFF9B7355);
      final trunk = Paint()
        ..color = trunkColor.withValues(alpha: isNight ? 0.66 : 0.74)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8.5 * scale;
      final trunkPath = Path()
        ..moveTo(root.dx, root.dy)
        ..cubicTo(
          root.dx + sign * 4 * scale,
          root.dy - 30 * scale,
          root.dx - sign * 6 * scale,
          root.dy - 57 * scale,
          root.dx + sign * 1 * scale,
          root.dy - 84 * scale,
        );
      canvas.drawPath(trunkPath, trunk);

      final branch = Paint()
        ..color = trunk.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.4 * scale;
      canvas.drawLine(
        root.translate(sign * 1 * scale, -61 * scale),
        root.translate(sign * 28 * scale, -91 * scale),
        branch,
      );
      canvas.drawLine(
        root.translate(-sign * 2 * scale, -50 * scale),
        root.translate(-sign * 21 * scale, -78 * scale),
        branch,
      );

      final canopyCenter = root.translate(sign * 4 * scale, -105 * scale);
      final deep = isNight ? const Color(0xFF2E5849) : const Color(0xFF6AAA5C);
      final mid = isNight ? const Color(0xFF47705A) : const Color(0xFF88C46E);
      final bright = isNight
          ? const Color(0xFF6E8F6D)
          : const Color(0xFFB8DD85);
      final shadow = Paint()
        ..color = const Color(
          0xFF2D201B,
        ).withValues(alpha: isNight ? 0.14 : 0.05)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * scale);
      final canopySpecs = [
        (Offset(-42 * sign, 10), 48.0, 42.0, deep, 0.90),
        (Offset(-27 * sign, -14), 54.0, 50.0, mid, 0.92),
        (Offset(3 * sign, -25), 58.0, 53.0, mid, 0.96),
        (Offset(32 * sign, -8), 50.0, 45.0, deep, 0.88),
        (Offset(22 * sign, 20), 50.0, 36.0, mid, 0.82),
        (Offset(-12 * sign, 23), 56.0, 38.0, deep, 0.80),
      ];

      for (final spec in canopySpecs) {
        final center = canopyCenter.translate(
          spec.$1.dx * scale,
          spec.$1.dy * scale,
        );
        final rect = Rect.fromCenter(
          center: center,
          width: spec.$2 * scale,
          height: spec.$3 * scale,
        );
        canvas.drawOval(rect.shift(Offset(0, 3 * scale)), shadow);
        canvas.drawOval(
          rect,
          Paint()..color = spec.$4.withValues(alpha: spec.$5),
        );
      }

      final highlight = Paint()
        ..color = bright.withValues(alpha: isNight ? 0.16 : 0.34);
      for (final offset in [
        Offset(-20 * sign, -24),
        Offset(11 * sign, -32),
        Offset(31 * sign, 0),
      ]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: canopyCenter.translate(
              offset.dx * scale,
              offset.dy * scale,
            ),
            width: 30 * scale,
            height: 14 * scale,
          ),
          highlight,
        );
      }
    }

    drawTree(
      root: Offset(size.width * 0.09, size.height * 0.73),
      scale: math.min(size.width / 470, 1.06),
      mirror: false,
    );
    drawTree(
      root: Offset(size.width * 0.92, size.height * 0.71),
      scale: math.min(size.width / 500, 1.0),
      mirror: true,
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

    final backPaint = Paint()
      ..color = (isNight ? const Color(0xFF497756) : const Color(0xFFA9D982))
          .withValues(alpha: isNight ? 0.64 : 0.76);
    final frontPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, baseY - 32),
        Offset(0, baseY + 54),
        isNight
            ? const [Color(0xFF5C8C62), Color(0xFF39704F)]
            : const [Color(0xFFB8E58D), Color(0xFF75C66B)],
      );

    for (var i = 0; i <= 9; i++) {
      final x = -24 + (size.width + 48) * i / 9;
      final y = baseY + 20 + ((i * 13) % 10);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 78 + ((i * 17) % 28),
          height: 43 + ((i * 11) % 14),
        ),
        backPaint,
      );
    }
    for (var i = 0; i <= 12; i++) {
      final x = -28 + (size.width + 56) * i / 12;
      final y = baseY + 16 + ((i * 19) % 12);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 64 + ((i * 23) % 25),
          height: 38 + ((i * 7) % 12),
        ),
        frontPaint,
      );
    }

    final leafPaint = Paint()
      ..color = Colors.white.withValues(alpha: isNight ? 0.08 : 0.18);
    for (var i = 0; i < 20; i++) {
      final x = size.width * ((i * 37 % 97) / 96);
      final y = baseY + 12 + ((i * 13) % 30);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((i.isEven ? -0.45 : 0.45));
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 3.4),
        leafPaint,
      );
      canvas.restore();
    }

    final flowerPaints = [
      Paint()
        ..color = const Color(
          0xFFFFD16E,
        ).withValues(alpha: isNight ? 0.72 : 0.92),
      Paint()
        ..color = const Color(
          0xFFFFA7B5,
        ).withValues(alpha: isNight ? 0.66 : 0.88),
      Paint()..color = Colors.white.withValues(alpha: isNight ? 0.72 : 0.92),
    ];
    for (var i = 0; i < 14; i++) {
      final row = i % 2;
      final x = size.width * (0.08 + (i % 7) * 0.14) + (row == 0 ? 0 : 12);
      if (x > size.width * 0.10 && x < size.width * 0.25) continue;
      if (x > size.width * 0.79 && x < size.width * 0.93) continue;
      if (x > size.width * 0.40 && x < size.width * 0.61) continue;
      final y = baseY + 10 + row * 18 + ((i * 5) % 7);
      final flutter = math.sin(progress * math.pi * 2 + i) * 0.8;
      final center = Offset(x + flutter, y);
      final paint = flowerPaints[i % flowerPaints.length];
      canvas.drawCircle(center, 2.3, paint);
      canvas.drawCircle(center.translate(2.4, -0.5), 1.6, paint);
    }
  }

  void _drawGrassTexture(Canvas canvas, Size size) {
    final grass = Paint()
      ..color = (isNight ? const Color(0xFFB0C69A) : const Color(0xFF4F914E))
          .withValues(alpha: isNight ? 0.18 : 0.25)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 36; i++) {
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
    for (var i = 0; i < 26; i++) {
      final x = size.width * (0.05 + (i % 9) * 0.112) + (i ~/ 9) * 8;
      if (x > size.width * 0.10 && x < size.width * 0.24) continue;
      if (x > size.width * 0.79 && x < size.width * 0.93) continue;
      if (x > size.width * 0.42 && x < size.width * 0.58) continue;
      final y = size.height * (0.69 + ((i * 11) % 19) / 100);
      final sway = math.sin(progress * math.pi * 2 + i) * 1.8;
      final stem = Paint()
        ..color = (isNight ? const Color(0xFFEAF5DD) : const Color(0xFF557A46))
            .withValues(alpha: isNight ? 0.34 : 0.42)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, y + 8), Offset(x + sway, y), stem);
      canvas.drawCircle(
        Offset(x + sway, y),
        i.isEven ? 2.6 : 2.1,
        Paint()
          ..color = flowerColors[i % flowerColors.length].withValues(
            alpha: 0.86,
          ),
      );
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
          center: base.translate(0, 17 * scale),
          width: 68 * scale,
          height: 14 * scale,
        ),
        Paint()..color = Colors.black.withValues(alpha: isNight ? 0.13 : 0.08),
      );
      final bodyPath = Path()
        ..moveTo(base.dx - 24 * scale, base.dy - 7 * scale)
        ..quadraticBezierTo(
          base.dx - 22 * scale,
          base.dy + 15 * scale,
          base.dx - 12 * scale,
          base.dy + 20 * scale,
        )
        ..lineTo(base.dx + 12 * scale, base.dy + 20 * scale)
        ..quadraticBezierTo(
          base.dx + 22 * scale,
          base.dy + 15 * scale,
          base.dx + 24 * scale,
          base.dy - 7 * scale,
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
            width: 54 * scale,
            height: 13 * scale,
          ),
          Radius.circular(10 * scale),
        ),
        Paint()..color = pot.withValues(alpha: 0.98),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: base.translate(0, -11 * scale),
            width: 45 * scale,
            height: 6 * scale,
          ),
          Radius.circular(6 * scale),
        ),
        Paint()..color = Colors.white.withValues(alpha: isNight ? 0.16 : 0.30),
      );

      drawLeaf(
        base.translate(sign * -15 * scale, -25 * scale),
        sign * -0.55,
        scale,
        leafA,
      );
      drawLeaf(
        base.translate(sign * -3 * scale, -32 * scale),
        sign * -0.08,
        scale * 1.05,
        leafB,
      );
      drawLeaf(
        base.translate(sign * 13 * scale, -24 * scale),
        sign * 0.55,
        scale,
        leafA,
      );
      canvas.drawLine(
        base.translate(0, -6 * scale),
        base.translate(0, -27 * scale),
        Paint()
          ..color = leafA.withValues(alpha: isNight ? 0.38 : 0.58)
          ..strokeWidth = 1.4 * scale
          ..strokeCap = StrokeCap.round,
      );
      final bloomColor = flip
          ? const Color(0xFFFFD16E)
          : const Color(0xFFFF9FAE);
      canvas.drawCircle(
        base.translate(sign * 2 * scale, -34 * scale),
        3.6 * scale,
        Paint()..color = bloomColor.withValues(alpha: isNight ? 0.70 : 0.92),
      );
      canvas.drawCircle(
        base.translate(sign * -8 * scale, -28 * scale),
        2.8 * scale,
        Paint()
          ..color = const Color(
            0xFFFFF4DE,
          ).withValues(alpha: isNight ? 0.56 : 0.88),
      );
      canvas.drawCircle(
        base.translate(sign * 10 * scale, -30 * scale),
        2.4 * scale,
        Paint()
          ..color = const Color(
            0xFFFFC96D,
          ).withValues(alpha: isNight ? 0.60 : 0.90),
      );
    }

    void drawDogHouse(Offset base, double scale) {
      final shadow = Paint()
        ..color = Colors.black.withValues(alpha: isNight ? 0.14 : 0.08);
      canvas.drawOval(
        Rect.fromCenter(
          center: base.translate(0, 17 * scale),
          width: 82 * scale,
          height: 15 * scale,
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

      final body = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: base.translate(0, -2 * scale),
          width: 58 * scale,
          height: 46 * scale,
        ),
        Radius.circular(13 * scale),
      );
      canvas.drawRRect(
        body.inflate(2.0 * scale),
        Paint()..color = Colors.white.withValues(alpha: isNight ? 0.10 : 0.48),
      );
      canvas.drawRRect(body, Paint()..color = wallColor);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            body.outerRect.left,
            body.outerRect.top,
            body.outerRect.width * 0.34,
            body.outerRect.height,
          ),
          Radius.circular(13 * scale),
        ),
        Paint()..color = sideColor.withValues(alpha: 0.70),
      );

      final roof = Path()
        ..moveTo(base.dx - 39 * scale, base.dy - 17 * scale)
        ..quadraticBezierTo(
          base.dx,
          base.dy - 54 * scale,
          base.dx + 39 * scale,
          base.dy - 17 * scale,
        )
        ..quadraticBezierTo(
          base.dx + 34 * scale,
          base.dy - 9 * scale,
          base.dx + 27 * scale,
          base.dy - 10 * scale,
        )
        ..lineTo(base.dx - 27 * scale, base.dy - 10 * scale)
        ..quadraticBezierTo(
          base.dx - 34 * scale,
          base.dy - 9 * scale,
          base.dx - 39 * scale,
          base.dy - 17 * scale,
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

      final door = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: base.translate(0, 8 * scale),
          width: 25 * scale,
          height: 29 * scale,
        ),
        Radius.circular(12 * scale),
      );
      canvas.drawRRect(
        door,
        Paint()
          ..shader = ui.Gradient.linear(
            door.outerRect.topCenter,
            door.outerRect.bottomCenter,
            isNight
                ? const [Color(0xFF3C2730), Color(0xFF251D22)]
                : const [Color(0xFF7B3034), Color(0xFF522327)],
          ),
      );
      canvas.drawCircle(
        base.translate(0, 3 * scale),
        3 * scale,
        Paint()..color = trimColor,
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

      final bonePaint = Paint()
        ..color = Colors.white.withValues(alpha: isNight ? 0.70 : 0.92);
      final boneCenter = base.translate(18 * scale, -3 * scale);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: boneCenter,
            width: 18 * scale,
            height: 5 * scale,
          ),
          Radius.circular(999),
        ),
        bonePaint,
      );
      canvas.drawCircle(
        boneCenter.translate(-8 * scale, 0),
        3 * scale,
        bonePaint,
      );
      canvas.drawCircle(
        boneCenter.translate(8 * scale, 0),
        3 * scale,
        bonePaint,
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

    drawDogHouse(Offset(size.width * 0.15, size.height * 0.80), 0.80);
    drawPlanter(
      Offset(size.width * 0.86, size.height * 0.81),
      0.84,
      flip: true,
    );
    drawGardenLight(Offset(size.width * 0.08, size.height * 0.68), 0.90);
    drawGardenLight(Offset(size.width * 0.91, size.height * 0.67), 0.82);
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(999),
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
    required this.petName,
    required this.status,
    required this.nextPlan,
    required this.completedMissions,
    required this.totalMissions,
  });

  final String petName;
  final String status;
  final CalendarEventData? nextPlan;
  final int completedMissions;
  final int totalMissions;

  @override
  Widget build(BuildContext context) {
    final nextPlanTitle = nextPlan?.title ?? 'No plan today';
    final nextPlanMeta = nextPlan?.timeLabel ?? 'Add a care plan when needed';
    final missionLabel = totalMissions == 0
        ? 'No missions'
        : '$completedMissions/$totalMissions done';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HomeSectionTitle(title: 'Today', trailing: missionLabel),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFEFB).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                blurRadius: 16,
                spreadRadius: -14,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HomeTodayInfoRow(
                icon: Icons.favorite_rounded,
                title: petName,
                subtitle: status,
                color: AppTheme.primaryColor,
                tint: const Color(0xFFFFE6E2),
              ),
              const SizedBox(height: 8),
              _HomeTodayInfoRow(
                icon: nextPlan?.icon ?? Icons.event_available_rounded,
                title: nextPlanTitle,
                subtitle: nextPlanMeta,
                color: nextPlan?.color ?? const Color(0xFFC9932E),
                tint: const Color(0xFFFFF1D0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeTodayInfoRow extends StatelessWidget {
  const _HomeTodayInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    letterSpacing: 0,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    height: 1.12,
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
        onTapAssessment,
      ),
      _HomeQuickCareData(
        'Calendar',
        Icons.calendar_month_rounded,
        const Color(0xFFFFE9B8),
        const Color(0xFFB98422),
        onTapCalendar,
      ),
      _HomeQuickCareData(
        'Assistant',
        Icons.medical_services_rounded,
        const Color(0xFFE4F0DA),
        const Color(0xFF657B4F),
        onTapAssistant,
      ),
      _HomeQuickCareData(
        'Records',
        Icons.folder_copy_rounded,
        const Color(0xFFDDF1F4),
        const Color(0xFF4D7B86),
        onTapHistory,
      ),
      _HomeQuickCareData(
        'Style',
        Icons.checkroom_rounded,
        const Color(0xFFEFE1F5),
        const Color(0xFF7E638F),
        onTapWardrobe,
      ),
    ];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
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
    this.onTap,
  );

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
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
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: data.background,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.85),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: data.foreground.withValues(alpha: 0.13),
                          blurRadius: 18,
                          spreadRadius: -10,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFEFB).withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(data.icon, color: data.foreground, size: 21),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
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
            Container(
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFEFB).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                ),
              ),
              child: const CircularProgressIndicator(strokeWidth: 2.5),
            )
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
    final color = mission.isCompleted
        ? AppTheme.primaryColor
        : const Color(0xFFC9932E);
    return Builder(
      builder: (context) => AnimatedScale(
        scale: bursting ? 1.02 : 1,
        duration: const Duration(milliseconds: 180),
        child: InkWell(
          onTap: () {
            final box = context.findRenderObject() as RenderBox?;
            final origin = box == null
                ? Offset.zero
                : box.localToGlobal(box.size.center(Offset.zero));
            onTap(origin);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 92),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFEFB).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.14),
                width: 1.25,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                  blurRadius: 18,
                  spreadRadius: -14,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(20),
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
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            mission.rewardDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
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
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: mission.isCompleted ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.20),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    mission.isCompleted ? Icons.check_rounded : Icons.circle,
                    color: mission.isCompleted
                        ? Colors.white
                        : Colors.transparent,
                    size: mission.isCompleted ? 22 : 1,
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
          color: const Color(0xFFFFFEFB).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.14),
            width: 1.25,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(20),
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
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassCardDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              borderColor: iconColor.withValues(alpha: 0.18),
              hasShadow: false,
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _SoftPulse(
                    child: Icon(icon, color: Colors.white, size: 26),
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
                    color: AppTheme.creamSurfaceColor.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(999),
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
    );
  }
}
