import 'package:flutter/material.dart';
import '../widgets/language_header.dart';
import '../widgets/language_list.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 55, 14, 65),
              Color.fromARGB(255, 6, 1, 7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(children: const [LanguageHeader(), LanguageList()]),
        ),
      ),
    );
  }
}
