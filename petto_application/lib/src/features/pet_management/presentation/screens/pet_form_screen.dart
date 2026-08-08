import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../health_assessment/presentation/widgets/pet_avatar_widget.dart';
import '../../domain/entities/pet_entity.dart';

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

  String _species = 'dog';
  String? _gender;
  String? _bloodType;
  DateTime _birthday = DateTime(DateTime.now().year - 1, 1, 1);

  @override
  void initState() {
    super.initState();
    final pet = widget.initial;
    _name = TextEditingController(text: pet?.name ?? '');
    _breed = TextEditingController(text: pet?.breed ?? '');
    _weight = TextEditingController(text: pet?.weightKg?.toString() ?? '');
    _species = (pet?.species ?? 'dog').toLowerCase() == 'cat' ? 'cat' : 'dog';
    _gender = pet?.gender;
    _bloodType = pet?.bloodType;
    _birthday = pet?.dateOfBirth ?? DateTime(DateTime.now().year - 1, 1, 1);
    _name.addListener(_refreshNamePreview);
  }

  @override
  void dispose() {
    _name.removeListener(_refreshNamePreview);
    _name.dispose();
    _breed.dispose();
    _weight.dispose();
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
    if (weightText.isNotEmpty && (weight == null || weight <= 0)) {
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
        bloodType: _bloodType,
        avatarUri: widget.initial?.avatarUri,
      ),
    );
  }

  void _showHint(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(22, 18, 22, 0),
          dismissDirection: DismissDirection.up,
        ),
      );
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
                      onSpeciesChanged: (value) {
                        setState(() => _species = value);
                      },
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
                                  _PetTextField(
                                    controller: _breed,
                                    icon: Icons.pets_rounded,
                                    hint: 'Breed',
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 12),
                                  _PetTextField(
                                    controller: _weight,
                                    icon: Icons.monitor_weight_rounded,
                                    hint: 'Weight (kg)',
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
                                  child: _PetTextField(
                                    controller: _breed,
                                    icon: Icons.pets_rounded,
                                    hint: 'Breed',
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _PetTextField(
                                    controller: _weight,
                                    icon: Icons.monitor_weight_rounded,
                                    hint: 'Weight (kg)',
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
                        _BloodTypePicker(
                          value: _bloodType,
                          onChanged: (value) {
                            setState(() {
                              _bloodType = value == _bloodType ? null : value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _BirthdayCard(
                          birthday: _birthday,
                          onChanged: (value) {
                            setState(() => _birthday = value);
                          },
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
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.10),
                width: 1.2,
              ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.075),
            blurRadius: 22,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
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
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
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
                        label: 'DOG',
                        selected: species == 'dog',
                        onTap: onSpeciesChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SpeciesSegment(
                        value: 'cat',
                        label: 'CAT',
                        selected: species == 'cat',
                        onTap: onSpeciesChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeciesSegment extends StatelessWidget {
  const _SpeciesSegment({
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final String label;
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
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withValues(alpha: 0.20),
            width: 1.4,
          ),
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
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.displayFontFamily,
                color: selected ? Colors.white : AppTheme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.7,
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
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.16),
          width: 1.4,
        ),
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
    required this.hint,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
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
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 19),
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
          borderSide: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: 0.16),
            width: 1.3,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
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
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withValues(alpha: 0.16),
            width: 1.3,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.sansFontFamily,
                color: selected ? Colors.white : AppTheme.secondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BloodTypePicker extends StatelessWidget {
  const _BloodTypePicker({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String> onChanged;

  static const _types = ['A', 'B', 'AB', 'O'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.16),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bloodtype_rounded,
                  color: AppTheme.primaryColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Blood type',
                      style: TextStyle(
                        fontFamily: AppTheme.displayFontFamily,
                        color: AppTheme.secondaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      value == null ? 'Optional' : 'Type $value selected',
                      style: TextStyle(
                        fontFamily: AppTheme.sansFontFamily,
                        color: AppTheme.mutedText.withValues(alpha: 0.82),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _types.map((type) {
              final selected = value == type;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: type == _types.last ? 0 : 8),
                  child: InkWell(
                    onTap: () => onChanged(type),
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: AppTheme.motionFast,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primaryColor
                            : AppTheme.surfaceColor.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primaryColor
                              : AppTheme.primaryColor.withValues(alpha: 0.14),
                          width: 1.1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          type,
                          style: TextStyle(
                            fontFamily: AppTheme.displayFontFamily,
                            color: selected
                                ? Colors.white
                                : AppTheme.secondaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _BirthdayCard extends StatelessWidget {
  const _BirthdayCard({required this.birthday, required this.onChanged});

  final DateTime birthday;
  final ValueChanged<DateTime> onChanged;

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
    final years = List.generate(26, (index) => DateTime.now().year - index);
    final days = List.generate(
      DateUtils.getDaysInMonth(birthday.year, birthday.month),
      (index) => index + 1,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.16),
          width: 1.3,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cake_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SlotDropdown<int>(
              value: birthday.day,
              values: days,
              labelBuilder: (value) => value.toString().padLeft(2, '0'),
              onChanged: (day) {
                onChanged(DateTime(birthday.year, birthday.month, day));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SlotDropdown<int>(
              value: birthday.month,
              values: List.generate(12, (index) => index + 1),
              labelBuilder: (value) => _months[value - 1],
              onChanged: (month) {
                final day = birthday.day.clamp(
                  1,
                  DateUtils.getDaysInMonth(birthday.year, month),
                );
                onChanged(DateTime(birthday.year, month, day));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SlotDropdown<int>(
              value: birthday.year,
              values: years,
              labelBuilder: (value) => '$value',
              onChanged: (year) {
                final day = birthday.day.clamp(
                  1,
                  DateUtils.getDaysInMonth(year, birthday.month),
                );
                onChanged(DateTime(year, birthday.month, day));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotDropdown<T> extends StatelessWidget {
  const _SlotDropdown({
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        borderRadius: BorderRadius.circular(20),
        dropdownColor: AppTheme.surfaceColor,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        style: const TextStyle(
          fontFamily: AppTheme.displayFontFamily,
          color: AppTheme.secondaryText,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
        items: values
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Center(child: Text(labelBuilder(item))),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
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
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTheme.displayFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
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
