

enum LetterType { vowel, consonant, special }

class Letter {
  final String character;
  final bool isUppercase;
  final LetterType type;
  final List<String> words;

  Letter({
    required this.character,
    required this.isUppercase,
    required this.type,
    required this.words,
  });

  String get id => "${character}_${isUppercase ? 'UP' : 'LOW'}";
}

class TaskProgress {
  bool speakingDone;
  bool writingDone;
  int findingCount; // Goal: 5

  TaskProgress({
    this.speakingDone = false,
    this.writingDone = false,
    this.findingCount = 0,
  });

  bool get findingDone => findingCount >= 5;
  bool get allDone => speakingDone && writingDone && findingDone;
}
