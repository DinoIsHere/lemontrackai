import 'dart:math' as math;
import 'package:flutter/material.dart';

class AuroraEffect extends StatefulWidget {
  const AuroraEffect({super.key});

  @override
  State<AuroraEffect> createState() => _AuroraEffectState();
}

class _AuroraEffectState extends State<AuroraEffect>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _intensityController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _intensityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: 0.8,
    )..animateTo(0.45, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    _intensityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, _intensityController]),
        builder: (context, child) {
          return CustomPaint(
            painter: _AuroraPainter(
              _controller.value,
              _intensityController.value,
            ),
          );
        },
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.t, this.intensity);

  final double t;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Lemon yellow glow, centered below chatbox.
    final cx = size.width * 0.5;
    final cy = size.height * 0.55;

    final radial = RadialGradient(
      center: Alignment(cx / size.width, cy / size.height),
      radius: 0.6,
      colors: [
        const Color(0xFFFFD54F).withOpacity(1.0 * intensity),
        const Color(0xFFFFC107).withOpacity(0.8 * intensity),
        const Color(0xFF3C2F00).withOpacity(0.4 * intensity),
        const Color(0xFF151000).withOpacity(0.2 * intensity),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.6, 0.85, 1.0],
      tileMode: TileMode.clamp,
    ).createShader(rect);

    final bg = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, bg);

    final glow = Paint()
      ..shader = radial
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, glow);

    final ox = size.width * 0.5;
    final oy = size.height * 0.6;
    final orb = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.35 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);
    canvas.drawCircle(Offset(ox, oy), size.width * 0.25, orb);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) => true;
}