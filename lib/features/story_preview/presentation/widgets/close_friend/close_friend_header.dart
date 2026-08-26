import 'package:flutter/material.dart';

class CloseFriendHeader extends StatelessWidget {
  final VoidCallback onBack;

  const CloseFriendHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: double.infinity,

      child: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            /// BACK BUTTON
            Positioned(
              left: 20,
              child: BackButton(
                color: Colors.white,
                onPressed: onBack,
              ),
            ),

            /// TITLE
            const Text(
              "Close Friends",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w200,
                fontFamily: "syncopate",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
