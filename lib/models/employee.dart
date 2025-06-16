// import 'package:intl/intl.dart'; // مهم لاستخدام التاريخ
// import 'package:flutter/material.dart';

// class EmployeeDetailsPage extends StatelessWidget {
//   final Map employee;

//   const EmployeeDetailsPage({required this.employee, Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final Map info = employee['info'] ?? {};

//     // جلب التاريخ الحالي بصيغة MM-dd
//     final today = DateFormat('MM-dd').format(DateTime.now());
//     final Map todayData = (employee['month'] ?? {})[today] ?? {};

//     final Map hours = todayData['hours'] ?? {};
//     final bool exist = todayData['exist'] ?? false;
//     final forbid = todayData['forbid'] ?? "غير محدد";

//     return Scaffold(
//       appBar: AppBar(title: Text(info['name'] ?? 'Details')),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Card(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//           elevation: 4,
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: ListView(
//               children: [
//                 CircleAvatar(
//                   radius: 60,
//                   backgroundImage: NetworkImage(info['image_url'] ?? ''),
//                 ),
//                 SizedBox(height: 20),
//                 Center(
//                   child: Text(
//                     info['name'] ?? '',
//                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 Divider(height: 30, thickness: 1),
//                 Text("الحضور اليوم: ${exist ? 'موجود' : 'غير موجود'}"),
//                 Text("عدد مرات المنع: $forbid"),
//                 SizedBox(height: 20),
//                 Text("ساعات العمل اليوم:", style: TextStyle(fontWeight: FontWeight.bold)),
//                 ...hours.entries.map((entry) {
//                   final location = entry.key;
//                   final details = entry.value;
//                   final total = details['total_time'] ?? [0, 0, 0];

//                   return Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 8),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text("- $location", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                         Text("  من: ${details['start'] ?? '-'}"),
//                         Text("  إلى: ${details['leave'] ?? '-'}"),
//                         Text("  الوقت الإجمالي: ${total[0]}h ${total[1]}m ${total[2]}s"),
//                       ],
//                     ),
//                   );
//                 }),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
