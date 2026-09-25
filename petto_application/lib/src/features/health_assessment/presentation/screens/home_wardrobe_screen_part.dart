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
      ..addAll(
        context.read<AuthController>().userId == null
            ? appearance.equipped
            : {
                if (_wardrobeController.equippedId != null)
                  _wardrobeController.equippedId!,
              },
      );
  }

  Future<void> _saveWardrobe() async {
    if (context.read<AuthController>().userId != null) {
      await _wardrobeController.setEquipped(
        _draftEquippedAccessoryIds.firstOrNull,
      );
      if (!mounted) return;
    }
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
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Wardrobe',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  _update(() {
                    _loadDraftForPet(_activePetIndex);
                    _activeView = _View.profile;
                  });
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _homeRoseSurface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Container(
              width: 232,
              height: 232,
              decoration: BoxDecoration(
                color: _homeRoseSurface,
                borderRadius: BorderRadius.circular(42),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.09),
                    blurRadius: 22,
                    spreadRadius: -14,
                    offset: const Offset(0, 14),
                  ),
                ],
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
                    '#D87986',
                    '#E69A8D',
                    '#D88F62',
                    '#B9876A',
                    '#F2B6C0',
                    '#FFD9C9',
                    '#CFA7B0',
                    '#F7F0EA',
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
                    if (color != '#F7F0EA') const SizedBox(width: 12),
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
                                if (context.read<AuthController>().userId !=
                                    null) {
                                  _draftEquippedAccessoryIds.clear();
                                }
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
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: _homeRoseSurface,
                disabledForegroundColor: AppTheme.primaryColor.withValues(
                  alpha: 0.45,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: const BorderSide(color: Colors.white, width: 2.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
