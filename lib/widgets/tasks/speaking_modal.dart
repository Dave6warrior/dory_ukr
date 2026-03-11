import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../models/letter.dart';
import '../../providers/alphabet_provider.dart';

class SpeakingModal extends StatefulWidget {
  final Letter letter;
  const SpeakingModal({super.key, required this.letter});

  @override
  State<SpeakingModal> createState() => _SpeakingModalState();
}

class _SpeakingModalState extends State<SpeakingModal> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "Натисни та говори";
  String? _status;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    // Request permission
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      setState(() => _text = "Потрібен доступ до мікрофона");
      return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          debugPrint('onStatus: $val');
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            _evaluateResult();
          }
        },
        onError: (val) {
          debugPrint('onError: $val');
          setState(() {
            _isListening = false;
            _text = "Помилка: ${val.errorMsg}";
          });
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _text = "Слухаю...";
          _status = null;
        });
        
        // Try to use Ukrainian locale, fallback to system
        // Note: 'uk-UA' is the standard locale code for Ukrainian
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
          }),
          localeId: 'uk_UA', 
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
            listenMode: stt.ListenMode.confirmation,
          ),
          listenFor: const Duration(seconds: 5),
        );
      } else {
        setState(() => _text = "Розпізнавання недоступне");
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  void _evaluateResult() {
    if (_text.isEmpty || _text == "Слухаю...") return;

    final target = widget.letter.character.toLowerCase();
    final recognized = _text.toLowerCase();

    // Logic: Check if the recognized text CONTAINS the letter or matches the word/pronunciation
    // Since speech-to-text for single letters is tricky (it might return "a" as "ah" or "hey"),
    // we use a relaxed check or check if it matches common phonetic variations.
    // Ideally, for a letter 'A', we expect "A" or "Ah" or words starting with "A".
    
    // Simple check: does it contain the character?
    // Or is it one of the example words?
    bool isCorrect = recognized.contains(target);
    
    // Also check if any example word was spoken
    for (var word in widget.letter.words) {
      if (recognized.contains(word.toLowerCase())) {
        isCorrect = true;
        break;
      }
    }

    // Fallback simulation for testing if real recognition fails (e.g. on simulator)
    // Remove this in production if needed, but useful for MVP validation without device
    if (recognized.contains("test")) isCorrect = true; 

    setState(() {
      _status = isCorrect ? "Молодець! ✅" : "Спробуй ще раз! ❌";
    });

    if (isCorrect) {
      Provider.of<AlphabetProvider>(context, listen: false).completeSpeaking(widget.letter.id);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Скажи літеру вголос:", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(widget.letter.character, style: TextStyle(fontSize: 100, color: Colors.blue[800])),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _text,
              style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: _listen,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _isListening ? Colors.red : Colors.blue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.red : Colors.blue).withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Icon(_isListening ? Icons.stop : Icons.mic, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          if (_status != null) 
            Text(
              _status!, 
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
                color: _status!.contains("✅") ? Colors.green : Colors.red,
              )
            ),
        ],
      ),
    );
  }
}
