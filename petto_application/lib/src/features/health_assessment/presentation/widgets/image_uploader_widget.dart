import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import 'pet_avatar_widget.dart';

class ImageUploaderWidget extends StatefulWidget {
  final Function(dynamic) onImageSelected;
  final dynamic initialImage;
  final String petName;
  final String petSpecies;
  final String? petColorHex;
  final String petPattern;
  final String petEyeType;
  final String petMouthType;
  final List<String> petEquipped;

  const ImageUploaderWidget({
    super.key,
    required this.onImageSelected,
    this.initialImage,
    this.petName = 'Your pet',
    this.petSpecies = 'Cat',
    this.petColorHex,
    this.petPattern = 'none',
    this.petEyeType = 'default',
    this.petMouthType = 'smile',
    this.petEquipped = const ['acc_collar'],
  });

  @override
  State<ImageUploaderWidget> createState() => _ImageUploaderWidgetState();
}

class _ImageUploaderWidgetState extends State<ImageUploaderWidget>
    with SingleTickerProviderStateMixin {
  dynamic _selectedImage;
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat();
    _selectedImage = widget.initialImage;
  }

  @override
  void didUpdateWidget(ImageUploaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImage != oldWidget.initialImage) {
      setState(() {
        _selectedImage = widget.initialImage;
      });
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();

    if (kIsWeb) {
      // Web: Use pickImage without path constraint
      final XFile? pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        widget.onImageSelected(bytes);
        setState(() {
          _selectedImage = bytes;
        });
      }
    } else {
      // Mobile: Use File
      final XFile? pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        widget.onImageSelected(file);
        setState(() {
          _selectedImage = file;
        });
      }
    }
  }

  void _clearImage() {
    widget.onImageSelected(null);
    setState(() {
      _selectedImage = null;
    });
  }

  Color _petColor() {
    if (widget.petColorHex != null) {
      return _colorFromHex(widget.petColorHex!);
    }
    switch (widget.petSpecies.toLowerCase()) {
      case 'dog':
        return AppTheme.accentColor;
      case 'bird':
        return AppTheme.warmSurfaceColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _displaySpecies() {
    final species = widget.petSpecies.toLowerCase();
    if (species == 'dog') return 'Dog';
    if (species == 'cat') return 'Cat';
    return widget.petSpecies;
  }

  Color _colorFromHex(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  Widget _buildPetHead({double size = 54}) {
    final species = _displaySpecies();
    final supportsCharacter = species == 'Dog' || species == 'Cat';
    if (!supportsCharacter) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _petColor().withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.pets_rounded,
          size: size * 0.55,
          color: AppTheme.secondaryText.withValues(alpha: 0.76),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: IgnorePointer(
        child: PetAvatarWidget(
          species: species,
          color: _petColor(),
          pattern: widget.petPattern,
          eyeType: widget.petEyeType,
          mouthType: widget.petMouthType,
          isRotating: false,
          headOnly: true,
          equipped: widget.petEquipped,
        ),
      ),
    );
  }

  Widget _buildEmptyPreview(BuildContext context) {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, child) {
        final wave = math.sin(_ambientController.value * math.pi * 2);
        final drift = math.cos(_ambientController.value * math.pi * 2);

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -26 + (drift * 4),
              right: -12,
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -28 + (wave * 5),
              left: -4,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentColor.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.94),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: AppTheme.primaryColor.withValues(alpha: 0.84),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CLEAR PHOTO',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.secondaryText.withValues(alpha: 0.7),
                        letterSpacing: 0.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.translate(
                      offset: Offset(0, wave * 3),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  _petColor().withValues(alpha: 0.18),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: _petColor().withValues(alpha: 0.14),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(child: _buildPetHead(size: 42)),
                          ),
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryText,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.4,
                                ),
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Upload Pet Photo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a bright photo of ${widget.petName}.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryText.withValues(alpha: 0.62),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryText,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.upload_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Choose Photo',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    if (_selectedImage == null) {
      return _buildEmptyPreview(context);
    }

    final imageWidget = _buildSelectedImageWidget();
    if (imageWidget == null) {
      return _buildImagePreviewFallback(context);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        imageWidget,
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.26),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: 14,
          left: 14,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _petColor().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(child: _buildPetHead(size: 22)),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.petName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 14,
          right: 14,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CircleOverlayButton(
                icon: Icons.edit_rounded,
                onTap: () => _showImageSourceSheet(context),
              ),
              const SizedBox(width: 8),
              _CircleOverlayButton(
                icon: Icons.close_rounded,
                onTap: _clearImage,
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Photo ready for ${widget.petName}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: AppTheme.secondaryText),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap edit to replace before AI check.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.secondaryText.withValues(
                                      alpha: 0.6,
                                    ),
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreviewFallback(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 42,
            color: AppTheme.mutedText.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 10),
          Text(
            'Could not preview image',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.secondaryText.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildSelectedImageWidget() {
    if (kIsWeb) {
      if (_selectedImage is List<int>) {
        return Image.memory(
          Uint8List.fromList(_selectedImage as List<int>),
          fit: BoxFit.cover,
        );
      }
    }

    if (_selectedImage is File) {
      return Image.file(_selectedImage as File, fit: BoxFit.cover);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Pet Image', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Add a clear photo so the AI can read your pet more accurately.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.secondaryText.withValues(alpha: 0.64),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _showImageSourceSheet(context),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            height: 228,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFFBF8),
                  _petColor().withValues(alpha: 0.09),
                  AppTheme.accentColor.withValues(alpha: 0.07),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppTheme.secondaryText.withValues(alpha: 0.08),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: _petColor().withValues(alpha: 0.09),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: _buildImagePreview(context),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceSheet(BuildContext context) {
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
                _selectedImage == null
                    ? 'Upload Pet Photo'
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
              _SourceTile(
                icon: Icons.photo_library_rounded,
                iconColor: AppTheme.primaryColor,
                label: 'Gallery',
                subtitle: 'Pick an existing photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (!kIsWeb) ...[
                const SizedBox(height: 10),
                _SourceTile(
                  icon: Icons.camera_alt_rounded,
                  iconColor: AppTheme.secondaryColor,
                  label: 'Camera',
                  subtitle: 'Take a new picture now',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
              if (_selectedImage != null) ...[
                const SizedBox(height: 10),
                _SourceTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: AppTheme.dangerColor,
                  label: 'Remove Photo',
                  subtitle: 'Clear the current image',
                  onTap: () {
                    Navigator.pop(context);
                    _clearImage();
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

class _CircleOverlayButton extends StatelessWidget {
  const _CircleOverlayButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, size: 18, color: AppTheme.secondaryText),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
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
              color: AppTheme.secondaryText.withValues(alpha: 0.42),
            ),
          ],
        ),
      ),
    );
  }
}
