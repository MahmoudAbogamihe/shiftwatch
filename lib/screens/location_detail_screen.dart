// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'add_employee_screen.dart';
// import 'num_of_location.dart';

// class LocationDetailScreen extends StatefulWidget {
//   static String screenRoute = 'location_detail_screen';

//   const LocationDetailScreen({super.key});

//   @override
//   State<LocationDetailScreen> createState() => _LocationDetailScreenState();
// }

// class _LocationDetailScreenState extends State<LocationDetailScreen> {
//   List<Map<String, dynamic>> employees = [];

//   @override
//   Widget build(BuildContext context) {
//     final args =
//         ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

//     final String locationNum = args['locationNum'] ?? '';
//     final String imagePath = args['imagePath'] ?? '';

//     final List<Map<String, dynamic>> allEmployeesData =
//         List<Map<String, dynamic>>.from(args['allEmployeesData'] ?? []);

//     employees = allEmployeesData;

//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 211, 211, 243),
//       appBar: AppBar(
//         backgroundColor: const Color.fromARGB(255, 211, 211, 243),
//         title: Text(locationNum),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.pushNamed(
//             context,
//             NumOfLocation.screenRoute,
//             arguments: {
//               'locationNum': locationNum,
//               'imagePath': imagePath,
//             },
//           );
//         },
//         backgroundColor: Colors.blueAccent,
//         child: const Icon(Icons.person_add),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             ClipOval(
//               child: Image.asset(
//                 imagePath,
//                 width: 100,
//                 height: 100,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) {
//                   return Container(
//                     width: 100,
//                     height: 100,
//                     color: Colors.grey,
//                     alignment: Alignment.center,
//                     child:
//                         const Icon(Icons.person, size: 50, color: Colors.white),
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(height: 10),
//             const Text("Employees at this location:",
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 10),
//             Expanded(
//               child: employees.isEmpty
//                   ? const Center(child: Text("No employees yet"))
//                   : ListView.builder(
//                       itemCount: employees.length,
//                       itemBuilder: (context, index) {
//                         final emp = employees[index];
//                         return Card(
//                           margin: const EdgeInsets.symmetric(vertical: 6),
//                           child: ListTile(
//                             leading: CircleAvatar(
//                               backgroundImage: emp['photo'] != null
//                                   ? FileImage(File(emp['photo']))
//                                   : const AssetImage('assets/default.png')
//                                       as ImageProvider,
//                             ),
//                             title: Text(emp['name']),
//                             subtitle: Text("Salary: ${emp['salary']}"),
//                             trailing: PopupMenuButton<String>(
//                               onSelected: (value) {
//                                 if (value == 'edit') {
//                                   Navigator.pushNamed(
//                                     context,
//                                     AddEmployeeScreen.screenRoute,
//                                     arguments: emp,
//                                   );
//                                 } else if (value == 'delete') {
//                                   setState(() {
//                                     employees.removeAt(index);
//                                   });
//                                 }
//                               },
//                               itemBuilder: (context) => [
//                                 const PopupMenuItem(
//                                   value: 'edit',
//                                   child: Text('Edit'),
//                                 ),
//                                 const PopupMenuItem(
//                                   value: 'delete',
//                                   child: Text('Delete'),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
