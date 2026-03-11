import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/letter.dart';
import 'animated_mark.dart';

class LetterCard extends StatefulWidget {
  final Letter letter;
  const LetterCard({super.key, required this.letter});

  @override
  State<LetterCard> createState() => _LetterCardState();
}

class _LetterCardState extends State<LetterCard> {
  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("uk-UA");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Future<void> playAudio(String letter, bool isUppercase) async {
    // "Велика літера А" or "Мала літера а"
    String textToPlay = isUppercase 
        ? "Велика літера $letter" 
        : "Мала літера $letter";
    
    if (letter == "ь") textToPlay = "М'який знак";
    
    debugPrint("PLAYING AUDIO: $textToPlay"); 
    await flutterTts.speak(textToPlay);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => playAudio(widget.letter.character, widget.letter.isUppercase),
      child: Container(
        width: 300,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              widget.letter.character,
              style: TextStyle(
                fontSize: 180,
                fontWeight: FontWeight.bold,
                color: widget.letter.type == LetterType.vowel ? Colors.red[800] : Colors.blue[800],
              ),
            ),
            if (widget.letter.type != LetterType.special) 
              Positioned.fill(
                child: AnimatedMark(type: widget.letter.type),
              ),
          ],
        ),
      ),
    );
  }
}
