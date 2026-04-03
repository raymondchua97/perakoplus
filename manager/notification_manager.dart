import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationManager {
  static Future<void> clearUnread() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasUnreadNotifications', false);
  }

  static Future<void> addNotification(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> stored = prefs.getStringList('notifications') ?? [];

    final notification = {
      "title": title,
      "body": body,
      "date": DateTime.now().toIso8601String(),
    };

    stored.insert(0, jsonEncode(notification));

    await prefs.setStringList('notifications', stored);

    /// 🔴 mark unread
    await prefs.setBool('hasUnreadNotifications', true);
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    final stored = prefs.getStringList('notifications') ?? [];

    return stored.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }
}
