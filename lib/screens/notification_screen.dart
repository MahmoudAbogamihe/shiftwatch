import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';

class NotificationScreen extends StatefulWidget {
  static const screenRoute = 'notification_screen';

  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupFCM();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('notifications');
    if (stored != null) {
      setState(() {
        _notifications.addAll(
          stored.map((e) => AppNotification.fromJson(json.decode(e))),
        );
      });
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encoded =
        _notifications.map((n) => json.encode(n.toJson())).toList();
    await prefs.setStringList('notifications', encoded);
  }

  void _setupFCM() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    debugPrint('🔔 FCM Permission: ${settings.authorizationStatus}');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }

  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final body = message.notification?.body ?? data['message'] ?? 'No message';
    final timestampString = data['timestamp'];

    DateTime timestamp;
    try {
      timestamp = timestampString != null
          ? DateTime.parse(timestampString)
          : DateTime.now();
    } catch (_) {
      timestamp = DateTime.now();
    }

    setState(() {
      bool exists = _notifications
          .any((note) => note.message == body && note.timestamp == timestamp);
      if (!exists) {
        _notifications.insert(
          0,
          AppNotification(
            message: body,
            timestamp: timestamp,
          ),
        );
        _saveNotifications();
      }
    });
  }

  void _removeNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
    _saveNotifications();
  }

  String _formatDate(DateTime dt) {
    return DateFormat('yyyy-MM-dd hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 4,
        leading: const Icon(Icons.notifications, color: Colors.white),
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.notifications_off_outlined,
                      size: 90, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final note = _notifications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active,
                          color: Colors.deepPurple),
                    ),
                    title: Text(
                      note.message,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _formatDate(note.timestamp),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.redAccent),
                      onPressed: () => _removeNotification(index),
                      tooltip: 'Delete notification',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
