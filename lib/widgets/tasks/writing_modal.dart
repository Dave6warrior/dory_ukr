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
  List<bool>? _targetGrid;      // Přesné pixely písmene
  List<bool>? _toleranceGrid;   // Zóna bezpečí pro děti (lehoučké vybočení)
  final Set<int> _coveredTargetCells = {};
  int _totalTargetCells = 0;
  bool _isHitMapReady = false;

  // ─── Interaction state ────────────────────────────────────────────────────
  bool _isFlashingError = false;
  bool _isSuccess = false;
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

    // Zatřesení při chybě
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    // Animace úspěchu (Zelená + Zvuk/Overlay)
    _successController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _successFade =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOut,
    ));
    _successScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _successController, curve: Curves.elasticOut));

    // Červené probliknutí při chybě
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

  // ─── Generování Hit-Mapy ───────────────────────────────────────────────
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
    int targetCount = 0;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final int index = (y * gridSize + x) * 4;
        final int alpha = byteData.getUint8(index + 3);
        if (alpha > 128) {
          _targetGrid![y * gridSize + x] = true;
          targetCount++;
        }
      }
    }
    _totalTargetCells = targetCount;

    // Rozšíření zóny tolerance pro děti (bezpečná zóna pro tah prstem)
    const int minorRadius = 55; // Velkorysá zóna pro malé děti

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (!_targetGrid![y * gridSize + x]) continue;
        for (int dy = -minorRadius; dy <= minorRadius; dy += 2) {
          for (int dx = -minorRadius; dx <= minorRadius; dx += 2) {
            final int distSq = dx * dx + dy * dy;
            final int ny = y + dy;
            final int nx = x + dx;
            if (ny < 0 || ny >= gridSize || nx < 0 || nx >= gridSize) continue;
            if (distSq <= minorRadius * minorRadius) {
              _toleranceGrid![ny * gridSize + nx] = true;
            }
          }
        }
      }
    }

    if (mounted) {
      setState(() => _isHitMapReady = true);
    }
  }

  // ─── Pomocné funkce souřadnic ─────────────────────────────────────────
  (int gx, int gy) _toGrid(Offset screenPos) {
    final double s = gridSize / _viewSize;
    return ((screenPos.dx * s).toInt(), (screenPos.dy * s).toInt());
  }

  // ─── Herní akce ──────────────────────────────────────────────────────────
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
      _points.add(null);
    });
    _shakeController.forward(from: 0.0);
    _errorFlashController.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _clear();
    });
  }

  void _checkSuccess() {
    if (_isSuccess || _totalTargetCells == 0) return;
    // Kontrola pokrytí písmene, 85% stačí k tomu, aby to vypadalo perfektně a dítě nebylo frustrované
    final double coverage = _coveredTargetCells.length / _totalTargetCells;
    if (coverage >= 0.85) {
      setState(() => _isSuccess = true);
      _successController.forward();
      Provider.of<AlphabetProvider>(context, listen: false)
          .completeWriting(widget.letter.id);
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  // ─── Zpracování dotyků (Nyní v GestureDetectoru pro fixaci scrollování) ─
  void _handlePointerDown(Offset localPos) {
    if (_isSuccess || _isFlashingError) return;
    final (gx, gy) = _toGrid(localPos);
    if (gx < 0 || gx >= gridSize || gy < 0 || gy >= gridSize) {
      _triggerError();
      return;
    }
    final int idx = gy * gridSize + gx;
    
    // Začínáme novou čáru
    _points.add(null);
    
    if (_targetGrid![idx] || _toleranceGrid![idx]) {
      setState(() {
        _points.add(localPos);
        if (_targetGrid![idx]) _coveredTargetCells.add(idx);
      });
      _checkSuccess();
    } else {
      _triggerError();
    }
  }

  void _handlePointerMove(Offset localPos) {
    if (_isSuccess || _isFlashingError) return;
    final (gx, gy) = _toGrid(localPos);

    if (gx < 0 || gx >= gridSize || gy < 0 || gy >= gridSize) {
      _triggerError();
      return;
    }

    final int idx = gy * gridSize + gx;

    if (_targetGrid![idx]) {
      // Jsme přímo na písmenu - zaznamenáme bod a pokrytí
      setState(() {
        _points.add(localPos);
        _coveredTargetCells.add(idx);
      });
      _checkSuccess();
    } else if (_toleranceGrid![idx]) {
      // Zóna benevolence (dítě trochu ujelo) - neznamená chybu!
      // Pouze nepřidáváme pokrytí, bod zaznamenáme, aby linka byla nepřerušená
      setState(() {
        _points.add(localPos);
      });
    } else {
      // Dítě hodně sjelo mimo tolerance - chyba a reset
      _triggerError();
    }
  }

  void _handlePointerUp() {
    if (_isSuccess || _isFlashingError) return;
    setState(() => _points.add(null));
    _checkSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
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
                                      math.pi * 4), 0),
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
                                // ── Podkladové slabé písmeno ──────────────
                                CustomPaint(
                                  size: Size.infinite,
                                  painter: LetterBackgroundPainter(
                                      character: widget.letter.character),
                                ),

                                // ── Vrstva kreslení (GestureDetector blokuje scrollování!) ─
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onPanStart: (e) => _handlePointerDown(e.localPosition),
                                  onPanUpdate: (e) => _handlePointerMove(e.localPosition),
                                  onPanEnd: (_) => _handlePointerUp(),
                                  onPanCancel: () => _handlePointerUp(),
                                  child: AnimatedBuilder(
                                    animation: _errorFlashController,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: DrawingPainter(
                                          character: widget.letter.character,
                                          points: _points,
                                          isError: _isFlashingError,
                                          isSuccess: _isSuccess,
                                          errorColor: _isFlashingError
                                              ? (_errorFlashColor.value ?? Colors.red)
                                              : Colors.red,
                                        ),
                                        size: Size.infinite,
                                      );
                                    },
                                  ),
                                ),

                                // ── Oslava úspěchu (Nápis "Molodec") ───────
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
                                        child: const Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '🌟',
                                              style: TextStyle(fontSize: 44),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Молодець!',
                                              style: TextStyle(
                                                fontSize: 34,
                                                fontWeight: FontWeight.w900,
                                                fontFamily: 'Nunito',
                                                color: Colors.white,
                                                letterSpacing: 0.5,
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
    );
  }
}

// ─── DrawingPainter (Kreslíř Masky) ─────────────────────────────────────────

class DrawingPainter extends CustomPainter {
  final String character;
  final List<Offset?> points;
  final bool isError;
  final bool isSuccess;
  final Color errorColor;

  DrawingPainter({
    required this.character,
    required this.points,
    this.isError = false,
    this.isSuccess = false,
    this.errorColor = Colors.red,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Vytvoříme si oddělenou vrstvu pro maskování
    canvas.saveLayer(Offset.zero & size, Paint());

    // 1. Nakreslíme tah prstem (bude to fungovat jako odkrývací maska)
    final maskPaint = Paint()
      ..color = Colors.black // Barva tu není důležitá, jde o pixely
      ..strokeWidth = size.width * 0.16 // Krásně silná čára pro děti
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, maskPaint);
      }
    }

    // 2. Definujeme si barvu výsledného krásného písmene
    Color textColor;
    if (isError) {
      textColor = errorColor;
    } else if (isSuccess) {
      textColor = const Color(0xFF27AE60); // Úspěch -> Zelená
    } else {
      textColor = const Color(0xFF1565C0); // Normální kreslení -> Modrá
    }

    // 3. Spojíme náš tah s dokonalým písmenem (BlendMode.srcIn = ukaž písmeno jen tam, kde je tah)
    final blendPaint = Paint()..blendMode = BlendMode.srcIn;
    canvas.saveLayer(Offset.zero & size, blendPaint);

    final textSpan = TextSpan(
      text: character,
      style: TextStyle(
        fontSize: size.height * 0.83,
        fontWeight: FontWeight.w900,
        fontFamily: 'Nunito',
        color: textColor,
      ),
    );
    final textPainter = TextPainter(
        text: textSpan, textDirection: TextDirection.ltr)
      ..layout();
    
    final xCenter = (size.width - textPainter.width) / 2;
    final yCenter = (size.height - textPainter.height) / 2;
    
    textPainter.paint(canvas, Offset(xCenter, yCenter));

    // Zavřeme vrstvy maskování
    canvas.restore();
    canvas.restore();
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
        color: Colors.grey.withValues(alpha: 0.22), // Slabě šedé pozadí
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