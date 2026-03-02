import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile_menu_drawer/constants/archive_model/archive_dummy_data.dart';

class ArchiveGridView extends StatelessWidget {
  const ArchiveGridView({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.builder(
          itemCount: archiveItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final item = archiveItems[index];
            debugPrint('Loading image: ${item.image}'); // Debug print

            return ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    item.image, 
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading image: $error'); // Debug print
                      return Container(
                        color: Colors.red,
                        child: const Center(
                          child: Text('Error', style: TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                  ),

                  /// DATE BADGE
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${item.day}\n${item.month}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
