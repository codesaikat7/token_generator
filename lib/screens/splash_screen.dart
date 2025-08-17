import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _progressAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;
  bool _isFirstTime = true;

    @override
  void initState() {
    super.initState();
    
    // Check if it's first time
    _checkFirstTime();
    
    // Initialize logo animations
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Initialize progress animation
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Add a subtle pulse animation
    _logoAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _logoAnimationController.repeat(reverse: true);
      }
    });

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _logoAnimationController.forward();
    _progressAnimationController.forward();

    // Navigate to home screen after delay
    Timer(const Duration(seconds: 3), () async {
      // Mark app as not first time after first launch
      if (_isFirstTime) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isFirstTime', false);
      }
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  Future<void> _checkFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('isFirstTime') ?? true;
      
      if (mounted) {
        setState(() {
          _isFirstTime = isFirstTime;
        });
      }
    } catch (e) {
      // If there's an error, assume it's first time
      if (mounted) {
        setState(() {
          _isFirstTime = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with animations
            AnimatedBuilder(
              animation: _logoAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 200,
                      height: 200,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // App name with fade animation
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'QueueMed',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tagline with fade animation
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'Smart Clinic Queue Management',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 60),

                        // Loading indicator
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Progress bar
                  SizedBox(
                    width: 200,
                    child: AnimatedBuilder(
                      animation: _progressAnimationController,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.deepPurple),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Loading text
                  AnimatedBuilder(
                    animation: _progressAnimationController,
                    builder: (context, child) {
                      return Text(
                        'Loading... ${(_progressAnimation.value * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
