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
            colors: [Color(0xFF9544A7), Color(0xFF42174C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: const [
              LanguageHeader(),
              LanguageList(),
            ],
          ),
        ),
      ),
    );
  }
}
