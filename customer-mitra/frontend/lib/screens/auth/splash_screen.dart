import 'package:flutter/material.dart';
import 'dart:async';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Start animation
    _controller.forward();

    // Navigate to onboarding
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const OnboardingScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E40AF),
              const Color(0xFF3B82F6),
              const Color(0xFF60A5FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Modern text design with shadow
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.95),
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'Nebeng',
                                style: TextStyle(
                                  fontSize: 72,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -2,
                                  height: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Perjalanan Lebih Mudah',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Animated dots indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              final delay = index * 0.15;
                              final animValue =
                                  (_controller.value - delay).clamp(0.0, 1.0);
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withOpacity(animValue * 0.7),
                                  shape: BoxShape.circle,
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
