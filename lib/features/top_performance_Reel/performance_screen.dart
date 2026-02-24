import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9544A7), Color(0xFF42174C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /// ===== HEADER =====
              SizedBox(
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Image.asset(
                              AppAssets.back,
                              width: 10,
                              height: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      "Performing Reel",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'syncopate',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// ===== MAIN CONTENT =====
              Image.asset(AppAssets.performance, width: 330, height: 400),

              const SizedBox(height: 15),

              const Text(
                'When the beat drops, I rise 🎵🔥',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Text(
                '20 April Duration 0:38',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),

              const SizedBox(height: 22),

              Image.asset(AppAssets.iconss, height: 60, width: 250),

              /// 🔥 THIS PUSHES CONTENT TO TOP
              const Spacer(),

              /// ===== BOTTOM SECTION =====
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/splash_screen_logo/image 43.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        'Made in India',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'Syncopate',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Powered by  ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: 'Syncopate',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: 'Hardkore Tech',
                          style: TextStyle(
                            color: Color(0xFF72008D),
                            fontSize: 11,
                            fontFamily: 'Syncopate',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
