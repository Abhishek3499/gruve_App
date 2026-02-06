import 'package:flutter/material.dart';
import 'package:gruve_app/screens/auth/screens/forgot_password_screen.dart';

class AuthForgotPassword extends StatelessWidget {
  const AuthForgotPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
          );
        },
        child: const Text(
          'Forgot Password?',
          style: TextStyle(
            color: Color(0xFFB86AD0),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
