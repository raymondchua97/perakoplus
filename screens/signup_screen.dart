import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ ADDED
import 'verify_email_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // 🔐 SIGN UP + EMAIL VERIFICATION
  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Please fill in all fields');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('Please enter a valid email address');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match');
      return;
    }

    if (password.length < 8) {
      _showMessage('Password must be at least 8 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Create Firebase user
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user!.updateDisplayName(name);

      // OPTIONAL but recommended
      await userCredential.user!.reload();
      // ✅ ADDED: SAVE NAME & EMAIL LOCALLY
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', name);
      await prefs.setString('userEmail', email);

      // 2️⃣ Send verification email
      await userCredential.user?.sendEmailVerification();

      // 3️⃣ Navigate to verification screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Signup failed');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              Center(
                child: Image.asset('assets/logonobackground.png', width: 200),
              ),

              const SizedBox(height: 20),

              const Text(
                'Sign Up',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Create your account',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B)),
              ),

              const SizedBox(height: 24),

              _inputField(
                controller: _nameController,
                hint: 'Full Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),

              _inputField(
                controller: _emailController,
                hint: 'Email',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 14),

              _passwordField(
                controller: _passwordController,
                hint: 'Password (min. 8 characters)',
                hidden: _hidePassword,
                onToggle: () => setState(() => _hidePassword = !_hidePassword),
              ),
              const SizedBox(height: 14),

              _passwordField(
                controller: _confirmPasswordController,
                hint: 'Confirm Password',
                hidden: _hideConfirmPassword,
                onToggle: () => setState(
                  () => _hideConfirmPassword = !_hideConfirmPassword,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              const Center(child: Text('Or sign up with')),

              const SizedBox(height: 12),

              _socialButton(
                label: 'Continue with Google',
                icon: Image.asset(
                  'assets/google.png',
                  width: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata),
                ),
                onTap: () => _showMessage('Google sign-in coming soon'),
              ),

              const SizedBox(height: 10),

              _socialButton(
                label: 'Continue with Facebook',
                icon: const Icon(Icons.facebook, color: Colors.white),
                background: const Color(0xFF1877F2),
                textColor: Colors.white,
                onTap: () => _showMessage('Facebook sign-in coming soon'),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI HELPERS ----------

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool hidden,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: hidden,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(hidden ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _socialButton({
    required String label,
    required Widget icon,
    Color background = Colors.white,
    Color textColor = Colors.black,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: icon,
        label: Text(label, style: TextStyle(color: textColor)),
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
