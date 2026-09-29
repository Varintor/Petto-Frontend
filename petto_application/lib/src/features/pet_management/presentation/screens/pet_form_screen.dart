import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/top_alert.dart';
import '../../../health_assessment/presentation/widgets/pet_avatar_widget.dart';
import '../../domain/entities/pet_entity.dart';
import '../../domain/pet_blood_type_catalog.dart';
import '../../domain/pet_breed_catalog.dart';

/// Add / edit pet profile.
///
/// The caller persists the returned [PetEntity], keeping this screen reusable
/// for both Home and Profile entry points.
class PetFormScreen extends StatefulWidget {
  final PetEntity? initial;

  const PetFormScreen({super.key, this.initial});

  bool get isEdit => initial != null;

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _breed;
  late final TextEditingController _weight;
  late final TextEditingController _bloodType;

  String _species = 'dog';
  String? _gender;
  DateTime? _birthday;

  @override
  void initState() {
    super.initState();
    final pet = widget.initial;
    _name = TextEditingController(text: pet?.name ?? '');
    _breed = TextEditingController(text: pet?.breed ?? '');
    _weight = TextEditingController(text: pet?.weightKg?.toString() ?? '');
    _bloodType = TextEditingController(text: pet?.bloodType ?? '');
    _species = (pet?.species ?? 'dog').toLowerCase() == 'cat' ? 'cat' : 'dog';
    _gender = pet?.gender;
    _birthday = pet?.dateOfBirth;
    _name.addListener(_refreshNamePreview);
  }

  @override
  void dispose() {
    _name.removeListener(_refreshNamePreview);
    _name.dispose();
    _breed.dispose();
    _weight.dispose();
    _bloodType.dispose();
    super.dispose();
  }

  void _refreshNamePreview() {
    if (mounted) setState(() {});
  }

  Color get _avatarColor {
    return _species == 'cat'
        ? const Color(0xFFA33E44)
        : const Color(0xFFA65A2F);
  }

  String get _petName {
    final value = _name.text.trim();
    return value.isEmpty ? 'New buddy' : value;
  }

  void _changeSpecies(String value) {
    if (value == _species) return;
    final currentBreed = _breed.text.trim();
    final oldKnownBreed = PetBreedCatalog.forSpecies(
      _species,
    ).contains(currentBreed);
    final validForNewSpecies = PetBreedCatalog.forSpecies(
      value,
    ).contains(currentBreed);
    final currentBloodType = _bloodType.text.trim();
    final oldKnownBloodType = PetBloodTypeCatalog.forSpecies(
      _species,
    ).contains(currentBloodType);
    final validBloodTypeForNewSpecies = PetBloodTypeCatalog.forSpecies(
      value,
    ).contains(currentBloodType);
    setState(() {
      _species = value;
      if (oldKnownBreed && !validForNewSpecies) _breed.clear();
      if (oldKnownBloodType && !validBloodTypeForNewSpecies) {
        _bloodType.clear();
      }
    });
  }

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus();
    final name = _name.text.trim();
    if (name.isEmpty) {
      _showHint('Name is required');
      return;
    }

    final weightText = _weight.text.trim();
    final weight = weightText.isEmpty ? null : double.tryParse(weightText);
    // Weight is optional, but if provided it must parse to a positive number —
    // reject blanks-that-aren't-numbers, zero, and negatives like "-3".
    if (weightText.isNotEmpty &&
        (weight == null || weight <= 0 || weight > 999.99)) {
      _showHint('Invalid weight');
      return;
    }

    Navigator.of(context).pop(
      PetEntity(
        id: widget.initial?.id,
        name: name,
        species: _species,
        breed: _breed.text.trim().isEmpty ? null : _breed.text.trim(),
        gender: _gender,
        dateOfBirth: _birthday,
        weightKg: weight,
        bloodType: _bloodType.text.trim().isEmpty
            ? null
            : _bloodType.text.trim(),
        avatarUri: widget.initial?.avatarUri,
      ),
    );
  }

  void _showHint(String message) {
    showTopAlert(context, message, icon: Icons.info_outline_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _PetFormDotBackground()),
            SafeArea(
              child: AnimatedPadding(
                duration: AppTheme.motionFast,
                curve: AppTheme.motionCurve,
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                  children: [
                    _AddPetHeader(
                      isEdit: widget.isEdit,
                      onClose: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 18),
                    _AddPetHeroCard(
                      species: _species,
                      color: _avatarColor,
                      petName: _petName,
                      onSpeciesChanged: _changeSpecies,
                    ),
                    const SizedBox(height: 18),
                    _FormSection(
                      icon: Icons.favorite_rounded,
                      title: 'Profile details',
                      subtitle: 'Name, breed, and weight.',
                      children: [
                        _PetTextField(
                          controller: _name,
                          icon: Icons.favorite_rounded,
                          iconColor: const Color(0xFFA66F79),
                          hint: 'Pet name',
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stacked = constraints.maxWidth < 390;
                            if (stacked) {
                              return Column(
                                children: [
                                  _PetBreedField(
                                    species: _species,
                                    controller: _breed,
                                  ),
                                  const SizedBox(height: 12),
                                  _PetTextField(
                                    controller: _weight,
                                    icon: Icons.monitor_weight_rounded,
                                    iconColor: const Color(0xFF748066),
                                    hint: 'Weight (kg)',
                                    textInputAction: TextInputAction.done,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: _PetBreedField(
                                    species: _species,
                                    controller: _breed,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _PetTextField(
                                    controller: _weight,
                                    icon: Icons.monitor_weight_rounded,
                                    iconColor: const Color(0xFF748066),
                                    hint: 'Weight (kg)',
                                    textInputAction: TextInputAction.done,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _FormSection(
                      icon: Icons.health_and_safety_rounded,
                      title: 'Little basics',
                      subtitle: 'Birthday, gender, and blood type.',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _GenderCard(
                                label: 'Male',
                                icon: Icons.male_rounded,
                                selected: _gender == 'male',
                                onTap: () => setState(() => _gender = 'male'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _GenderCard(
                                label: 'Female',
                                icon: Icons.female_rounded,
                                selected: _gender == 'female',
                                onTap: () => setState(() => _gender = 'female'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _PetBloodTypeField(
                          species: _species,
                          controller: _bloodType,
                        ),
                        const SizedBox(height: 12),
                        _BirthdayCard(
                          birthday: _birthday,
                          onChanged: (value) {
                            setState(() => _birthday = value);
                          },
                          onClear: () => setState(() => _birthday = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SavePetButton(
                      label: widget.isEdit ? 'SAVE CHANGES' : 'ADD PET',
                      onTap: _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPetHeader extends StatelessWidget {
  const _AddPetHeader({required this.isEdit, required this.onClose});

  final bool isEdit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onClose,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.close_rounded,
              color: AppTheme.secondaryText,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Pet' : 'Add Pet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.secondaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Create a clean little profile.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddPetHeroCard extends StatelessWidget {
  const _AddPetHeroCard({
    required this.species,
    required this.color,
    required this.petName,
    required this.onSpeciesChanged,
  });

  final String species;
  final Color color;
  final String petName;
  final ValueChanged<String> onSpeciesChanged;

  @override
  Widget build(BuildContext context) {
    final avatar = SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.075),
              shape: BoxShape.circle,
            ),
          ),
          PetAvatarWidget(
            species: species,
            color: color,
            mouthType: 'smile',
            eyeType: 'default',
          ),
        ],
      ),
    );
    final profileInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            species == 'cat' ? 'CAT PROFILE' : 'DOG PROFILE',
            style: const TextStyle(
              fontFamily: AppTheme.sansFontFamily,
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          petName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.secondaryText,
            fontWeight: FontWeight.w900,
            height: 0.95,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SpeciesSegment(
                value: 'dog',
                selected: species == 'dog',
                onTap: onSpeciesChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SpeciesSegment(
                value: 'cat',
                selected: species == 'cat',
                onTap: onSpeciesChanged,
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.075),
            blurRadius: 22,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 330) {
            return Column(
              children: [
                avatar,
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: profileInfo),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatar,
              const SizedBox(width: 14),
              Expanded(child: profileInfo),
            ],
          );
        },
      ),
    );
  }
}

class _SpeciesSegment extends StatelessWidget {
  const _SpeciesSegment({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final bool selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final isDog = value == 'dog';
    final avatarColor = isDog
        ? const Color(0xFFA65A2F)
        : const Color(0xFFA33E44);

    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: AppTheme.motionFast,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : AppTheme.surfaceColor.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white, width: selected ? 3 : 2),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.10),
                    blurRadius: 14,
                    spreadRadius: -8,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white
                    : AppTheme.primaryColor.withValues(alpha: 0.055),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: PetAvatarWidget(
                species: value,
                color: avatarColor,
                headOnly: true,
                eyeType: selected ? 'default' : 'happy',
                mouthType: 'smile',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.055),
            blurRadius: 18,
            spreadRadius: -7,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.secondaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _PetTextField extends StatelessWidget {
  const _PetTextField({
    required this.controller,
    required this.icon,
    this.iconColor = AppTheme.primaryColor,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
  });

  final TextEditingController controller;
  final IconData icon;
  final Color iconColor;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: keyboardType == null
          ? TextCapitalization.words
          : TextCapitalization.none,
      onSubmitted: (_) {
        if (textInputAction == TextInputAction.next) {
          FocusScope.of(context).nextFocus();
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      scrollPadding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 160,
      ),
      style: const TextStyle(
        fontFamily: AppTheme.sansFontFamily,
        color: AppTheme.secondaryText,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: AppTheme.sansFontFamily,
          color: AppTheme.mutedText.withValues(alpha: 0.58),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: AppTheme.primaryColor.withValues(alpha: 0.045),
        prefixIcon: Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.only(left: 12, right: 10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 64,
          minHeight: 58,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.white, width: 3),
        ),
      ),
    );
  }
}

class _PetBreedField extends StatefulWidget {
  const _PetBreedField({required this.species, required this.controller});

  final String species;
  final TextEditingController controller;

  @override
  State<_PetBreedField> createState() => _PetBreedFieldState();
}

class _PetBreedFieldState extends State<_PetBreedField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (value) =>
          PetBreedCatalog.suggestions(widget.species, value.text),
      onSelected: (option) {
        widget.controller.value = TextEditingValue(
          text: option,
          selection: TextSelection.collapsed(offset: option.length),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return _PetTextField(
          controller: controller,
          focusNode: focusNode,
          icon: Icons.pets_rounded,
          iconColor: const Color(0xFFA58043),
          hint: 'Breed (optional)',
          textInputAction: TextInputAction.next,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final visibleOptions = options.take(8).toList(growable: false);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360, maxHeight: 240),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: visibleOptions.length,
                itemBuilder: (context, index) {
                  final option = visibleOptions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.pets_rounded,
                      color: Color(0xFFA58043),
                    ),
                    title: Text(
                      option,
                      style: const TextStyle(
                        fontFamily: AppTheme.sansFontFamily,
                        color: AppTheme.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: AppTheme.motionFast,
        height: 58,
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white, width: selected ? 3 : 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : const Color(0xFFA66F79),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.sansFontFamily,
                  color: selected ? Colors.white : AppTheme.secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetBloodTypeField extends StatefulWidget {
  const _PetBloodTypeField({required this.species, required this.controller});

  final String species;
  final TextEditingController controller;

  @override
  State<_PetBloodTypeField> createState() => _PetBloodTypeFieldState();
}

class _PetBloodTypeFieldState extends State<_PetBloodTypeField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (value) =>
          PetBloodTypeCatalog.suggestions(widget.species, value.text),
      onSelected: (option) {
        widget.controller.value = TextEditingValue(
          text: option,
          selection: TextSelection.collapsed(offset: option.length),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return _PetTextField(
          controller: controller,
          focusNode: focusNode,
          icon: Icons.bloodtype_rounded,
          iconColor: const Color(0xFF99545B),
          hint: 'Blood type (optional)',
          textInputAction: TextInputAction.next,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final visibleOptions = options.toList(growable: false);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360, maxHeight: 220),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: visibleOptions.length,
                itemBuilder: (context, index) {
                  final option = visibleOptions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.bloodtype_rounded,
                      color: Color(0xFF99545B),
                    ),
                    title: Text(
                      option,
                      style: const TextStyle(
                        fontFamily: AppTheme.sansFontFamily,
                        color: AppTheme.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BirthdayCard extends StatelessWidget {
  const _BirthdayCard({
    required this.birthday,
    required this.onChanged,
    required this.onClear,
  });

  final DateTime? birthday;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onClear;

  static const _months = [
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

  @override
  Widget build(BuildContext context) {
    final selectedBirthday = birthday;
    if (selectedBirthday == null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF826F86).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.cake_rounded,
                color: Color(0xFF826F86),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Birthday not set',
                    style: TextStyle(
                      fontFamily: AppTheme.displayFontFamily,
                      color: AppTheme.secondaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Optional — add it if known',
                    style: TextStyle(
                      fontFamily: AppTheme.sansFontFamily,
                      color: AppTheme.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () =>
                  onChanged(DateTime(DateTime.now().year - 1, 1, 1)),
              style: FilledButton.styleFrom(
                minimumSize: const Size(58, 38),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.09),
                foregroundColor: AppTheme.primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'SET',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
    }
    final years = List.generate(26, (index) => DateTime.now().year - index);
    final days = List.generate(
      DateUtils.getDaysInMonth(selectedBirthday.year, selectedBirthday.month),
      (index) => index + 1,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final showLeadingIcon = constraints.maxWidth >= 300;
        return Container(
          padding: const EdgeInsets.fromLTRB(9, 9, 8, 9),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Row(
            children: [
              if (showLeadingIcon) ...[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF826F86).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.cake_rounded,
                    color: Color(0xFF826F86),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                flex: 6,
                child: _SlotDropdown<int>(
                  value: selectedBirthday.day,
                  values: days,
                  semanticLabel: 'Day',
                  labelBuilder: (value) => value.toString().padLeft(2, '0'),
                  onChanged: (day) {
                    onChanged(
                      DateTime(
                        selectedBirthday.year,
                        selectedBirthday.month,
                        day,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 8,
                child: _SlotDropdown<int>(
                  value: selectedBirthday.month,
                  values: List.generate(12, (index) => index + 1),
                  semanticLabel: 'Month',
                  labelBuilder: (value) => _months[value - 1],
                  onChanged: (month) {
                    final day = selectedBirthday.day.clamp(
                      1,
                      DateUtils.getDaysInMonth(selectedBirthday.year, month),
                    );
                    onChanged(DateTime(selectedBirthday.year, month, day));
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 10,
                child: _SlotDropdown<int>(
                  value: selectedBirthday.year,
                  values: years,
                  semanticLabel: 'Year',
                  labelBuilder: (value) => '$value',
                  onChanged: (year) {
                    final day = selectedBirthday.day.clamp(
                      1,
                      DateUtils.getDaysInMonth(year, selectedBirthday.month),
                    );
                    onChanged(DateTime(year, selectedBirthday.month, day));
                  },
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Clear birthday',
                onPressed: onClear,
                style: IconButton.styleFrom(
                  fixedSize: const Size(38, 38),
                  minimumSize: const Size(38, 38),
                  padding: EdgeInsets.zero,
                  backgroundColor: AppTheme.surfaceColor,
                ),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppTheme.mutedText,
                  size: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SlotDropdown<T> extends StatelessWidget {
  const _SlotDropdown({
    required this.value,
    required this.values,
    required this.semanticLabel,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final List<T> values;
  final String semanticLabel;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Container(
        height: 42,
        padding: const EdgeInsets.only(left: 8, right: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.07),
          ),
        ),
        child: PopupMenuButton<T>(
          initialValue: value,
          tooltip: 'Select $semanticLabel',
          position: PopupMenuPosition.under,
          constraints: const BoxConstraints(maxHeight: 280, minWidth: 76),
          color: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          onSelected: onChanged,
          itemBuilder: (context) => values
              .map(
                (item) => PopupMenuItem<T>(
                  value: item,
                  height: 42,
                  child: Center(
                    child: Text(
                      labelBuilder(item),
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: AppTheme.displayFontFamily,
                        color: AppTheme.secondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      labelBuilder(value),
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontFamily: AppTheme.displayFontFamily,
                        color: AppTheme.secondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavePetButton extends StatelessWidget {
  const _SavePetButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: AppTheme.displayFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.check_rounded, size: 22),
          ],
        ),
      ),
    );
  }
}

class _PetFormDotBackground extends StatelessWidget {
  const _PetFormDotBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PetFormDotPainter());
  }
}

class _PetFormDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    const gap = 38.0;
    for (double y = 22; y < size.height; y += gap) {
      for (double x = 22; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 3.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
