import 'package:flutter/material.dart';

class SimpleReportSheet extends StatefulWidget {
  const SimpleReportSheet({super.key});

  @override
  State<SimpleReportSheet> createState() => _SimpleReportSheetState();
}

class _SimpleReportSheetState extends State<SimpleReportSheet> {
  final List<String> reportReasons = [
    'I just don\'t like it',
    'Bullying or unwanted contact',
    'Suicide, self-injury or eating disorders',
    'Substance abuse or addiction',
    'Harassment or discrimination',
    'Violence or threats of violence',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.57,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCD72E3), Color(0xFF3C034A)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0x80FFFFFF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Why are you reporting this post?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Report reasons list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: reportReasons.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // 👇 AUTO SUBMIT + CLOSE
                    Navigator.of(context).pop(reportReasons[index]);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x804B005D),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // ONLY TEXT (clean UI)
                        Expanded(
                          child: Text(
                            reportReasons[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 06),
        ],
      ),
    );
  }
}
