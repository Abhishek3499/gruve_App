import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../../../core/assets.dart';
import 'message_popup_menu.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final Function(MessageAction)? onActionSelected;

  const ChatBubble({super.key, required this.message, this.onActionSelected});

  void _showPopupMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Stack(
          children: [
            /// Blur Background
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Color(0x33000000)),
            ),

            /// Tap outside to close
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(color: Colors.transparent),
            ),

            /// Popup Menu
            Positioned(
              left: 30,
              top: 200,
              child: MessagePopupMenu(
                onActionSelected: (action) {
                  Navigator.pop(context);
                  if (onActionSelected != null) {
                    onActionSelected!(action);
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showPopupMenu(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: message.isSent
            ? _buildSentBubble(context)
            : _buildReceivedBubble(context),
      ),
    );
  }

  Widget _buildReceivedBubble(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              // BUBBLE — avatar ke peeche se start, left side mein avatar ka space
              Container(
                margin: const EdgeInsets.only(left: 28), // avatar ka half
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: 50, // avatar width ke baad text
                  right: 16,
                  top: 14,
                  bottom: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF72008D),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image content
                    if (message.hasImage) ...[
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: Image.file(
                          File(message.imagePath!),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 200,
                              color: Colors.grey[600],
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Image not available',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Text content
                    if (message.text.isNotEmpty) ...[
                      Text(
                        message.text,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                    ],
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.done_all,
                            size: 14,
                            color: Colors.blue[200],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // AVATAR — bubble ke upar overlap, left side
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 38,
                  backgroundImage: AssetImage(AppAssets.profile),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSentBubble(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.60,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF72008D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Image content
                if (message.hasImage) ...[
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: Image.file(
                      File(message.imagePath!),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[600],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.white,
                                size: 48,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Image not available',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Text content
                if (message.text.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      message.text,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Timestamp row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.done_all, size: 14, color: Colors.blue[300]),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(radius: 18, backgroundImage: AssetImage(AppAssets.user)),
      ],
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final min = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$min${timestamp.hour >= 12 ? 'PM' : 'AM'}';
  }
}
