import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Timer(const Duration(seconds: 3), widget.onFinished);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF1493);
    const bg = Color(0xFF0D0D0D);

    return Scaffold(
      backgroundColor: bg,
      body: FadeTransition(
        opacity: _fadeIn,
        child: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pink glow behind icon
              Positioned(
                top: MediaQuery.of(context).size.height * 0.32,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        pink.withValues(alpha: 0.3),
                        pink.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Headphone icon
              Positioned(
                top: MediaQuery.of(context).size.height * 0.35,
                child: const Icon(
                  Icons.headphones_rounded,
                  size: 80,
                  color: pink,
                ),
              ),
              // Sound bars left
              Positioned(
                left: 30,
                top: MediaQuery.of(context).size.height * 0.4,
                child: const _SoundBars(alignment: _BarAlignment.left),
              ),
              // Sound bars right
              Positioned(
                right: 30,
                top: MediaQuery.of(context).size.height * 0.4,
                child: const _SoundBars(alignment: _BarAlignment.right),
              ),
              // CLUBBER title
              Positioned(
                top: MediaQuery.of(context).size.height * 0.5,
                child: const Text(
                  'CLUBBER',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                    color: pink,
                    letterSpacing: 8,
                  ),
                ),
              ),
              // Subtitle
              Positioned(
                top: MediaQuery.of(context).size.height * 0.57,
                child: Text(
                  'REQUEST THE BEAT',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    letterSpacing: 4,
                  ),
                ),
              ),
              // Page dots
              Positioned(
                bottom: 80,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 0
                            ? pink
                            : pink.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _BarAlignment { left, right }

class _SoundBars extends StatelessWidget {
  const _SoundBars({required this.alignment});

  final _BarAlignment alignment;

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF1493);
    const bars = [
      _BarSpec(60, 0.4),
      _BarSpec(100, 0.6),
      _BarSpec(80, 0.5),
    ];
    final ordered =
        alignment == _BarAlignment.left ? bars : bars.reversed.toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: ordered.map((spec) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          width: 3,
          height: spec.height,
          decoration: BoxDecoration(
            color: pink.withValues(alpha: spec.opacity),
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      }).toList(),
    );
  }
}

class _BarSpec {
  const _BarSpec(this.height, this.opacity);
  final double height;
  final double opacity;
}
