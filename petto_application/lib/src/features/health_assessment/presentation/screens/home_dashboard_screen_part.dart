part of 'home_screen.dart';

extension _HomeDashboardScreenPart on _HomeScreenState {
  void _triggerMission(int missionId, Offset origin) {
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
    controller.completeMission(missionId);

    // Unlock the matching wardrobe item and tell the user.
    final reward = _HomeScreenState._accessoryForMission(mission.missionType);
    if (reward != null && !_unlockedAccessoryIds.contains(reward.id)) {
      _update(() => _unlockedAccessoryIds.add(reward.id));
      showTopAlert(
        context,
        'Unlocked ${reward.emoji} ${reward.name}!',
        icon: Icons.celebration_rounded,
      );
    }

    Timer(const Duration(milliseconds: 950), () {
      if (!mounted) return;
      _update(() {
        _showConfetti = false;
        _burstMissionId = null;
      });
    });
  }

  void _selectPet(int index) {
    _activePetIndex = index;
    _loadDraftForPet(index);

    // Sync petId with AuthController for other features (health assessment, etc.)
    final selectedPet = _pets[index];
    context.read<AuthController>().setPetId(selectedPet.id);

    // Reload health assessment history for the newly selected pet
    context.read<HealthAssessmentController>().loadPetHistory(selectedPet.id);

    // Reload missions and stats for the newly selected pet
    context.read<MissionsController>().loadAll(petId: selectedPet.id);
    context.read<ActivityTrackingController>().loadStats(petId: selectedPet.id);
  }

  Widget _buildDashboardView(BuildContext context) {
    return Consumer<MissionsController>(
      builder: (context, mc, _) {
        final stats = mc.dashboardStats;
        final missions = mc.missions;
        final happiness = stats.happinessPercent;
        final energy = stats.energyPercent;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 72,
                child: ListView.separated(
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  scrollDirection: Axis.horizontal,
                  itemCount: _pets.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == _pets.length) {
                      return _AddPetChip(onTap: _addPet);
                    }
                    final pet = _pets[index];
                    final appearance =
                        _savedAppearances[index] ??
                        _defaultAppearanceForSpecies(pet.species);
                    final selected = index == _activePetIndex;
                    return _PetChip(
                      pet: pet,
                      appearance: appearance,
                      selected: selected,
                      onTap: () {
                        _update(() {
                          _selectPet(index);
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Container(
                height: 280,
                margin: const EdgeInsets.only(bottom: 34),
                child: Column(
                  children: [
                    Expanded(
                      child: _RoomStage(
                        showActionMenu: _showActionMenu,
                        petSpecies: _activeAppearance.species,
                        petColor: _colorFromHex(_activeAppearance.colorHex),
                        petPattern: _activeAppearance.pattern,
                        equipped: _activeAppearance.equipped.toList(
                          growable: false,
                        ),
                        eyeType: _activeAppearance.eyeType,
                        mouthType: _activeAppearance.mouthType,
                        onToggleMenu: () {
                          _update(() {
                            _showActionMenu = !_showActionMenu;
                          });
                        },
                        onTapAssessment: () {
                          _update(() {
                            _showActionMenu = false;
                            _assessmentModalTitle = 'Smart AI Scan';
                            _showAssessment = true;
                          });
                        },
                        onTapWardrobe: () {
                          _update(() {
                            _showActionMenu = false;
                            _openWardrobe();
                          });
                        },
                        onTapProfile: () {
                          _update(() {
                            _activeView = _View.profile;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _activePet.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.successColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _activePet.status.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Happiness',
                      value: '$happiness',
                      suffix: '%',
                      icon: Icons.favorite_rounded,
                      color: AppTheme.primaryColor,
                      progress: happiness / 100.0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      title: 'Energy',
                      value: '$energy',
                      suffix: '%',
                      icon: Icons.bolt_rounded,
                      color: AppTheme.accentColor,
                      progress: energy / 100.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildHomeCalendarSection(context),
              const SizedBox(height: 28),
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
                      '${mc.completedCount}/${mc.totalCount} done',
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
                    rewardAccessory:
                        _HomeScreenState._accessoryForMission(mission.missionType),
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
                    rewardAccessory:
                        _HomeScreenState._accessoryForMission(mission.missionType),
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
    void startWalk() {
      final controller = context.read<ActivityTrackingController>();
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => LiveWalkScreen(petName: _activePet.name),
            ),
          )
          .then((_) => controller.loadStats());
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
                      : () => controller.loadStats(),
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
              actionLabel: 'Soon',
              enabled: false,
              onTap: () {},
            ),
          ],
        );
      },
    );
  }
}

class _SoftPulse extends StatefulWidget {
  const _SoftPulse({required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

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
    if (!widget.enabled) return widget.child;
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
    this.enabled = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? iconColor : AppTheme.mutedText;
    return Opacity(
      opacity: enabled ? 1 : 0.56,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(30),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCardDecoration(
                color: enabled
                    ? Colors.white
                    : AppTheme.creamSurfaceColor.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(30),
                borderColor: effectiveColor.withValues(
                  alpha: enabled ? 0.18 : 0.08,
                ),
                hasShadow: false,
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: enabled
                          ? effectiveColor
                          : effectiveColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _SoftPulse(
                      enabled: enabled,
                      child: Icon(
                        icon,
                        color: enabled ? Colors.white : effectiveColor,
                        size: 26,
                      ),
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
                      color: enabled
                          ? AppTheme.creamSurfaceColor.withValues(alpha: 0.72)
                          : AppTheme.secondaryText.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: enabled
                                    ? AppTheme.primaryColor
                                    : AppTheme.mutedText,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        if (enabled) ...[
                          const SizedBox(width: 5),
                          const _SoftNudge(
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
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
