import 'package:flutter/material.dart';
import 'package:gruve_app/features/user_profile/data/report_user_reasons.dart';

enum ReportSheetTarget { user, post }

class SimpleReportSheet extends StatelessWidget {
  final ReportSheetTarget target;

  const SimpleReportSheet({
    super.key,
    this.target = ReportSheetTarget.user,
  });

  String get _title {
    switch (target) {
      case ReportSheetTarget.post:
        return 'Why are you reporting this post?';
      case ReportSheetTarget.user:
        return 'Why are you reporting this user?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.57,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kReportUserReasons.length,
              itemBuilder: (context, index) {
                final reason = kReportUserReasons[index];
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(reason.key),
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
                    child: Text(
                      reason.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
