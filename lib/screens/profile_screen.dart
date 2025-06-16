import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../user_panel/user_panel_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const String screenRoute = 'profile_screen';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String username;
  late String empName;
  Map<String, dynamic>? empData;
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    username = args['username'] as String;
    empName = args['empName'] as String;

    fetchEmployeeData();
  }

  void fetchEmployeeData() async {
    setState(() {
      isLoading = true;
    });

    final dbRef = FirebaseDatabase.instance.ref('$username/employees/$empName');
    final snapshot = await dbRef.get();

    if (snapshot.exists) {
      setState(() {
        empData = Map<String, dynamic>.from(snapshot.value as Map);
        isLoading = false;
      });
    } else {
      setState(() {
        empData = null;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Employee data not found.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                EditProfileScreen.screenRoute,
                arguments: {
                  'username': username,
                  'empName': empName,
                  'info': empData?['info'] ?? {},
                },
              ).then((result) {
                if (result == true) {
                  fetchEmployeeData(); // Refresh data after editing
                }
              });
            },
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade400,
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      UserPanelScreen(
                    userName: username,
                    userEmail: FirebaseAuth.instance.currentUser?.email,
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;

                    final tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    final offsetAnimation = animation.drive(tween);

                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : empData == null
              ? const Center(child: Text("No data found for this employee."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildProfileDetails(empData!),
                ),
    );
  }

  Widget _buildProfileDetails(Map<String, dynamic> data) {
    final infoRaw = data['info'];
    final info = (infoRaw as Map?)?.cast<String, dynamic>() ?? {};

    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: info['photo_url'] != null &&
                  info['photo_url'].toString().isNotEmpty
              ? NetworkImage(info['photo_url'])
              : null,
          child: (info['photo_url'] == null ||
                  info['photo_url'].toString().isEmpty)
              ? const Icon(Icons.person, size: 60)
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          empName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _buildInfoCard(
            Icons.phone, "Phone", info['phone']?.toString() ?? "N/A"),
        _buildInfoCard(
            Icons.home, "Address", info['address']?.toString() ?? "N/A"),
        _buildInfoCard(Icons.monetization_on, "Salary",
            info['salary']?.toString() ?? "N/A"),
        _buildInfoCard(Icons.access_time, "Working Hours",
            info['working_hours']?.toString() ?? "N/A"),
        _buildInfoCard(
            Icons.badge, "Position", info['position']?.toString() ?? "N/A"),
        _buildInfoCard(Icons.location_on, "In Location",
            info['In Location']?.toString() ?? "N/A"),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
}
