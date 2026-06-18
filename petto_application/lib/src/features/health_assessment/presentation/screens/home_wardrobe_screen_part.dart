part of 'home_screen.dart';

extension _HomeWardrobeScreenPart on _HomeScreenState {
  void _openWardrobe() {
    _loadDraftForPet(_activePetIndex);
    _activeView = _View.wardrobe;
  }

  void _loadDraftForPet(int index) {
    // Authenticated users start with _pets empty until /users/{id}/pets returns.
    // Touching _pets[index] before then crashes with RangeError; bail out and
    // let the next pet selection re-load the draft once data arrives.
    if (index < 0 || index >= _pets.length) return;
    final appearance =
        _savedAppearances[index] ??
        _defaultAppearanceForSpecies(_pets[index].species);
    _selectedSpecies = appearance.species;
    _selectedColor = appearance.colorHex;
    _selectedEyeType = appearance.eyeType;
    _selectedMouthType = appearance.mouthType;
    _selectedPattern = appearance.pattern;
    _draftEquippedAccessoryIds
      ..clear()
      ..addAll(appearance.equipped);
  }

  void _saveWardrobe() {
    final appearance = _PetAppearanceData(
      species: _selectedSpecies,
      colorHex: _selectedColor,
      eyeType: _selectedEyeType,
      mouthType: _selectedMouthType,
      pattern: _selectedPattern,
      equipped: _draftEquippedAccessoryIds.toSet(),
    );
    _update(() {
      _savedAppearances[_activePetIndex] = appearance;
    });
    showTopAlert(context, 'Wardrobe saved.');
  }

  bool _hasWardrobeChanges() {
    final appearance = _activeAppearance;
    return appearance.species != _selectedSpecies ||
        appearance.colorHex != _selectedColor ||
        appearance.eyeType != _selectedEyeType ||
        appearance.mouthType != _selectedMouthType ||
        appearance.pattern != _selectedPattern ||
        appearance.equipped.length != _draftEquippedAccessoryIds.length ||
        !appearance.equipped.containsAll(_draftEquippedAccessoryIds);
  }

  Widget _buildWardrobeView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Wardrobe',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              _SquareIconButton(
                icon: Icons.close_rounded,
                onTap: () {
                  _update(() {
                    _loadDraftForPet(_activePetIndex);
                    _activeView = _View.dashboard;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Container(
              width: 232,
              height: 232,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(42),
                boxShadow: AppTheme.subtleShadow,
              ),
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, 10),
                  child: SizedBox(
                    width: 168,
                    height: 168,
                    child: PetAvatarWidget(
                      species: _selectedSpecies,
                      color: _colorFromHex(_selectedColor),
                      pattern: _selectedPattern,
                      equipped: _draftEquippedAccessoryIds.toList(
                        growable: false,
                      ),
                      eyeType: _selectedEyeType,
                      mouthType: _selectedMouthType,
                      isRotating: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          _WardrobeSection(
            title: 'Species',
            child: Row(
              children: [
                Expanded(
                  child: _SelectionChip(
                    label: 'Dog',
                    selected: _selectedSpecies == 'Dog',
                    leading: _SpeciesChoiceIcon(
                      species: 'Dog',
                      size: 24,
                      dimmed: _selectedSpecies != 'Dog',
                    ),
                    onTap: () {
                      _update(() {
                        _selectedSpecies = 'Dog';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SelectionChip(
                    label: 'Cat',
                    selected: _selectedSpecies == 'Cat',
                    leading: _SpeciesChoiceIcon(
                      species: 'Cat',
                      size: 24,
                      dimmed: _selectedSpecies != 'Cat',
                    ),
                    onTap: () {
                      _update(() {
                        _selectedSpecies = 'Cat';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          _WardrobeSection(
            title: 'Fur Colors',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final color in const [
                    '#C83F4E',
                    '#7B3034',
                    '#C98287',
                    '#FFE1D9',
                    '#C47A45',
                    '#FFFFFF',
                  ]) ...[
                    _ColorSwatchButton(
                      colorHex: color,
                      selected: _selectedColor == color,
                      onTap: () {
                        _update(() {
                          _selectedColor = color;
                        });
                      },
                    ),
                    if (color != '#FFFFFF') const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
          ),
          _WardrobeSection(
            title: 'Eye Types',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final item in const [
                  'default',
                  'happy',
                  'wink',
                  'cool',
                  'sleepy',
                  'angry',
                  'star',
                ])
                  _MiniSelectionCard(
                    label: item,
                    selected: _selectedEyeType == item,
                    onTap: () {
                      _update(() {
                        _selectedEyeType = item;
                      });
                    },
                  ),
              ],
            ),
          ),
          _WardrobeSection(
            title: 'Mouth Types',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final item in const [
                  'default',
                  'smile',
                  'pout',
                  'surprised',
                  'tongue',
                  'cat',
                ])
                  _MiniSelectionCard(
                    label: item,
                    selected: _selectedMouthType == item,
                    onTap: () {
                      _update(() {
                        _selectedMouthType = item;
                      });
                    },
                  ),
              ],
            ),
          ),
          _WardrobeSection(
            title: 'Patterns',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final item in const [
                  'none',
                  'spots',
                  'stripes',
                  'patches',
                  'tabby',
                ])
                  _MiniSelectionCard(
                    label: item,
                    selected: _selectedPattern == item,
                    onTap: () {
                      _update(() {
                        _selectedPattern = item;
                      });
                    },
                  ),
              ],
            ),
          ),
          _WardrobeSection(
            title: 'Accessories',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final accessory in _HomeScreenState._accessories)
                  _AccessoryCard(
                    accessory: accessory,
                    unlocked: _isAccessoryUnlocked(accessory),
                    equipped: _draftEquippedAccessoryIds.contains(accessory.id),
                    onTap: _isAccessoryUnlocked(accessory)
                        ? () {
                            _update(() {
                              if (_draftEquippedAccessoryIds.contains(
                                accessory.id,
                              )) {
                                _draftEquippedAccessoryIds.remove(accessory.id);
                              } else {
                                _draftEquippedAccessoryIds.add(accessory.id);
                              }
                            });
                          }
                        : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _hasWardrobeChanges() ? _saveWardrobe : null,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save Look'),
            ),
          ),
        ],
      ),
    );
  }
}
