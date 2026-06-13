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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onTapProfile,
            child: Align(
              alignment: const Alignment(0, 0.26),
              child: SizedBox(
                width: 212,
                height: 212,
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
          top: 12,
          right: 26,
          child: SizedBox(
            width: 176,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _RoomMenuButton(expanded: showActionMenu, onTap: onToggleMenu),
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
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutQuint,
      builder: (context, value, child) {
        final eased = Curves.easeOutQuint.transform(value);
        return Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 9 * eased, sigmaY: 9 * eased),
            child: Container(
              color: AppTheme.secondaryColor.withValues(alpha: 0.13 * eased),
              alignment: Alignment.bottomCenter,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..translateByDouble(0, 24 * (1 - eased), 0, 1)
                  ..scaleByDouble(0.985 + (0.015 * eased), 1, 1, 1),
                child: Opacity(opacity: eased, child: child),
              ),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: AppTheme.glassCardDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(42)),
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
                    color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              left: false,
              right: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftReveal extends StatelessWidget {
  const _SoftReveal({required this.child, this.delay = 0});

  final Widget child;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final clampedDelay = delay.clamp(0.0, 0.72);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + (clampedDelay * 360).round()),
      curve: Curves.linear,
      builder: (context, value, child) {
        final localProgress = ((value - clampedDelay) / (1 - clampedDelay))
            .clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(localProgress);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - eased)),
            child: Transform.scale(
              scale: 0.985 + (0.015 * eased),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _DockNavItemData {
  const _DockNavItemData({
    required this.view,
    required this.icon,
    required this.label,
  });

  final _View view;
  final IconData icon;
  final String label;
}

class _DockNotchClipper extends CustomClipper<Path> {
  const _DockNotchClipper();

  @override
  Path getClip(Size size) {
    const radius = 30.0;
    final centerX = size.width / 2;
    const notchRadius = 43.0;
    const notchDepth = 25.0;
    final notchStart = centerX - notchRadius;
    final notchEnd = centerX + notchRadius;

    return Path()
      ..moveTo(radius, 0)
      ..lineTo(notchStart, 0)
      ..cubicTo(centerX - 31, 0, centerX - 33, notchDepth, centerX, notchDepth)
      ..cubicTo(centerX + 33, notchDepth, centerX + 31, 0, notchEnd, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant _DockNotchClipper oldClipper) => false;
}

class _DockNavItem extends StatelessWidget {
  const _DockNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _DockNavItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppTheme.primaryColor;
    final inactiveColor = AppTheme.mutedText.withValues(alpha: 0.78);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 42,
              height: 32,
              decoration: BoxDecoration(
                color: selected
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                item.icon,
                size: 24,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? activeColor : inactiveColor,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockCenterButton extends StatelessWidget {
  const _DockCenterButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: expanded ? Colors.white : AppTheme.primaryColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 7),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondaryText.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: AnimatedRotation(
          turns: expanded ? 0.125 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Icon(
            expanded ? Icons.close_rounded : Icons.add_rounded,
            color: expanded ? AppTheme.secondaryText : Colors.white,
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _NavActionBubble extends StatelessWidget {
  const _NavActionBubble({
    required this.width,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: 50,
          padding: const EdgeInsets.fromLTRB(8, 7, 14, 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.10),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.075),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.10),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 9),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.secondaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
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
          final floatA = math.sin(phase * 1.18);
          final floatB = math.cos(phase * 1.34);

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        AppTheme.backgroundColor,
                        AppTheme.creamSurfaceColor,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: _HomeDotPainter())),
              Positioned(
                top: -76 + (slowDrift * 8),
                right: -68 + (slowWave * 6),
                child: const _BokehOrb(
                  size: 236,
                  color: AppTheme.blushSurfaceColor,
                  glowColor: AppTheme.primaryColor,
                  opacity: 0.34,
                  blur: 18,
                ),
              ),
              Positioned(
                top: 88 + (floatA * 9),
                left: -42 + (slowDrift * 6),
                child: const _BokehOrb(
                  size: 138,
                  color: Colors.white,
                  glowColor: AppTheme.warmSurfaceColor,
                  opacity: 0.72,
                  blur: 12,
                ),
              ),
              Positioned(
                top: 242 + (floatB * 8),
                right: 24 + (slowWave * 5),
                child: const _BokehOrb(
                  size: 132,
                  color: AppTheme.roseSurfaceColor,
                  glowColor: AppTheme.primaryColor,
                  opacity: 0.18,
                  blur: 20,
                ),
              ),
              Positioned(
                top: 392 + (slowDrift * 7),
                left: 56 + (floatB * 4),
                child: const _BokehOrb(
                  size: 92,
                  color: Colors.white,
                  glowColor: AppTheme.blushSurfaceColor,
                  opacity: 0.58,
                  blur: 10,
                ),
              ),
              Positioned(
                bottom: 246 + (slowWave * 8),
                left: -54 + (floatA * 5),
                child: const _BokehOrb(
                  size: 168,
                  color: AppTheme.creamSurfaceColor,
                  glowColor: AppTheme.warmSurfaceColor,
                  opacity: 0.62,
                  blur: 16,
                ),
              ),
              Positioned(
                bottom: 84 + (slowDrift * 7),
                right: -64 + (floatB * 6),
                child: const _BokehOrb(
                  size: 218,
                  color: Colors.white,
                  glowColor: AppTheme.blushSurfaceColor,
                  opacity: 0.62,
                  blur: 16,
                ),
              ),
              Positioned(
                bottom: -56 + (floatA * 5),
                left: 26 + (slowWave * 5),
                child: const _BokehOrb(
                  size: 176,
                  color: AppTheme.blushSurfaceColor,
                  glowColor: AppTheme.primaryColor,
                  opacity: 0.20,
                  blur: 22,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.2, -0.38),
                      radius: 1.18,
                      colors: [
                        Colors.white.withValues(alpha: 0.28),
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0),
                      ],
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

class _HomeDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = AppTheme.primaryColor.withValues(alpha: 0.04);
    for (double y = 18; y < size.height; y += 32) {
      for (double x = 18; x < size.width; x += 32) {
        canvas.drawCircle(Offset(x, y), 2.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BokehOrb extends StatelessWidget {
  const _BokehOrb({
    required this.size,
    required this.color,
    required this.glowColor,
    required this.opacity,
    required this.blur,
  });

  final double size;
  final Color color;
  final Color glowColor;
  final double opacity;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.32, -0.34),
            radius: 0.98,
            colors: [
              Colors.white.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.84),
              glowColor.withValues(alpha: opacity * 0.16),
              color.withValues(alpha: 0),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: opacity * 0.52),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: opacity * 0.18),
              blurRadius: 54,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Align(
          alignment: const Alignment(-0.36, -0.34),
          child: Container(
            width: size * 0.24,
            height: size * 0.24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: opacity * 0.34),
            ),
          ),
        ),
      ),
    );
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
      AppTheme.warmSurfaceColor,
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
          borderColor: AppTheme.primaryColor.withValues(alpha: 0.12),
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
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: expanded
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
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
                    width: expanded ? 18 : 16,
                    color: AppTheme.secondaryText,
                  ),
                  const SizedBox(height: 4),
                  _MenuLine(
                    width: expanded ? 12 : 22,
                    color: AppTheme.secondaryText,
                  ),
                  const SizedBox(height: 4),
                  _MenuLine(
                    width: expanded ? 18 : 14,
                    color: AppTheme.secondaryText,
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
                border: Border.all(
                  color: AppTheme.warmSurfaceColor.withValues(alpha: 0.42),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.06),
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
                border: Border.all(
                  color: AppTheme.warmSurfaceColor.withValues(alpha: 0.42),
                  width: 1,
                ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minWidth: 126),
        padding: const EdgeInsets.fromLTRB(6, 5, 16, 5),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryColor, Color(0xFF934247)],
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor.withValues(alpha: 0.72)
                : AppTheme.primaryColor.withValues(alpha: 0.10),
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.045),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.95)
                    : AppTheme.blushSurfaceColor.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? Colors.white
                      : AppTheme.primaryColor.withValues(alpha: 0.08),
                  width: 1.2,
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
            const SizedBox(width: 11),
            Text(
              pet.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? Colors.white : AppTheme.secondaryText,
                fontWeight: FontWeight.w900,
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
        size: 38,
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
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(scale: 0.96 + (0.04 * value), child: child);
        },
        child: Container(
          constraints: const BoxConstraints(minWidth: 132),
          padding: const EdgeInsets.fromLTRB(6, 5, 16, 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.10),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.blushSurfaceColor.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1.4),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add Pet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.secondaryText,
                      fontWeight: FontWeight.w900,
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
      decoration: AppTheme.glassCardDecoration(
        color: Colors.white,
        borderColor: color.withValues(alpha: 0.22),
      ),
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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
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
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.10),
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
      opacity: 1,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        scale: bursting ? 1.025 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: AppTheme.glassCardDecoration(
            color: Colors.white,
            borderColor: completed
                ? AppTheme.primaryColor.withValues(alpha: 0.22)
                : AppTheme.primaryColor.withValues(alpha: 0.24),
            borderWidth: 1.6,
          ),
          padding: const EdgeInsets.fromLTRB(15, 14, 14, 14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: completed
                      ? AppTheme.primaryColor.withValues(alpha: 0.86)
                      : AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(mission.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: completed
                            ? AppTheme.creamSurfaceColor.withValues(alpha: 0.9)
                            : AppTheme.blushSurfaceColor.withValues(
                                alpha: 0.86,
                              ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '+${mission.reward} treats XP',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: completed
                              ? AppTheme.primaryColor
                              : AppTheme.primaryColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      )
                    : GestureDetector(
                        onTapDown: (details) => onTap(details.globalPosition),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.blushSurfaceColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.28,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.76,
                            ),
                            size: 16,
                          ),
                        ),
                      ),
              ),
            ],
          ),
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
    Widget chip(String text, _VetFilter filter) {
      final selected = current == filter;
      return InkWell(
        onTap: () => onChanged(filter),
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? Colors.white : AppTheme.mutedText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.10),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip('All', _VetFilter.all),
          chip('Online', _VetFilter.online),
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
          color: dark ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(32),
          borderColor: dark
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withValues(alpha: 0.12),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: dark ? Colors.white : AppTheme.blushSurfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: dark ? AppTheme.primaryColor : AppTheme.primaryColor,
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
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(32),
          borderColor: (vet.online ? AppTheme.successColor : AppTheme.mutedText)
              .withValues(alpha: 0.16),
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
                        color: vet.online
                            ? AppTheme.successColor.withValues(alpha: 0.13)
                            : AppTheme.blushSurfaceColor.withValues(
                                alpha: 0.72,
                              ),
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
                        : AppTheme.creamSurfaceColor.withValues(alpha: 0.82),
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
                          : AppTheme.creamSurfaceColor.withValues(alpha: 0.82),
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
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.10),
            width: 1.1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w800,
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
    final textColor = AppTheme.secondaryText;
    final mutedColor = AppTheme.mutedText;
    return Container(
      decoration: AppTheme.glassCardDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderColor: AppTheme.warmSurfaceColor.withValues(alpha: 0.38),
        borderWidth: 1.2,
      ),
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                      ),
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
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.urgency,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '"${item.result}"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: mutedColor,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
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
    final textColor = AppTheme.secondaryText;
    final mutedColor = AppTheme.mutedText;
    return Container(
      decoration: AppTheme.glassCardDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderColor: AppTheme.warmSurfaceColor.withValues(alpha: 0.38),
        borderWidth: 1.2,
      ),
      padding: const EdgeInsets.all(18),
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
                child: Icon(Icons.history_rounded, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.date,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                      ),
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
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.urgency,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '"${item.result}"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: mutedColor,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
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
      decoration: AppTheme.glassCardDecoration(
        color: Colors.white,
        borderColor: iconColor.withValues(alpha: 0.16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
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
        decoration: AppTheme.glassCardDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderColor: AppTheme.secondaryColor.withValues(alpha: 0.13),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1EC),
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
  });

  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppTheme.secondaryText.withValues(alpha: 0.08),
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
                color: tint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(icon, size: 18, color: tint),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
            color: selected
                ? AppTheme.secondaryColor.withValues(alpha: 0.34)
                : AppTheme.warmSurfaceColor.withValues(alpha: 0.46),
            width: selected ? 1.8 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppTheme.primaryColor.withValues(alpha: 0.08)
                  : AppTheme.secondaryColor.withValues(alpha: 0.06),
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
                    ? AppTheme.blushSurfaceColor.withValues(alpha: 0.74)
                    : AppTheme.creamSurfaceColor.withValues(alpha: 0.66),
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
        ? AppTheme.accentColor
        : AppTheme.primaryColor;

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
