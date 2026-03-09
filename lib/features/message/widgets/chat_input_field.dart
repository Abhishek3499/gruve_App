import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class ChatInputField extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isLoading;

  const ChatInputField({
    super.key,
    required this.onSendMessage,
    this.isLoading = false,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isLoading) {
      widget.onSendMessage(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Color(0xFF1C0B21)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF72008D),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            /// Left Icon
            Image.asset(
              AppAssets.camera,
              color: Colors.white,
              height: 28,
              width: 28,
            ),

            const SizedBox(width: 10),

            /// Text Field
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Text Message",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              ),
            ),

            /// Send Button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: widget.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Center(
                        child: Image.asset(
                          AppAssets.send,
                          width: 20,
                          height: 20,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
