import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../user_panel/user_panel_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const String screenRoute = 'dashboard_screen';
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String empName;
  late String username;
  Map<String, dynamic>? empData;
  bool isLoading = true;
  String? selectedDay;
  String? selectedMonth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = Map<String, String>.from(
      (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    );

    empName = args['empName']!;
    username = args['username']!;
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
        // Optionally select first day if available
        if (empData != null && empData!['month'] != null) {
          final monthMap = Map<String, dynamic>.from(empData!['month']);
          final days = monthMap.keys.toList()..sort();
          if (days.isNotEmpty) selectedDay = days.first;
        }
      });
    } else {
      setState(() {
        empData = null;
        isLoading = false;
      });
    }
  }

  String getCurrentDate() {
    final now = DateTime.now();
    return "${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final date = getCurrentDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
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
              ? Center(
                  child: Text(
                    "No data found.",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(empData!),
                      const SizedBox(height: 10),
                      Text(
                        "Select Month",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _buildMonthsBar(
                        Map<String, dynamic>.from(empData?['month'] ?? {}),
                      ),
                      const SizedBox(height: 5),
                      _buildOverviewCard(empData!, date, username, empName),
                      const SizedBox(height: 5),
                      Text(
                        "Daily Work Hours",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMonthlyHoursBarChart(
                        Map<String, dynamic>.from(empData?['month'] ?? {}),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Details of days",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _buildDaysBar(
                        Map<String, dynamic>.from(empData?['month'] ?? {}),
                      ),
                      const SizedBox(height: 5),
                      selectedDay != null
                          ? _buildDayDetails(empData, selectedDay!)
                          : const Center(child: Text("No day selected")),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> data) {
    final info = Map<String, dynamic>.from(data['info'] ?? {});
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage:
              info.containsKey('photo_url') && info['photo_url'] != ''
                  ? NetworkImage(info['photo_url'])
                  : null,
          child: info['photo_url'] == null || info['photo_url'] == ''
              ? const Icon(Icons.person, size: 40)
              : null,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(empName,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(info['position'] ?? '',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthsBar(Map<String, dynamic> data) {
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final months = data.keys
        .map((dayKey) => dayKey.split('-').first) // "06" from "06-09"
        .toSet()
        .toList()
      ..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: months.map((monthStr) {
          final monthInt = int.tryParse(monthStr);
          final monthName =
              (monthInt != null && monthInt >= 1 && monthInt <= 12)
                  ? monthNames[monthInt - 1]
                  : monthStr;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(monthName),
              selected: selectedMonth == monthStr,
              onSelected: (_) {
                setState(() {
                  selectedMonth = monthStr; // still "06", for filtering logic
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewCard(
    Map<String, dynamic> data,
    String date,
    String username,
    String employeeName,
  ) {
    if (!data.containsKey('month')) {
      return const Text("No data available for this month.");
    }

    final monthData = Map<String, dynamic>.from(data['month']);

    // دالة لجلب المرتب وساعات العمل اليومية من Firebase
    Future<Map<String, dynamic>> getEmployeeWorkData({
      required String username,
      required String employeeName,
    }) async {
      final ref = FirebaseDatabase.instance.ref();
      final snapshot = await ref
          .child(username)
          .child('employees')
          .child(employeeName)
          .child('info')
          .once();

      if (snapshot.snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        final salary = (data['salary'] ?? 0).toDouble();
        final workingHours = (data['working_hours'] ?? 0).toDouble();

        return {
          'salary': salary,
          'working_hours': workingHours,
        };
      } else {
        throw Exception("Employee info not found.");
      }
    }

    // تحويل الوقت الإجمالي إلى ساعات عشرية
    double calculateTotalWorkedHours(Map<String, dynamic> monthData) {
      int totalSeconds = 0;

      monthData.forEach((key, dayData) {
        if (dayData != null && dayData.containsKey('total_time')) {
          final time = dayData['total_time'];
          if (time is List && time.length >= 3) {
            final h = time[0] as int;
            final m = time[1] as int;
            final s = time[2] as int;

            totalSeconds += (h * 3600) + (m * 60) + s;
          }
        }
      });

      // تحويل الثواني إلى ساعات (double)
      return totalSeconds / 3600;
    }

    // تنسيق الوقت لعرضه
    String formatTotalHours(double totalHours) {
      int hours = totalHours.floor();
      int minutes = ((totalHours - hours) * 60).floor();
      int seconds = (((totalHours * 3600) % 60)).round();

      if (hours == 0 && minutes == 0) {
        return '$seconds s';
      } else if (hours == 0) {
        return '$minutes m';
      } else if (minutes == 0) {
        return '$hours h';
      } else {
        return '$hours h $minutes m';
      }
    }

    int calculateForbiddenAttempts(Map<String, dynamic> monthData) {
      int count = 0;

      monthData.forEach((_, dayData) {
        if (dayData != null && dayData['forbid'] != null) {
          final forbid = dayData['forbid'] as Map;

          forbid.forEach((_, locationMap) {
            if (locationMap is Map) {
              count++; // كل موقع فيه محاولة واحدة
            }
          });
        }
      });

      return count;
    }

    // حساب عدد الأيام التي اشتغل فيها الموظف
    int calculateWorkingDays(Map<String, dynamic> monthData) {
      int count = 0;
      monthData.forEach((key, dayData) {
        if (dayData != null && dayData.containsKey('total_time')) {
          final time = dayData['total_time'];
          if (time is List && time.length >= 4) {
            final h = time[1] as int;
            final m = time[2] as int;
            final ms = time[3] as int;
            if (h != 0 || m != 0 || ms != 0) {
              count++;
            }
          }
        }
      });
      return count;
    }

    // حساب قيمة الساعة
    double calculateHourlyRate({
      required double monthlySalary,
      required double workingHoursPerDay,
      required int workingDaysInMonth,
    }) {
      final totalHoursPerMonth = workingHoursPerDay * workingDaysInMonth;
      return monthlySalary / totalHoursPerMonth;
    }

    // حساب الراتب المتوقع
    String calculateExpectedSalary(double totalHours, double hourlyRate) {
      double salary = totalHours * hourlyRate;
      return '${salary.toStringAsFixed(2)} EGP';
    }

    // نستخدم FutureBuilder لانتظار بيانات Firebase
    return FutureBuilder<Map<String, dynamic>>(
      future:
          getEmployeeWorkData(username: username, employeeName: employeeName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        } else if (!snapshot.hasData) {
          return const Text("No employee data found.");
        }

        final salary = snapshot.data!['salary'] as double;
        final dailyHours = snapshot.data!['working_hours'] as double;
        const workingDaysInMonth = 26;

        final hourlyRate = calculateHourlyRate(
          monthlySalary: salary,
          workingHoursPerDay: dailyHours,
          workingDaysInMonth: workingDaysInMonth,
        );

        final totalHoursDecimal = calculateTotalWorkedHours(monthData);
        final formattedHours = formatTotalHours(totalHoursDecimal);
        final expectedSalary =
            calculateExpectedSalary(totalHoursDecimal, hourlyRate);
        final workingDays = calculateWorkingDays(monthData);

        final forbiddenAttempts = calculateForbiddenAttempts(monthData);

        final overview = {
          "Working Days": workingDays.toString(),
          "Worked Hours": formattedHours,
          "🚫 Forbidden": forbiddenAttempts.toString(),
          "Expected Salary": expectedSalary,
        };

        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Monthly Overview",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color.fromARGB(255, 11, 19, 66))),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: overview.entries.map((e) {
                    return Expanded(
                      child: Column(
                        // mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            e.value,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.key,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDaysBar(Map<String, dynamic> monthData) {
    List<String> days = monthData.keys.toList()..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: days.map((day) {
          final dayOnly = int.parse(day.split('-').last).toString();
          final isSelected = selectedDay == day;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                ],
                border: Border.all(
                  color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
                  width: 1.2,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    selectedDay = day;
                  });
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
                  child: Text(
                    dayOnly,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyHoursBarChart(Map<String, dynamic> monthData) {
    final List<BarChartGroupData> barGroups = [];
    final List<String> dayLabels = [];

    final sortedKeys = monthData.keys.toList()
      ..sort((a, b) {
        final dayA = int.tryParse(a.split('-').last) ?? 0;
        final dayB = int.tryParse(b.split('-').last) ?? 0;
        return dayA.compareTo(dayB);
      });

    int index = 0;

    for (var dayKey in sortedKeys) {
      final dayData = monthData[dayKey];
      double hours = 0;

      if (dayData != null && dayData.containsKey('total_time')) {
        final time = dayData['total_time'];
        if (time is List && time.length >= 4) {
          final h = time[0] as int;
          final m = time[1] as int;
          final s = time[2] as int;
          hours = h + (m / 60) + (s / 3600);
        }
      }

      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: hours,
              color: Colors.blueAccent,
              width: 10,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );

      dayLabels.add(int.parse(dayKey.split('-').last).toString());
      index++;
    }

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 12, // أقصى عدد ساعات عمل باليوم (يمكنك تغييره حسب الحاجة)
          barGroups: barGroups,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i >= 0 && i < dayLabels.length) {
                    return SideTitleWidget(
                      meta: meta,
                      space: 2,
                      child: Text(
                        dayLabels[i],
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
        ),
      ),
    );
  }

  Widget _buildDayDetails(dynamic empData, String selectedDay) {
    if (empData == null) return Container();

    final monthData = empData['month'];
    if (monthData == null || monthData[selectedDay] == null) {
      return const Text("No data for selected day.");
    }

    final now = DateTime.now();
    final fullDateStr = "${now.year}-$selectedDay";
    final parsedDate = DateTime.tryParse(fullDateStr);

    String formattedDisplayDate = "Invalid date";
    if (parsedDate != null) {
      final dayName = DateFormat.EEEE().format(parsedDate);
      formattedDisplayDate =
          "$dayName, ${parsedDate.year}/${parsedDate.month}/${parsedDate.day}";
    }

    final Map<String, dynamic> dayData =
        Map<String, dynamic>.from(monthData[selectedDay]);
    final arriveTime = dayData['start'] ?? 'N/A';
    final leaveTime = dayData['leave'] ?? 'N/A';

    final totalWorked = _formatWorkedTime(dayData['total_time']);
    final hoursMap = Map<String, dynamic>.from(dayData['hours'] ?? {});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDisplayDate,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B1342),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _infoColumn(Icons.login, "Arrival", arriveTime.toString()),
                    _infoColumn(Icons.logout, "Exit", leaveTime.toString()),
                    _infoColumn(Icons.timer, "Worked", totalWorked),
                  ],
                ),
                const Divider(
                  color: Colors.grey,
                  thickness: 0.6,
                  height: 24,
                  indent: 12,
                  endIndent: 12,
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildPieChartWithLegend(hoursMap)),
                          const Divider(
                            color: Colors.grey,
                            thickness: 0.6,
                            height: 24,
                            indent: 12,
                            endIndent: 12,
                          ),
                          Expanded(child: _buildForbiddenAttempts(dayData)),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildPieChartWithLegend(hoursMap),
                          const Divider(
                            color: Colors.grey,
                            thickness: 0.6,
                            height: 24,
                            indent: 12,
                            endIndent: 12,
                          ),
                          _buildForbiddenAttempts(dayData),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildPieChartWithLegend(Map<String, dynamic> hoursMap) {
    if (hoursMap.isEmpty) return const SizedBox.shrink();

    Map<String, double> locationToMinutes = {};

    // حساب الدقائق الدقيقة
    hoursMap.forEach((location, timeList) {
      if (timeList is List && timeList.length >= 4) {
        final h = (timeList[0] as num).toDouble();
        final m = (timeList[1] as num).toDouble();
        final s = (timeList[2] as num).toDouble();
        // final ms = (timeList[3] as num?)?.toDouble() ?? 0;

        // نحول كل شيء إلى ثواني ثم إلى دقائق
        final totalSeconds = (h * 3600) + (m * 60) + s;
        final totalMinutes = totalSeconds / 60;

        locationToMinutes[location] = totalMinutes;
      }
    });

    final total = locationToMinutes.values.fold(0.0, (a, b) => a + b);

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.redAccent,
      Colors.indigo,
    ];

    List<PieChartSectionData> sections = [];
    int i = 0;

    locationToMinutes.forEach((location, minutes) {
      final percentage = total == 0 ? 0 : (minutes / total) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: percentage.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 40,
          titleStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
      i++;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "🧭 Time Distribution in Locations",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 35,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                locationToMinutes.entries.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final location = entry.value.key;
              final totalMinutes = entry.value.value;

              final totalSecondsDouble = totalMinutes * 60;
              final totalMilliseconds = (totalSecondsDouble * 1000).round();

              final hours = totalMilliseconds ~/ (3600 * 1000);
              final minutes =
                  (totalMilliseconds % (3600 * 1000)) ~/ (60 * 1000);
              final seconds = (totalMilliseconds % (60 * 1000)) ~/ 1000;
              final milliseconds = totalMilliseconds % 1000;

              final color = colors[index % colors.length];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          location,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      [
                        if (hours > 0) '${hours}h',
                        if (minutes > 0) '${minutes}m',
                        if (seconds > 0) '${seconds}s',
                        if (milliseconds > 0) '${milliseconds}ms',
                      ].join(' '),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildForbiddenAttempts(Map<String, dynamic> dayData) {
    final forbidMap = dayData['forbid'] as Map<dynamic, dynamic>?;

    if (forbidMap == null || forbidMap.isEmpty) {
      return const SizedBox.shrink();
    }

    List<Widget> attemptWidgets = [];
    int attemptNum = 1;

    forbidMap.forEach((key, attemptData) {
      if (attemptData is Map && attemptData.containsKey('start')) {
        final location = 'Attendant $attemptNum';
        final start = attemptData['start'] ?? 'N/A';

        String? officeKey;

        attemptData.forEach((k, v) {
          if (k != 'start' && k.toLowerCase().contains('office')) {
            officeKey = k;
          }
        });

// لو لقينا المفتاح:
        final durationData = officeKey != null ? attemptData[officeKey] : null;

        final formattedTime = _formatWorkedTime(durationData);

        attemptWidgets.add(
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: Text(
                '$attemptNum',
                style: const TextStyle(color: Colors.red),
              ),
            ),
            title: Text(
              location,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Started at $start\nDuration: $formattedTime'),
            isThreeLine: true,
          ),
        );
        attemptNum++;
      }
    });

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              "🚫 Forbidden Attempts (${attemptNum - 1})",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          ...attemptWidgets,
        ],
      ),
    );
  }

  String _formatWorkedTime(dynamic timeList) {
    try {
      if (timeList == null || timeList.length < 3) return "N/A";

      final h = (timeList[0] as num).toInt();
      final m = (timeList[1] as num).toInt();
      final s = (timeList[2] as num).toInt();

      List<String> parts = [];
      if (h > 0 && m > 0 && s > 0) parts.add('$h h $m m $s s');
      if (h > 0 && m == 0 && s == 0) parts.add('$h h');
      if (h == 0 && m > 0 && s == 0) parts.add('$m m');
      if (h == 0 && m == 0 && s > 0) parts.add('$s s');
      if (h == 0 && m > 0 && s > 0) parts.add('$m m $s s');

      return parts.isEmpty ? "0 m" : parts.join(' ');
    } catch (e) {
      return "N/A";
    }
  }
}
