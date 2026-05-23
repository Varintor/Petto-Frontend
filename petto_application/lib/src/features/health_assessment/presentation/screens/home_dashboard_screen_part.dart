part of 'home_screen.dart';

extension _HomeDashboardScreenPart on _HomeScreenState {
  void _triggerMission(String id, Offset origin) {
    if (_completedMissionIds.contains(id)) return;
    _update(() {
      _completedMissionIds.add(id);
      _showConfetti = true;
      _confettiOrigin = origin;
      _confettiSeed++;
      _burstMissionId = id;
    });
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
  }

  Widget _buildDashboardView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 58,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _HomeScreenState._pets.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == _HomeScreenState._pets.length) {
                  return _AddPetChip(
                    onTap: () => _showPreviewSnackBar('Add Pet'),
                  );
                }
                final pet = _HomeScreenState._pets[index];
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
                        color: Color(0xFF4CAF50),
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
                  value: '85',
                  suffix: '%',
                  icon: Icons.favorite_rounded,
                  color: AppTheme.primaryColor,
                  progress: 0.85,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricCard(
                  title: 'Energy',
                  value: '40',
                  suffix: '%',
                  icon: Icons.bolt_rounded,
                  color: AppTheme.accentColor,
                  progress: 0.40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Today's Missions",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '${_completedMissionIds.length} of ${_HomeScreenState._missions.length} done',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final mission in _HomeScreenState._missions) ...[
            _MissionCard(
              mission: mission,
              completed: _completedMissionIds.contains(mission.id),
              bursting: _burstMissionId == mission.id,
              onTap: (origin) => _triggerMission(mission.id, origin),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
