import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('darkMode') ?? false;

  runApp(PerakoApp(initialDark: isDark));
}

class PerakoApp extends StatefulWidget {
  final bool initialDark;

  const PerakoApp({super.key, required this.initialDark});

  @override
  State<PerakoApp> createState() => _PerakoAppState();
}

class _PerakoAppState extends State<PerakoApp> {
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.initialDark;
  }

  void _updateTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);

    setState(() {
      _isDark = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      /// 🔥 THIS IS THE REAL FIX
      builder: (context, child) {
        return KeyedSubtree(key: ValueKey(_isDark), child: child!);
      },

      theme: ThemeData.light(),

      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
      ),

      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,

      home: AuthGate(onThemeChanged: _updateTheme),
    );
  }
}
