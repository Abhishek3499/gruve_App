import 'package:flutter/material.dart';

class DoneButton extends StatelessWidget {
  final VoidCallback onDone;
  final bool isLoading;

  const DoneButton({super.key, required this.onDone, this.isLoading = false});

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
          onTap: isLoading ? null : onDone,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
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
