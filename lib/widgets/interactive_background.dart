import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

class InteractiveBackground extends StatefulWidget {
  final Widget child;
  const InteractiveBackground({super.key, required this.child});

  @override
  State<InteractiveBackground> createState() => _InteractiveBackgroundState();
}

class _InteractiveBackgroundState extends State<InteractiveBackground> {
  double _x = 0.0;
  double _y = 0.0;
  StreamSubscription? _streamSubscription;
  final List<_BackgroundElement> _elements = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateElements();
    
    // Check if sensors are available (basic check by trying to listen)
    // On desktop, this might not emit anything, which is fine.
    try {
      _streamSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
        if (mounted) {
          setState(() {
            // Smooth damping
            _x = (_x * 0.9) + (event.x * 0.1);
            _y = (_y * 0.9) + (event.y * 0.1);
          });
        }
      }, onError: (e) {
        // Sensors not available
      });
    } catch (e) {
      // Ignore
    }
  }

  void _generateElements() {
    for (int i = 0; i < 10; i++) {
      _elements.add(_BackgroundElement(
        icon: _random.nextBool() ? Icons.cloud : Icons.star,
        color: _random.nextBool() ? Colors.white.withValues(alpha: 0.4) : Colors.yellow.withValues(alpha: 0.2),
        top: _random.nextDouble() * 800,
        left: _random.nextDouble() * 400,
        size: 20 + _random.nextDouble() * 40,
        depth: 0.2 + _random.nextDouble() * 0.8, // Parallax depth factor
      ));
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[100]!, Colors.yellow[50]!],
            ),
          ),
        ),
        // Animated Elements
        ..._elements.map((e) {
          // Calculate offset based on sensor data and depth
          final offsetX = _x * 10 * e.depth;
          final offsetY = _y * 10 * e.depth;
          
          return Positioned(
            top: e.top + offsetY,
            left: e.left - offsetX, // Invert X for natural feel
            child: Icon(e.icon, size: e.size, color: e.color),
          );
        }),
        // Content
        widget.child,
      ],
    );
  }
}

class _BackgroundElement {
  final IconData icon;
  final Color color;
  final double top;
  final double left;
  final double size;
  final double depth;

  _BackgroundElement({
    required this.icon, 
    required this.color, 
    required this.top, 
    required this.left, 
    required this.size, 
    required this.depth
  });
}
