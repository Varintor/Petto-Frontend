part of 'home_screen.dart';

class _RoomStage extends StatelessWidget {
  const _RoomStage({
    required this.showActionMenu,
    required this.petSpecies,
    required this.petColor,
    required this.petPattern,
    required this.equipped,
    required this.eyeType,
    required this.mouthType,
    required this.onToggleMenu,
    required this.onTapAssessment,
    required this.onTapWardrobe,
    required this.onTapProfile,
  });

  final bool showActionMenu;
  final String petSpecies;
  final Color petColor;
  final String petPattern;
  final List<String> equipped;
  final String eyeType;
  final String mouthType;
  final VoidCallback onToggleMenu;
  final VoidCallback onTapAssessment;
  final VoidCallback onTapWardrobe;
  final VoidCallback onTapProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFF1ECE7), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                onTap: onTapProfile,
                child: Align(
                  alignment: const Alignment(0.02, 0.44),
                  child: SizedBox(
                    width: 194,
                    height: 194,
                    child: PetAvatarWidget(
                      species: petSpecies,
                      color: petColor,
                      pattern: petPattern,
                      equipped: equipped,
                      mouthType: mouthType,
                      eyeType: eyeType,
                      isRotating: true,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: SizedBox(
                width: 176,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _RoomMenuButton(
                      expanded: showActionMenu,
                      onTap: onToggleMenu,
                    ),
                    const SizedBox(height: 8),
                    IgnorePointer(
                      ignoring: !showActionMenu,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            offset: showActionMenu
                                ? Offset.zero
                                : const Offset(0, -0.12),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: showActionMenu ? 1 : 0,
                              child: _RoomQuickActionChip(
                                label: 'Assessment',
                                icon: Icons.auto_awesome_rounded,
                                color: AppTheme.primaryColor,
                                textWidth: 112,
                                onTap: onTapAssessment,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            offset: showActionMenu
                                ? Offset.zero
                                : const Offset(0, -0.08),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: showActionMenu ? 1 : 0,
                              child: _RoomQuickActionChip(
                                label: 'Wardrobe',
                                icon: Icons.checkroom_rounded,
                                color: AppTheme.secondaryColor,
                                textWidth: 104,
                                onTap: onTapWardrobe,
                              ),
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
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppTheme.secondaryColor.withValues(alpha: 0.14),
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: AppTheme.glassCardDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(42),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: child,
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

class _BackgroundDecor extends StatefulWidget {
  @override
  State<_BackgroundDecor> createState() => _BackgroundDecorState();
}

class _BackgroundDecorState extends State<_BackgroundDecor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 14000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final phase = _controller.value * math.pi * 2;
          final slowWave = math.sin(phase);
          final slowDrift = math.cos(phase * 0.82);
          final shimmer = ((math.sin(phase * 1.2) + 1) / 2);
          final floatA = math.sin(phase * 1.45);
          final floatB = math.cos(phase * 1.18);
          final orbPulse = 1 + (math.sin(phase * 1.6) * 0.035);

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFFFFEFD),
                        const Color(0xFFFFFBF8),
                        const Color(0xFFFFF8F2),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.18),
                      radius: 1.18,
                      colors: [
                        Colors.white.withValues(alpha: 0.94),
                        const Color(0x00FFFFFF),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -42 + (slowDrift * 5),
                left: -28 + (slowWave * 4),
                child: _AmbientShape(
                  width: 192,
                  height: 160,
                  colors: [
                    const Color(0xFFFFDCCB).withValues(alpha: 0.22),
                    const Color(0xFFFFF4EC).withValues(alpha: 0.1),
                    const Color(0x00FFF4EC),
                  ],
                  radius: 96,
                  rotation: -0.12,
                ),
              ),
              Positioned(
                top: 152 + (floatA * 8),
                right: -16 + (slowDrift * 4),
                child: Transform.scale(
                  scale: orbPulse,
                  child: const _FloatingOrb(
                    size: 188,
                    tint: Color(0xFFD7F2EE),
                    glow: Color(0xFFBDEBE3),
                  ),
                ),
              ),
              Positioned(
                bottom: 238 + (floatB * 7),
                left: -12 + (slowWave * 3),
                child: Transform.scale(
                  scale: 0.98 + (floatB * 0.035),
                  child: const _FloatingOrb(
                    size: 148,
                    tint: Color(0xFFFFF0B4),
                    glow: Color(0xFFFFE59B),
                  ),
                ),
              ),
              Positioned(
                bottom: 120 + (floatA * 6),
                right: 38 + (slowDrift * 3),
                child: Transform.scale(
                  scale: 1 + (slowWave * 0.03),
                  child: const _FloatingOrb(
                    size: 118,
                    tint: Color(0xFFFFE1D9),
                    glow: Color(0xFFFFCEC4),
                  ),
                ),
              ),
              Positioned(
                top: 334 + (floatB * 6),
                left: 164 + (slowWave * 2),
                child: Transform.scale(
                  scale: 0.98 + (slowDrift * 0.025),
                  child: const _FloatingOrb(
                    size: 116,
                    tint: Color(0xFFFFE5F4),
                    glow: Color(0xFFF8CFE5),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _DotPainter(progress: _controller.value),
                ),
              ),
              Positioned(
                top: 86 + (slowWave * 6),
                right: 34 + (slowDrift * 3),
                child: Opacity(
                  opacity: 0.014 + (shimmer * 0.008),
                  child: Transform.translate(
                    offset: Offset(0, slowWave * 4),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 54,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 222 + (slowDrift * 4),
                left: 24 + (slowWave * 3),
                child: Opacity(
                  opacity: 0.01 + (shimmer * 0.006),
                  child: Transform.translate(
                    offset: Offset(slowDrift * 3, slowWave * 4),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 22,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 300 + (slowWave * 3),
                left: 40 + (slowDrift * 3),
                child: Opacity(
                  opacity: 0.01 + (shimmer * 0.006),
                  child: Transform.translate(
                    offset: Offset(slowWave * 3, slowDrift * 4),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 46,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 420 + (slowDrift * 3),
                right: 66 + (slowWave * 2),
                child: Opacity(
                  opacity: 0.008 + (shimmer * 0.005),
                  child: Transform.translate(
                    offset: Offset(slowDrift * 2, slowWave * 3),
                    child: const Icon(
                      Icons.circle_rounded,
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AmbientShape extends StatelessWidget {
  const _AmbientShape({
    required this.width,
    required this.height,
    required this.colors,
    required this.radius,
    required this.rotation,
  });

  final double width;
  final double height;
  final List<Color> colors;
  final double radius;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: RadialGradient(
            center: const Alignment(-0.2, -0.25),
            radius: 0.92,
            colors: colors,
          ),
        ),
      ),
    );
  }
}

class _FloatingOrb extends StatelessWidget {
  const _FloatingOrb({
    required this.size,
    required this.tint,
    required this.glow,
  });

  final double size;
  final Color tint;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.24, -0.3),
          radius: 0.96,
          colors: [
            Colors.white.withValues(alpha: 0.46),
            tint.withValues(alpha: 0.24),
            tint.withValues(alpha: 0.12),
            tint.withValues(alpha: 0),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.12),
            blurRadius: 26,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Align(
        alignment: const Alignment(-0.32, -0.28),
        child: Container(
          width: size * 0.26,
          height: size * 0.26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  const _DotPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = ((math.sin(progress * math.pi * 2) + 1) / 2);
    final softPaint = Paint()
      ..color = const Color(
        0xFFF0E7DC,
      ).withValues(alpha: 0.12 + (pulse * 0.02));
    final warmPaint = Paint()
      ..color = const Color(
        0xFFF7DCC9,
      ).withValues(alpha: 0.09 + (pulse * 0.02));
    final accentPaint = Paint()
      ..color = const Color(0xFFF9EBC5).withValues(alpha: 0.08);

    for (double y = 0; y < size.height; y += 20) {
      for (double x = 0; x < size.width; x += 20) {
        final column = (x / 20).round();
        final row = (y / 20).round();
        final isAccent = (column + row) % 9 == 0;
        final isWarm = (column * row) % 11 == 0;
        canvas.drawCircle(
          Offset(x, y),
          isAccent ? 0.82 : 0.72,
          isAccent ? accentPaint : (isWarm ? warmPaint : softPaint),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ConfettiOverlay extends StatelessWidget {
  const _ConfettiOverlay({super.key, required this.origin, required this.seed});

  final Offset origin;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      const Color(0xFF57C785),
    ];
    final random = math.Random(seed);
    final viewport = MediaQuery.of(context).size;
    final burstOrigin = Offset(
      origin.dx.clamp(28.0, viewport.width - 28.0),
      origin.dy.clamp(28.0, viewport.height - 28.0),
    );
    final particles = List.generate(
      18,
      (index) => _BurstParticleData(
        angle: ((math.pi * 2) / 18) * index + (random.nextDouble() * 0.26),
        distance: 36 + random.nextDouble() * 58,
        size: 10 + random.nextDouble() * 10,
        color: colors[index % colors.length],
        icon: index.isEven
            ? Icons.auto_awesome_rounded
            : (index % 3 == 0 ? Icons.star_rounded : Icons.favorite_rounded),
        spin: (random.nextDouble() - 0.5) * 1.6,
      ),
    );

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) {
          final fade = (1 - progress).clamp(0.0, 1.0);
          return Stack(
            children: [
              Positioned(
                left: burstOrigin.dx - (18 + progress * 18),
                top: burstOrigin.dy - (18 + progress * 18),
                child: Opacity(
                  opacity: fade * 0.32,
                  child: Container(
                    width: 36 + (progress * 36),
                    height: 36 + (progress * 36),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accentColor.withValues(
                          alpha: fade * 0.75,
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              for (final particle in particles)
                Positioned(
                  left:
                      burstOrigin.dx +
                      (math.cos(particle.angle) *
                          particle.distance *
                          Curves.easeOutBack.transform(progress)) -
                      (particle.size / 2),
                  top:
                      burstOrigin.dy +
                      (math.sin(particle.angle) *
                          particle.distance *
                          Curves.easeOutBack.transform(progress)) -
                      (particle.size / 2),
                  child: Transform.rotate(
                    angle: particle.spin * progress,
                    child: Opacity(
                      opacity: fade,
                      child: Icon(
                        particle.icon,
                        size: particle.size,
                        color: particle.color.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BurstParticleData {
  const _BurstParticleData({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.icon,
    required this.spin,
  });

  final double angle;
  final double distance;
  final double size;
  final Color color;
  final IconData icon;
  final double spin;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 40,
        height: 40,
        decoration: AppTheme.glassCardDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: AppTheme.secondaryText, size: 20),
      ),
    );
  }
}

class _RoomMenuButton extends StatelessWidget {
  const _RoomMenuButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: expanded
              ? const Color(0xFFFFF4EC)
              : Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: expanded ? const Color(0xFFF6D8C7) : const Color(0xFFF1EAE4),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE6D9CE).withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: AnimatedRotation(
            turns: expanded ? 0.08 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              width: 18,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MenuLine(
                    width: expanded ? 16 : 14,
                    color: expanded
                        ? AppTheme.primaryColor
                        : AppTheme.secondaryText,
                  ),
                  const SizedBox(height: 3.5),
                  _MenuLine(
                    width: expanded ? 10 : 18,
                    color: AppTheme.secondaryText,
                  ),
                  const SizedBox(height: 3.5),
                  _MenuLine(
                    width: expanded ? 16 : 12,
                    color: expanded
                        ? AppTheme.primaryColor
                        : AppTheme.secondaryText,
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

class _MenuLine extends StatelessWidget {
  const _MenuLine({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: width,
      height: 2.3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _RoomQuickActionChip extends StatelessWidget {
  const _RoomQuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.textWidth,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double textWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: textWidth,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFF3ECE6), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE6D9CE).withValues(alpha: 0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF3ECE6), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, size: 17, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetChip extends StatelessWidget {
  const _PetChip({
    required this.pet,
    required this.appearance,
    this.profileImage,
    required this.selected,
    required this.onTap,
  });

  final _PetData pet;
  final _PetAppearanceData appearance;
  final Object? profileImage;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final petAccent = Color(
      int.parse(appearance.colorHex.replaceFirst('#', '0xFF')),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 5, 18, 5),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? petAccent.withValues(alpha: 0.34) : Colors.white,
            width: 2,
          ),
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? petAccent.withValues(alpha: 0.12)
                    : const Color(0xFFF8F7F4),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: _PetChipAvatar(
                  profileImage: profileImage,
                  appearance: appearance,
                  dimmed: !selected,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              pet.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? AppTheme.secondaryText : AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetChipAvatar extends StatelessWidget {
  const _PetChipAvatar({
    required this.profileImage,
    required this.appearance,
    required this.dimmed,
  });

  final Object? profileImage;
  final _PetAppearanceData appearance;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    if (profileImage is Uint8List) {
      return Image.memory(profileImage! as Uint8List, fit: BoxFit.cover);
    }
    if (profileImage is List<int>) {
      return Image.memory(
        Uint8List.fromList(profileImage! as List<int>),
        fit: BoxFit.cover,
      );
    }
    if (profileImage is File) {
      return Image.file(profileImage! as File, fit: BoxFit.cover);
    }

    return Center(
      child: _SpeciesAvatarIcon(
        species: appearance.species,
        appearance: appearance,
        size: 42,
        dimmed: dimmed,
      ),
    );
  }
}

class _AddPetChip extends StatelessWidget {
  const _AddPetChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppTheme.mutedText.withValues(alpha: 0.24),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(Icons.add_rounded, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Add Pet',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppTheme.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.suffix,
    required this.icon,
    required this.color,
    required this.progress,
  });

  final String title;
  final String value;
  final String suffix;
  final IconData icon;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: SizedBox(width: suffix.isEmpty ? 0 : 4),
                ),
                TextSpan(
                  text: suffix,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.mission,
    required this.completed,
    required this.bursting,
    required this.onTap,
  });

  final _MissionData mission;
  final bool completed;
  final bool bursting;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: completed ? 0.68 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: AppTheme.glassCardDecoration(
          color: completed
              ? Colors.white.withValues(alpha: 0.52)
              : Colors.white.withValues(alpha: 0.84),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: completed ? Colors.white : const Color(0xFFF8F6F2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(mission.icon, color: AppTheme.secondaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+${mission.reward} XP',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedScale(
              duration: const Duration(milliseconds: 260),
              scale: bursting ? 1.08 : 1,
              child: completed
                  ? Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                    )
                  : GestureDetector(
                      onTapDown: (details) => onTap(details.globalPosition),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.24,
                            ),
                            width: 1.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: AppTheme.primaryColor.withValues(alpha: 0.9),
                          size: 17,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({required this.event});

  final _CalendarEventData event;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: event.color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(event.icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  event.timeLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: event.color),
                ),
              ],
            ),
          ),
          Icon(
            event.completed
                ? Icons.check_circle_rounded
                : Icons.check_circle_outline_rounded,
            color: event.completed
                ? AppTheme.successColor
                : AppTheme.mutedText.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class _FilterToggle extends StatelessWidget {
  const _FilterToggle({required this.current, required this.onChanged});

  final _VetFilter current;
  final ValueChanged<_VetFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String text, _VetFilter filter, Color? activeColor) {
      final selected = current == filter;
      return InkWell(
        onTap: () => onChanged(filter),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected
                  ? (activeColor ?? AppTheme.secondaryText)
                  : AppTheme.mutedText,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip('All', _VetFilter.all, AppTheme.secondaryText),
          chip('Online', _VetFilter.online, AppTheme.successColor),
        ],
      ),
    );
  }
}

class _ConsultActionCard extends StatelessWidget {
  const _ConsultActionCard({
    required this.dark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool dark;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        height: 172,
        decoration: AppTheme.glassCardDecoration(
          color: dark ? AppTheme.secondaryColor : Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: 0.18)
                    : AppTheme.secondaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: dark ? Colors.white : AppTheme.secondaryColor,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: dark ? Colors.white : AppTheme.secondaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: dark
                    ? Colors.white.withValues(alpha: 0.75)
                    : AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VetCard extends StatelessWidget {
  const _VetCard({
    required this.vet,
    required this.onChat,
    required this.onCall,
  });

  final _VetData vet;
  final VoidCallback onChat;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChat,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        decoration: AppTheme.glassCardDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EEE8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          vet.name.substring(4, 5),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ),
                    if (vet.online)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white, width: 2.4),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vet.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vet.specialty.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: vet.online
                        ? AppTheme.successColor.withValues(alpha: 0.12)
                        : const Color(0xFFF6F1EA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    vet.online ? 'Online' : 'Offline',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: vet.online
                          ? AppTheme.successColor
                          : AppTheme.mutedText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Open chat to send pet profile, AI health checks, and recent health updates.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.secondaryText.withValues(alpha: 0.7),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onChat,
                    icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                    label: const Text('Open Chat'),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: onCall,
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: onCall != null
                          ? AppTheme.secondaryColor.withValues(alpha: 0.08)
                          : const Color(0xFFF5F1EB),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.call_rounded,
                      size: 20,
                      color: onCall != null
                          ? AppTheme.secondaryColor
                          : AppTheme.mutedText.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VetChatQuickAction extends StatelessWidget {
  const _VetChatQuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFF0E8E1), width: 1.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.secondaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VetChatBubble extends StatelessWidget {
  const _VetChatBubble({required this.message});

  final _VetChatMessageData message;

  @override
  Widget build(BuildContext context) {
    final isVet = message.fromVet;
    final accent = message.tint ?? AppTheme.primaryColor;

    return Align(
      alignment: isVet ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment: isVet
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isVet
                    ? Colors.white
                    : AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isVet ? 8 : 22),
                  bottomRight: Radius.circular(isVet ? 22 : 8),
                ),
                border: Border.all(
                  color: isVet
                      ? const Color(0xFFF1EAE4)
                      : AppTheme.primaryColor.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.title != null) ...[
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            message.icon ?? Icons.description_rounded,
                            size: 16,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message.title!,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppTheme.secondaryText,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    message.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message.timeLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.mutedText.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryPreviewCard extends StatelessWidget {
  const _HistoryPreviewCard({required this.item});

  final _HistoryData item;

  @override
  Widget build(BuildContext context) {
    final color = _urgencyCardColor(item.urgency);
    return Container(
      decoration: AppTheme.glassCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.history_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.date,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.urgency,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '"${item.result}"',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Color _urgencyCardColor(String urgency) {
    switch (urgency) {
      case 'Critical':
        return AppTheme.primaryColor;
      case 'Abnormal':
        return AppTheme.accentColor;
      default:
        return AppTheme.successColor;
    }
  }
}

class _HistoryDetailCard extends StatelessWidget {
  const _HistoryDetailCard({required this.item});

  final _HistoryData item;

  @override
  Widget build(BuildContext context) {
    final color = _urgencyColor(item.urgency);
    return Container(
      decoration: AppTheme.glassCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.search_rounded, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.date,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.urgency,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '"${item.result}"',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {},
                  child: const Text('Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Share with Vet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _urgencyColor(String urgency) {
    switch (urgency) {
      case 'Critical':
        return AppTheme.primaryColor;
      case 'Abnormal':
        return AppTheme.accentColor;
      default:
        return AppTheme.successColor;
    }
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _ProfileLinkCard extends StatelessWidget {
  const _ProfileLinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        decoration: AppTheme.glassCardDecoration(),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F6F2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: AppTheme.secondaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: AppTheme.mutedText),
          ],
        ),
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.label,
    required this.icon,
    required this.tint,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: emphasized
              ? tint.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: emphasized
                ? tint.withValues(alpha: 0.12)
                : AppTheme.secondaryText.withValues(alpha: 0.08),
            width: 1.1,
          ),
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: emphasized
                    ? Colors.white.withValues(alpha: 0.72)
                    : tint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(icon, size: 18, color: tint),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: emphasized ? tint : AppTheme.secondaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WardrobeSection extends StatelessWidget {
  const _WardrobeSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 12),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({
    required this.label,
    required this.selected,
    required this.leading,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFFF6D7CC) : const Color(0xFFEAE6E1),
            width: selected ? 1.8 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppTheme.primaryColor.withValues(alpha: 0.08)
                  : const Color(0x0F3F6174),
              blurRadius: selected ? 16 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFFF3EE)
                    : const Color(0xFFF8F6F3),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(child: leading),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected
                    ? AppTheme.secondaryText
                    : AppTheme.secondaryText,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeciesChoiceIcon extends StatelessWidget {
  const _SpeciesChoiceIcon({
    required this.species,
    required this.size,
    this.dimmed = false,
  });

  final String species;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final normalized = species.toLowerCase();
    final color = dimmed
        ? AppTheme.secondaryText.withValues(alpha: 0.48)
        : AppTheme.primaryColor;

    if (normalized == 'dog') {
      return CustomPaint(
        size: Size.square(size),
        painter: _DogHouseIconPainter(color: color),
      );
    }

    return Icon(Icons.pets_rounded, size: size, color: color);
  }
}

class _DogHouseIconPainter extends CustomPainter {
  const _DogHouseIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    final bone = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.28, size.height * 0.34),
          radius: size.width * 0.16,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.28, size.height * 0.66),
          radius: size.width * 0.16,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.72, size.height * 0.34),
          radius: size.width * 0.16,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.72, size.height * 0.66),
          radius: size.width * 0.16,
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.28,
            size.height * 0.3,
            size.width * 0.44,
            size.height * 0.4,
          ),
          Radius.circular(size.width * 0.14),
        ),
      );
    canvas.drawPath(bone, fill);
  }

  @override
  bool shouldRepaint(covariant _DogHouseIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _SpeciesAvatarIcon extends StatelessWidget {
  const _SpeciesAvatarIcon({
    required this.species,
    required this.size,
    this.dimmed = false,
    this.appearance,
  });

  final String species;
  final double size;
  final bool dimmed;
  final _PetAppearanceData? appearance;

  @override
  Widget build(BuildContext context) {
    final currentAppearance = appearance;
    final normalized = (currentAppearance?.species ?? species).toLowerCase();
    final color = currentAppearance != null
        ? Color(int.parse(currentAppearance.colorHex.replaceFirst('#', '0xFF')))
        : normalized == 'dog'
        ? const Color(0xFFF5C44F)
        : const Color(0xFFF6A253);

    return Opacity(
      opacity: dimmed ? 0.82 : 1,
      child: IgnorePointer(
        child: SizedBox(
          width: size,
          height: size,
          child: PetAvatarWidget(
            species: normalized == 'dog' ? 'Dog' : 'Cat',
            color: color,
            pattern:
                currentAppearance?.pattern ??
                (normalized == 'dog' ? 'none' : 'tabby'),
            equipped:
                currentAppearance?.equipped.toList(growable: false) ?? const [],
            eyeType: currentAppearance?.eyeType ?? 'default',
            mouthType: currentAppearance?.mouthType ?? 'smile',
            isRotating: false,
            headOnly: true,
          ),
        ),
      ),
    );
  }
}

class _ColorSwatchButton extends StatelessWidget {
  const _ColorSwatchButton({
    required this.colorHex,
    required this.selected,
    required this.onTap,
  });

  final String colorHex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(colorHex);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : Colors.white,
            width: 4,
          ),
          boxShadow: selected ? AppTheme.subtleShadow : null,
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final value = int.parse(hex.replaceFirst('#', '0xFF'));
    return Color(value);
  }
}

class _MiniSelectionCard extends StatelessWidget {
  const _MiniSelectionCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: AppTheme.glassCardDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              selected ? Icons.visibility_rounded : Icons.star_border_rounded,
              color: selected ? AppTheme.primaryColor : AppTheme.secondaryText,
            ),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected
                    ? AppTheme.primaryColor
                    : AppTheme.secondaryText,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessoryCard extends StatelessWidget {
  const _AccessoryCard({
    required this.accessory,
    required this.equipped,
    required this.onTap,
  });

  final _AccessoryData accessory;
  final bool equipped;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Opacity(
        opacity: accessory.unlocked ? 1 : 0.32,
        child: Container(
          width: 156,
          decoration: AppTheme.glassCardDecoration(
            color: equipped
                ? AppTheme.primaryColor.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              if (!accessory.unlocked)
                const Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: AppTheme.secondaryText,
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(accessory.emoji, style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 12),
                  Text(
                    accessory.name.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.secondaryText,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
