import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class SimpleBlockSheet extends StatelessWidget {
  const SimpleBlockSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCD72E3), Color(0xFF3C034A)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(45)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// HANDLE BAR
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 20),

              /// AVATAR CENTER
              Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.asset(AppAssets.appleIcon, fit: BoxFit.cover),
                ),
              ),

              const SizedBox(height: 16),

              /// TITLE LEFT ALIGN
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Block gaivyyy?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 08),

              /// DESCRIPTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Blocking this user will prevent them from seeing your content and interacting with you.',
                  style: TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              /// INFO ROWS (UNCHANGED)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Image.asset(AppAssets.blockuser),
                      title: 'Content visibility',
                      description:
                          'Blocked users can\'t see your posts or profile',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Image.asset(AppAssets.message3dot),
                      title: 'Messages',
                      description:
                          'Lorem Ipsum is simply dummy text of the printing',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Image.asset(AppAssets.setting3dot),
                      title: 'Activity',
                      description:
                          'Lorem Ipsum is simply dummy text of the printing',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              /// BLOCK BUTTON
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
                      onTap: () => Navigator.of(context).pop(true),
                      borderRadius: BorderRadius.circular(25),
                      child: const Center(
                        child: Text(
                          'Block',
                          style: TextStyle(
                            color: Colors.white,
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
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required Widget icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),

      child: Row(
        children: [
          SizedBox(width: 20, height: 20, child: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
