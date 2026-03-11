import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/letter.dart';
import '../providers/alphabet_provider.dart';
import 'tasks/speaking_modal.dart';
import 'tasks/writing_modal.dart';
import 'tasks/finding_modal.dart';

class TaskBar extends StatelessWidget {
  final Letter letter;
  const TaskBar({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AlphabetProvider>(context);
    final progress = provider.getProgress(letter.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TaskIcon(
            icon: Icons.mic,
            color: Colors.red,
            isDone: progress.speakingDone,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => SpeakingModal(letter: letter),
            ),
          ),
          const SizedBox(width: 30),
          _TaskIcon(
            icon: Icons.edit,
            color: Colors.green,
            isDone: progress.writingDone,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => WritingModal(letter: letter),
            ),
          ),
          const SizedBox(width: 30),
          _TaskIcon(
            icon: Icons.search,
            color: Colors.blue,
            isDone: progress.findingDone,
            score: "${progress.findingCount}/5",
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => FindingModal(letter: letter),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDone;
  final String? score;
  final VoidCallback onTap;

  const _TaskIcon({
    required this.icon,
    required this.color,
    required this.isDone,
    required this.onTap,
    this.score,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDone ? color.withValues(alpha: 0.2) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: isDone ? color : Colors.grey[400],
            ),
          ),
          if (isDone)
            const Positioned(
              right: 0,
              bottom: 0,
              child: Icon(Icons.check_circle, color: Colors.green, size: 18),
            )
          else if (score != null)
            Positioned(
              right: -5,
              bottom: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                child: Text(score!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
