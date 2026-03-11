import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/letter.dart';
import '../../providers/alphabet_provider.dart';

class FindingModal extends StatefulWidget {
  final Letter letter;
  const FindingModal({super.key, required this.letter});

  @override
  State<FindingModal> createState() => _FindingModalState();
}

class _FindingModalState extends State<FindingModal> {
  late List<String> _words;
  late String _currentWord;
  int _wordIndex = 0;
  bool _isCorrect = false;
  bool _isIncorrect = false;
  int? _tappedIndex;

  @override
  void initState() {
    super.initState();
    _words = List.from(widget.letter.words)..shuffle();
    _currentWord = _words[0];
  }

  void _onCharTap(int index) {
    if (_isCorrect || _isIncorrect) return;

    setState(() {
      _tappedIndex = index;
    });

    final tappedChar = _currentWord[index];
    if (tappedChar.toLowerCase() == widget.letter.character.toLowerCase()) {
      setState(() {
        _isCorrect = true;
      });
      debugPrint("SUCCESS SOUND: Ding!");
      Provider.of<AlphabetProvider>(context, listen: false).incrementFindingCount(widget.letter.id);
      
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        final provider = Provider.of<AlphabetProvider>(context, listen: false);
        if (provider.getProgress(widget.letter.id).findingDone) {
          Navigator.pop(context);
        } else {
          _nextWord();
        }
      });
    } else {
      setState(() {
        _isIncorrect = true;
      });
      debugPrint("BUZZ SOUND: Bzzz!");
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        _nextWord();
      });
    }
  }

  void _nextWord() {
    setState(() {
      _wordIndex = (_wordIndex + 1) % _words.length;
      _currentWord = _words[_wordIndex];
      _isCorrect = false;
      _isIncorrect = false;
      _tappedIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = Provider.of<AlphabetProvider>(context).getProgress(widget.letter.id);

    return Container(
      height: 500,
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
              const Text("Знайди літеру у слові:", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                child: Text("${progress.findingCount}/5", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Spacer(),
          Text(
            "Знайди: ${widget.letter.character}",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue[800]),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _currentWord.split('').asMap().entries.map((entry) {
              int idx = entry.key;
              String char = entry.value;
              bool isTarget = _tappedIndex == idx;

              return GestureDetector(
                onTap: () => _onCharTap(idx),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        char,
                        style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                      ),
                      if (isTarget && _isCorrect)
                        CustomPaint(
                          painter: CorrectMarkPainter(type: widget.letter.type),
                          size: const Size(50, 50),
                        ),
                      if (isTarget && _isIncorrect)
                        const Icon(Icons.close, color: Colors.red, size: 60),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class CorrectMarkPainter extends CustomPainter {
  final LetterType type;
  CorrectMarkPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    if (type == LetterType.vowel) {
      paint.color = Colors.red.withValues(alpha: 0.6);
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 1.5, paint);
    } else {
      paint.color = Colors.blue.withValues(alpha: 0.6);
      canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
