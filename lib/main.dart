import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_notification.dart';

import 'screens/choose_location_to_edit_screen.dart';
import 'screens/location_to_edit_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/setupScreen.dart';
import 'screens/choose_location_screen.dart';
import 'screens/location_screen.dart';
import 'screens/employee_setup_screen.dart';
import 'screens/num_of_location.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/employee_screen.dart';
import 'screens/notification_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final List<String> stored = prefs.getStringList('notifications') ?? [];

  final notification = message.notification;
  final body = notification?.body ?? message.data['message'] ?? 'No message';
  final timestamp = DateTime.now();

  final newNote = AppNotification(
    message: body,
    timestamp: timestamp,
  );

  stored.insert(0, json.encode(newNote.toJson()));
  await prefs.setStringList('notifications', stored);

  debugPrint('📩 Background message saved: ${newNote.message}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<AppNotification> _allNotes = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _requestPermissionAndSetupListeners();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('notifications');
    if (stored != null) {
      setState(() {
        _allNotes.addAll(
          stored.map((e) => AppNotification.fromJson(json.decode(e))),
        );
      });
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encoded =
        _allNotes.map((n) => json.encode(n.toJson())).toList();
    await prefs.setStringList('notifications', encoded);
  }

  Future<void> _requestPermissionAndSetupListeners() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    if (Platform.isAndroid && await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 FCM permission status: ${settings.authorizationStatus}');

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel_id',
              'Default',
              channelDescription: 'General notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );

        final newNote = AppNotification(
          message: notification.body ?? 'No message',
          timestamp: DateTime.now(),
        );

        setState(() {
          _allNotes.insert(0, newNote);
        });

        await _saveNotifications();

        debugPrint('📩 Foreground message saved: ${newNote.message}');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleRouteFromMessage);

    final initialMsg = await messaging.getInitialMessage();
    if (initialMsg != null) _handleRouteFromMessage(initialMsg);

    final token = await messaging.getToken();
    debugPrint('🔑 FCM token: $token');

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('🔑 Refreshed FCM token: $newToken');
    });
  }

  void _handleRouteFromMessage(RemoteMessage message) {
    final route = message.data['route'];
    if (route != null && mounted) {
      Navigator.of(context).pushNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShiftWatchApp',
      debugShowCheckedModeBanner: false,
      initialRoute: SplashScreen.screenRoute,
      routes: {
        SplashScreen.screenRoute: (_) => const SplashScreen(),
        LoginScreen.screenRoute: (_) => LoginScreen(),
        SignUpScreen.screenRoute: (_) => SignUpScreen(),
        SetupScreen.screenRoute: (_) => SetupScreen(),
        ChooseLocationScreen.screenRoute: (_) => ChooseLocationScreen(),
        LocationScreen.screenRoute: (_) => LocationScreen(),
        EmployeeSetupScreen.screenRoute: (_) => EmployeeSetupScreen(),
        NumOfLocation.screenRoute: (_) => NumOfLocation(),
        ProfileScreen.screenRoute: (_) => ProfileScreen(),
        EditProfileScreen.screenRoute: (_) => EditProfileScreen(),
        DashboardScreen.screenRoute: (_) => DashboardScreen(),
        EmployeeScreen.screenRoute: (_) => EmployeeScreen(allNotes: _allNotes),
        NotificationScreen.screenRoute: (_) => const NotificationScreen(),
        ChooseLocationToEditScreen.screenRoute: (_) =>
            ChooseLocationToEditScreen(),
        LocationToEditScreen.screenRoute: (_) => LocationToEditScreen(),
      },
    );
  }
}
