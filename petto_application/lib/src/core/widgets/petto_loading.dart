import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

class PettoSkeletonBox extends StatelessWidget {
  const PettoSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 18,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      period: const Duration(milliseconds: 1350),
      baseColor: AppTheme.warmSurfaceColor.withValues(alpha: 0.52),
      highlightColor: AppTheme.surfaceColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.warmSurfaceColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class PettoPageSkeleton extends StatelessWidget {
  const PettoPageSkeleton({
    super.key,
    this.itemCount = 3,
    this.showHeader = true,
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 32),
    this.compact = false,
  });

  final int itemCount;
  final bool showHeader;
  final EdgeInsets padding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardHeight = compact ? 82.0 : 108.0;
          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - padding.vertical,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader) ...[
                    Row(
                      children: [
                        const PettoSkeletonBox(
                          width: 54,
                          height: 54,
                          radius: 20,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              PettoSkeletonBox(
                                width: 174,
                                height: 20,
                                radius: 10,
                              ),
                              SizedBox(height: 9),
                              PettoSkeletonBox(
                                width: 118,
                                height: 12,
                                radius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  const PettoSkeletonBox(width: 132, height: 16, radius: 8),
                  const SizedBox(height: 14),
                  for (var i = 0; i < itemCount; i++) ...[
                    _PettoSkeletonCard(height: cardHeight, compact: compact),
                    if (i != itemCount - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PettoCardSkeleton extends StatelessWidget {
  const PettoCardSkeleton({super.key, this.height = 112, this.compact = false});

  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _PettoSkeletonCard(height: height, compact: compact);
  }
}

class _PettoSkeletonCard extends StatelessWidget {
  const _PettoSkeletonCard({required this.height, required this.compact});

  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(compact ? 22 : 26),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          PettoSkeletonBox(
            width: compact ? 46 : 58,
            height: compact ? 46 : 58,
            radius: compact ? 17 : 21,
          ),
          SizedBox(width: compact ? 12 : 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PettoSkeletonBox(
                  width: compact ? 146 : 188,
                  height: compact ? 15 : 18,
                  radius: 9,
                ),
                const SizedBox(height: 10),
                const FractionallySizedBox(
                  widthFactor: 0.72,
                  child: PettoSkeletonBox(height: 11, radius: 7),
                ),
                if (!compact) ...[
                  const SizedBox(height: 8),
                  const FractionallySizedBox(
                    widthFactor: 0.44,
                    child: PettoSkeletonBox(height: 10, radius: 6),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PettoChatSkeleton extends StatelessWidget {
  const PettoChatSkeleton({super.key, this.padding = const EdgeInsets.all(20)});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Align(
            alignment: Alignment.centerLeft,
            child: PettoSkeletonBox(width: 220, height: 72, radius: 24),
          ),
          SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: PettoSkeletonBox(width: 176, height: 58, radius: 22),
          ),
          SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: PettoSkeletonBox(width: 252, height: 92, radius: 24),
          ),
        ],
      ),
    );
  }
}

class PettoInlineProgress extends StatelessWidget {
  const PettoInlineProgress({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.auto_awesome_rounded,
    this.compact = false,
    this.onDark = false,
    this.borderColor,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool compact;
  final bool onDark;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? Colors.white : AppTheme.secondaryText;
    final muted = onDark
        ? Colors.white.withValues(alpha: 0.72)
        : AppTheme.mutedText;
    final track = onDark
        ? Colors.white.withValues(alpha: 0.18)
        : AppTheme.primaryColor.withValues(alpha: 0.10);

    return Semantics(
      liveRegion: true,
      label: '$title${subtitle == null ? '' : ', $subtitle'}',
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: EdgeInsets.all(compact ? 14 : 20),
        decoration: BoxDecoration(
          color: onDark
              ? Colors.white.withValues(alpha: 0.10)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(compact ? 20 : 28),
          border: Border.all(
            color:
                borderColor ??
                (onDark
                    ? Colors.white.withValues(alpha: 0.22)
                    : AppTheme.primaryColor.withValues(alpha: 0.10)),
            width: borderColor == null ? 1 : 3,
          ),
          boxShadow: onDark ? null : AppTheme.subtleShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: compact ? 38 : 48,
                  height: compact ? 38 : 48,
                  decoration: BoxDecoration(
                    color: onDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : AppTheme.blushSurfaceColor,
                    borderRadius: BorderRadius.circular(compact ? 14 : 18),
                  ),
                  child: Icon(
                    icon,
                    size: compact ? 20 : 24,
                    color: onDark ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.displayFontFamily,
                          fontSize: compact ? 15 : 18,
                          fontWeight: FontWeight.w800,
                          color: foreground,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.sansFontFamily,
                            fontSize: compact ? 11 : 12,
                            fontWeight: FontWeight.w600,
                            color: muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 12 : 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: compact ? 6 : 8,
                color: track,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.62,
                  child: Shimmer.fromColors(
                    period: const Duration(milliseconds: 1150),
                    baseColor: AppTheme.primaryColor,
                    highlightColor: onDark
                        ? AppTheme.roseSurfaceColor
                        : AppTheme.secondaryColor,
                    child: Container(color: AppTheme.primaryColor),
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

class PettoButtonProgress extends StatelessWidget {
  const PettoButtonProgress({
    super.key,
    this.onDark = true,
    this.width = 42,
    this.height = 7,
  });

  final bool onDark;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final base = onDark
        ? Colors.white.withValues(alpha: 0.46)
        : AppTheme.primaryColor.withValues(alpha: 0.18);
    final highlight = onDark
        ? Colors.white
        : AppTheme.primaryColor.withValues(alpha: 0.52);
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Shimmer.fromColors(
          period: const Duration(milliseconds: 950),
          baseColor: base,
          highlightColor: highlight,
          child: ColoredBox(color: base),
        ),
      ),
    );
  }
}
