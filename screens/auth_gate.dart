import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'verify_email_screen.dart';
import 'welcome_screen.dart';
import 'main_tabs_screen.dart';

class AuthGate extends StatelessWidget {
  final Function(bool)? onThemeChanged;

  const AuthGate({super.key, this.onThemeChanged});

  Future<bool> _hasStartingBalance() async {
    final prefs = await SharedPreferences.getInstance();

    /// 🔥 FIX: ensure proper default on first install
    if (!prefs.containsKey('hasStartingBalance')) {
      await prefs.setBool('hasStartingBalance', false);
    }

    return prefs.getBool('hasStartingBalance') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        /// 🔄 LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        /// ❌ NOT LOGGED IN
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final user = snapshot.data!;

        /// ❌ NOT VERIFIED
        if (!user.emailVerified) {
          return const VerifyEmailScreen();
        }

        /// ✅ CHECK STARTING BALANCE
        return FutureBuilder<bool>(
          future: _hasStartingBalance(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final hasBalance = snapshot.data ?? false;

            /// 🆕 FIRST TIME USER
            if (!hasBalance) {
              return const WelcomeScreen();
            }

            /// 🏠 MAIN APP
            return MainTabsScreen(onThemeChanged: onThemeChanged);
          },
        );
      },
    );
  }
}
