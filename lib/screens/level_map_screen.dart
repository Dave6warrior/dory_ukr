import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alphabet_provider.dart';

class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Карта пригод'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AlphabetProvider>(
        builder: (context, provider, child) {
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 50, top: 20),
            itemCount: provider.letters.length,
            itemBuilder: (context, index) {
              final letter = provider.letters[index];
              final progress = provider.getProgress(letter.id);
              final isLocked = index > 0 && !provider.getProgress(provider.letters[index - 1].id).allDone;
              
              // Zig-zag pattern logic
              // Even index: Left side, Odd index: Right side
              final isLeft = index % 2 == 0;
              final double horizontalOffset = isLeft ? 60.0 : MediaQuery.of(context).size.width - 140.0;
              
              return SizedBox(
                height: 140, // Height for each step
                child: Stack(
                  children: [
                    // Draw path to next node if exists
                    if (index < provider.letters.length - 1)
                      CustomPaint(
                        size: Size.infinite,
                        painter: PathPainter(
                          startIndex: index,
                          startOffset: Offset(horizontalOffset + 40, 40), // Center of current circle
                          endOffset: Offset(
                            (index % 2 != 0 ? 60.0 : MediaQuery.of(context).size.width - 140.0) + 40, 
                            140 + 40
                          ),
                          color: isLocked ? Colors.grey[300]! : Colors.orange[200]!,
                        ),
                      ),
                    
                    Positioned(
                      left: horizontalOffset,
                      child: GestureDetector(
                        onTap: () { // Allow clicking even if locked for demo, or restrict
                           provider.setCurrentIndex(index);
                           Navigator.pop(context); 
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: progress.allDone ? Colors.green : (isLocked ? Colors.grey : Colors.orange),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: Center(
                                child: isLocked
                                    ? const Icon(Icons.lock, color: Colors.white38, size: 30)
                                    : Text(
                                        letter.character,
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 16, color: progress.speakingDone ? Colors.orange : Colors.grey[400]),
                                Icon(Icons.star, size: 16, color: progress.writingDone ? Colors.orange : Colors.grey[400]),
                                Icon(Icons.star, size: 16, color: progress.findingDone ? Colors.orange : Colors.grey[400]),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  final int startIndex;
  final Offset startOffset;
  final Offset endOffset;
  final Color color;

  PathPainter({
    required this.startIndex,
    required this.startOffset,
    required this.endOffset,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    Path path = Path();
    path.moveTo(startOffset.dx, startOffset.dy);
    
    // Simple cubic bezier for smooth path
    path.cubicTo(
      startOffset.dx, startOffset.dy + 60, 
      endOffset.dx, endOffset.dy - 60, 
      endOffset.dx, endOffset.dy
    );

    // Draw dashed path
    double dashWidth = 10;
    double dashSpace = 10;
    PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
      double dashDistance = 0.0;
      while (dashDistance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(dashDistance, dashDistance + dashWidth),
          paint,
        );
        dashDistance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
