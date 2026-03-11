import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/letter.dart';
import '../utils/alphabet_data.dart';

class AlphabetProvider with ChangeNotifier {
  final List<Letter> _letters = AlphabetData.generateAlphabet();
  int _currentIndex = 0;
  final Map<String, TaskProgress> _progress = {};
  bool _shouldCelebrate = false;

  AlphabetProvider() {
    _loadProgress();
  }

  List<Letter> get letters => _letters;
  int get currentIndex => _currentIndex;
  Letter get currentLetter => _letters[_currentIndex];
  bool get shouldCelebrate => _shouldCelebrate;

  TaskProgress getProgress(String letterId) {
    return _progress.putIfAbsent(letterId, () => TaskProgress());
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _progress.map((key, value) => MapEntry(key, {
      'speakingDone': value.speakingDone,
      'writingDone': value.writingDone,
      'findingCount': value.findingCount,
    }));
    await prefs.setString('alphabet_progress', jsonEncode(data));
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataStr = prefs.getString('alphabet_progress');
    if (dataStr != null) {
      final Map<String, dynamic> data = jsonDecode(dataStr);
      data.forEach((key, value) {
        _progress[key] = TaskProgress(
          speakingDone: value['speakingDone'] ?? false,
          writingDone: value['writingDone'] ?? false,
          findingCount: value['findingCount'] ?? 0,
        );
      });
      notifyListeners();
    }
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _letters.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void nextLetter() {
    if (_currentIndex < _letters.length - 1) {
      _currentIndex++;
      HapticFeedback.lightImpact();
      notifyListeners();
    }
  }

  void previousLetter() {
    if (_currentIndex > 0) {
      _currentIndex--;
      HapticFeedback.lightImpact();
      notifyListeners();
    }
  }

  void _checkCelebration(String letterId) {
    final p = getProgress(letterId);
    if (p.allDone) {
      _shouldCelebrate = true;
      HapticFeedback.vibrate();
      notifyListeners();
      // Reset trigger after a delay
      Future.delayed(const Duration(seconds: 3), () {
        _shouldCelebrate = false;
        notifyListeners();
      });
    }
  }

  void completeSpeaking(String letterId) {
    getProgress(letterId).speakingDone = true;
    HapticFeedback.mediumImpact();
    _saveProgress();
    _checkCelebration(letterId);
    notifyListeners();
  }

  void completeWriting(String letterId) {
    getProgress(letterId).writingDone = true;
    HapticFeedback.mediumImpact();
    _saveProgress();
    _checkCelebration(letterId);
    notifyListeners();
  }

  void incrementFindingCount(String letterId) {
    final p = getProgress(letterId);
    if (p.findingCount < 5) {
      p.findingCount++;
      HapticFeedback.selectionClick();
      _saveProgress();
      _checkCelebration(letterId);
      notifyListeners();
    }
  }
}
