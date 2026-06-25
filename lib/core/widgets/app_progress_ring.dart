// lib/core/widgets/app_progress_ring.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated circular progress ring. Supports single or triple concentric rings.
class AppProgressRing extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final Color color;
  final Color backgroundColor;
  final double size;
  final double strokeWidth;
  final Widget? child;
  final bool animate;

  const AppProgressRing({
    super.key,
    required this.value,
    required this.color,
    this.backgroundColor = const Color(0xFF334155),
    this.size = 80,
    this.strokeWidth = 8,
    this.child,
    this.animate = true,
  });

  @override
  State<AppProgressRing> createState() => _AppProgressRingState();
}

class _AppProgressRingState extends State<AppProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AppProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: _animation.value, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: _animation.value,
              color: widget.color,
              backgroundColor: widget.backgroundColor,
              strokeWidth: widget.strokeWidth,
            ),
            child: Center(child: widget.child),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final fgPaint = Paint()
      ..shader = LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color;
}

/// Three concentric animated progress rings.
class AppTripleRing extends StatelessWidget {
  final double outerValue;
  final double middleValue;
  final double innerValue;
  final Color outerColor;
  final Color middleColor;
  final Color innerColor;
  final double outerSize;

  const AppTripleRing({
    super.key,
    required this.outerValue,
    required this.middleValue,
    required this.innerValue,
    this.outerColor = const Color(0xFF6366F1),
    this.middleColor = const Color(0xFF8B5CF6),
    this.innerColor = const Color(0xFF06B6D4),
    this.outerSize = 96,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AppProgressRing(
            value: outerValue,
            color: outerColor,
            backgroundColor: outerColor.withValues(alpha: 0.1),
            size: outerSize,
            strokeWidth: 9,
          ),
          AppProgressRing(
            value: middleValue,
            color: middleColor,
            backgroundColor: middleColor.withValues(alpha: 0.1),
            size: outerSize * 0.68,
            strokeWidth: 9,
          ),
          AppProgressRing(
            value: innerValue,
            color: innerColor,
            backgroundColor: innerColor.withValues(alpha: 0.1),
            size: outerSize * 0.36,
            strokeWidth: 9,
          ),
        ],
      ),
    );
  }
}
