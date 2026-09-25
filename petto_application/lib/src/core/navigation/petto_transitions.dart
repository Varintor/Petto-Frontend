import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A short, opaque route transition used throughout Petto.
///
/// Keeping the incoming page opaque and avoiding a cross-fade prevents the
/// outgoing screen from showing through while still giving navigation a soft
/// sense of direction.
class PettoPageRoute<T> extends PageRouteBuilder<T> {
  PettoPageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog = false,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionDuration: AppTheme.pageTransitionDuration,
         reverseTransitionDuration: AppTheme.pageTransitionReverseDuration,
         opaque: true,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return PettoTransitions.buildPageTransition(
             context: context,
             animation: animation,
             child: child,
             fullscreenDialog: fullscreenDialog,
           );
         },
       );
}

abstract final class PettoTransitions {
  static Widget buildPageTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Widget child,
    bool fullscreenDialog = false,
  }) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return child;
    }

    final curved = CurvedAnimation(
      parent: animation,
      curve: AppTheme.motionCurveSoft,
      reverseCurve: AppTheme.motionReverseCurve,
    );
    final begin = fullscreenDialog
        ? const Offset(0, 0.018)
        : const Offset(0.014, 0);

    return ClipRect(
      child: SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }

  /// AnimatedSwitcher layout that never paints two full screens together.
  static Widget currentChildOnly(
    Widget? currentChild,
    List<Widget> previousChildren,
  ) {
    return currentChild ?? const SizedBox.shrink();
  }

  static Widget buildSectionTransition(
    Widget child,
    Animation<double> animation,
  ) {
    return Builder(
      builder: (context) {
        if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
          return child;
        }
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppTheme.motionCurveSoft,
          reverseCurve: AppTheme.motionReverseCurve,
        );
        return ClipRect(
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.008, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
