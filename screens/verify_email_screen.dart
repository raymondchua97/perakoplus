import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _checking = false;

  Future<void> _checkVerification() async {
    setState(() => _checking = true);

    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();

    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (refreshedUser != null && refreshedUser.emailVerified) {
      // ✅ EMAIL VERIFIED → GO TO WELCOME
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
      return;
    }

    // ❌ Not verified yet
    setState(() => _checking = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email not verified yet. Please check your inbox.'),
      ),
    );
  }

  Future<void> _resendEmail() async {
    await FirebaseAuth.instance.currentUser?.sendEmailVerification();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Verification email resent')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 80,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verify your email',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'We sent a verification link to your email.\nPlease verify to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _checking ? null : _checkVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _checking
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'I have verified',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _resendEmail,
                child: const Text(
                  'Resend email',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2563EB),
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
