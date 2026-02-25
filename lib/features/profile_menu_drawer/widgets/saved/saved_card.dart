import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile_menu_drawer/models/saved_model.dart';

class SavedCard extends StatelessWidget {
  final SavedModel model;

  const SavedCard({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(01)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildImage(model.images[1]),
                      _verticalDivider(),
                      _buildImage(model.images[0]),
                    ],
                  ),
                ),
                _horizontalDivider(),
                Expanded(
                  child: Row(
                    children: [
                      _buildImage(model.images[2]),
                      _verticalDivider(),
                      _buildImage(model.images[3]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start, // 👈 ADD THIS
          children: [
            Container(width: 158),

            Text(
              model.title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImage(String? image) {
    if (image == null) {
      return Expanded(child: Container(color: Colors.grey.shade600));
    }

    return Expanded(child: Image.asset(image, fit: BoxFit.cover));
  }

  Widget _verticalDivider() {
    return Container(width: 1.5, color: Colors.white);
  }

  Widget _horizontalDivider() {
    return Container(height: 1.5, color: Colors.white);
  }
}
