import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/ship_geometry.dart';
import '../../theme/app_theme.dart';

/// 深空背景：渐变、星点与两团星云光晕，随主题切换明暗。
class SpaceBackdrop extends StatelessWidget {
  const SpaceBackdrop({super.key, required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _BackdropPainter(brightness),
      size: Size.infinite,
    ),
  );
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter(this.brightness);

  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final dark = brightness == Brightness.dark;

    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? const [Color(0xFF0B1226), Color(0xFF070A16), Color(0xFF0A0F20)]
            : const [Color(0xFFF6FAFF), Color(0xFFE4EFFC), Color(0xFFF2F7FF)],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final cyanGlow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              appCyan.withValues(alpha: dark ? 0.16 : 0.14),
              appCyan.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.82, size.height * 0.06),
              radius: size.shortestSide * 0.85,
            ),
          );
    canvas.drawRect(rect, cyanGlow);

    final violetGlow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              appViolet.withValues(alpha: dark ? 0.13 : 0.1),
              appViolet.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.1, size.height * 0.9),
              radius: size.shortestSide * 0.8,
            ),
          );
    canvas.drawRect(rect, violetGlow);

    final random = math.Random(20261107);
    final starPaint = Paint();
    final count = (size.width * size.height / 9000).round().clamp(40, 150);
    for (var i = 0; i < count; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 0.5 + random.nextDouble() * 1.4;
      final alpha = (dark ? 0.35 : 0.2) + random.nextDouble() * 0.5;
      starPaint.color = (random.nextBool() ? Colors.white : appCyan).withValues(
        alpha: alpha,
      );
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }

    // 底部两道细弧线，呼应喷射轨迹。
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = (dark ? appCyan : const Color(0xFF6B8FB8)).withValues(
        alpha: 0.12,
      );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 1.15),
        radius: size.width * 0.9,
      ),
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) =>
      oldDelegate.brightness != brightness;
}

/// 首页战机徽标：同心轨道缓慢旋转，尾焰呼吸，纯矢量绘制。
class PlaneEmblem extends StatefulWidget {
  const PlaneEmblem({super.key, required this.size});

  final double size;

  @override
  State<PlaneEmblem> createState() => _PlaneEmblemState();
}

class _PlaneEmblemState extends State<PlaneEmblem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _EmblemPainter(progress: _controller.value),
          size: Size.square(widget.size),
        ),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    _paintGlow(canvas, center, radius);
    _paintOrbits(canvas, center, radius);
    _paintJet(canvas, center, radius);
    _paintSparks(canvas, center, radius);
  }

  void _paintGlow(Canvas canvas, Offset center, double radius) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          appCyan.withValues(alpha: 0.28),
          appCyan.withValues(alpha: 0.06),
          appCyan.withValues(alpha: 0),
        ],
        stops: const [0, 0.55, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glow);
  }

  void _paintOrbits(Canvas canvas, Offset center, double radius) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = appCyan.withValues(alpha: 0.2);
    canvas.drawCircle(center, radius * 0.72, ring);
    ring.color = appCyan.withValues(alpha: 0.12);
    canvas.drawCircle(center, radius * 0.88, ring);

    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = appCyan.withValues(alpha: 0.55);
    const segments = 18;
    for (var i = 0; i < segments; i += 2) {
      final start = progress * math.pi * 2 + i * math.pi * 2 / segments;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.92),
        start,
        math.pi * 2 / segments * 0.7,
        false,
        dash,
      );
    }

    final amber = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = appAmber.withValues(alpha: 0.5);
    final start = -progress * math.pi * 2 * 1.4;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.62),
      start,
      math.pi * 0.34,
      false,
      amber,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.62),
      start + math.pi,
      math.pi * 0.22,
      false,
      amber,
    );
  }

  void _paintJet(Canvas canvas, Offset center, double radius) {
    final scale = radius / 120;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.18);
    canvas.scale(scale * 2.4);

    // 尾焰
    final flicker = 0.86 + 0.14 * math.sin(progress * math.pi * 2 * 6);
    final flame = Path()
      ..moveTo(-6, 13)
      ..lineTo(0, 13 + 16 * flicker)
      ..lineTo(6, 13)
      ..close();
    canvas.drawPath(
      flame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD54F), Color(0x00FF8A5C)],
        ).createShader(const Rect.fromLTWH(-6, 13, 12, 20)),
    );

    final body = playerHullPath;
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9BE8FF), Color(0xFF2B6BFF)],
        ).createShader(const Rect.fromLTWH(-14, -17, 28, 29)),
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFFDDF7FF),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -5), width: 3.4, height: 8),
      Paint()..color = Colors.white,
    );
    canvas.restore();
  }

  void _paintSparks(Canvas canvas, Offset center, double radius) {
    final spark = Paint()..color = appAmber.withValues(alpha: 0.8);
    for (var i = 0; i < 5; i++) {
      final angle = progress * math.pi * 2 + i * math.pi * 2 / 5;
      final distance = radius * (0.62 + 0.04 * math.sin(i + progress * 12));
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * distance,
        1.6,
        spark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EmblemPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
