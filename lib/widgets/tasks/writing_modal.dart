import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../../models/letter.dart';
import '../../providers/alphabet_provider.dart';

class WritingModal extends StatefulWidget {
  final Letter letter;
  const WritingModal({super.key, required this.letter});

  @override
  State<WritingModal> createState() => _WritingModalState();
}

class _WritingModalState extends State<WritingModal>
    with TickerProviderStateMixin {
  // ─── Drawing state ───────────────────────────────────────────────────────
  final List<Offset?> _points = [];

  // ─── Hit-map state ────────────────────────────────────────────────────────
  final int gridSize = 300;
  List<bool>? _targetGrid;      // exact letter pixels
  List<bool>? _toleranceGrid;   // minor-deviation zone  (radius 40)
  List<bool>? _deadZoneGrid;    // outer zone – outside → major error (radius 70)
  final Set<int> _coveredTargetCells = {};
  int _totalTargetCells = 0;
  bool _isHitMapReady = false;

  /// Precomputed list of every target pixel in SCREEN space (used for snapping).
  List<Offset> _targetPixels = [];

  // ─── Interaction state ────────────────────────────────────────────────────
  bool _isFlashingError = false;
  bool _isSuccess = false;
  /// Current canvas view size (set in LayoutBuilder).
  double _viewSize = 0;

  // ─── Animation controllers ────────────────────────────────────────────────
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  late AnimationController _successController;
  late Animation<double> _successFade;
  late Animation<double> _successScale;

  late AnimationController _errorFlashController;
  late Animation<Color?> _errorFlashColor;

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Shake on error
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    // Success overlay fade-in + scale
    _successController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _successFade =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOut,
    ));
    _successScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _successController, curve: Curves.elasticOut));

    // Error flash (drawn line pulses red briefly)
    _errorFlashController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _errorFlashColor = ColorTween(begin: Colors.red, end: Colors.red[200])
        .animate(_errorFlashController);

    _initHitMap();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _successController.dispose();
    _errorFlashController.dispose();
    super.dispose();
  }

  // ─── Hit-map initialisation ───────────────────────────────────────────────
  Future<void> _initHitMap() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
        recorder, Rect.fromLTWH(0, 0, gridSize.toDouble(), gridSize.toDouble()));

    final textSpan = TextSpan(
      text: widget.letter.character,
      style: const TextStyle(
        fontSize: 250,
        fontWeight: FontWeight.w900,
        fontFamily: 'Nunito',
        color: Colors.black,
      ),
    );
    final textPainter = TextPainter(
        text: textSpan, textDirection: TextDirection.ltr)
      ..layout();
    final xCenter = (gridSize - textPainter.width) / 2;
    final yCenter = (gridSize - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(xCenter, yCenter));

    final picture = recorder.endRecording();
    final image = await picture.toImage(gridSize, gridSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return;

    _targetGrid = List<bool>.filled(gridSize * gridSize, false);
    _toleranceGrid = List<bool>.filled(gridSize * gridSize, false);
    _deadZoneGrid = List<bool>.filled(gridSize * gridSize, false);
    final rawTargetPixels = <Offset>[];
    int targetCount = 0;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final int index = (y * gridSize + x) * 4;
        final int alpha = byteData.getUint8(index + 3);
        if (alpha > 128) {
          _targetGrid![y * gridSize + x] = true;
          rawTargetPixels.add(Offset(x.toDouble(), y.toDouble()));
          targetCount++;
        }
      }
    }
    _totalTargetCells = targetCount;

    // Dilate tolerance zones
    const int minorRadius = 40;
    const int majorRadius = 70;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (!_targetGrid![y * gridSize + x]) continue;
        for (int dy = -majorRadius; dy <= majorRadius; dy += 2) {
          for (int dx = -majorRadius; dx <= majorRadius; dx += 2) {
            final int distSq = dx * dx + dy * dy;
            final int ny = y + dy;
            final int nx = x + dx;
            if (ny < 0 || ny >= gridSize || nx < 0 || nx >= gridSize) continue;
            if (distSq <= majorRadius * majorRadius) {
              _deadZoneGrid![ny * gridSize + nx] = true;
            }
            if (distSq <= minorRadius * minorRadius) {
              _toleranceGrid![ny * gridSize + nx] = true;
            }
          }
        }
      }
    }

    // Store target pixels in grid coords (converted to screen on demand via _gridToScreen).
    _targetPixels = rawTargetPixels;

    if (mounted) {
      setState(() => _isHitMapReady = true);
    }
  }

  // ─── Coordinate helpers ───────────────────────────────────────────────────
  double get _gridToScreenScale => _viewSize / gridSize;

  /// Projects screen offset to grid coordinates.
  (int gx, int gy) _toGrid(Offset screenPos) {
    final double s = gridSize / _viewSize;
    return ((screenPos.dx * s).toInt(), (screenPos.dy * s).toInt());
  }

  /// Finds the nearest target pixel (in SCREEN space) within [maxScreenDist].
  /// Returns null if none found.
  Offset? _snapToPath(Offset screenPos, {double maxScreenDist = 28.0}) {
    if (_targetPixels.isEmpty) return null;
    final double scale = _gridToScreenScale;
    // Search only in a bounding box to avoid O(n) full scan on every frame.
    final double margin = maxScreenDist / scale;
    final double gx = screenPos.dx / scale;
    final double gy = screenPos.dy / scale;

    double bestDist = double.infinity;
    Offset? bestPx;
    for (final p in _targetPixels) {
      final double dx = p.dx - gx;
      final double dy = p.dy - gy;
      if (dx.abs() > margin || dy.abs() > margin) continue;
      final double dist = dx * dx + dy * dy;
      if (dist < bestDist) {
        bestDist = dist;
        bestPx = p;
      }
    }
    if (bestPx == null) return null;
    // Convert back to screen space
    return Offset(bestPx.dx * scale, bestPx.dy * scale);
  }

  // ─── Actions ──────────────────────────────────────────────────────────────
  void _clear() {
    setState(() {
      _points.clear();
      _coveredTargetCells.clear();
      _isFlashingError = false;
      _isSuccess = false;
    });
    _successController.reset();
    _errorFlashController.reset();
  }

  void _triggerError() {
    if (_isFlashingError || _isSuccess) return;
    setState(() {
      _isFlashingError = true;
      _points.add(null); // break stroke
    });
    _shakeController.forward(from: 0.0);
    _errorFlashController.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _clear();
    });
  }

  void _completeTask() {
    if (_isSuccess) return;
    setState(() => _isSuccess = true);
    _successController.forward();
    Provider.of<AlphabetProvider>(context, listen: false)
        .completeWriting(widget.letter.id);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.pop(context);
    });
  }

  // ─── Pointer handlers ─────────────────────────────────────────────────────
  void _handlePointerDown(Offset localPos) {
    if (_isSuccess || _isFlashingError) return;
    final (gx, gy) = _toGrid(localPos);
    if (gx < 0 || gx >= gridSize || gy < 0 || gy >= gridSize) {
      _triggerError();
      return;
    }
    final int idx = gy * gridSize + gx;
    if (_deadZoneGrid![idx]) {
      // Within dead zone – start tracking.
      final snapped = _snapToPath(localPos);
      setState(() {
        _points.add(snapped ?? localPos);
        if (_targetGrid![idx]) _coveredTargetCells.add(idx);
      });
    } else {
      _triggerError();
    }
  }

  void _handlePointerMove(Offset localPos) {
    if (_isSuccess || _isFlashingError) return;
    final (gx, gy) = _toGrid(localPos);

    if (gx < 0 || gx >= gridSize || gy < 0 || gy >= gridSize) {
      // Off canvas entirely
      _triggerError();
      return;
    }

    final int idx = gy * gridSize + gx;

    if (_targetGrid![idx]) {
      // ✅ On the letter – snap and draw.
      final snapped = _snapToPath(localPos) ?? localPos;
      setState(() {
        _points.add(snapped);
        _coveredTargetCells.add(idx);
      });
    } else if (_toleranceGrid![idx]) {
      // 🟡 Minor deviation – pause stroke without error.
      setState(() => _points.add(null));
    } else if (_deadZoneGrid![idx]) {
      // 🟠 Outer tolerance – also just pause.
      setState(() => _points.add(null));
    } else {
      // 🔴 Way off – major error.
      _triggerError();
    }
  }

  void _handlePointerUp() {
    if (_isSuccess || _isFlashingError) return;
    setState(() => _points.add(null));

    if (_totalTargetCells > 0) {
      final double coverage = _coveredTargetCells.length / _totalTargetCells;
      if (coverage >= 0.85) _completeTask();
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      // Absorb vertical drags at the modal level so the bottom sheet won't scroll.
      child: GestureDetector(
        onVerticalDragStart: (_) {},
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Напиши літеру:',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.refresh, size: 32),
                    onPressed: _clear),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: !_isHitMapReady
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(builder: (context, constraints) {
                      final double viewSize = math.min(
                          constraints.maxWidth, constraints.maxHeight);
                      _viewSize = viewSize;

                      return Center(
                        child: AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(
                                _shakeAnimation.value *
                                    math.sin(_shakeController.value *
                                        math.pi *
                                        4),
                                0),
                            child: child,
                          ),
                          child: SizedBox(
                            width: viewSize,
                            height: viewSize,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: Colors.grey[300]!),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // ── Background letter guide ──────────────
                                  CustomPaint(
                                    size: Size.infinite,
                                    painter: LetterBackgroundPainter(
                                        character: widget.letter.character),
                                  ),

                                  // ── Drawing layer (Listener = touch lock) ─
                                  Listener(
                                    behavior: HitTestBehavior.opaque,
                                    onPointerDown: (e) =>
                                        _handlePointerDown(e.localPosition),
                                    onPointerMove: (e) =>
                                        _handlePointerMove(e.localPosition),
                                    onPointerUp: (_) => _handlePointerUp(),
                                    onPointerCancel: (_) => _handlePointerUp(),
                                    child: AnimatedBuilder(
                                      animation: _errorFlashController,
                                      builder: (context, child) {
                                        return CustomPaint(
                                          painter: DrawingPainter(
                                            points: _points,
                                            isError: _isFlashingError,
                                            isSuccess: _isSuccess,
                                            errorColor: _isFlashingError
                                                ? (_errorFlashColor.value ??
                                                    Colors.red)
                                                : Colors.red,
                                          ),
                                          size: Size.infinite,
                                        );
                                      },
                                    ),
                                  ),

                                  // ── Success overlay ───────────────────────
                                  if (_isSuccess)
                                    FadeTransition(
                                      opacity: _successFade,
                                      child: ScaleTransition(
                                        scale: _successScale,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2ECC71)
                                                .withValues(alpha: 0.92),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF27AE60)
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 20,
                                                spreadRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                '🌟',
                                                style: TextStyle(fontSize: 44),
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'Молодець!',
                                                style: TextStyle(
                                                  fontSize: 34,
                                                  fontWeight: FontWeight.w900,
                                                  fontFamily: 'Nunito',
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                  shadows: [
                                                    Shadow(
                                                      color: Color(0x661B8A4A),
                                                      blurRadius: 6,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isSuccess
                  ? const SizedBox.shrink()
                  : const Text(
                      'Проведи лінію по контуру!',
                      key: ValueKey('hint'),
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ─── DrawingPainter ──────────────────────────────────────────────────────────

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  final bool isError;
  final bool isSuccess;
  final Color errorColor;

  DrawingPainter({
    required this.points,
    this.isError = false,
    this.isSuccess = false,
    this.errorColor = Colors.red,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Color strokeColor;
    if (isError) {
      strokeColor = errorColor;
    } else if (isSuccess) {
      strokeColor = const Color(0xFF27AE60); // rich green
    } else {
      strokeColor = const Color(0xFF1565C0); // deep blue
    }

    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = size.width * 0.083 // matches background letter stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

// ─── LetterBackgroundPainter ─────────────────────────────────────────────────

class LetterBackgroundPainter extends CustomPainter {
  final String character;

  LetterBackgroundPainter({required this.character});

  @override
  void paint(Canvas canvas, Size size) {
    final textSpan = TextSpan(
      text: character,
      style: TextStyle(
        fontSize: size.height * 0.83,
        fontWeight: FontWeight.w900,
        fontFamily: 'Nunito',
        color: Colors.grey.withValues(alpha: 0.22),
      ),
    );
    final textPainter = TextPainter(
        text: textSpan, textDirection: TextDirection.ltr)
      ..layout();
    final xCenter = (size.width - textPainter.width) / 2;
    final yCenter = (size.height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(xCenter, yCenter));
  }

  @override
  bool shouldRepaint(LetterBackgroundPainter old) =>
      old.character != character;
}
