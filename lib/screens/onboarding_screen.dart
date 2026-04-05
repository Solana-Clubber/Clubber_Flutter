import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onGetStarted, this.onSkip});

  final VoidCallback onGetStarted;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF1493);
    const bg = Color(0xFF0D0D0D);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            // Skip button
            Positioned(
              top: 16,
              right: 24,
              child: GestureDetector(
                onTap: onSkip ?? onGetStarted,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            // Purple glow behind bars
            Positioned(
              top: size.height * 0.2,
              left: size.width * 0.1,
              child: Container(
                width: size.width * 0.8,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(100),
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF9C59B5).withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Equalizer bars
            Positioned(
              top: size.height * 0.18,
              left: 0,
              right: 0,
              child: const _EqualizerBars(),
            ),
            // Title
            Positioned(
              top: size.height * 0.48,
              left: 0,
              right: 0,
              child: const Column(
                children: [
                  Text(
                    'Request Your',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    'Favorite Songs Live',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            // Subtitle
            Positioned(
              top: size.height * 0.6,
              left: 24,
              right: 24,
              child: Text(
                'Skip the wait. Send song requests\ndirectly to DJs and make your\nnight unforgettable.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ),
            // Page indicators
            Positioned(
              top: size.height * 0.73,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 8,
                    decoration: BoxDecoration(
                      color: pink,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: pink.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: pink.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // Get Started button
            Positioned(
              left: 24,
              right: 24,
              bottom: 40,
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: onGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pink,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  child: const Text('Get Started'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EqualizerBars extends StatelessWidget {
  const _EqualizerBars();

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF1493);
    const purple = Color(0xFF9C59B5);

    const bars = [
      _EqBar(height: 120, topOffset: 50),
      _EqBar(height: 180, topOffset: 10),
      _EqBar(height: 240, topOffset: -30),
      _EqBar(height: 200, topOffset: -10),
      _EqBar(height: 140, topOffset: 40),
    ];

    return SizedBox(
      height: 260,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((bar) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Transform.translate(
              offset: Offset(0, bar.topOffset),
              child: Container(
                width: 28,
                height: bar.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [pink, purple],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EqBar {
  const _EqBar({required this.height, required this.topOffset});
  final double height;
  final double topOffset;
}
