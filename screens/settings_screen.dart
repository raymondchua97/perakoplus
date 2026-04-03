import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool)? onThemeChanged;

  const SettingsScreen({super.key, this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  final user = FirebaseAuth.instance.currentUser;

  String _name = "User";
  String _email = "No Email";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _showLogoutDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// ICON
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout, color: Colors.red, size: 28),
                ),

                const SizedBox(height: 16),

                /// TITLE
                Text(
                  "Log Out",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),

                const SizedBox(height: 8),

                /// MESSAGE
                Text(
                  "Are you sure you want to log out?\n\nYour data will be removed.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),

                const SizedBox(height: 20),

                /// BUTTONS
                Row(
                  children: [
                    /// CANCEL
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// LOGOUT
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Log Out",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// LOAD SETTINGS
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final darkValue = prefs.get('darkMode');
    if (darkValue != null && darkValue is! bool) {
      await prefs.remove('darkMode');
    }

    final notifValue = prefs.get('notifications');
    if (notifValue != null && notifValue is! bool) {
      await prefs.remove('notifications');
    }

    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _darkMode = prefs.getBool('darkMode') ?? false;

      /// 🔥 GUEST CHECK
      final isGuest = prefs.getBool('isGuest') ?? false;

      if (isGuest) {
        _name = "Guest";
        _email = "guest@perako.app";
      } else {
        final user = FirebaseAuth.instance.currentUser;
        _name = user?.displayName ?? "User";
        _email = user?.email ?? "No Email";
      }
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// LOGOUT
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// GET INITIAL FOR AVATAR
  String _getInitial() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? "U";

    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return "U";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              /// TITLE
              Row(
                children: const [
                  Icon(Icons.settings, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// PROFILE (UPDATED)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardStyle(context),
                child: Row(
                  children: [
                    /// AVATAR
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.blue,
                      child: Text(
                        _getInitial(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    /// NAME + EMAIL
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _sectionTitle(context, 'Settings'),

              /// 🔔 NOTIFICATIONS (WITH FEEDBACK)
              _switchTile(
                context,
                title: 'Notifications',
                value: _notificationsEnabled,
                onChanged: (v) {
                  setState(() => _notificationsEnabled = v);
                  _saveBool('notifications', v);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        v
                            ? "Notifications Enabled 🔔"
                            : "Notifications Disabled 🔕",
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),

              /// 🌙 DARK MODE
              _switchTile(
                context,
                title: 'Dark Mode',
                value: _darkMode,
                onChanged: (v) async {
                  final prefs = await SharedPreferences.getInstance();

                  await prefs.setBool('darkMode', v);

                  setState(() {
                    _darkMode = v;
                  });

                  widget.onThemeChanged?.call(v);
                },
              ),

              const SizedBox(height: 30),

              /// 🔴 LOG OUT
              GestureDetector(
                onTap: () => _showLogoutDialog(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: _cardStyle(context),
                  alignment: Alignment.center,
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
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

  // ================= UI =================
  BoxDecoration _cardStyle(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _switchTile(
    BuildContext context, {
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardStyle(context),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
