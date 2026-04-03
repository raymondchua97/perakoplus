import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';

class MainTabsScreen extends StatefulWidget {
  final Function(bool)? onThemeChanged;

  const MainTabsScreen({super.key, required this.onThemeChanged});

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  static int _savedIndex = 0;
  int _index = _savedIndex;

  @override
  Widget build(BuildContext context) {
    /// 🔥 FIX: DO NOT STORE SCREENS IN initState
    final screens = [
      const HomeScreen(),
      const HistoryScreen(),
      const InsightsScreen(),
      SettingsScreen(onThemeChanged: widget.onThemeChanged),
    ];

    return Scaffold(
      extendBody: true,

      /// ✅ KEEP SCREENS ALIVE
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: screens),
      ),

      /// ✅ NAV BAR (UNCHANGED)
      bottomNavigationBar: RepaintBoundary(
        child: CurvedNavigationBar(
          index: _index,
          height: 64,
          backgroundColor: Colors.transparent,
          color: const Color(0xFF2563EB),
          buttonBackgroundColor: const Color(0xFF2563EB),
          animationDuration: const Duration(milliseconds: 300),
          animationCurve: Curves.easeOutCubic,
          items: const [
            Icon(Icons.home, size: 26, color: Colors.white),
            Icon(Icons.history, size: 26, color: Colors.white),
            Icon(Icons.bar_chart, size: 26, color: Colors.white),
            Icon(Icons.settings, size: 26, color: Colors.white),
          ],
          onTap: (index) {
            setState(() {
              _index = index;
              _savedIndex = index;
            });
          },
        ),
      ),
    );
  }
}
