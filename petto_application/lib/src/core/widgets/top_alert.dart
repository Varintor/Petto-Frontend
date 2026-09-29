import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

_TopAlertHandle? _activeTopAlert;
_TopAlertRequest? _queuedTopAlert;

void showTopAlert(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_rounded,
  Duration duration = const Duration(milliseconds: 2800),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null || message.trim().isEmpty) return;

  final request = _TopAlertRequest(
    overlay: overlay,
    message: message.trim(),
    icon: icon,
    duration: duration,
  );
  final active = _activeTopAlert;
  if (active != null && active.key.currentState == null) {
    if (active.entry.mounted) active.entry.remove();
    _activeTopAlert = null;
    _showRequest(request);
    return;
  }
  if (active != null) {
    _queuedTopAlert = request;
    active.dismiss();
    return;
  }
  _showRequest(request);
}

void _showRequest(_TopAlertRequest request) {
  final key = GlobalKey<_TopAlertOverlayState>();
  late final OverlayEntry entry;
  late final _TopAlertHandle handle;
  entry = OverlayEntry(
    builder: (context) => _TopAlertOverlay(
      key: key,
      message: request.message,
      icon: request.icon,
      duration: request.duration,
      onDismissed: () {
        if (entry.mounted) entry.remove();
        if (identical(_activeTopAlert, handle)) _activeTopAlert = null;
        final queued = _queuedTopAlert;
        _queuedTopAlert = null;
        if (queued != null) _showRequest(queued);
      },
    ),
  );
  handle = _TopAlertHandle(entry: entry, key: key);
  _activeTopAlert = handle;
  request.overlay.insert(entry);
}

class _TopAlertRequest {
  const _TopAlertRequest({
    required this.overlay,
    required this.message,
    required this.icon,
    required this.duration,
  });

  final OverlayState overlay;
  final String message;
  final IconData icon;
  final Duration duration;
}

class _TopAlertHandle {
  const _TopAlertHandle({required this.entry, required this.key});

  final OverlayEntry entry;
  final GlobalKey<_TopAlertOverlayState> key;

  void dismiss() {
    final state = key.currentState;
    if (state != null) {
      state.dismiss();
    } else if (entry.mounted) {
      entry.remove();
      _activeTopAlert = null;
    }
  }
}

class _TopAlertOverlay extends StatefulWidget {
  const _TopAlertOverlay({
    super.key,
    required this.message,
    required this.icon,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_TopAlertOverlay> createState() => _TopAlertOverlayState();
}

class _TopAlertOverlayState extends State<_TopAlertOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Timer? _timer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _controller.forward();
    _timer = Timer(widget.duration, dismiss);
  }

  Future<void> dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _timer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    if (_activeTopAlert?.key == widget.key) {
      _activeTopAlert = null;
      _queuedTopAlert = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.7),
                    end: Offset.zero,
                  ).animate(_animation),
                  child: FadeTransition(
                    opacity: _animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.97,
                        end: 1,
                      ).animate(_animation),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF8B3439),
                                AppTheme.primaryColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondaryText.withValues(
                                  alpha: 0.26,
                                ),
                                blurRadius: 26,
                                spreadRadius: -8,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.icon,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.message,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.sansFontFamily,
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.25,
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
