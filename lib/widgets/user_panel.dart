import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPanelButton extends StatefulWidget {
  const UserPanelButton({super.key});

  @override
  _UserPanelButtonState createState() => _UserPanelButtonState();
}

class _UserPanelButtonState extends State<UserPanelButton> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userName;
  bool showUserPanel = false;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  void fetchUserInfo() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      QuerySnapshot querySnapshot = await _firestore
          .collection('usersInfo')
          .where('userEmail', isEqualTo: user.email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          userName = querySnapshot.docs.first.get('userName');
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  void toggleUserPanel() {
    setState(() {
      showUserPanel = !showUserPanel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Circle Button
        Positioned(
          right: 10,
          top: 10,
          child: GestureDetector(
            onTap: toggleUserPanel,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade400,
              child: Text(
                userName != null && userName!.isNotEmpty ? userName![0] : '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        // **Sliding User Info Panel**
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          right: showUserPanel ? 0 : -250,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () {}, // Prevent closing when clicking inside
            child: Container(
              width: 250,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue.shade400,
                    child: Text(
                      userName != null && userName!.isNotEmpty
                          ? userName![0]
                          : '?',
                      style: const TextStyle(fontSize: 30, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userName ?? "User Name",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: toggleUserPanel,
                    child: const Text("Close"),
                  ),
                ],
              ),
            ),
          ),
        ),

        // **Click outside to close**
        if (showUserPanel)
          GestureDetector(
            onTap: toggleUserPanel,
            child: Container(
              color: Colors.black.withOpacity(0.3), // Semi-transparent overlay
              width: double.infinity,
              height: double.infinity,
            ),
          ),
      ],
    );
  }
}
