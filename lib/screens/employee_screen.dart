import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

import '../models/app_notification.dart';
import '../user_panel/user_panel_screen.dart';
import 'choose_location_screen.dart';
import 'dashboard_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class EmployeeScreen extends StatefulWidget {
  static const String screenRoute = 'employee_screen';
  final List<AppNotification> allNotes;
  const EmployeeScreen({super.key, required this.allNotes});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late DatabaseReference _employeesRef;
  Map<String, dynamic> _employees = {};
  String? _username;
  bool _isLoading = true;

  static const String azureBaseUrl =
      'https://gp1storage2.blob.core.windows.net';
  static const String sasToken =
      'sv=2024-11-04&ss=bfqt&srt=co&sp=rwdlacupiytfx&se=2025-09-24T05:14:52Z&st=2025-05-15T21:14:52Z&spr=https&sig=MlWw3VH44GSpIHQ45Bw5htIOuaJEaJSw%2Fc%2FgQF9bVJA%3D';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final email = user.email!;
      final username = await _fetchUsernameByEmail(email);
      if (username != null) {
        setState(() {
          _username = username;
          _employeesRef = FirebaseDatabase.instance.ref('$username/employees');
        });
        _listenEmployees();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Username not found')),
        );
      }
    }
  }

  Future<String?> _fetchUsernameByEmail(String email) async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('usersInfo')
          .where('userEmail', isEqualTo: email)
          .get();

      if (qs.docs.isNotEmpty) {
        final name = qs.docs.first.get('userName') as String;
        debugPrint('✅ Username fetched: $name');
        return name;
      }
    } catch (e) {
      debugPrint('❌ Error fetching username: $e');
    }
    return null;
  }

  void _listenEmployees() {
    _employeesRef.onValue.listen((event) {
      if (!mounted) return;
      setState(() {
        _isLoading = false; // ✅
        if (event.snapshot.exists) {
          _employees = Map<String, dynamic>.from(
              event.snapshot.value as Map<dynamic, dynamic>);
        } else {
          _employees = {};
        }
      });
    });
  }

  String _formatTime(List<dynamic>? t) =>
      (t == null || t.length < 3) ? '0h 0m 0s' : '${t[0]}h ${t[1]}m ${t[2]}s';

  void _onMenuSelected(String choice, String empName) {
    switch (choice) {
      case 'Delete':
        _confirmDelete(empName);
        break;
      case 'Dashboard':
        Navigator.pushNamed(
          context,
          DashboardScreen.screenRoute,
          arguments: {
            'empName': empName,
            'username': _username,
          },
        );
        break;
      case 'Profile':
        Navigator.pushNamed(
          context,
          ProfileScreen.screenRoute,
          arguments: {
            'empName': empName,
            'username': _username,
          },
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$choice clicked for $empName')),
        );
    }
  }

  void _confirmDelete(String empName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete $empName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteEmployee(empName);
            },
            child: const Text('OK', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEmployee(String empName) async {
    try {
      // حذف الموظف من قاعدة البيانات
      await _employeesRef.child(empName).remove();

      // تحديث قيمة last_updated بصيغة ISO 8601
      await FirebaseDatabase.instance
          .ref(_username)
          .child('last_updated')
          .set(DateTime.now().toIso8601String());

      // حذف صورة الموظف من Azure
      final encodedEmpName = Uri.encodeComponent(empName);
      final deleteUrl =
          '$azureBaseUrl/$_username-images/$encodedEmpName.jpg?$sasToken';

      final res = await http.delete(Uri.parse(deleteUrl));
      final ok = res.statusCode == 200 ||
          res.statusCode == 202 ||
          res.statusCode == 204;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? '$empName deleted successfully'
              : 'Deleted DB entry but image delete failed (${res.statusCode})'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting $empName: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayKey =
        '${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        titleSpacing: 0,
        title: Row(
          children: [
            SizedBox(
              width: 20,
            ),
            const Icon(Icons.home, color: Colors.black87, size: 32),
            const SizedBox(width: 12),
            const Text('Home',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    color: Colors.black87)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.restart_alt,
                  size: 28, color: Colors.black87),
              onPressed: () async {
                if (_username == null) return;

                final startRef =
                    FirebaseDatabase.instance.ref('$_username/start');
                final snapshot = await startRef.get();

                int current = 0;
                if (snapshot.exists && snapshot.value != null) {
                  current = int.tryParse(snapshot.value.toString()) ?? 0;
                }

                await startRef.set(current + 1);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Restart +1 تم بنجاح')),
                );
              },
              tooltip: 'Restart',
            ),
            IconButton(
              icon: const Icon(Icons.notifications,
                  size: 28, color: Colors.black87),
              onPressed: () =>
                  Navigator.pushNamed(context, NotificationScreen.screenRoute),
              tooltip: 'Show all notes',
            ),
            IconButton(
              icon: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade400,
                child: Text(
                  _username != null && _username!.isNotEmpty
                      ? _username![0].toUpperCase()
                      : '?',
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
                      userName: _username,
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
            SizedBox(
              width: 10,
            ),
          ],
        ),
      ),
      body: _username == null || _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
              ? Center(
                  child: Text(
                    'There are no employees…',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Stack(
                  children: [
                    _employees.isEmpty
                        ? Center(
                            child: Text(
                              'There are no employees…',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: ListView.builder(
                              itemCount: _employees.length,
                              itemBuilder: (context, idx) {
                                final empName = _employees.keys.elementAt(idx);
                                final empMap = Map<String, dynamic>.from(
                                    _employees[empName]);
                                final info = Map<String, dynamic>.from(
                                    empMap['info'] ?? {});
                                final todayData = (empMap['month'] ??
                                    {})[todayKey] as Map<dynamic, dynamic>?;

                                final imageUrl =
                                    '$azureBaseUrl/$_username-images/$empName.jpg';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 16),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    elevation: 5,
                                    shadowColor: Colors.black.withOpacity(0.15),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                                child: Image.network(
                                                  imageUrl,
                                                  width: 76,
                                                  height: 76,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                    width: 76,
                                                    height: 76,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[300],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50),
                                                    ),
                                                    child: const Icon(
                                                        Icons.person,
                                                        size: 40,
                                                        color: Colors.grey),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 20),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      empName,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 20,
                                                          color:
                                                              Colors.black87),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      info['position'] ?? '',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color:
                                                              Colors.grey[700]),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      info['In Location'] ?? '',
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.blueGrey),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuButton<String>(
                                                icon: const Icon(
                                                    Icons.more_vert,
                                                    color: Colors.grey),
                                                onSelected: (c) =>
                                                    _onMenuSelected(c, empName),
                                                itemBuilder: (_) => [
                                                  PopupMenuItem(
                                                    value: 'Dashboard',
                                                    child: ListTile(
                                                      leading: Icon(
                                                        Icons.dashboard,
                                                        color: Colors.blue[700],
                                                      ),
                                                      title: const Text(
                                                          'Dashboard'),
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'Profile',
                                                    child: ListTile(
                                                      leading: Icon(
                                                        Icons.person,
                                                        color:
                                                            Colors.green[700],
                                                      ),
                                                      title:
                                                          const Text('Profile'),
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'Delete',
                                                    child: ListTile(
                                                      leading: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red),
                                                      title: const Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _formatTime(
                                                      todayData?['total_time']),
                                                  style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87),
                                                ),
                                                const Text('Hours Worked',
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FloatingActionButton(
                          backgroundColor: Colors.blue[700],
                          onPressed: () {
                            Navigator.pushNamed(
                                context, ChooseLocationScreen.screenRoute,
                                arguments: {'userName': _username});
                          },
                          child: const Icon(Icons.add, size: 30),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
