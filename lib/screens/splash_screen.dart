import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'setupScreen.dart';
import 'employee_screen.dart';

class SplashScreen extends StatefulWidget {
  static const String screenRoute = 'splash_screen';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _determineStartScreen();
  }

  Future<void> _determineStartScreen() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // المستخدم غير مسجل دخول
      _navigateTo(LoginScreen.screenRoute);
      return;
    }

    final email = user.email;
    if (email == null) {
      // البريد الإلكتروني غير متوفر، نذهب للإعداد
      _navigateTo(SetupScreen.screenRoute);
      return;
    }

    final userName = await _fetchUsernameByEmail(email);

    if (userName == null) {
      // لم يتم إيجاد اسم المستخدم في Firestore
      _navigateTo(SetupScreen.screenRoute);
      return;
    }

    // التأكد من أن المستخدم قام بالإعداد من قبل (setup_done = true)
    final setupDoneRef = FirebaseDatabase.instance.ref('$userName/setup_done');
    final setupDoneSnapshot = await setupDoneRef.get();

    if (setupDoneSnapshot.exists && setupDoneSnapshot.value == true) {
      // المستخدم أكمل الإعداد، نذهب إلى شاشة الموظفين
      _navigateTo(EmployeeScreen.screenRoute);
    } else {
      // المستخدم لم يكمل الإعداد
      _navigateTo(SetupScreen.screenRoute);
    }
  }

  Future<String?> _fetchUsernameByEmail(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('usersInfo')
          .where('userEmail', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.get('userName') as String;
      }
    } catch (e) {
      debugPrint('Error fetching username by email: $e');
    }
    return null;
  }

  void _navigateTo(String route) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
