import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/alphabet_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AlphabetProvider(),
      child: const UaAlphabetApp(),
    ),
  );
}

class UaAlphabetApp extends StatelessWidget {
  const UaAlphabetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Українська абетка',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          primary: Colors.orange,
          secondary: Colors.blue,
        ),
        textTheme: GoogleFonts.comicNeueTextTheme(),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
