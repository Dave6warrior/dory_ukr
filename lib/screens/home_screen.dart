import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../providers/alphabet_provider.dart';
import '../widgets/letter_card.dart';
import '../widgets/task_bar.dart';
import '../widgets/interactive_background.dart';
import 'level_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AlphabetProvider>(context, listen: false);
    _pageController = PageController(initialPage: provider.currentIndex);
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by InteractiveBackground
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Українська абетка'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.map, size: 30, color: Colors.blue),
            onPressed: () async {
              await Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const LevelMapScreen())
              );
              if (!context.mounted) return;
              // Sync page when returning from map
              final provider = Provider.of<AlphabetProvider>(context, listen: false);
              if (_pageController.hasClients) {
                _pageController.jumpToPage(provider.currentIndex);
              }
            },
          )
        ],
      ),
      body: InteractiveBackground(
        child: Consumer<AlphabetProvider>(
          builder: (context, provider, child) {
            if (provider.shouldCelebrate) {
              _confettiController.play();
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: provider.letters.length,
                      onPageChanged: (index) {
                        provider.setCurrentIndex(index);
                      },
                      itemBuilder: (context, index) {
                        final letter = provider.letters[index];
                        return Center(
                          child: LetterCard(letter: letter),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded, size: 40),
                          onPressed: provider.currentIndex > 0 
                              ? () => _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300), 
                                  curve: Curves.easeInOut) 
                              : null,
                        ),
                        Text(
                          "${provider.currentIndex + 1} / ${provider.letters.length}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 40),
                          onPressed: provider.currentIndex < provider.letters.length - 1 
                              ? () => _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300), 
                                  curve: Curves.easeInOut) 
                              : null,
                        ),
                      ],
                    ),
                  ),
                  TaskBar(letter: provider.currentLetter),
                  const SizedBox(height: 30),
                ],
              ),
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}
