import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Screens
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

// Background message handler for FCM
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 Background message: ${message.messageId}');
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
  final List<String> _allNotes = [];

  @override
  void initState() {
    super.initState();
    _requestPermissionAndSetupListeners();
  }

  void _requestPermissionAndSetupListeners() async {
    // نفس كودك القديم
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShiftWatchApp',
      debugShowCheckedModeBanner: false,
      initialRoute:
          SplashScreen.screenRoute, // خلي البداية دايمًا على SplashScreen
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
        NotificationScreen.screenRoute: (_) => NotificationScreen(),
        ChooseLocationToEditScreen.screenRoute: (_) =>
            ChooseLocationToEditScreen(),
        LocationToEditScreen.screenRoute: (_) => LocationToEditScreen(),
      },
    );
  }
}

// // main.dart
// import 'dart:io' show Platform;

// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';

// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

// // Screens
// import 'screens/choose_location_to_edit_screen.dart';
// import 'screens/location_to_edit_screen.dart';
// import 'screens/splash_screen.dart';
// import 'screens/login_screen.dart';
// import 'screens/sign_up_screen.dart';
// import 'screens/setupScreen.dart';
// import 'screens/choose_location_screen.dart';
// import 'screens/location_screen.dart';
// import 'screens/employee_setup_screen.dart';
// import 'screens/num_of_location.dart';
// import 'screens/profile_screen.dart';
// import 'screens/edit_profile_screen.dart';
// import 'screens/dashboard_screen.dart';
// import 'screens/employee_screen.dart';
// import 'screens/notification_screen.dart';

// /* ────────────────────────────────────────────────────────────
//    🔔  Background handler for FCM
//    ──────────────────────────────────────────────────────────── */
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // Keep it minimal — only the stuff you need in background/terminated state
//   await Firebase.initializeApp();
//   debugPrint('📩 Background message: ${message.messageId}');
// }

// /* ────────────────────────────────────────────────────────────
//    🔔  One global instance for local notifications
//    ──────────────────────────────────────────────────────────── */

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();

//   // Register background handler before runApp
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//   runApp(const MyApp());
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   final List<String> _allNotes = [];

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissionAndSetupListeners();
//   }

//   /* ─────────────────────────────────────────────────────────
//      🔑  Permissions, listeners, token-handling
//      ───────────────────────────────────────────────────────── */
//   Future<void> _requestPermissionAndSetupListeners() async {
//     final FirebaseMessaging messaging = FirebaseMessaging.instance;

//     // Android 13+ runtime POST_NOTIFICATIONS permission
//     if (Platform.isAndroid && (await Permission.notification.status).isDenied) {
//       await Permission.notification.request();
//     }

//     // iOS & older Android prompt
//     final settings = await messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//     if (settings.authorizationStatus == AuthorizationStatus.denied) {
//       debugPrint('🚫 Notification permission denied');
//     }

//     // Foreground message listener

//     // Background-open & terminated-open listener
//     FirebaseMessaging.onMessageOpenedApp.listen(_handleRouteFromMessage);
//     final initialMsg = await messaging.getInitialMessage();
//     if (initialMsg != null) _handleRouteFromMessage(initialMsg);

//     // FCM token handling
//     final token = await messaging.getToken();
//     debugPrint('🔑 FCM token: $token');
//     // TODO: upload to backend so you can target this device.

//     FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
//       debugPrint('🔑 Refreshed FCM token: $newToken');
//       // TODO: update backend with newToken
//     });
//   }

//   /* ─────────────────────────────────────────────────────────
//      🎯  Foreground notification banner
//      ───────────────────────────────────────────────────────── */

//   /* ─────────────────────────────────────────────────────────
//      🚀  Navigate on notification-tap
//      ───────────────────────────────────────────────────────── */
//   void _handleRouteFromMessage(RemoteMessage msg) {
//     final route = msg.data['route'] as String?;
//     if (route != null && mounted) {
//       Navigator.of(context).pushNamed(route, arguments: msg.data);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'ShiftWatchApp',
//       debugShowCheckedModeBanner: false,
//       initialRoute:
//           SplashScreen.screenRoute, // Always start with SplashScreen on launch
//       routes: {
//         SplashScreen.screenRoute: (_) => const SplashScreen(),
//         LoginScreen.screenRoute: (_) => LoginScreen(),
//         SignUpScreen.screenRoute: (_) => SignUpScreen(),
//         SetupScreen.screenRoute: (_) => SetupScreen(),
//         ChooseLocationScreen.screenRoute: (_) => ChooseLocationScreen(),
//         LocationScreen.screenRoute: (_) => LocationScreen(),
//         EmployeeSetupScreen.screenRoute: (_) => EmployeeSetupScreen(),
//         NumOfLocation.screenRoute: (_) => NumOfLocation(),
//         ProfileScreen.screenRoute: (_) => ProfileScreen(),
//         EditProfileScreen.screenRoute: (_) => EditProfileScreen(),
//         DashboardScreen.screenRoute: (_) => DashboardScreen(),
//         EmployeeScreen.screenRoute: (_) => EmployeeScreen(allNotes: _allNotes),
//         NotificationScreen.screenRoute: (_) => NotificationScreen(),
//         ChooseLocationToEditScreen.screenRoute: (_) =>
//             ChooseLocationToEditScreen(),
//         LocationToEditScreen.screenRoute: (_) => LocationToEditScreen(),
//       },
//     );
//   }
// }
