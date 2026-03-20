import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/saved/saved_header.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/saved/saves_footer.dart';
import '../constants/saved_constants.dart';
import '../widgets/saved/saved_card.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 71, 18, 86),
              Color.fromARGB(255, 6, 1, 7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          // ✅ yaha child use hoga
          child: Column(
            children: [
              /// ===== HEADER =====
              const SavedHeader(),

              const SizedBox(height: 30),

              /// ===== CARDS ROW =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: SavedConstants.categories.map((category) {
                  return SavedCard(model: category);
                }).toList(),
              ),

              const Spacer(),

              /// ===== FOOTER =====
              const SavesFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
