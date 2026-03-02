import 'package:flutter/material.dart';

class FaqList extends StatelessWidget {
  const FaqList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5, // 50% screen
      width: double.infinity,

      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Color(0xFF7D2D90),
        borderRadius: BorderRadius.circular(35),
      ),
      child: Column(
        children: const [
          _FaqItem(
            question: 'Why does Qubiko AI app force close?',
            hasDropdown: false,
          ),
          _FaqDivider(),
          _FaqItem(
            question: 'Why is generating my Qubiko AI response so slow?',
            hasDropdown: false,
          ),
          _FaqDivider(),
          _FaqItem(
            question: 'Why can\'t I add a payment method?',
            hasDropdown: false,
          ),
          _FaqDivider(),
          _FaqItem(
            question: 'Why don\'t I get e-receipt after subscription?',
            hasDropdown: false,
          ),
          _FaqDivider(),
          _FaqItem(question: 'Is Qubiko AI App free?', hasDropdown: true),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final bool hasDropdown;

  const _FaqItem({required this.question, required this.hasDropdown});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              question,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (hasDropdown)
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white70,
              size: 20,
            ),
        ],
      ),
    );
  }
}

class _FaqDivider extends StatelessWidget {
  const _FaqDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
