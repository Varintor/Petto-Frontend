import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class PetAvatarWidget extends StatefulWidget {
  const PetAvatarWidget({
    super.key,
    required this.species,
    required this.color,
    this.eyeType = 'default',
    this.mouthType = 'smile',
    this.pattern = 'none',
    this.equipped = const <String>[],
    this.isRotating = false,
    this.headOnly = false,
  });

  final String species;
  final Color color;
  final String eyeType;
  final String mouthType;
  final String pattern;
  final List<String> equipped;
  final bool isRotating;
  final bool headOnly;

  @override
  State<PetAvatarWidget> createState() => _PetAvatarWidgetState();
}

class _PetAvatarWidgetState extends State<PetAvatarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _petted = false;
  final List<_HeartData> _hearts = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePet() {
    setState(() {
      _petted = true;
      _hearts.add(
        _HeartData(
          id: DateTime.now().microsecondsSinceEpoch,
          xOffset: (math.Random().nextDouble() * 0.34) - 0.17,
          start: _controller.value,
        ),
      );
      if (_hearts.length > 5) {
        _hearts.removeAt(0);
      }
    });

    Timer(const Duration(milliseconds: 950), () {
      if (!mounted) return;
      setState(() {
        _petted = false;
        if (_hearts.isNotEmpty) {
          _hearts.removeAt(0);
        }
      });
    });
  }

  double _blinkProgress(double t) {
    double pulse(double start, double width) {
      final delta = (t - start).abs();
      if (delta > width / 2) return 0;
      return 1 - (delta / (width / 2));
    }

    return math.max(pulse(0.18, 0.08), pulse(0.63, 0.06));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final normalized = _controller.value;
        final phase = normalized * math.pi * 2;
        final blink = _blinkProgress(normalized);
        final tiltY = widget.isRotating && !widget.headOnly
            ? math.sin(phase * 0.8) * 0.08
            : 0.0;
        final tiltX = widget.isRotating && !widget.headOnly
            ? math.cos(phase * 0.65) * 0.035
            : 0.0;
        final bob = widget.headOnly ? 0.0 : math.sin(phase * 1.2) * 2.6;
        final scale = _petted
            ? (widget.headOnly ? 1.03 : 1.05)
            : (widget.headOnly ? 1.0 : 1 + (math.sin(phase * 1.2) * 0.01));

        return GestureDetector(
          onTap: widget.headOnly ? null : _handlePet,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              for (final heart in _hearts)
                Positioned(
                  top: 6,
                  child: Transform.translate(
                    offset: Offset(
                      heart.xOffset * 150,
                      -_heartTravel(heart.start, normalized),
                    ),
                    child: Opacity(
                      opacity: 1 - _heartFade(heart.start, normalized),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 24 + (_petted ? 4 : 0),
                        color: const Color(0xFFFF8FA3),
                      ),
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(0, bob),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(tiltX)
                    ..rotateY(tiltY)
                    ..scaleByDouble(scale, scale, 1, 1),
                  child: CustomPaint(
                    size: const Size.square(220),
                    painter: _PetAvatarPainter(
                      species: widget.species,
                      color: widget.color,
                      eyeType: widget.eyeType,
                      mouthType: widget.mouthType,
                      pattern: widget.pattern,
                      equipped: widget.equipped,
                      phase: phase,
                      blink: blink,
                      petted: _petted,
                      headOnly: widget.headOnly,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _heartTravel(double start, double current) {
    final progress = _loopDelta(start, current) / 0.18;
    return (progress.clamp(0.0, 1.0)) * 38;
  }

  double _heartFade(double start, double current) {
    final progress = _loopDelta(start, current) / 0.2;
    return progress.clamp(0.0, 1.0);
  }

  double _loopDelta(double start, double current) {
    if (current >= start) return current - start;
    return (1 - start) + current;
  }
}

class _PetAvatarPainter extends CustomPainter {
  _PetAvatarPainter({
    required this.species,
    required this.color,
    required this.eyeType,
    required this.mouthType,
    required this.pattern,
    required this.equipped,
    required this.phase,
    required this.blink,
    required this.petted,
    required this.headOnly,
  });

  final String species;
  final Color color;
  final String eyeType;
  final String mouthType;
  final String pattern;
  final List<String> equipped;
  final double phase;
  final double blink;
  final bool petted;
  final bool headOnly;

  bool get isDog => species.toLowerCase() == 'dog';

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200;
    final bounce = headOnly
        ? (petted ? -1.2 : 0.0)
        : (petted ? -2.6 : math.sin(phase * 1.15) * 1.4);

    canvas.save();
    canvas.scale(scale, scale);

    if (headOnly) {
      canvas.translate(0, 18);
      canvas.save();
      canvas.translate(0, bounce);
      _paintHead(canvas);
      canvas.restore();
      canvas.restore();
      return;
    }

    _paintShadow(canvas);
    _paintTail(canvas);

    canvas.save();
    canvas.translate(0, bounce);
    _paintBody(canvas);
    _paintHead(canvas);
    _paintPaws(canvas);
    _paintAccessories(canvas);
    canvas.restore();
    canvas.restore();
  }

  void _paintShadow(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 182), width: 96, height: 22),
      Paint()
        ..color = const Color(0xFF25333A).withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  void _paintTail(Canvas canvas) {
    final anchor = isDog ? const Offset(140, 140) : const Offset(138, 146);
    final path = Path()
      ..moveTo(anchor.dx, anchor.dy)
      ..cubicTo(
        anchor.dx + 18,
        anchor.dy - 8,
        anchor.dx + 40,
        anchor.dy - 34,
        anchor.dx + (isDog ? 34 : 26),
        anchor.dy - (isDog ? 72 : 58),
      );

    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(
      math.sin(phase * (isDog ? 2.8 : 2.0)) * (isDog ? 0.4 : 0.24) +
          (petted ? 0.06 : 0),
    );
    canvas.translate(-anchor.dx, -anchor.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = _shade(color, -0.03)
        ..strokeWidth = isDog ? 16 : 13
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..strokeWidth = isDog ? 6 : 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _paintBody(Canvas canvas) {
    final bodyRect = Rect.fromCenter(
      center: const Offset(100, 145),
      width: 80,
      height: 62,
    );
    final body = RRect.fromRectAndRadius(bodyRect, const Radius.circular(36));

    canvas.drawRRect(body, Paint()..color = _shade(color, -0.01));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_shade(color, 0.12), _shade(color, -0.06)],
        ).createShader(bodyRect),
    );

    if (isDog) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(100, 149), width: 34, height: 24),
        Paint()..color = Colors.white.withValues(alpha: 0.78),
      );
    } else if (pattern == 'tabby' || pattern == 'stripes') {
      final stripe = Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(74, 140), const Offset(86, 140), stripe);
      canvas.drawLine(const Offset(114, 140), const Offset(126, 140), stripe);
    }
  }

  void _paintHead(Canvas canvas) {
    _paintEars(canvas);

    final headRect = Rect.fromCenter(
      center: const Offset(100, 90),
      width: 116,
      height: 106,
    );
    final head = RRect.fromRectAndRadius(headRect, const Radius.circular(58));
    canvas.drawRRect(head, Paint()..color = color);
    canvas.drawRRect(
      head,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_shade(color, 0.16), _shade(color, -0.05)],
        ).createShader(headRect),
    );

    _paintPattern(canvas);

    canvas.drawOval(
      Rect.fromLTWH(headRect.left + 14, headRect.top + 14, 34, 20),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    final faceDrift = headOnly
        ? (petted ? -1.0 : 0.0)
        : (petted ? -1.5 : math.sin(phase * 1.4) * 0.9);
    canvas.save();
    canvas.translate(0, faceDrift);
    _paintEyes(canvas);
    _paintCheeks(canvas);
    if (isDog) {
      _paintDogMuzzle(canvas);
    } else {
      _paintCatNose(canvas);
      _paintWhiskers(canvas);
    }
    _paintMouth(canvas);
    canvas.restore();
  }

  void _paintEars(Canvas canvas) {
    final inner = Paint()..color = const Color(0xFFFFB8B3);

    if (isDog) {
      final earPaint = Paint()..color = _shade(color, -0.06);
      final left = Path()
        ..moveTo(56, 56)
        ..cubicTo(26, 62, 20, 108, 42, 122)
        ..cubicTo(60, 132, 74, 102, 72, 70)
        ..close();
      final right = Path()
        ..moveTo(144, 56)
        ..cubicTo(174, 62, 180, 108, 158, 122)
        ..cubicTo(140, 132, 126, 102, 128, 70)
        ..close();
      final wiggle = math.sin(phase * 1.9) * (headOnly ? 0.12 : 0.08);
      _paintRotatedLayer(
        canvas,
        pivot: const Offset(71, 72),
        angle: -wiggle,
        paintLayer: () {
          canvas.drawPath(left, earPaint);
          canvas.drawOval(const Rect.fromLTWH(42, 74, 18, 28), inner);
        },
      );
      _paintRotatedLayer(
        canvas,
        pivot: const Offset(129, 72),
        angle: wiggle,
        paintLayer: () {
          canvas.drawPath(right, earPaint);
          canvas.drawOval(const Rect.fromLTWH(140, 74, 18, 28), inner);
        },
      );
    } else {
      final earPaint = Paint()..color = _shade(color, 0.02);
      final left = Path()
        ..moveTo(54, 58)
        ..quadraticBezierTo(58, 42, 67, 29)
        ..quadraticBezierTo(73, 20, 76, 18)
        ..quadraticBezierTo(82, 23, 88, 32)
        ..quadraticBezierTo(93, 42, 94, 58)
        ..close();
      final right = Path()
        ..moveTo(106, 58)
        ..quadraticBezierTo(107, 42, 112, 32)
        ..quadraticBezierTo(118, 23, 124, 18)
        ..quadraticBezierTo(127, 20, 133, 29)
        ..quadraticBezierTo(142, 42, 146, 58)
        ..close();
      final leftInner = Path()
        ..moveTo(62, 56)
        ..quadraticBezierTo(65, 44, 71, 34)
        ..quadraticBezierTo(74, 29, 76, 28)
        ..quadraticBezierTo(80, 31, 84, 39)
        ..quadraticBezierTo(87, 46, 88, 56)
        ..close();
      final rightInner = Path()
        ..moveTo(112, 56)
        ..quadraticBezierTo(113, 46, 116, 39)
        ..quadraticBezierTo(120, 31, 124, 28)
        ..quadraticBezierTo(126, 29, 129, 34)
        ..quadraticBezierTo(135, 44, 138, 56)
        ..close();
      final wiggle = math.sin(phase * 1.8) * (headOnly ? 0.1 : 0.06);
      _paintRotatedLayer(
        canvas,
        pivot: const Offset(74, 60),
        angle: -wiggle,
        paintLayer: () {
          canvas.drawPath(left, earPaint);
          canvas.drawPath(leftInner, inner);
        },
      );
      _paintRotatedLayer(
        canvas,
        pivot: const Offset(126, 60),
        angle: wiggle,
        paintLayer: () {
          canvas.drawPath(right, earPaint);
          canvas.drawPath(rightInner, inner);
        },
      );
    }
  }

  void _paintRotatedLayer(
    Canvas canvas, {
    required Offset pivot,
    required double angle,
    required VoidCallback paintLayer,
  }) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
    paintLayer();
    canvas.restore();
  }

  void _paintPattern(Canvas canvas) {
    final mark = Paint()..color = Colors.black.withValues(alpha: 0.09);

    switch (pattern) {
      case 'tabby':
        final stripe = Paint()
          ..color = Colors.black.withValues(alpha: 0.1)
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round;
        final forehead = Path()
          ..moveTo(78, 54)
          ..lineTo(88, 67)
          ..lineTo(100, 58)
          ..lineTo(112, 67)
          ..lineTo(122, 54);
        canvas.drawPath(forehead, stripe);
        canvas.drawLine(const Offset(62, 96), const Offset(78, 96), stripe);
        canvas.drawLine(const Offset(122, 96), const Offset(138, 96), stripe);
        break;
      case 'stripes':
        canvas.drawLine(
          const Offset(66, 98),
          const Offset(82, 98),
          mark
            ..strokeWidth = 8
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          const Offset(118, 98),
          const Offset(134, 98),
          mark
            ..strokeWidth = 8
            ..strokeCap = StrokeCap.round,
        );
        break;
      case 'spots':
        canvas.drawCircle(const Offset(68, 70), 10, mark);
        canvas.drawCircle(const Offset(130, 84), 12, mark);
        break;
      case 'patches':
        canvas.drawOval(
          const Rect.fromLTWH(54, 60, 28, 22),
          Paint()..color = Colors.white.withValues(alpha: 0.2),
        );
        break;
      default:
        break;
    }
  }

  void _paintEyes(Canvas canvas) {
    _paintEye(canvas, const Offset(76, 92), true);
    _paintEye(canvas, const Offset(124, 92), false);
  }

  void _paintEye(Canvas canvas, Offset center, bool leftSide) {
    final stroke = Paint()
      ..color = const Color(0xFF4B3B38)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = const Color(0xFF4B3B38);
    final effectiveEye = petted ? 'happy' : eyeType;

    if (blink > 0.68 && effectiveEye == 'default') {
      canvas.drawLine(
        Offset(center.dx - 7, center.dy + 1),
        Offset(center.dx + 7, center.dy + 1),
        stroke,
      );
      return;
    }

    switch (effectiveEye) {
      case 'happy':
        final path = Path()
          ..moveTo(center.dx - 8, center.dy + 1)
          ..quadraticBezierTo(
            center.dx,
            center.dy - 6,
            center.dx + 8,
            center.dy + 1,
          );
        canvas.drawPath(path, stroke);
        break;
      case 'wink':
        if (leftSide) {
          _drawOpenEye(canvas, center, fill, blinkScale: 1, roundness: 1.2);
        } else {
          canvas.drawLine(
            Offset(center.dx - 7, center.dy),
            Offset(center.dx + 7, center.dy),
            stroke,
          );
        }
        break;
      case 'cool':
        _drawOpenEye(canvas, center, fill, blinkScale: 0.7, roundness: 1.6);
        break;
      case 'star':
        final star = Path()
          ..moveTo(center.dx, center.dy - 7)
          ..lineTo(center.dx + 2, center.dy - 2)
          ..lineTo(center.dx + 7, center.dy - 2)
          ..lineTo(center.dx + 3, center.dy + 1)
          ..lineTo(center.dx + 4.5, center.dy + 6)
          ..lineTo(center.dx, center.dy + 3)
          ..lineTo(center.dx - 4.5, center.dy + 6)
          ..lineTo(center.dx - 3, center.dy + 1)
          ..lineTo(center.dx - 7, center.dy - 2)
          ..lineTo(center.dx - 2, center.dy - 2)
          ..close();
        canvas.drawPath(star, Paint()..color = const Color(0xFFFFD45F));
        break;
      case 'angry':
        _drawOpenEye(canvas, center, fill, blinkScale: 0.95, roundness: 1.1);
        canvas.drawLine(
          Offset(center.dx - 8, leftSide ? center.dy - 8 : center.dy - 2),
          Offset(center.dx + 6, leftSide ? center.dy - 3 : center.dy - 8),
          stroke,
        );
        break;
      case 'sleepy':
        final path = Path()
          ..moveTo(center.dx - 8, center.dy - 1)
          ..quadraticBezierTo(
            center.dx,
            center.dy + 6,
            center.dx + 8,
            center.dy - 1,
          );
        canvas.drawPath(path, stroke);
        break;
      default:
        _drawOpenEye(
          canvas,
          center,
          fill,
          blinkScale: 1 - (blink * 0.82),
          roundness: isDog ? 1.15 : 1.2,
        );
    }
  }

  void _drawOpenEye(
    Canvas canvas,
    Offset center,
    Paint fill, {
    required double blinkScale,
    required double roundness,
  }) {
    final eyeScale = blinkScale.clamp(0.18, 1.0);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1, eyeScale);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 14 * roundness, height: 16),
      fill,
    );
    canvas.drawCircle(const Offset(-2.5, -3), 3, Paint()..color = Colors.white);
    canvas.drawCircle(
      const Offset(2.8, 2.6),
      1.3,
      Paint()..color = Colors.white.withValues(alpha: 0.84),
    );
    canvas.restore();
  }

  void _paintCheeks(Canvas canvas) {
    final blush = Paint()
      ..color = const Color(0xFFFF9CAA).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(64, 108), width: 18, height: 9),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(136, 108), width: 18, height: 9),
      blush,
    );
  }

  void _paintDogMuzzle(Canvas canvas) {
    final muzzle = Rect.fromCenter(
      center: const Offset(100, 112),
      width: 56,
      height: 38,
    );
    canvas.drawOval(
      muzzle,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    final nose = Path()
      ..moveTo(92, 102)
      ..quadraticBezierTo(100, 96, 108, 102)
      ..quadraticBezierTo(106, 110, 100, 110)
      ..quadraticBezierTo(94, 110, 92, 102)
      ..close();
    canvas.drawPath(nose, Paint()..color = const Color(0xFF4C3B38));
    canvas.drawOval(
      const Rect.fromLTWH(96, 100, 4, 2),
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  void _paintCatNose(Canvas canvas) {
    final nosePad = Rect.fromCenter(
      center: const Offset(100, 111.5),
      width: 26,
      height: 22,
    );
    canvas.drawOval(
      nosePad,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    final nose = Path()
      ..moveTo(96.4, 104.8)
      ..quadraticBezierTo(100, 102.7, 103.6, 104.8)
      ..quadraticBezierTo(102.7, 108.3, 100, 109.2)
      ..quadraticBezierTo(97.3, 108.3, 96.4, 104.8)
      ..close();
    canvas.drawPath(nose, Paint()..color = const Color(0xFFFFB4C0));
    canvas.drawLine(
      const Offset(100, 109.2),
      const Offset(100, 114.5),
      Paint()
        ..color = const Color(0xFF7C5D57)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      const Rect.fromLTWH(98.3, 104.7, 2.2, 1.2),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  void _paintWhiskers(Canvas canvas) {
    final whisker = Paint()
      ..color = const Color(0xFF7C5D57).withValues(alpha: 0.78)
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final upperLeft = Path()
      ..moveTo(77, 108)
      ..quadraticBezierTo(66, 104, 53, 105);
    final lowerLeft = Path()
      ..moveTo(78, 116)
      ..quadraticBezierTo(66, 117.5, 54, 121);
    final upperRight = Path()
      ..moveTo(123, 108)
      ..quadraticBezierTo(134, 104, 147, 105);
    final lowerRight = Path()
      ..moveTo(122, 116)
      ..quadraticBezierTo(134, 117.5, 146, 121);

    canvas.drawPath(upperLeft, whisker);
    canvas.drawPath(lowerLeft, whisker);
    canvas.drawPath(upperRight, whisker);
    canvas.drawPath(lowerRight, whisker);
  }

  void _paintMouth(Canvas canvas) {
    final stroke = Paint()
      ..color = const Color(0xFF4B3B38)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final catStroke = Paint()
      ..color = const Color(0xFF4B3B38).withValues(alpha: 0.9)
      ..strokeWidth = 1.9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = const Color(0xFF4B3B38);
    final tongue = Paint()..color = const Color(0xFFFF8FA3);
    final effectiveMouth = petted ? 'smile' : mouthType;

    switch (effectiveMouth) {
      case 'smile':
        if (isDog) {
          canvas.drawPath(
            Path()
              ..moveTo(92, 118)
              ..quadraticBezierTo(100, 125, 108, 118),
            stroke,
          );
        } else {
          canvas.drawPath(
            Path()
              ..moveTo(96.5, 113.2)
              ..quadraticBezierTo(98.4, 116.2, 100, 114.9)
              ..quadraticBezierTo(101.6, 116.2, 103.5, 113.2),
            catStroke,
          );
        }
        break;
      case 'pout':
        if (isDog) {
          canvas.drawLine(
            const Offset(95, 120),
            const Offset(105, 120),
            stroke,
          );
        } else {
          canvas.drawLine(
            const Offset(97.4, 115.2),
            const Offset(102.6, 115.2),
            catStroke,
          );
        }
        break;
      case 'surprised':
        if (isDog) {
          canvas.drawOval(const Rect.fromLTWH(96, 116, 8, 10), fill);
        } else {
          canvas.drawOval(
            const Rect.fromLTWH(98.2, 113.8, 3.6, 5.2),
            Paint()..color = const Color(0xFF4B3B38).withValues(alpha: 0.92),
          );
        }
        break;
      case 'tongue':
        if (isDog) {
          canvas.drawPath(
            Path()
              ..moveTo(93, 118)
              ..quadraticBezierTo(100, 123, 107, 118),
            stroke,
          );
          canvas.drawPath(
            Path()
              ..moveTo(96, 120)
              ..quadraticBezierTo(100, 131, 104, 120)
              ..close(),
            tongue,
          );
        } else {
          canvas.drawPath(
            Path()
              ..moveTo(96.6, 114.2)
              ..quadraticBezierTo(98.4, 117.2, 100, 115.9)
              ..quadraticBezierTo(101.6, 117.2, 103.4, 114.2),
            catStroke,
          );
          canvas.drawPath(
            Path()
              ..moveTo(98.3, 116.0)
              ..quadraticBezierTo(100, 122.2, 101.7, 116.0)
              ..close(),
            tongue,
          );
          canvas.drawLine(
            const Offset(100, 116.0),
            const Offset(100, 120.0),
            Paint()
              ..color = const Color(0xFFFF6C84)
              ..strokeWidth = 0.9
              ..strokeCap = StrokeCap.round,
          );
        }
        break;
      case 'cat':
        canvas.drawPath(
          Path()
            ..moveTo(96.5, 113.2)
            ..quadraticBezierTo(98.2, 116.8, 100, 115.0)
            ..quadraticBezierTo(101.8, 116.8, 103.5, 113.2),
          catStroke,
        );
        break;
      default:
        if (isDog) {
          canvas.drawPath(
            Path()
              ..moveTo(92, 118)
              ..quadraticBezierTo(100, 125, 108, 118),
            stroke,
          );
        } else {
          canvas.drawPath(
            Path()
              ..moveTo(96.5, 113.2)
              ..quadraticBezierTo(98.4, 116.2, 100, 114.9)
              ..quadraticBezierTo(101.6, 116.2, 103.5, 113.2),
            catStroke,
          );
        }
    }
  }

  void _paintPaws(Canvas canvas) {
    final pawPaint = Paint()..color = _shade(color, 0.02);
    final left = RRect.fromRectAndRadius(
      Rect.fromLTWH(isDog ? 74 : 76, 158, isDog ? 16 : 14, isDog ? 20 : 18),
      const Radius.circular(12),
    );
    final right = RRect.fromRectAndRadius(
      Rect.fromLTWH(isDog ? 110 : 110, 158, isDog ? 16 : 14, isDog ? 20 : 18),
      const Radius.circular(12),
    );
    canvas.drawRRect(left, pawPaint);
    canvas.drawRRect(right, pawPaint);
    canvas.drawOval(
      Rect.fromLTWH(isDog ? 76 : 77, isDog ? 168 : 166, 12, 6),
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );
    canvas.drawOval(
      Rect.fromLTWH(112, isDog ? 168 : 166, 12, 6),
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );
  }

  void _paintAccessories(Canvas canvas) {
    if (equipped.contains('acc_collar')) {
      final collar = Path()
        ..moveTo(68, 136)
        ..quadraticBezierTo(100, 146, 132, 136);
      canvas.drawPath(
        collar,
        Paint()
          ..color = const Color(0xFFFF667C)
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        const Offset(100, 144),
        7.5,
        Paint()..color = const Color(0xFFFFD54A),
      );
      canvas.drawCircle(
        const Offset(98, 142),
        2,
        Paint()..color = Colors.white,
      );
    }

    if (equipped.contains('acc_hat')) {
      final hat = Path()
        ..moveTo(72, 46)
        ..quadraticBezierTo(76, 18, 100, 18)
        ..quadraticBezierTo(124, 18, 128, 46)
        ..close();
      canvas.drawPath(hat, Paint()..color = const Color(0xFF4CB7A7));
      canvas.drawLine(
        const Offset(64, 46),
        const Offset(136, 46),
        Paint()
          ..color = const Color(0xFF1E6071)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  Color _shade(Color base, double delta) {
    final hsl = HSLColor.fromColor(base);
    final lightness = (hsl.lightness + delta).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  @override
  bool shouldRepaint(covariant _PetAvatarPainter oldDelegate) {
    return oldDelegate.species != species ||
        oldDelegate.color != color ||
        oldDelegate.eyeType != eyeType ||
        oldDelegate.mouthType != mouthType ||
        oldDelegate.pattern != pattern ||
        oldDelegate.phase != phase ||
        oldDelegate.blink != blink ||
        oldDelegate.petted != petted ||
        oldDelegate.headOnly != headOnly ||
        oldDelegate.equipped.join(',') != equipped.join(',');
  }
}

class _HeartData {
  const _HeartData({
    required this.id,
    required this.xOffset,
    required this.start,
  });

  final int id;
  final double xOffset;
  final double start;
}
