part of 'home_screen.dart';

extension _HomeProfileScreenPart on _HomeScreenState {
  Widget _buildProfileView(BuildContext context) {
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
                  profileImage: _petProfileImages[index],
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
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: AppTheme.subtleShadow,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildActivePetProfileMedia(),
                    ),
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: InkWell(
                        onTap: () => _showProfileImageSourceSheet(context),
                        borderRadius: BorderRadius.circular(999),
                        child: Ink(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.95),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondaryColor.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  _activePet.name,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  '${_activePet.species} • ${_activePet.breed}\n${_activePet.ageLabel}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.primaryColor.withValues(alpha: 0.75),
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.scale_rounded,
                  iconColor: AppTheme.primaryColor,
                  value: _activePet.weightLabel,
                  label: 'Current Weight',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatTile(
                  icon: Icons.emoji_events_rounded,
                  iconColor: AppTheme.accentColor,
                  value: 'LVL 12',
                  label: 'Total Rank',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ProfileLinkCard(
            icon: Icons.auto_awesome_rounded,
            title: 'Accessories',
            subtitle: '${_activeAppearance.equipped.length} Items Equipped',
            onTap: () {
              _update(() {
                _openWardrobe();
              });
            },
          ),
          const SizedBox(height: 12),
          _ProfileLinkCard(
            icon: Icons.history_rounded,
            title: 'Health Records',
            subtitle: 'View all past logs',
            onTap: () {
              _update(() {
                _activeView = _View.history;
              });
            },
          ),
          const SizedBox(height: 18),
          _ProfileActionButton(
            label: 'Edit Bio',
            icon: Icons.edit_rounded,
            tint: AppTheme.secondaryColor,
            onTap: () => _showPreviewSnackBar('Edit Bio'),
          ),
          const SizedBox(height: 12),
          _ProfileActionButton(
            label: 'Logout',
            icon: Icons.logout_rounded,
            tint: AppTheme.primaryColor,
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final auth = context.read<AuthController>();
      await auth.logout();
      // AuthGate will automatically redirect to login screen
    }
  }

  Object? get _activePetProfileImage => _petProfileImages[_activePetIndex];

  Widget _buildActivePetProfileMedia() {
    final image = _activePetProfileImage;
    if (image is Uint8List) {
      return Image.memory(image, fit: BoxFit.cover);
    }
    if (image is List<int>) {
      return Image.memory(Uint8List.fromList(image), fit: BoxFit.cover);
    }
    if (image is File) {
      return Image.file(image, fit: BoxFit.cover);
    }

    return Padding(
      padding: const EdgeInsets.all(18),
      child: PetAvatarWidget(
        species: _activeAppearance.species,
        color: _colorFromHex(_activeAppearance.colorHex),
        pattern: _activeAppearance.pattern,
        equipped: _activeAppearance.equipped.toList(growable: false),
        eyeType: _activeAppearance.eyeType,
        mouthType: _activeAppearance.mouthType,
        isRotating: true,
      ),
    );
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    final picker = ImagePicker();

    try {
      final XFile? pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        _update(() {
          _petProfileImages[_activePetIndex] = bytes;
        });
        return;
      }

      _update(() {
        _petProfileImages[_activePetIndex] = File(pickedFile.path);
      });
    } catch (_) {
      if (!mounted) return;
      showTopAlert(
        context,
        'Could not update pet photo.',
        icon: Icons.info_outline_rounded,
      );
    }
  }

  void _clearProfileImage() {
    _update(() {
      _petProfileImages.remove(_activePetIndex);
    });
  }

  void _showProfileImageSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryText.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _activePetProfileImage == null
                    ? 'Add Pet Photo'
                    : 'Update Pet Photo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Choose where you want to pick the image from.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryText.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 18),
              _ProfileImageSourceTile(
                icon: Icons.photo_library_rounded,
                iconColor: AppTheme.primaryColor,
                label: 'Gallery',
                subtitle: 'Pick an existing photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
              if (!kIsWeb) ...[
                const SizedBox(height: 10),
                _ProfileImageSourceTile(
                  icon: Icons.camera_alt_rounded,
                  iconColor: AppTheme.secondaryColor,
                  label: 'Camera',
                  subtitle: 'Take a new picture now',
                  onTap: () {
                    Navigator.pop(context);
                    _pickProfileImage(ImageSource.camera);
                  },
                ),
              ],
              if (_activePetProfileImage != null) ...[
                const SizedBox(height: 10),
                _ProfileImageSourceTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: AppTheme.dangerColor,
                  label: 'Remove Photo',
                  subtitle: 'Clear the current image',
                  onTap: () {
                    Navigator.pop(context);
                    _clearProfileImage();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileImageSourceTile extends StatelessWidget {
  const _ProfileImageSourceTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCFA),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppTheme.secondaryText.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryText.withValues(alpha: 0.58),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppTheme.secondaryText.withValues(alpha: 0.38),
            ),
          ],
        ),
      ),
    );
  }
}
