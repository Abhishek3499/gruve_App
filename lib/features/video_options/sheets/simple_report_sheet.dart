import 'package:flutter/material.dart';

class SimpleReportSheet extends StatefulWidget {
  const SimpleReportSheet({super.key});

  @override
  State<SimpleReportSheet> createState() => _SimpleReportSheetState();
}

class _SimpleReportSheetState extends State<SimpleReportSheet> {
  String? selectedReason;

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
      height: MediaQuery.of(context).size.height * 0.60,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCD72E3), Color(0xFF3C034A)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white54,
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

          // Report list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: reportReasons.length,
              itemBuilder: (context, index) {
                final isSelected = selectedReason == reportReasons[index];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedReason = reportReasons[index];
                    });
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
                        // Left icon
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Text
                        Expanded(
                          child: Text(
                            reportReasons[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // Radio icon
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Submit button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFCD72E3),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: selectedReason != null
                      ? () {
                          Navigator.of(context).pop(selectedReason);
                        }
                      : null,
                  borderRadius: BorderRadius.circular(25),
                  child: Center(
                    child: Text(
                      'Submit Report',
                      style: TextStyle(
                        color: selectedReason != null
                            ? Colors.white
                            : Colors.white54,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
