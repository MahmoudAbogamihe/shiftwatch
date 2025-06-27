import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'employee_screen.dart';
import 'setupScreen.dart';
import 'sign_up_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class LoginScreen extends StatefulWidget {
  static const String screenRoute = 'login_screen';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool showSpinner = false;
  bool _obscurePassword = true;
  String? userName;
  String? errorMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> checkIfSetupExists(String userName) async {
    final dbRef = FirebaseDatabase.instance.ref();
    final snapshot = await dbRef.child(userName).child('employees').get();

    if (snapshot.exists && snapshot.value != null) {
      print("✅ Found employees data: ${snapshot.value}");
      return true;
    } else {
      print("❌ No employees data found for $userName");
      return false;
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter both email and password.');
      return;
    }

    setState(() => showSpinner = true);

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      final querySnapshot = await _firestore
          .collection('usersInfo')
          .where('userEmail', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        userName = doc.get('userName');
        print('✅ Username fetched: $userName');
      } else {
        _showMessage('User info not found in Firestore.');
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();

      if (token != null && userName != null) {
        final dbRef = FirebaseDatabase.instance.ref();
        final userRef = dbRef.child(userName!);

        final snapshot = await userRef.get();

        if (snapshot.exists) {
          await userRef.update({'token': token});
          print("🔁 Token updated for $userName");
        } else {
          await userRef.set({'token': token});
          print("✅ Created username node with token for $userName");
        }
      }

      // التحقق من وجود الإعداد من قاعدة البيانات
      final isSetupComplete = await checkIfSetupExists(userName!);

      // حفظه في SharedPreferences (اختياري)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSetupComplete', isSetupComplete);

      if (isSetupComplete) {
        Navigator.pushReplacementNamed(context, EmployeeScreen.screenRoute);
      } else {
        Navigator.pushReplacementNamed(context, SetupScreen.screenRoute);
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No account found. Please sign up.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password. Try again.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      } else {
        message = 'Authentication error: ${e.message}';
      }
      setState(() {
        errorMessage = message;
        showSpinner = false;
      });
      _passwordController.clear();
    } catch (e) {
      setState(() {
        errorMessage = 'An unexpected error occurred. Please try again.';
        showSpinner = false;
      });
      print('❌ Error: $e');
    } finally {
      setState(() => showSpinner = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'images/59271.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 5, color: Colors.black54)
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _login,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 40),
                            child: Text(
                              'Login',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(color: Colors.white),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                    context, SignUpScreen.screenRoute);
                              },
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 20),
                          Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ]
                      ],
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
}
