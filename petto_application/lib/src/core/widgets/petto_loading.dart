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
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: AppTheme.subtleShadow,
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
                (onDark ? Colors.white.withValues(alpha: 0.45) : Colors.white),
            width: onDark && borderColor == null ? 2 : 3,
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
            _PettoIndeterminateTrack(height: compact ? 5 : 7, onDark: onDark),
          ],
        ),
      ),
    );
  }
}

/// A quiet, centered loader for transitions where the whole screen is waiting.
/// It deliberately avoids a large card so it does not look like page content.
class PettoPageProgress extends StatelessWidget {
  const PettoPageProgress({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.pets_rounded,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '$title${subtitle == null ? '' : ', $subtitle'}',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 330),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.blushSurfaceColor,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: AppTheme.subtleShadow,
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 31),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTheme.displayFontFamily,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.secondaryText,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTheme.sansFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const SizedBox(
                  width: 76,
                  child: _PettoIndeterminateTrack(height: 6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact status row for loading inside an existing card, map, or panel.
class PettoStatusProgress extends StatelessWidget {
  const PettoStatusProgress({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.sync_rounded,
    this.onDark = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? Colors.white : AppTheme.secondaryText;
    final muted = onDark
        ? Colors.white.withValues(alpha: 0.72)
        : AppTheme.mutedText;
    return Semantics(
      liveRegion: true,
      label: '$title${subtitle == null ? '' : ', $subtitle'}',
      child: Container(
        constraints: const BoxConstraints(maxWidth: 390),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: AppTheme.glassCardDecoration(
          color: onDark
              ? Colors.black.withValues(alpha: 0.18)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          borderColor: Colors.white,
          borderWidth: onDark ? 2 : 3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: onDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : AppTheme.blushSurfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: onDark ? 0.55 : 1),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: onDark ? Colors.white : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 11),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: foreground,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.sansFontFamily,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 30,
              child: _PettoIndeterminateTrack(height: 5, onDark: onDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _PettoIndeterminateTrack extends StatelessWidget {
  const _PettoIndeterminateTrack({this.height = 6, this.onDark = false});

  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: height,
        backgroundColor: onDark
            ? Colors.white.withValues(alpha: 0.18)
            : AppTheme.primaryColor.withValues(alpha: 0.10),
        valueColor: AlwaysStoppedAnimation<Color>(
          onDark ? Colors.white : AppTheme.primaryColor,
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
