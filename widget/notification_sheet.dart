import 'package:flutter/material.dart';
import '../manager/notification_manager.dart';

class NotificationSheet {
  static Future<void> show(BuildContext context) async {
    final notifications = await NotificationManager.getNotifications();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,

          child: notifications.isEmpty
              ? const Center(child: Text("No notifications yet"))
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];

                    return ListTile(
                      leading: const Icon(Icons.notifications),
                      title: Text(n['title']),
                      subtitle: Text(n['body']),
                    );
                  },
                ),
        );
      },
    );
  }
}
