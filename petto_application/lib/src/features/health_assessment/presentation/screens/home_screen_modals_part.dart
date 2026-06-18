part of 'home_screen.dart';

extension _HomeScreenModalsPart on _HomeScreenState {
  Widget _buildAssessmentModal(BuildContext context) {
    return _BottomOverlay(
      expand: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _assessmentModalTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                _SquareIconButton(
                  icon: Icons.close_rounded,
                  onTap: () {
                    _update(() {
                      _showAssessment = false;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: HealthAssessmentScreen(
              embedInScaffold: false,
              compactMode: true,
              initialPetName: _activePet.name,
              initialPetType: _activePet.species.toLowerCase(),
              availablePets: _pets
                  .asMap()
                  .entries
                  .map((entry) {
                    final index = entry.key;
                    final pet = entry.value;
                    final appearance =
                        _savedAppearances[index] ??
                        _defaultAppearanceForSpecies(pet.species);
                    return HealthAssessmentPetOption(
                      id: '${pet.name}_${pet.species}'.toLowerCase(),
                      petId: pet.id,
                      name: pet.name,
                      species: pet.species,
                      breed: pet.breed,
                      colorHex: appearance.colorHex,
                      pattern: appearance.pattern,
                      eyeType: appearance.eyeType,
                      mouthType: appearance.mouthType,
                      equipped: appearance.equipped.toList(growable: false),
                    );
                  })
                  .toList(growable: false),
              onBackToDashboard: () {
                _update(() {
                  _showAssessment = false;
                  _activeView = _View.consult;
                });
              },
              onTalkToVet: () {
                final preferredVet = _HomeScreenState._vets.firstWhere(
                  (vet) => vet.online,
                  orElse: () => _HomeScreenState._vets.first,
                );
                _update(() {
                  _showAssessment = false;
                  _activeView = _View.consult;
                  _activeChatVet = preferredVet;
                });
                _shareAiCheckWithVet(vetOverride: preferredVet);
              },
              onSaveNotes: () {
                _update(() {
                  _showAssessment = false;
                  _showNotesModal = true;
                });
              },
              showHero: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesModal(BuildContext context) {
    return _BottomOverlay(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Consult Notes',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                _SquareIconButton(
                  icon: Icons.close_rounded,
                  onTap: () {
                    _update(() {
                      _showNotesModal = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 5,
              scrollPadding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom + 140,
              ),
              decoration: const InputDecoration(
                hintText: 'Write summary or notes from your vet visit...',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                _update(() {
                  _showNotesModal = false;
                });
                _showPreviewSnackBar('Save Notes');
              },
              child: const Text('Save Notes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyDetailModal(BuildContext context) {
    final node = _selectedNode!;
    return Positioned.fill(
      child: Container(
        color: AppTheme.secondaryColor.withValues(alpha: 0.2),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: AppTheme.glassCardDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(42),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          node.icon,
                          color: AppTheme.primaryColor,
                          size: 30,
                        ),
                      ),
                      const Spacer(),
                      _SquareIconButton(
                        icon: Icons.close_rounded,
                        onTap: () {
                          _update(() {
                            _selectedNode = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    node.tag,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    node.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    node.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () {
                      _update(() {
                        _selectedNode = null;
                        if (node.id == '3') {
                          _showAssessment = true;
                        }
                      });
                    },
                    child: Text(
                      node.completed
                          ? 'Completed'
                          : node.id == '5'
                          ? 'Claim Reward'
                          : 'Complete Task',
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
