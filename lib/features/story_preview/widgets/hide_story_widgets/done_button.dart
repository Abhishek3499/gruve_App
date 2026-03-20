import 'package:flutter/material.dart';

class DoneButton extends StatelessWidget {
  final VoidCallback onDone;

  const DoneButton({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 48,

      decoration: BoxDecoration(
        color: Color(0xFF72008D), // new background color
        borderRadius: BorderRadius.circular(30),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onDone,
          child: const Center(
            child: Text(
              "Done",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
