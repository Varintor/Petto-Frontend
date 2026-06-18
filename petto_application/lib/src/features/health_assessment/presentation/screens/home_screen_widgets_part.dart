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
                width: 248,
                height: 232,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    const _RoomSparkles(),
                    SizedBox(
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
                  ],
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
  const _BottomOverlay({required this.child, this.expand = false});

  final Widget child;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final maxPanelHeight =
        media.size.height - media.padding.top - keyboardInset - 12;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppTheme.motionNormal,
      curve: AppTheme.motionCurveSoft,
      builder: (context, value, child) {
        final eased = Curves.easeOutQuint.transform(value);
        final panelMaxHeight = math.max(240.0, maxPanelHeight);
        final panelChild = Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..translateByDouble(0, 24 * (1 - eased), 0, 1)
            ..scaleByDouble(0.985 + (0.015 * eased), 1, 1, 1),
          child: Opacity(opacity: eased, child: child),
        );
        return Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 9 * eased, sigmaY: 9 * eased),
            child: Container(
              color: AppTheme.secondaryColor.withValues(alpha: 0.13 * eased),
              alignment: Alignment.bottomCenter,
              child: AnimatedPadding(
                duration: AppTheme.motionFast,
                curve: AppTheme.motionCurve,
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: expand
                    ? SizedBox(height: panelMaxHeight, child: panelChild)
                    : ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: panelMaxHeight),
                        child: panelChild,
                      ),
              ),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: AppTheme.glassCardDecoration(
          color: AppTheme.surfaceColor,
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
      duration: Duration(milliseconds: 460 + (clampedDelay * 320).round()),
      curve: Curves.linear,
      builder: (context, value, child) {
        final localProgress = ((value - clampedDelay) / (1 - clampedDelay))
            .clamp(0.0, 1.0);
        final eased = AppTheme.motionCurve.transform(localProgress);
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

class _RoomSparkles extends StatefulWidget {
  const _RoomSparkles();

  @override
  State<_RoomSparkles> createState() => _RoomSparklesState();
}

class _RoomSparklesState extends State<_RoomSparkles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        size: const Size(248, 232),
        painter: _RoomSparklePainter(_controller.value),
      ),
    );
  }
}

class _RoomSparklePainter extends CustomPainter {
  const _RoomSparklePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final points = <_SparklePoint>[
      _SparklePoint(
        offset: Offset(size.width * 0.18, size.height * 0.28),
        size: 9,
        phase: 0.0,
        color: AppTheme.accentColor,
      ),
      _SparklePoint(
        offset: Offset(size.width * 0.82, size.height * 0.23),
        size: 7,
        phase: 0.22,
        color: AppTheme.secondaryColor,
      ),
      _SparklePoint(
        offset: Offset(size.width * 0.24, size.height * 0.70),
        size: 6,
        phase: 0.48,
        color: AppTheme.secondaryColor,
      ),
      _SparklePoint(
        offset: Offset(size.width * 0.78, size.height * 0.72),
        size: 8,
        phase: 0.64,
        color: AppTheme.accentColor,
      ),
      _SparklePoint(
        offset: Offset(size.width * 0.50, size.height * 0.09),
        size: 5,
        phase: 0.84,
        color: AppTheme.primaryColor,
      ),
    ];

    for (final point in points) {
      final cycle = ((progress + point.phase) % 1.0);
      final pulse = math.sin(cycle * math.pi);
      final alpha = 0.18 + (pulse * 0.38);
      final drift = Offset(0, -2.5 * pulse);
      _drawSparkle(
        canvas,
        point.offset + drift,
        point.size * (0.82 + pulse * 0.28),
        point.color.withValues(alpha: alpha),
      );
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final softPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, size * 0.9, softPaint);

    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..quadraticBezierTo(
        center.dx + size * 0.22,
        center.dy - size * 0.22,
        center.dx + size,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx + size * 0.22,
        center.dy + size * 0.22,
        center.dx,
        center.dy + size,
      )
      ..quadraticBezierTo(
        center.dx - size * 0.22,
        center.dy + size * 0.22,
        center.dx - size,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx - size * 0.22,
        center.dy - size * 0.22,
        center.dx,
        center.dy - size,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoomSparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SparklePoint {
  const _SparklePoint({
    required this.offset,
    required this.size,
    required this.phase,
    required this.color,
  });

  final Offset offset;
  final double size;
  final double phase;
  final Color color;
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, this.large = false});

  final _NotificationData item;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(large ? 14 : 10),
      decoration: BoxDecoration(
        color: large
            ? AppTheme.surfaceColor.withValues(alpha: 0.98)
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(large ? 24 : 20),
        border: Border.all(
          color: item.unread
              ? AppTheme.primaryColor.withValues(alpha: large ? 0.18 : 0.12)
              : AppTheme.warmSurfaceColor.withValues(alpha: 0.46),
          width: large ? 1.4 : 1,
        ),
        boxShadow: large
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.055),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: large ? 48 : 38,
            height: large ? 48 : 38,
            decoration: BoxDecoration(
              color: item.tint.withValues(alpha: large ? 0.13 : 0.10),
              borderRadius: BorderRadius.circular(large ? 18 : 15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1,
              ),
            ),
            child: Icon(item.icon, color: item.tint, size: large ? 22 : 19),
          ),
          SizedBox(width: large ? 12 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppTheme.secondaryText,
                              fontWeight: FontWeight.w900,
                              fontSize: large ? 14 : null,
                            ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: large ? 9 : 7,
                        vertical: large ? 5 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: item.unread
                            ? AppTheme.primaryColor.withValues(alpha: 0.10)
                            : AppTheme.creamSurfaceColor.withValues(
                                alpha: 0.72,
                              ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: item.unread
                              ? AppTheme.primaryColor.withValues(alpha: 0.10)
                              : AppTheme.warmSurfaceColor.withValues(
                                  alpha: 0.55,
                                ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.unread) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            item.time,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: item.unread
                                      ? AppTheme.primaryColor
                                      : AppTheme.mutedText,
                                  fontSize: large ? 10 : 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                    height: large ? 1.35 : 1.25,
                    fontWeight: FontWeight.w600,
                    fontSize: large ? 12 : null,
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
    const activeColor = Colors.white;
    final inactiveColor = AppTheme.creamSurfaceColor.withValues(alpha: 0.68);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: AppTheme.motionFast,
        curve: AppTheme.motionCurve,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppTheme.motionFast,
              curve: AppTheme.motionCurve,
              width: 42,
              height: 32,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.transparent,
                  width: 1,
                ),
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
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.25,
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
          color: expanded ? AppTheme.surfaceColor : AppTheme.primaryColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: expanded
                ? AppTheme.primaryColor.withValues(alpha: 0.18)
                : AppTheme.surfaceColor,
            width: 7,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondaryText.withValues(alpha: 0.24),
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
            color: expanded ? AppTheme.primaryColor : Colors.white,
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
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
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
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 9),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
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

class _BackgroundDecor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFFFFC),
                    AppTheme.backgroundColor,
                    const Color(0xFFFAF7F1),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _HomeDotPainter())),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.2, -0.38),
                  radius: 1.18,
                  colors: [
                    Colors.white.withValues(alpha: 0.20),
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = AppTheme.primaryColor.withValues(alpha: 0.045);
    for (double y = 18; y < size.height; y += 32) {
      for (double x = 18; x < size.width; x += 32) {
        canvas.drawCircle(Offset(x, y), 2.1, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          borderColor: AppTheme.primaryColor.withValues(alpha: 0.12),
        ),
        child: Icon(icon, color: AppTheme.secondaryText, size: 20),
      ),
    );
  }
}

class _CalendarArrowButton extends StatelessWidget {
  const _CalendarArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 21),
      ),
    );
  }
}

class _CalendarMonthHeader extends StatelessWidget {
  const _CalendarMonthHeader({
    required this.month,
    required this.year,
    required this.onPrevious,
    required this.onNext,
  });

  final String month;
  final int year;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                month,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.secondaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$year Events',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.mutedText,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.warmSurfaceColor.withValues(alpha: 0.72),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              _CalendarArrowButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPrevious,
              ),
              const SizedBox(width: 4),
              _CalendarArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: onNext,
              ),
            ],
          ),
        ),
      ],
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
                color: AppTheme.surfaceColor.withValues(alpha: 0.96),
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
                color: AppTheme.surfaceColor.withValues(alpha: 0.94),
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
        duration: AppTheme.motionFast,
        curve: AppTheme.motionCurve,
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
          color: selected
              ? null
              : AppTheme.surfaceColor.withValues(alpha: 0.82),
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
                    color: AppTheme.primaryColor.withValues(alpha: 0.10),
                    blurRadius: 18,
                    spreadRadius: -6,
                    offset: const Offset(0, 7),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppTheme.secondaryText.withValues(alpha: 0.035),
                    blurRadius: 16,
                    spreadRadius: -7,
                    offset: const Offset(0, 8),
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
            color: AppTheme.surfaceColor.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.10),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryText.withValues(alpha: 0.035),
                blurRadius: 16,
                spreadRadius: -7,
                offset: const Offset(0, 8),
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
        color: AppTheme.surfaceColor,
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
    this.rewardAccessory,
  });

  final _MissionData mission;
  final bool completed;
  final bool bursting;
  final ValueChanged<Offset> onTap;

  /// Cosmetic granted when this mission is completed. Shown as the reward
  /// chip; falls back to the legacy "+X treats XP" badge when null (mission
  /// type isn't mapped to an accessory yet).
  final _AccessoryData? rewardAccessory;

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
            color: AppTheme.surfaceColor,
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (rewardAccessory != null) ...[
                            Text(
                              rewardAccessory!.emoji,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            rewardAccessory != null
                                ? rewardAccessory!.name
                                : '+${mission.reward} treats XP',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                          ),
                        ],
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
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.mutedText,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CalendarScheduleHeader extends StatelessWidget {
  const _CalendarScheduleHeader({
    required this.title,
    required this.selectedEvents,
    required this.onAdd,
  });

  final String title;
  final int selectedEvents;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
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
                selectedEvents == 0
                    ? 'A quiet care day'
                    : '$selectedEvents plan${selectedEvents == 1 ? '' : 's'} ready',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.mutedText,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppTheme.surfaceColor.withValues(alpha: 0.72),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Add',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
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

class _NoPlansCard extends StatelessWidget {
  const _NoPlansCard({required this.petName, required this.onAdd});

  final String petName;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 184),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppTheme.warmSurfaceColor.withValues(alpha: 0.74),
          width: 1.4,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.blushSurfaceColor.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
              ),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: AppTheme.primaryColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No plan yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              '$petName has a calm day. Add a care plan when needed.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedText,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppTheme.surfaceColor.withValues(alpha: 0.74),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_task_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Create plan',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarPlanTypeChip extends StatelessWidget {
  const _CalendarPlanTypeChip({
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
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : AppTheme.creamSurfaceColor.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.warmSurfaceColor.withValues(alpha: 0.70),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppTheme.primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
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

class _HomeCalendarDayChip extends StatelessWidget {
  const _HomeCalendarDayChip({
    required this.date,
    required this.selected,
    required this.hasEvent,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool hasEvent;
  final VoidCallback onTap;

  String get _weekday {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 62,
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.blushSurfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryColor
                  : AppTheme.primaryColor.withValues(alpha: 0.08),
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _weekday,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? Colors.white70 : AppTheme.mutedText,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${date.day}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? Colors.white : AppTheme.secondaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: hasEvent ? 6 : 3,
                height: hasEvent ? 6 : 3,
                decoration: BoxDecoration(
                  color: hasEvent
                      ? (selected ? Colors.white : AppTheme.primaryColor)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCalendarEventTile extends StatelessWidget {
  const _HomeCalendarEventTile({required this.event});

  final _CalendarEventData event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.creamSurfaceColor.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(event.icon, color: event.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  event.timeLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: event.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            event.completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: event.completed
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withValues(alpha: 0.32),
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({required this.event, this.onDelete});

  final _CalendarEventData event;

  /// When provided, a small trash icon is rendered and tapping it invokes the
  /// callback. Used by [_buildCalendarView] so users can remove plans.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCardDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        borderColor: AppTheme.primaryColor.withValues(alpha: 0.11),
        borderWidth: 1.4,
      ),
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: event.color.withValues(alpha: 0.10)),
            ),
            child: Icon(event.icon, color: event.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: event.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    event.timeLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: event.color,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: event.completed
                  ? AppTheme.primaryColor
                  : AppTheme.creamSurfaceColor.withValues(alpha: 0.82),
              shape: BoxShape.circle,
              border: Border.all(
                color: event.completed
                    ? AppTheme.primaryColor
                    : AppTheme.warmSurfaceColor.withValues(alpha: 0.62),
              ),
            ),
            child: Icon(
              event.completed
                  ? Icons.check_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: event.completed
                  ? Colors.white
                  : AppTheme.primaryColor.withValues(alpha: 0.55),
              size: event.completed ? 19 : 18,
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Remove plan',
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.mutedText,
                size: 20,
              ),
            ),
          ],
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
        color: AppTheme.surfaceColor.withValues(alpha: 0.92),
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

class _AssistantSummaryCard extends StatelessWidget {
  const _AssistantSummaryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.onTap,
    required this.trailingLabel,
    required this.onTrailingTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
  final VoidCallback onTap;
  final String trailingLabel;
  final VoidCallback onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 168),
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.glassCardDecoration(
          color: AppTheme.surfaceColor.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(32),
          borderColor: AppTheme.primaryColor.withValues(alpha: 0.13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.secondaryText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedText,
                          height: 1.34,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onTrailingTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 116,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.14),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        trailingLabel,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
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
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 142,
        decoration: AppTheme.glassCardDecoration(
          color: dark ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(28),
          borderColor: dark
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withValues(alpha: 0.12),
        ),
        padding: const EdgeInsets.all(20),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: dark ? Colors.white : AppTheme.secondaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
          color: AppTheme.surfaceColor.withValues(alpha: 0.95),
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
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.16),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.045),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 7),
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

class _AssessmentHistoryCard extends StatelessWidget {
  const _AssessmentHistoryCard({required this.assessment, this.onTap});

  final AssessmentEntity assessment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final riskBucket = assessment.riskBucket;
    final color = _riskColor(riskBucket);
    final riskLabel = _riskLabel(riskBucket);
    final dateLabel = _formatDate(assessment.createdAt);
    final symptomText =
        (assessment.symptoms != null && assessment.symptoms!.isNotEmpty)
        ? assessment.symptoms!
        : 'No symptom description';
    final aiPreview = assessment.aiResponse.length > 120
        ? '${assessment.aiResponse.substring(0, 120)}...'
        : assessment.aiResponse;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: AppTheme.glassCardDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderColor: color.withValues(alpha: 0.22),
          borderWidth: 1.3,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + risk badge row
            if (assessment.imageUri != null && assessment.imageUri!.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: Image.network(
                      assessment.imageUri!,
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _a, _b) => Container(
                        width: double.infinity,
                        height: 140,
                        color: color.withValues(alpha: 0.08),
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: color.withValues(alpha: 0.4),
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        riskLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              // No image — compact header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.mutedText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        riskLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                symptomText,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.secondaryText,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  aiPreview,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _riskColor(String bucket) {
    switch (bucket) {
      case 'high':
        return AppTheme.primaryColor;
      case 'moderate':
        return AppTheme.accentColor;
      default:
        return AppTheme.successColor;
    }
  }

  String _riskLabel(String bucket) {
    switch (bucket) {
      case 'high':
        return 'High Risk';
      case 'moderate':
        return 'Moderate';
      default:
        return 'Low Risk';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _AssessmentDetailScreen extends StatelessWidget {
  const _AssessmentDetailScreen({
    required this.assessment,
    required this.onShareWithVet,
  });

  final AssessmentEntity assessment;
  final VoidCallback onShareWithVet;

  @override
  Widget build(BuildContext context) {
    final riskBucket = assessment.riskBucket;
    final color = _riskColor(riskBucket);
    final riskLabel = _riskLabel(riskBucket);
    final dateLabel = _formatDateTime(assessment.createdAt);
    final symptomText =
        (assessment.symptoms != null && assessment.symptoms!.isNotEmpty)
        ? assessment.symptoms!
        : 'No symptom description';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: Stack(
          children: [
            _BackgroundDecor(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Row(
                      children: [
                        _SquareIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Latest check',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (assessment.imageUri != null &&
                              assessment.imageUri!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.network(
                                assessment.imageUri!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: double.infinity,
                                  height: 210,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: Icon(
                                    Icons.image_not_supported_rounded,
                                    color: color.withValues(alpha: 0.4),
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: AppTheme.glassCardDecoration(
                              color: color.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(30),
                              borderColor: color.withValues(alpha: 0.16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.fact_check_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Assessment Complete',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppTheme.secondaryText,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dateLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppTheme.mutedText,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceColor.withValues(
                                      alpha: 0.88,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    riskLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: color,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: AppTheme.glassCardDecoration(
                              color: AppTheme.surfaceColor.withValues(
                                alpha: 0.98,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              borderColor: AppTheme.primaryColor.withValues(
                                alpha: 0.10,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.09,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.report_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Reported symptoms',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppTheme.secondaryText,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        symptomText,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.mutedText,
                                              height: 1.38,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _AiAnalysisPanel(
                            riskColor: color,
                            riskLabel: riskLabel,
                            symptoms: symptomText,
                            response: assessment.aiResponse,
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton.icon(
                              onPressed: onShareWithVet,
                              icon: const Icon(Icons.send_rounded),
                              label: const Text('Share with Care Team'),
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
        ),
      ),
    );
  }

  Color _riskColor(String bucket) {
    switch (bucket) {
      case 'high':
        return AppTheme.primaryColor;
      case 'moderate':
        return AppTheme.accentColor;
      default:
        return AppTheme.successColor;
    }
  }

  String _riskLabel(String bucket) {
    switch (bucket) {
      case 'high':
        return 'High Risk';
      case 'moderate':
        return 'Moderate';
      default:
        return 'Low Risk';
    }
  }

  String _formatDateTime(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]} • $hour:$minute $suffix';
  }
}

class _AiAnalysisPanel extends StatelessWidget {
  const _AiAnalysisPanel({
    required this.riskColor,
    required this.riskLabel,
    required this.symptoms,
    required this.response,
  });

  final Color riskColor;
  final String riskLabel;
  final String symptoms;
  final String response;

  @override
  Widget build(BuildContext context) {
    final observations = _pointsFrom(
      response,
      fallback: [
        'Review the visible signs together with the reported symptoms.',
        'Track changes in comfort, appetite, breathing, and activity.',
      ],
    );
    final highRisk = riskLabel.toLowerCase().contains('high');
    final concerns = highRisk
        ? [
            'Symptoms may need prompt professional review.',
            'Watch for worsening pain, bleeding, weakness, or breathing changes.',
          ]
        : [
            'Symptoms may be mild, but changes should still be monitored.',
            'Follow up if the condition does not improve.',
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.glassCardDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.99),
        borderRadius: BorderRadius.circular(32),
        borderColor: riskColor.withValues(alpha: 0.16),
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
                  color: riskColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: riskColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AiAnalysisSection(
            icon: Icons.visibility_rounded,
            title: 'Observations',
            color: AppTheme.primaryColor,
            items: observations.take(2).toList(),
          ),
          const SizedBox(height: 10),
          _AiAnalysisSection(
            icon: Icons.health_and_safety_rounded,
            title: 'Potential concerns',
            color: riskColor,
            items: concerns,
          ),
          const SizedBox(height: 10),
          _AiAnalysisSection(
            icon: Icons.lightbulb_rounded,
            title: 'Recommended actions',
            color: AppTheme.accentColor,
            items: [
              'Do: Keep ${_shortSymptom(symptoms)} under close observation.',
              'Do not: Ignore worsening symptoms or sudden behavior changes.',
              'Urgency: Contact your care team if symptoms persist.',
            ],
            itemIcons: const [
              Icons.check_circle_rounded,
              Icons.cancel_rounded,
              Icons.notifications_active_rounded,
            ],
            itemColors: [
              AppTheme.successColor,
              AppTheme.primaryColor,
              AppTheme.accentColor,
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.creamSurfaceColor.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_rounded,
                  color: AppTheme.primaryColor.withValues(alpha: 0.72),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Preliminary AI screening, not a diagnosis. Use this as guidance and consult a veterinarian when concerned.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedText,
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _pointsFrom(String value, {required List<String> fallback}) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return fallback;
    final pieces = cleaned
        .split(RegExp(r'(?<=[.!?])\s+|\n+|•'))
        .map((line) => line.trim())
        .where((line) => line.length > 8)
        .toList();
    if (pieces.isEmpty) return fallback;
    return pieces.take(3).toList();
  }

  String _shortSymptom(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'No symptom description') {
      return 'your pet';
    }
    return trimmed.length > 34 ? '${trimmed.substring(0, 34)}...' : trimmed;
  }
}

class _AiAnalysisSection extends StatelessWidget {
  const _AiAnalysisSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
    this.itemIcons,
    this.itemColors,
  });

  final IconData icon;
  final String title;
  final Color color;
  final List<String> items;
  final List<IconData>? itemIcons;
  final List<Color>? itemColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 9),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.secondaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final entry in items.indexed) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  itemIcons != null && entry.$1 < itemIcons!.length
                      ? itemIcons![entry.$1]
                      : Icons.circle_rounded,
                  size: itemIcons != null ? 16 : 7,
                  color: itemColors != null && entry.$1 < itemColors!.length
                      ? itemColors![entry.$1]
                      : color.withValues(alpha: 0.72),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.$2,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryText.withValues(alpha: 0.86),
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (entry.$1 != items.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _AssessmentDetailSheet extends StatelessWidget {
  const _AssessmentDetailSheet({
    required this.assessment,
    required this.onShareWithVet,
  });

  final AssessmentEntity assessment;
  final VoidCallback onShareWithVet;

  @override
  Widget build(BuildContext context) {
    final riskBucket = assessment.riskBucket;
    final color = _riskColor(riskBucket);
    final riskLabel = _riskLabel(riskBucket);
    final dateLabel = _formatDateTime(assessment.createdAt);
    final symptomText =
        (assessment.symptoms != null && assessment.symptoms!.isNotEmpty)
        ? assessment.symptoms!
        : 'No symptom description';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: AppTheme.glassCardDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(42)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (assessment.imageUri != null &&
                      assessment.imageUri!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        assessment.imageUri!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: color.withValues(alpha: 0.4),
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          riskLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.creamSurfaceColor.withValues(
                            alpha: 0.82,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: AppTheme.mutedText,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              dateLabel,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppTheme.mutedText,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'SYMPTOMS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    symptomText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.secondaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'AI ANALYSIS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.10)),
                    ),
                    child: Text(
                      assessment.aiResponse,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryText,
                        height: 1.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onShareWithVet();
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Share with Vet'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _riskColor(String bucket) {
    switch (bucket) {
      case 'high':
        return AppTheme.primaryColor;
      case 'moderate':
        return AppTheme.accentColor;
      default:
        return AppTheme.successColor;
    }
  }

  String _riskLabel(String bucket) {
    switch (bucket) {
      case 'high':
        return 'High Risk';
      case 'moderate':
        return 'Moderate';
      default:
        return 'Low Risk';
    }
  }

  String _formatDateTime(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute $suffix';
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
        color: AppTheme.surfaceColor.withValues(alpha: 0.96),
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
        color: AppTheme.surfaceColor.withValues(alpha: 0.96),
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
          color: AppTheme.surfaceColor.withValues(alpha: 0.95),
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
          color: AppTheme.surfaceColor.withValues(alpha: 0.92),
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
    required this.unlocked,
    required this.equipped,
    required this.onTap,
  });

  final _AccessoryData accessory;

  /// Runtime unlocked state (read from [_HomeScreenState._unlockedAccessoryIds]
  /// so wardrobe items earned via missions show as unlocked).
  final bool unlocked;
  final bool equipped;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Opacity(
        opacity: unlocked ? 1 : 0.32,
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
              if (!unlocked)
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
