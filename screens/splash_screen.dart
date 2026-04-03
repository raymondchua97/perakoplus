import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoMove;

  bool _showLoader = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _logoMove = Tween<double>(
      begin: 0.0,
      end: -240.0,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_controller);

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Stay in center
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Move logo up
    await _controller.forward();
    if (!mounted) return;

    // ✅ Show loading AFTER logo reaches final position
    setState(() {
      _showLoader = true;
    });

    // Simulate loading
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    // Go to login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // LOGO (unchanged behavior)
            AnimatedBuilder(
              animation: _logoMove,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0.0, _logoMove.value),
                  child: child,
                );
              },
              child: Image.asset(
                'assets/logonobackground.png',
                width: 200,
                fit: BoxFit.contain,
              ),
            ),

            // LOADING INDICATOR (always centered)
            if (_showLoader) const CircularProgressIndicator(strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}
