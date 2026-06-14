import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/top_alert.dart';
import '../controllers/health_assessment_controller.dart';
import '../widgets/image_uploader_widget.dart';
import '../widgets/pet_avatar_widget.dart';
import '../widgets/result_display_widget.dart';

class HealthAssessmentScreen extends StatefulWidget {
  final bool embedInScaffold;
  final bool compactMode;
  final String? initialPetName;
  final String? initialPetType;
  final List<HealthAssessmentPetOption> availablePets;
  final VoidCallback? onBackToDashboard;
  final VoidCallback? onTalkToVet;
  final VoidCallback? onSaveNotes;
  final bool showHero;

  const HealthAssessmentScreen({
    super.key,
    this.embedInScaffold = true,
    this.compactMode = false,
    this.initialPetName,
    this.initialPetType,
    this.availablePets = const [],
    this.onBackToDashboard,
    this.onTalkToVet,
    this.onSaveNotes,
    this.showHero = true,
  });

  @override
  State<HealthAssessmentScreen> createState() => _HealthAssessmentScreenState();
}

class _HealthAssessmentScreenState extends State<HealthAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _petNameController;
  final _symptomsController = TextEditingController();
  final _scrollController = ScrollController();
  String _selectedPetType = 'dog';
  String? _selectedPetId;
  dynamic _selectedImage;

  @override
  void initState() {
    super.initState();
    _petNameController = TextEditingController(text: widget.initialPetName);
    if (widget.initialPetType != null) {
      _selectedPetType = widget.initialPetType!.toLowerCase();
    }
    if (widget.availablePets.isNotEmpty) {
      final matchedPet =
          widget.availablePets.cast<HealthAssessmentPetOption?>().firstWhere(
            (pet) => pet?.name == widget.initialPetName,
            orElse: () => null,
          ) ??
          widget.availablePets.first;
      _applySelectedPet(matchedPet);
    }
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _symptomsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onImageSelected(dynamic image) {
    setState(() {
      _selectedImage = image;
    });
  }

  void _applySelectedPet(HealthAssessmentPetOption pet) {
    _selectedPetId = pet.id;
    _selectedPetType = pet.species.toLowerCase();
    _petNameController.text = pet.name;
  }

  Future<void> _submitAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    // The backend requires a photo for the AI scan, so guard early.
    if (_selectedImage == null) {
      showTopAlert(
        context,
        'Please add a pet photo before starting the analysis.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    final controller = context.read<HealthAssessmentController>();
    await controller.submitAssessment(
      petName: _petNameController.text,
      petType: _selectedPetType,
      symptoms: _symptomsController.text.isEmpty
          ? null
          : _symptomsController.text,
      imageData: _selectedImage,
    );
  }

  HealthAssessmentPetOption? _currentSelectedPetOption() {
    if (widget.availablePets.isEmpty) return null;

    for (final pet in widget.availablePets) {
      if (pet.id == _selectedPetId) {
        return pet;
      }
    }

    return widget.availablePets.first;
  }

  Color _petBaseColor(String species) {
    final selectedPet = _currentSelectedPetOption();
    if (selectedPet != null &&
        selectedPet.species.toLowerCase() == species.toLowerCase() &&
        selectedPet.colorHex != null) {
      return _colorFromHex(selectedPet.colorHex!);
    }

    switch (species.toLowerCase()) {
      case 'dog':
        return AppTheme.accentColor;
      case 'bird':
        return AppTheme.warmSurfaceColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  Color _petAccentColor(String species) {
    switch (species.toLowerCase()) {
      case 'dog':
        return AppTheme.secondaryColor;
      case 'bird':
        return AppTheme.accentColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  Color _petSelectionColor(HealthAssessmentPetOption pet) {
    if (pet.colorHex != null) {
      return _colorFromHex(pet.colorHex!);
    }
    return _petAccentColor(pet.species);
  }

  Color _colorFromHex(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  Widget _buildPetHeadAvatar(
    dynamic petOrSpecies, {
    double size = 44,
    bool dimmed = false,
  }) {
    final pet = petOrSpecies is HealthAssessmentPetOption ? petOrSpecies : null;
    final species = pet?.species ?? petOrSpecies as String;
    final normalizedSpecies = species.toLowerCase();
    final isDog = normalizedSpecies == 'dog';
    final isCat = normalizedSpecies == 'cat';

    if (!isDog && !isCat) {
      return Opacity(
        opacity: dimmed ? 0.86 : 1,
        child: Icon(
          Icons.pets_rounded,
          size: size * 0.62,
          color: _petAccentColor(species),
        ),
      );
    }

    return Opacity(
      opacity: dimmed ? 0.86 : 1,
      child: SizedBox(
        width: size,
        height: size,
        child: IgnorePointer(
          child: PetAvatarWidget(
            species: isDog ? 'Dog' : 'Cat',
            color: pet?.colorHex != null
                ? _colorFromHex(pet!.colorHex!)
                : _petBaseColor(species),
            pattern: pet?.pattern ?? (isDog ? 'none' : 'tabby'),
            eyeType: pet?.eyeType ?? 'default',
            mouthType: pet?.mouthType ?? 'smile',
            isRotating: false,
            headOnly: true,
            equipped: pet?.equipped ?? const ['acc_collar'],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPet = _currentSelectedPetOption();
    final displayPetName = selectedPet?.name ?? _petNameController.text.trim();
    final displayPetSpecies = selectedPet?.species ?? _selectedPetType;

    final content = Consumer<HealthAssessmentController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.currentAssessment != null) {
          return ResultDisplayWidget(
            assessment: controller.currentAssessment!,
            onReset: controller.reset,
            compactMode: widget.compactMode,
            onBackToDashboard: widget.onBackToDashboard,
            onTalkToVet: widget.onTalkToVet,
            onSaveNotes: widget.onSaveNotes,
          );
        }

        if (controller.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.dangerColor,
                  ),
                  const SizedBox(height: 16),
                  Text(controller.errorMessage ?? 'An error occurred'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.reset,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ClipRect(
            child: Scrollbar(
              controller: _scrollController,
              thickness: 4,
              radius: const Radius.circular(999),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  widget.compactMode ? 20.0 : 24.0,
                  widget.compactMode ? 20.0 : 24.0,
                  widget.compactMode ? 16.0 : 20.0,
                  widget.compactMode ? 28.0 : 36.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.showHero) ...[
                        Text(
                          'AI Health Scan ✨',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryText,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload a photo and tell us how your pet is doing today.',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 24),
                      ],
                      ImageUploaderWidget(
                        onImageSelected: _onImageSelected,
                        initialImage: _selectedImage,
                        petName: displayPetName.isEmpty
                            ? 'Your pet'
                            : displayPetName,
                        petSpecies: displayPetSpecies,
                        petColorHex: selectedPet?.colorHex,
                        petPattern: selectedPet?.pattern ?? 'none',
                        petEyeType: selectedPet?.eyeType ?? 'default',
                        petMouthType: selectedPet?.mouthType ?? 'smile',
                        petEquipped:
                            selectedPet?.equipped ?? const ['acc_collar'],
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Who are we checking?'),
                      const SizedBox(height: 12),
                      if (widget.availablePets.isNotEmpty)
                        _buildOwnedPetSelector()
                      else ...[
                        _buildInputField(
                          controller: _petNameController,
                          hintText: 'Pet name',
                          icon: Icons.edit_rounded,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Name required' : null,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Species'),
                        const SizedBox(height: 12),
                        _buildSpeciesSelector(),
                      ],
                      const SizedBox(height: 24),
                      _buildSectionTitle('Describe the symptoms'),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: _symptomsController,
                        hintText:
                            'e.g. Redness on the ear, scratching a lot...',
                        icon: Icons.notes_rounded,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        onPressed: _submitAssessment,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Start AI Analysis',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!widget.embedInScaffold) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Health Assessment')),
      body: content,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppTheme.mutedText,
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildOwnedPetSelector() {
    final selectedPet = widget.availablePets.firstWhere(
      (pet) => pet.id == _selectedPetId,
      orElse: () => widget.availablePets.first,
    );
    final selectedAccent = _petSelectionColor(selectedPet);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: widget.compactMode ? 122 : 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.availablePets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final pet = widget.availablePets[index];
              final isSelected = pet.id == _selectedPetId;
              final accent = _petSelectionColor(pet);
              return InkWell(
                onTap: () {
                  setState(() {
                    _applySelectedPet(pet);
                  });
                },
                borderRadius: BorderRadius.circular(28),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  scale: isSelected ? 1 : 0.985,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 168,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isSelected
                            ? [Colors.white, accent.withValues(alpha: 0.12)]
                            : [Colors.white, const Color(0xFFFFFCFA)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isSelected
                            ? accent.withValues(alpha: 0.24)
                            : AppTheme.secondaryText.withValues(alpha: 0.08),
                        width: 1.3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.14),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ]
                          : AppTheme.subtleShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.88)
                                    : accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: _buildPetHeadAvatar(
                                  pet,
                                  size: 34,
                                  dimmed: !isSelected,
                                ),
                              ),
                            ),
                            const Spacer(),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accent.withValues(alpha: 0.12)
                                    : const Color(0xFFF9F5EF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                isSelected ? 'Selected' : pet.species,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: isSelected
                                          ? accent
                                          : AppTheme.mutedText,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.1,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          pet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppTheme.secondaryText),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pet.species,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.secondaryText.withValues(
                                  alpha: 0.58,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selectedAccent.withValues(alpha: 0.14),
              width: 1.1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selectedAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: _buildPetHeadAvatar(selectedPet, size: 34),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedPet.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${selectedPet.species} ready for AI check',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryText.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selectedAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Ready',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selectedAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.secondaryText.withValues(alpha: 0.08),
          width: 1.1,
        ),
        boxShadow: AppTheme.subtleShadow,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              validator: validator,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                isCollapsed: true,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryText.withValues(alpha: 0.42),
                  height: 1.4,
                ),
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.secondaryText,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeciesSelector() {
    final types = [
      {'id': 'dog', 'label': 'Dog'},
      {'id': 'cat', 'label': 'Cat'},
      {'id': 'bird', 'label': 'Bird'},
      {'id': 'other', 'label': 'Other'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: types.map((type) {
        final id = type['id'] as String;
        final label = type['label'] as String;
        final isSelected = _selectedPetType == id;
        final accent = _petAccentColor(id);
        final isCharacterType = id == 'dog' || id == 'cat';
        return GestureDetector(
          onTap: () => setState(() => _selectedPetType = id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 152,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? accent.withValues(alpha: 0.22)
                    : AppTheme.secondaryText.withValues(alpha: 0.08),
                width: 1.2,
              ),
              boxShadow: isSelected ? AppTheme.subtleShadow : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.82)
                        : accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: isCharacterType
                        ? _buildPetHeadAvatar(id, size: 34)
                        : Icon(
                            id == 'bird'
                                ? Icons.flutter_dash_rounded
                                : Icons.favorite_border_rounded,
                            color: accent,
                            size: 20,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class HealthAssessmentPetOption {
  const HealthAssessmentPetOption({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    this.colorHex,
    this.pattern = 'none',
    this.eyeType = 'default',
    this.mouthType = 'smile',
    this.equipped = const ['acc_collar'],
  });

  final String id;
  final String name;
  final String species;
  final String breed;
  final String? colorHex;
  final String pattern;
  final String eyeType;
  final String mouthType;
  final List<String> equipped;
}
