import 'package:flutter/material.dart';

class ReplyingCard extends StatefulWidget {
  const ReplyingCard({super.key});

  @override
  State<ReplyingCard> createState() => _ReplyingCardState();
}

class _ReplyingCardState extends State<ReplyingCard> {
  int selectedValue = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF72008D), Color(0xFF511263)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF2E1735),
            offset: Offset(-10, -10),
            blurRadius: 19,
          ),
          BoxShadow(
            color: Color(0xFF2E1735),
            offset: Offset(10, 10),
            blurRadius: 19,
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Replying",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          _buildOption("Everyone", 0),
          const SizedBox(height: 6),

          _buildOption("People you follow", 1),
          const SizedBox(height: 6),

          _buildOption("Off", 2),
        ],
      ),
    );
  }

  Widget _buildOption(String text, int value) {
    final isSelected = selectedValue == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedValue = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 20,
        ), // 🔥 equal height feel
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),

            /// 🔥 Custom Radio (better UI)
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
