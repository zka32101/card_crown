import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 勝利時の紙吹雪パーティクル
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Confetti> _particles;
  final _rng = math.Random();

  static const _colors = [
    Color(0xFFFFD700), Color(0xFFFF6B6B), Color(0xFF6BCB77),
    Color(0xFF4D96FF), Color(0xFFFF922B), Color(0xFFCC5DE8),
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
      ..addListener(() => setState(() {}))
      ..forward();

    _particles = List.generate(80, (i) => _Confetti(
      x: _rng.nextDouble(),
      delay: _rng.nextDouble() * 0.4,
      speed: 0.3 + _rng.nextDouble() * 0.7,
      size: 4 + _rng.nextDouble() * 8,
      color: _colors[i % _colors.length],
      rotSpeed: (_rng.nextDouble() - 0.5) * 10,
      sway: (_rng.nextDouble() - 0.5) * 0.3,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(_particles, _controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _Confetti {
  final double x;
  final double delay;
  final double speed;
  final double size;
  final Color color;
  final double rotSpeed;
  final double sway;

  const _Confetti({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotSpeed,
    required this.sway,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> particles;
  final double t;

  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (progress <= 0) continue;

      final y = size.height * progress * p.speed;
      final x = size.width * p.x + math.sin(progress * math.pi * 4) * size.width * p.sway * 0.1;
      final opacity = progress < 0.7 ? 1.0 : (1.0 - (progress - 0.7) / 0.3);
      final angle = progress * math.pi * p.rotSpeed;

      final paint = Paint()..color = p.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
