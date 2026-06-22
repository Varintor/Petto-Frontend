part of 'home_screen.dart';

extension _HomeProfileScreenPart on _HomeScreenState {
  Widget _buildProfileView(BuildContext context) {
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
              separatorBuilder: (context, index) => const SizedBox(width: 12),
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
          _PetProfileDetailsCard(
            pet: _activePet,
            birthday: _profileBirthdayLabel(_activePet.dateOfBirth),
            gender: _profileValue(_activePet.gender),
            bloodType: _profileValue(_activePet.bloodType),
            onEdit: _editActivePet,
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
            label: 'Logout',
            icon: Icons.logout_rounded,
            tint: AppTheme.primaryColor,
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  String _profileValue(String? value) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) return 'Not set';
    return clean[0].toUpperCase() + clean.substring(1);
  }

  String _profileBirthdayLabel(DateTime? date) {
    if (date == null) return 'Not set';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppTheme.secondaryText.withValues(alpha: 0.34),
      builder: (dialogContext) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppTheme.motionNormal,
        curve: AppTheme.motionCurveSoft,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - value)),
              child: Transform.scale(
                scale: 0.98 + (0.02 * value),
                child: child,
              ),
            ),
          );
        },
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 26),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                width: 1.2,
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppTheme.primaryColor,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Logout?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can sign back in anytime.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: AppTheme.secondaryText,
                          side: BorderSide(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.12,
                            ),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
      isScrollControlled: true,
      showDragHandle: false,
      barrierColor: AppTheme.secondaryText.withValues(alpha: 0.18),
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
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

class _PetProfileDetailsCard extends StatelessWidget {
  const _PetProfileDetailsCard({
    required this.pet,
    required this.birthday,
    required this.gender,
    required this.bloodType,
    required this.onEdit,
  });

  final _PetData pet;
  final String birthday;
  final String gender;
  final String bloodType;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.14),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.055),
            blurRadius: 22,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.badge_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pet Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.secondaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Details from onboarding',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.14),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        color: AppTheme.primaryColor,
                        size: 17,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontFamily: AppTheme.sansFontFamily,
                          color: AppTheme.primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ProfileDetailTile(
                  icon: Icons.pets_rounded,
                  label: 'Type',
                  value: pet.species,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProfileDetailTile(
                  icon: Icons.favorite_rounded,
                  label: 'Gender',
                  value: gender,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ProfileDetailTile(
                  icon: Icons.category_rounded,
                  label: 'Breed',
                  value: pet.breed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProfileDetailTile(
                  icon: Icons.bloodtype_rounded,
                  label: 'Blood',
                  value: bloodType,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ProfileDetailTile(
                  icon: Icons.cake_rounded,
                  label: 'Birthday',
                  value: birthday,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProfileDetailTile(
                  icon: Icons.scale_rounded,
                  label: 'Weight',
                  value: pet.weightLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailTile extends StatelessWidget {
  const _ProfileDetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.10),
          width: 1.1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withValues(alpha: 0.94),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.sansFontFamily,
                    color: AppTheme.mutedText.withValues(alpha: 0.84),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.displayFontFamily,
                    color: AppTheme.secondaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
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
          color: AppTheme.surfaceColor,
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
