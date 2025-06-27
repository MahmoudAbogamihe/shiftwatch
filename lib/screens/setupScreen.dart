import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../user_panel/user_panel_screen.dart';
import 'choose_location_screen.dart';

class SetupScreen extends StatefulWidget {
  static String screenRoute = 'setup_screen'; // snake_case

  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? userName;
  String? userEmail;
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  void fetchUserInfo() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        setState(() {
          errorMessage = "No authenticated user found.";
          isLoading = false;
        });
        return;
      }

      final email = user.email;
      if (email == null) {
        setState(() {
          errorMessage = "User email not available.";
          isLoading = false;
        });
        return;
      }

      QuerySnapshot querySnapshot = await _firestore
          .collection('usersInfo')
          .where('userEmail', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final fetchedEmail = doc.data().toString().contains('userEmail')
            ? doc.get('userEmail')
            : null;
        final fetchedUserName = doc.data().toString().contains('userName')
            ? doc.get('userName')
            : null;

        if (mounted) {
          setState(() {
            if (fetchedEmail != null && fetchedEmail.isNotEmpty) {
              userEmail = fetchedEmail;
            }
            if (fetchedUserName != null && fetchedUserName.isNotEmpty) {
              userName = fetchedUserName;
            }
            errorMessage = null;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = "User info not found.";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Error fetching user data: $e";
          isLoading = false;
        });
      }
    }
  }

  void _showUserPanel(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _UserPanelDialog(
        userName: userName,
        userEmail: userEmail,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 243),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 211, 211, 243),
        actions: [
          if (userEmail != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => _showUserPanel(context),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade400,
                  child: Text(
                    userName?.isNotEmpty == true
                        ? userName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 130),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const CircularProgressIndicator()
                  else ...[
                    if (userName != null)
                      Text(
                        "Welcome, $userName!",
                        style: const TextStyle(
                          fontSize: 29,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    const SizedBox(height: 30),
                    Container(
                      height: MediaQuery.of(context).size.width * 0.5,
                      width: MediaQuery.of(context).size.width * 0.5,
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image: AssetImage(
                              'images/Screenshot 2025-03-06 231250.png'),
                          fit: BoxFit.cover,
                        ),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.grey.shade400, width: 3),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Let's Setup Your Environment.",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Get everything ready for your workspace',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 60, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.blue.shade400,
                      ),
                      onPressed: () => Navigator.pushNamed(
                          context, ChooseLocationScreen.screenRoute,
                          arguments: {'userName': userName}),
                      child: const Text(
                        'Start',
                        style: TextStyle(
                            fontSize: 23,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserPanelDialog extends StatelessWidget {
  final String? userName;
  final String? userEmail;

  const _UserPanelDialog({
    Key? key,
    this.userName,
    this.userEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.3),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            Container(color: Colors.transparent),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {}, // prevent dialog close when tapping inside panel
                child: UserPanelScreen(
                  userName: userName,
                  userEmail: userEmail,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
