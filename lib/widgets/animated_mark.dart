import 'package:flutter/material.dart';
import '../models/letter.dart';

class AnimatedMark extends StatefulWidget {
  final LetterType type;
  const AnimatedMark({super.key, required this.type});

  @override
  State<AnimatedMark> createState() => _AnimatedMarkState();
}

class _AnimatedMarkState extends State<AnimatedMark> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuart);
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      _controller.reset();
      _controller.forward();
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
        return CustomPaint(
          painter: MarkPainter(
            type: widget.type,
            progress: _animation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class MarkPainter extends CustomPainter {
  final LetterType type;
  final double progress;

  MarkPainter({required this.type, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    if (type == LetterType.vowel) {
      paint.color = Colors.red.withValues(alpha: 0.7);
      // Circle around the center of the widget
      final center = Offset(size.width / 2, size.height / 2);
      // Adjust radius to enclose the letter (approx 180 fontSize)
      final radius = (size.width / 2.2) * progress; 
      canvas.drawCircle(center, radius, paint);
    } else if (type == LetterType.consonant) {
      paint.color = Colors.blue.withValues(alpha: 0.7);
      // Draw line at the bottom
      final start = Offset(size.width * 0.2, size.height * 0.85);
      final end = Offset(size.width * 0.2 + (size.width * 0.6 * progress), size.height * 0.85);
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(MarkPainter oldDelegate) => oldDelegate.progress != progress;
}
