import 'package:flutter/material.dart';

class FaqList extends StatelessWidget {
  const FaqList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Height ko remove ya wrap_content kiya ja sakta hai agar items zyada hon
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        color: const Color(0xFF7D2D90),
        borderRadius: BorderRadius.circular(35),
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min, // Container ko content ke hisab se adjust karega
        children: const [
          _FaqItem(
            question: 'Why does Qubiko AI app force close?',
            answer: 'This might be due to low memory. Try clearing cache.',
            hasDropdown: false,
          ),
          _FaqDivider(),
          _FaqItem(
            question: 'Why is generating my Qubiko AI response so slow?',
            answer: 'Server load can sometimes cause delays.',
            hasDropdown: false,
          ),
          _FaqDivider(),
          _FaqItem(
            question: 'Why can\'t I add a payment method?',
            answer: 'Check your internet connection or card validity.',
            hasDropdown: false,
          ),
          _FaqDivider(),
          _FaqItem(
            question: 'Why don\'t I get e-receipt after subscription?',
            answer: 'Receipts are sent to your registered email.',
            hasDropdown: false,
          ),
          _FaqDivider(),
          _FaqItem(
            question: 'Is Qubiko AI App free?',
            answer: 'Yes, Qubiko AI offers a free tier with daily limits.',
            hasDropdown: true,
          ),
          // Bottom padding for rounded corners
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer; // Answer add kiya
  final bool hasDropdown;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.hasDropdown,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Agar dropdown nahi hai to purana look, agar hai to Expansion look
    return Theme(
      // Border lines hatane ke liye
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        enabled: widget.hasDropdown,
        trailing: widget.hasDropdown
            ? Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.white70,
                size: 20,
              )
            : const SizedBox.shrink(), // No icon if no dropdown
        title: Text(
          widget.question,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onExpansionChanged: (bool expanded) {
          setState(() => _isExpanded = expanded);
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
            child: Text(
              widget.answer,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqDivider extends StatelessWidget {
  const _FaqDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
