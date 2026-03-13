import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../../models/letter.dart';
import '../../providers/alphabet_provider.dart';
import '../../utils/letter_segments.dart';

// ─── Segment tracking helper ────────────────────────────────────────────────
class _SegmentTracker {
  final List<Offset> points;
  late final double totalLength;
  late final List<double> _cumLengths;

  _SegmentTracker(this.points) {
    _cumLengths = [0.0];
    for (int i = 1; i < points.length; i++) {
      _cumLengths.add(_cumLengths.last + (points[i] - points[i - 1]).distance);
    }
    totalLength = _cumLengths.last;
  }

  (Offset, double, double) project(Offset point) {
    double bestDist = double.infinity;
    Offset bestPt = points.first;
    double bestProgress = 0.0;

    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final ab = b - a;
      final segLen = ab.distance;
      if (segLen == 0) continue;

      double t = ((point.dx - a.dx) * ab.dx + (point.dy - a.dy) * ab.dy) /
          (segLen * segLen);
      t = t.clamp(0.0, 1.0);

      final closest = a + ab * t;
      final dist = (point - closest).distance;

      if (dist < bestDist) {
        bestDist = dist;
        bestPt = closest;
        bestProgress = (_cumLengths[i] + t * segLen) / totalLength;
      }
    }
    return (bestPt, bestProgress, bestDist);
  }

  Path pathUpTo(double progress) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    final target = progress * totalLength;

    for (int i = 0; i < points.length - 1; i++) {
      if (_cumLengths[i] >= target) break;
      if (_cumLengths[i + 1] <= target) {
        path.lineTo(points[i + 1].dx, points[i + 1].dy);
      } else {
        final segLen = _cumLengths[i + 1] - _cumLengths[i];
        final t = (target - _cumLengths[i]) / segLen;
        final end = Offset.lerp(points[i], points[i + 1], t)!;
        path.lineTo(end.dx, end.dy);
        break;
      }
    }
    return path;
  }
}

// ─── Main widget ────────────────────────────────────────────────────────────
class WritingModal extends StatefulWidget {
  final Letter letter;
  const WritingModal({super.key, required this.letter});

  @override
  State<WritingModal> createState() => _WritingModalState();
}

class _WritingModalState extends State<WritingModal>
    with TickerProviderStateMixin {
  // ─── Segment state ──────────────────────────────────────────
  late List<List<Offset>> _segmentsNorm;
  int _activeIdx = 0;
  double _activeProgress = 0.0;
  double _furthestProgress = 0.0;
  final Set<int> _completedSegs = {};

  // ─── Touch state ────────────────────────────────────────────
  Offset? _touchPos;
  bool _isDrawing = false;
  double _distanceTraveled = 0.0;
  Offset? _lastMovePos;

  // ─── Sparkle trail ──────────────────────────────────────────
  final List<Offset> _sparkleTrail = [];
  static const int _maxTrail = 8;

  // ─── UI flags ───────────────────────────────────────────────
  bool _isError = false;
  bool _isSuccess = false;
  bool _isReady = false;

  // ─── Layout cache ───────────────────────────────────────────
  Rect _letterRect = Rect.zero;
  Size _canvasSize = Size.zero;

  // ─── Ink bounds (normalised to TextPainter layout) ──────────
  double _inkNL = 0, _inkNT = 0, _inkNR = 1, _inkNB = 1;

  // ─── Animation controllers ─────────────────────────────────
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _sparkleCtrl;
  late AnimationController _successCtrl;
  late Animation<double> _successFade;
  late Animation<double> _successScale;
  late ConfettiController _confettiCtrl;

  // ─── Celebration ────────────────────────────────────────────
  static const _phrases = [
    'Молодець!', 'Чудово!', 'Супер!', 'Так тримати!',
    'Гарна робота!', 'Браво!', 'Відмінно!', 'Чемпіон!',
  ];
  static const _sparkleColors = [
    Color(0xFF0057B7), Color(0xFFFFD700), Color(0xFF2ECC71),
    Color(0xFFE74C3C), Color(0xFF9B59B6), Color(0xFFF39C12),
  ];
  late String _phrase;

  // ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _segmentsNorm = LetterSegments.getSegments(widget.letter.character);
    _phrase = _phrases[math.Random().nextInt(_phrases.length)];

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeCtrl);

    _sparkleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();

    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _successFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _successCtrl, curve: Curves.easeOut));
    _successScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));

    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));

    _computeInkBounds();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _sparkleCtrl.dispose();
    _successCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  // ─── Compute real ink bounds via off-screen render ──────────
  Future<void> _computeInkBounds() async {
    const gs = 300;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec, const Rect.fromLTWH(0, 0, gs * 1.0, gs * 1.0));

    final ts = TextSpan(
      text: widget.letter.character,
      style: const TextStyle(
          fontSize: 250,
          fontWeight: FontWeight.w900,
          fontFamily: 'Nunito',
          color: Colors.black),
    );
    final tp = TextPainter(text: ts, textDirection: TextDirection.ltr)
      ..layout();
    final ox = (gs - tp.width) / 2;
    final oy = (gs - tp.height) / 2;
    tp.paint(c, Offset(ox, oy));

    final pic = rec.endRecording();
    final img = await pic.toImage(gs, gs);
    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bd == null) return;

    int minX = gs, maxX = 0, minY = gs, maxY = 0;
    for (int y = 0; y < gs; y++) {
      for (int x = 0; x < gs; x++) {
        if (bd.getUint8((y * gs + x) * 4 + 3) > 20) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX <= minX || maxY <= minY) {
      if (mounted) setState(() => _isReady = true);
      return;
    }

    _inkNL = (minX - ox) / tp.width;
    _inkNT = (minY - oy) / tp.height;
    _inkNR = (maxX - ox) / tp.width;
    _inkNB = (maxY - oy) / tp.height;

    if (mounted) setState(() => _isReady = true);
  }

  // ─── Coordinate helpers ─────────────────────────────────────
  void _computeLetterRect(Size canvasSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: widget.letter.character,
        style: TextStyle(
            fontSize: canvasSize.height * 0.83,
            fontWeight: FontWeight.w900,
            fontFamily: 'Nunito'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final lx = (canvasSize.width - tp.width) / 2;
    final ly = (canvasSize.height - tp.height) / 2;

    // Map to actual ink bounds (not full ascent/descent)
    _letterRect = Rect.fromLTRB(
      lx + _inkNL * tp.width,
      ly + _inkNT * tp.height,
      lx + _inkNR * tp.width,
      ly + _inkNB * tp.height,
    );
    _canvasSize = canvasSize;
  }

  List<Offset> _toCanvas(List<Offset> norm) => norm
      .map((p) => Offset(
            _letterRect.left + p.dx * _letterRect.width,
            _letterRect.top + p.dy * _letterRect.height,
          ))
      .toList();

  // ─── Pointer handlers ──────────────────────────────────────
  void _onPointerDown(PointerDownEvent e) {
    if (_isSuccess || _isError) return;
    if (_activeIdx >= _segmentsNorm.length) return;

    final pos = e.localPosition;
    final seg = _toCanvas(_segmentsNorm[_activeIdx]);
    final tolerance = _canvasSize.width * 0.30;

    if ((pos - seg.first).distance <= tolerance) {
      setState(() {
        _isDrawing = true;
        _touchPos = pos;
        _activeProgress = 0.0;
        _furthestProgress = 0.0;
        _distanceTraveled = 0.0;
        _lastMovePos = pos;
        _sparkleTrail.clear();
      });
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_isDrawing || _isSuccess || _isError) return;

    final pos = e.localPosition;
    final seg = _toCanvas(_segmentsNorm[_activeIdx]);
    final tracker = _SegmentTracker(seg);
    final (_, progress, dist) = tracker.project(pos);
    final tolerance = _canvasSize.width * 0.30;

    if (dist > tolerance) {
      _triggerError();
      return;
    }

    setState(() {
      _touchPos = pos;
      if (_lastMovePos != null) {
        _distanceTraveled += (pos - _lastMovePos!).distance;
      }
      _lastMovePos = pos;
      if (progress > _furthestProgress) {
        _furthestProgress = progress;
        _activeProgress = progress;
      }
      _sparkleTrail.add(pos);
      if (_sparkleTrail.length > _maxTrail) _sparkleTrail.removeAt(0);
    });

    _checkSegmentDone();
  }

  void _onPointerUp(PointerUpEvent e) {
    if (!_isDrawing) return;
    setState(() {
      _isDrawing = false;
      _touchPos = null;
      _sparkleTrail.clear();
    });
    // Check on pointer up too (for taps on dots)
    _checkSegmentDone();
  }

  // ─── Game actions ───────────────────────────────────────────
  void _resetAll() {
    setState(() {
      _activeIdx = 0;
      _activeProgress = 0.0;
      _furthestProgress = 0.0;
      _completedSegs.clear();
      _isDrawing = false;
      _isError = false;
      _isSuccess = false;
      _touchPos = null;
      _sparkleTrail.clear();
      _distanceTraveled = 0.0;
      _lastMovePos = null;
    });
    _successCtrl.reset();
    _confettiCtrl.stop();
  }

  void _triggerError() {
    if (_isError || _isSuccess) return;
    setState(() {
      _isError = true;
      _isDrawing = false;
      _touchPos = null;
      _sparkleTrail.clear();
    });
    _shakeCtrl.forward(from: 0.0);

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _isError = false;
          _activeIdx = 0;
          _activeProgress = 0.0;
          _furthestProgress = 0.0;
          _completedSegs.clear();
        });
      }
    });
  }

  void _checkSegmentDone() {
    if (_activeIdx >= _segmentsNorm.length) return;
    final seg = _toCanvas(_segmentsNorm[_activeIdx]);
    final tracker = _SegmentTracker(seg);
    // Short segments (dots): just progress check. Long: also need distance.
    final isShort = tracker.totalLength < 40;
    final minDist = tracker.totalLength * 0.55;
    if (_activeProgress >= 0.85 &&
        (isShort || _distanceTraveled >= minDist)) {
      setState(() {
        _completedSegs.add(_activeIdx);
        _activeIdx++;
        _activeProgress = 0.0;
        _furthestProgress = 0.0;
        _isDrawing = false;
        _touchPos = null;
        _sparkleTrail.clear();
        _distanceTraveled = 0.0;
        _lastMovePos = null;
      });
      _checkAllDone();
    }
  }

  void _checkAllDone() {
    if (_completedSegs.length == _segmentsNorm.length) {
      setState(() => _isSuccess = true);
      _confettiCtrl.play();
      _successCtrl.forward();
      Provider.of<AlphabetProvider>(context, listen: false)
          .completeWriting(widget.letter.id);
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  // ─── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Напиши літеру:',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            IconButton(
                icon: const Icon(Icons.refresh, size: 32),
                onPressed: _resetAll),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: !_isReady
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(builder: (context, constraints) {
                  final viewSize = math.min(
                      constraints.maxWidth, constraints.maxHeight);
                  _computeLetterRect(Size(viewSize, viewSize));

                  return Center(
                    child: AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (ctx, child) => Transform.translate(
                        offset: Offset(
                            _shakeAnim.value *
                                math.sin(_shakeCtrl.value * math.pi * 4),
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
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Stack(alignment: Alignment.center, children: [
                            // ── Background letter ─────────
                            CustomPaint(
                              size: Size.infinite,
                              painter: _LetterBgPainter(
                                  character: widget.letter.character),
                            ),

                            // ── Drawing layer ─────────────
                            Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: _onPointerDown,
                              onPointerMove: _onPointerMove,
                              onPointerUp: _onPointerUp,
                              child: AnimatedBuilder(
                                animation: _sparkleCtrl,
                                builder: (ctx, _) => CustomPaint(
                                  painter: _TracingPainter(
                                    character: widget.letter.character,
                                    segments: _segmentsNorm
                                        .map(_toCanvas)
                                        .toList(),
                                    completedSegs: _completedSegs,
                                    activeIdx: _activeIdx,
                                    activeProgress: _activeProgress,
                                    isError: _isError,
                                    touchPos: _touchPos,
                                    sparkleRotation:
                                        _sparkleCtrl.value * 2 * math.pi,
                                    sparkleTrail: List.of(_sparkleTrail),
                                    totalSegments: _segmentsNorm.length,
                                    sparkleColors: _sparkleColors,
                                  ),
                                  size: Size.infinite,
                                ),
                              ),
                            ),

                            // ── Confetti ──────────────────
                            Align(
                              alignment: Alignment.topCenter,
                              child: ConfettiWidget(
                                confettiController: _confettiCtrl,
                                blastDirectionality:
                                    BlastDirectionality.explosive,
                                shouldLoop: false,
                                numberOfParticles: 30,
                                gravity: 0.15,
                                colors: const [
                                  Color(0xFF0057B7), Color(0xFFFFD700),
                                  Color(0xFF2ECC71), Color(0xFFE74C3C),
                                  Color(0xFF9B59B6),
                                ],
                              ),
                            ),

                            // ── Success overlay ───────────
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
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF27AE60)
                                              .withValues(alpha: 0.5),
                                          blurRadius: 20, spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('🌟',
                                              style: TextStyle(fontSize: 44)),
                                          const SizedBox(height: 4),
                                          Text(_phrase,
                                              style: const TextStyle(
                                                fontSize: 34,
                                                fontWeight: FontWeight.w900,
                                                fontFamily: 'Nunito',
                                                color: Colors.white,
                                              )),
                                        ]),
                                  ),
                                ),
                              ),
                          ]),
                        ),
                      ),
                    ),
                  );
                }),
        ),
        const SizedBox(height: 20),
        // ── Progress dots ─────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSuccess
              ? const SizedBox.shrink()
              : Row(
                  key: const ValueKey('dots'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_segmentsNorm.length, (i) {
                    Color c;
                    if (_completedSegs.contains(i)) {
                      c = const Color(0xFF27AE60);
                    } else if (i == _activeIdx) {
                      c = const Color(0xFF1565C0);
                    } else {
                      c = Colors.grey[300]!;
                    }
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        color: c, shape: BoxShape.circle,
                        border: i == _activeIdx
                            ? Border.all(
                                color: const Color(0xFF1565C0), width: 2)
                            : null,
                      ),
                    );
                  }),
                ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSuccess
              ? const SizedBox.shrink()
              : Text(
                  'Обведи частину ${_activeIdx + 1} з ${_segmentsNorm.length}',
                  key: const ValueKey('hint'),
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ),
        const SizedBox(height: 10),
      ]),
    );
  }
}

// ─── Tracing Painter ────────────────────────────────────────────────────────
class _TracingPainter extends CustomPainter {
  final String character;
  final List<List<Offset>> segments;
  final Set<int> completedSegs;
  final int activeIdx;
  final double activeProgress;
  final bool isError;
  final Offset? touchPos;
  final double sparkleRotation;
  final List<Offset> sparkleTrail;
  final int totalSegments;
  final List<Color> sparkleColors;

  _TracingPainter({
    required this.character,
    required this.segments,
    required this.completedSegs,
    required this.activeIdx,
    required this.activeProgress,
    required this.isError,
    required this.touchPos,
    required this.sparkleRotation,
    required this.sparkleTrail,
    required this.totalSegments,
    required this.sparkleColors,
  });

  void _paintLetter(Canvas canvas, Size size, Color color) {
    final ts = TextSpan(
      text: character,
      style: TextStyle(
          fontSize: size.height * 0.83,
          fontWeight: FontWeight.w900,
          fontFamily: 'Nunito',
          color: color),
    );
    final tp = TextPainter(text: ts, textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas,
        Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
  }

  void _drawStroke(
      Canvas canvas, List<Offset> seg, double progress, double w) {
    if (seg.length < 2 || progress <= 0) return;
    canvas.drawPath(
      _SegmentTracker(seg).pathUpTo(progress),
      Paint()
        ..color = Colors.black
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  /// Guide: semi-transparent letter tinted by segment stroke.
  void _drawGuide(Canvas canvas, Size size, List<Offset> seg, double sw) {
    canvas.saveLayer(Offset.zero & size, Paint());
    _drawStroke(canvas, seg, 1.0, sw);
    canvas.saveLayer(
        Offset.zero & size, Paint()..blendMode = BlendMode.srcIn);
    _paintLetter(canvas, size,
        const Color(0xFF42A5F5).withValues(alpha: 0.28));
    canvas.restore();
    canvas.restore();

    // Start circle
    canvas.drawCircle(seg.first, 11,
        Paint()..color = const Color(0xFF42A5F5).withValues(alpha: 0.45));
    canvas.drawCircle(
        seg.first, 11,
        Paint()
          ..color = const Color(0xFF1565C0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width * 0.13;

    // 1. Completed segments → green
    if (completedSegs.isNotEmpty) {
      canvas.saveLayer(Offset.zero & size, Paint());
      for (final i in completedSegs) {
        _drawStroke(canvas, segments[i], 1.0, sw);
      }
      canvas.saveLayer(
          Offset.zero & size, Paint()..blendMode = BlendMode.srcIn);
      _paintLetter(canvas, size, const Color(0xFF27AE60));
      canvas.restore();
      canvas.restore();
    }

    // 2. Active segment → blue or red
    if (activeIdx < totalSegments && activeProgress > 0) {
      final color = isError ? Colors.red : const Color(0xFF1565C0);
      canvas.saveLayer(Offset.zero & size, Paint());
      _drawStroke(canvas, segments[activeIdx], activeProgress, sw);
      canvas.saveLayer(
          Offset.zero & size, Paint()..blendMode = BlendMode.srcIn);
      _paintLetter(canvas, size, color);
      canvas.restore();
      canvas.restore();
    }

    // 3. Guide for active segment
    if (activeIdx < totalSegments && !isError) {
      _drawGuide(canvas, size, segments[activeIdx], sw);
    }

    // 4. Colorful sparkle trail
    for (int i = 0; i < sparkleTrail.length; i++) {
      final t = (i + 1) / sparkleTrail.length;
      final color = sparkleColors[i % sparkleColors.length];
      canvas.drawCircle(
        sparkleTrail[i],
        3.5 + t * 2,
        Paint()..color = color.withValues(alpha: t * 0.6),
      );
    }

    // 5. Sparkle ring at touch point (colorful)
    if (touchPos != null && !isError) {
      const n = 6;
      const r = 16.0;
      for (int i = 0; i < n; i++) {
        final a = sparkleRotation + (i * 2 * math.pi / n);
        final dc = Offset(
            touchPos!.dx + r * math.cos(a), touchPos!.dy + r * math.sin(a));
        final color = sparkleColors[i % sparkleColors.length];
        final paint = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.9),
              color.withValues(alpha: 0.5),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: dc, radius: 6));
        canvas.drawCircle(dc, 6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_TracingPainter old) => true;
}

// ─── Background letter painter ──────────────────────────────────────────────
class _LetterBgPainter extends CustomPainter {
  final String character;
  _LetterBgPainter({required this.character});

  @override
  void paint(Canvas canvas, Size size) {
    final ts = TextSpan(
      text: character,
      style: TextStyle(
          fontSize: size.height * 0.83,
          fontWeight: FontWeight.w900,
          fontFamily: 'Nunito',
          color: Colors.grey.withValues(alpha: 0.22)),
    );
    final tp = TextPainter(text: ts, textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas,
        Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
  }

  @override
  bool shouldRepaint(_LetterBgPainter old) => old.character != character;
}