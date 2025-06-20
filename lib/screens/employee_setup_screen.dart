import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'choose_location_screen.dart';
import 'employee_screen.dart';

class EmployeeSetupScreen extends StatefulWidget {
  static String screenRoute = 'employee_setup_screen';

  const EmployeeSetupScreen({super.key});

  @override
  EmployeeSetupScreenState createState() => EmployeeSetupScreenState();
}

class EmployeeSetupScreenState extends State<EmployeeSetupScreen> {
  List<TextEditingController> _nameControllers = [];
  List<TextEditingController> _salaryControllers = [];
  List<TextEditingController> _workingHoursControllers = [];
  List<TextEditingController> _phoneControllers = [];
  List<TextEditingController> _addressControllers = [];
  List<TextEditingController> _positionController = [];
  List<File?> _employeePhotos = [];
  late String locationNum = '';
  late String userName = '';
  int employeeNum = 1;
  late List<List<List<int>>> polygonDimensions = [];
  int maxPolygons = 1;
  Uint8List theEditionVariable = Uint8List(0);
  int currentIndex = 0;
  List<Map<String, dynamic>> allEmployeesData = [];
  Map<String, List<Map<String, dynamic>>> allLocationsData = {};

  void _addListenersForCurrentEmployee() {
    for (var controller in [
      _nameControllers[currentIndex],
      _salaryControllers[currentIndex],
      _workingHoursControllers[currentIndex],
      _phoneControllers[currentIndex],
      _positionController[currentIndex],
      _addressControllers[currentIndex]
    ]) {
      controller.addListener(() {
        setState(() {});
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _employeePhotos = List.generate(maxPolygons, (index) => null);
    _nameControllers =
        List.generate(maxPolygons, (_) => TextEditingController());
    _salaryControllers =
        List.generate(maxPolygons, (_) => TextEditingController());
    _workingHoursControllers =
        List.generate(maxPolygons, (_) => TextEditingController());
    _phoneControllers =
        List.generate(maxPolygons, (_) => TextEditingController());
    _addressControllers =
        List.generate(maxPolygons, (_) => TextEditingController());
    _positionController =
        List.generate(maxPolygons, (_) => TextEditingController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null) {
        if (args.containsKey('polygonDimensions')) {
          setState(() {
            polygonDimensions =
                args['polygonDimensions'] as List<List<List<int>>>;
          });
        }

        if (args.containsKey('locationNum')) {
          setState(() {
            locationNum = args['locationNum'] as String;
          });
        }

        if (args.containsKey('maxPolygons')) {
          setState(() {
            maxPolygons = args['maxPolygons'] as int;
          });
        }

        if (args.containsKey('userName')) {
          setState(() {
            userName = args['userName'] as String;
          });
        }

        if (args.containsKey('theEditionVariable')) {
          Uint8List originalImage =
              Uint8List.fromList(List<int>.from(args['theEditionVariable']));
          _fixImageOrientation(originalImage);
        }

        if (args.containsKey('allLocationsData')) {
          setState(() {
            allLocationsData = args['allLocationsData'];
          });
        }
      }
      _initializeEmployeeData();
      _addListenersForCurrentEmployee();
    });
  }

  Future<void> finishSetupRealtime(
    BuildContext context,
    String username,
    List<Map<String, dynamic>> employeesDataaa,
    Map<String, dynamic> allLocationsData,
    void Function() saveEmployeeData,
    void Function(String) showWarning,
  ) async {
    saveEmployeeData();

    final databaseRef = FirebaseDatabase.instance.ref();
    List<String> skippedEmployees = [];
    List<Future<void>> uploadTasks = [];

    // Helper
    String trimStr(dynamic val) => (val ?? '').toString().trim();

    for (var emp in employeesDataaa) {
      uploadTasks.add(() async {
        final String name = trimStr(emp['name']);
        final String phone = trimStr(emp['phone']);
        final String address = trimStr(emp['address']);
        final String position = trimStr(emp['position']);
        final int salary = int.tryParse(emp['salary'].toString()) ?? 0;
        final int workingHours =
            int.tryParse(emp['working_hours'].toString()) ?? 0;
        final String photoPath = emp['photo'] ?? '';
        final File image = File(photoPath);

        if (name.isEmpty || phone.isEmpty || address.isEmpty) {
          showWarning("بيانات ناقصة للموظف: $name");
          skippedEmployees.add(name);
          return;
        }

        if (!await image.exists()) {
          showWarning("الصورة غير موجودة للموظف: $name");
          skippedEmployees.add(name);
          return;
        }

        final empRef = databaseRef.child('$username/employees/$name');
        final empSnapshot = await empRef.get();

        // اسم الموظف موجود بالفعل
        if (empSnapshot.exists) {
          final shouldUpdate = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('الموظف موجود'),
              content:
                  Text('الموظف "$name" موجود بالفعل. هل تريد تحديث بياناته؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text('تحديث'),
                ),
              ],
            ),
          );

          if (shouldUpdate != true) {
            skippedEmployees.add(name);
            return;
          }
        }

        // رفع الصورة
        final imageUrl = await uploadCompressedImageToAzure(
          file: image,
          containerName: '$username-images',
          fileName: '$name.jpg',
        );

        if (imageUrl == null) {
          showWarning("فشل رفع صورة الموظف: $name");
          skippedEmployees.add(name);
          return;
        }

        // تحليل إحداثيات المكان
        List<List<int>> location;
        try {
          final workspaceString = emp['workspace'] ?? '';
          if (workspaceString.isEmpty) {
            showWarning("بيانات الموقع فارغة للموظف: $name");
            skippedEmployees.add(name);
            return;
          }

          final decoded = jsonDecode(workspaceString);
          location = (decoded as List)
              .map<List<int>>(
                  (point) => (point as List).map<int>((e) => e as int).toList())
              .toList();
        } catch (e) {
          showWarning("خطأ في تحليل موقع العمل للموظف: $name");
          skippedEmployees.add(name);
          return;
        }

        // تحديث بيانات الموظف
        await empRef.child('info').update({
          'phone': phone,
          'position': position,
          'address': address,
          'salary': salary,
          'working_hours': workingHours,
          'location': location,
          'photo_url': imageUrl,
          'In Location': 'Not exist now',
        });
      }());
    }

    // انتظر انتهاء كل العمليات
    await Future.wait(uploadTasks);

    try {
      final token = await FirebaseMessaging.instance.getToken();

      await databaseRef.child(username).update({
        'token': token ?? '',
        'last_updated': DateTime.now().toIso8601String(),
      });

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, EmployeeScreen.screenRoute);
      }

      print('✅ تم رفع البيانات بنجاح');

      if (skippedEmployees.isNotEmpty) {
        print('⚠️ تم تخطي الموظفين التاليين: ${skippedEmployees.join(', ')}');
      }
    } catch (error) {
      print('❌ خطأ في رفع البيانات إلى Firebase: $error');
      showWarning('فشل في رفع البيانات، حاول مرة أخرى.');
    }
  }

// رفع الصورة بعد ضغطها إلى Azure

  Future<String?> uploadCompressedImageToAzure({
    required File file,
    required String containerName,
    required String fileName,
  }) async {
    final String accountName = 'gp1storage2';
    final String sasToken =
        'sv=2024-11-04&ss=bfqt&srt=co&sp=rwdlacupiytfx&se=2027-02-16T22:26:06Z&st=2025-05-09T13:26:06Z&spr=https,http&sig=H%2BJaeH5Yu2EBBoblfSEfn%2BHWHZCPRza1XzAdhKZYCzE%3D';

    // تنظيف اسم الكونتينر: أحرف صغيرة فقط وأرقام وشرطة
    final safeContainerName =
        containerName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]'), '');

    // ترميز اسم الملف لتجنب الأحرف الغير مسموح بها في الرابط
    final safeFileName = Uri.encodeComponent(fileName);

    final String url =
        'https://$accountName.blob.core.windows.net/$safeContainerName/$safeFileName?$sasToken';

    print('Uploading to URL: $url'); // تحقق من الرابط النهائي

    try {
      final imageBytes = await file.readAsBytes();
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) return null;

      final resized = img.copyResize(decoded, width: 512); // تقليل الحجم
      final compressedBytes =
          img.encodeJpg(resized, quality: 60); // تقليل الجودة

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'x-ms-blob-type': 'BlockBlob',
          'x-ms-version': '2020-10-02',
          'Content-Type': 'image/jpeg',
          'Content-Length': compressedBytes.length.toString(),
        },
        body: compressedBytes,
      );

      if (response.statusCode == 201) {
        print('✅ تم رفع الصورة: $safeFileName');
        return url.split('?').first;
      } else {
        print('❌ فشل في رفع الصورة: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ خطأ أثناء رفع الصورة: $e');
      return null;
    }
  }

  void _initializeEmployeeData() {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      if (args.containsKey('polygonDimensions')) {
        polygonDimensions =
            List<List<List<int>>>.from(args['polygonDimensions']);
      } else {
        // Handle the error or warning
        _showWarning('Image dimensions not found.');
      }
    }

    for (int i = 0; i < maxPolygons; i++) {
      _employeePhotos.add(null);
      _positionController.add(TextEditingController());
      _nameControllers.add(TextEditingController());
      _salaryControllers.add(TextEditingController());
      _workingHoursControllers.add(TextEditingController());
      _phoneControllers.add(TextEditingController());
      _addressControllers.add(TextEditingController());
    }
  }

  List<Map<String, dynamic>> getAllEmployeesFromAllLocations() {
    List<Map<String, dynamic>> allEmployees = [];

    allLocationsData.forEach((locationName, employeesList) {
      allEmployees.addAll(employeesList);
    });

    return allEmployees;
  }

  void _saveEmployeeData() {
    Map<String, dynamic> employeeData = {
      'Location': locationNum,
      'workspace': jsonEncode(polygonDimensions[currentIndex]),
      'name': _nameControllers[currentIndex].text.replaceAll(' ', '_'),
      'position': _positionController[currentIndex].text,
      'salary': _salaryControllers[currentIndex].text,
      'working_hours': _workingHoursControllers[currentIndex].text,
      'phone': _phoneControllers[currentIndex].text,
      'address': _addressControllers[currentIndex].text,
      'photo': _employeePhotos[currentIndex]?.path,
    };

    // Just call saveEmployeeData, don't overwrite manually
    saveEmployeeData(locationNum, employeeData);
    allEmployeesData.add(employeeData);

    getAllEmployeesFromAllLocations();

    employeeNum++; // Increment the employee number for the next employee

    print("Saved Employee ${currentIndex + 1}: $employeeData");
    print("Updated allLocationsData: $allLocationsData");
    print("Updated allEmployeesData: $allEmployeesData");
  }

  void saveEmployeeData(
      String locationName, Map<String, dynamic> employeeData) {
    allLocationsData.putIfAbsent(locationName, () => []);
    allLocationsData[locationName]!.add(employeeData);
  }

  Future<void> _fixImageOrientation(Uint8List originalImage) async {
    img.Image? decodedImage = img.decodeImage(originalImage);
    if (decodedImage != null) {
      img.Image fixedImage = img.bakeOrientation(decodedImage);
      setState(() {
        theEditionVariable = Uint8List.fromList(img.encodeJpg(fixedImage));
      });
    }
  }

  bool _isPickingImage = false;

  Future<void> _pickImage(int index) async {
    if (_isPickingImage)
      return; // Prevent triggering the picker again if it's already active.

    setState(() {
      _isPickingImage = true;
    });

    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _employeePhotos[index] = File(pickedFile.path);
      });
    }

    setState(() {
      _isPickingImage = false; // Re-enable the picker after the operation.
    });
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  bool _isCurrentEmployeeValid() {
    return _nameControllers[currentIndex].text.isNotEmpty &&
        _employeePhotos[currentIndex] != null &&
        _positionController[currentIndex].text.isNotEmpty &&
        _salaryControllers[currentIndex].text.isNotEmpty &&
        _workingHoursControllers[currentIndex].text.isNotEmpty &&
        _phoneControllers[currentIndex].text.isNotEmpty &&
        _addressControllers[currentIndex].text.isNotEmpty;
  }

  void _showImagePreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black.withOpacity(0.3),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (theEditionVariable.isNotEmpty)
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 2,
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(10),
                  minScale: 1.0,
                  maxScale: 5.0,
                  child: Image.memory(theEditionVariable, fit: BoxFit.cover),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _nextEmployee() {
    if (!_isCurrentEmployeeValid()) {
      _showWarning(
          'Please fill in all fields and select a photo before proceeding.');
      return;
    }
    _saveEmployeeData();
    if (currentIndex < maxPolygons - 1) {
      setState(() {
        currentIndex++;
        _addListenersForCurrentEmployee();
      });
    }
  }

  void _previousEmployee() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        _addListenersForCurrentEmployee();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 243),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15),
          child: IndexedStack(
            index: currentIndex,
            children: List.generate(maxPolygons, (index) {
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;

              return SingleChildScrollView(
                child: Card(
                  color: const Color.fromARGB(255, 189, 189, 252),
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 9,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.02,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Enter Employee Information',
                          style: TextStyle(
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 20),
                            Expanded(
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  'Employee ${currentIndex + 1} of $maxPolygons',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.image),
                              onPressed: _showImagePreview,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _pickImage(index),
                          child: Center(
                            child: CircleAvatar(
                              radius: screenWidth * 0.13,
                              backgroundColor: Colors.white,
                              backgroundImage: _employeePhotos[index] != null
                                  ? FileImage(_employeePhotos[index]!)
                                  : null,
                              child: _employeePhotos[index] == null
                                  ? const Icon(
                                      Icons.person_add_alt_1,
                                      size: 50,
                                      color: Color.fromARGB(255, 189, 189, 252),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(_nameControllers[index], 'Name',
                            TextInputType.name),
                        _buildTextField(_positionController[index], 'position',
                            TextInputType.name),
                        _buildTextField(_salaryControllers[index], 'Salary',
                            TextInputType.number),
                        _buildTextField(_workingHoursControllers[index],
                            'Working Hours', TextInputType.number),
                        _buildTextField(_phoneControllers[index], 'Phone',
                            TextInputType.phone),
                        _buildTextField(_addressControllers[index], 'Address',
                            TextInputType.streetAddress),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  if (currentIndex > 0) {
                                    _previousEmployee();
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text("Back"),
                              ),
                              Builder(
                                builder: (context) {
                                  bool isValid = _isCurrentEmployeeValid();
                                  bool isLastEmployee =
                                      currentIndex == maxPolygons - 1;

                                  return isLastEmployee
                                      ? ElevatedButton(
                                          onPressed: isValid
                                              ? () {
                                                  _saveEmployeeData();
                                                  Navigator.pushNamed(
                                                    context,
                                                    ChooseLocationScreen
                                                        .screenRoute,
                                                    arguments: {
                                                      "userName": userName,
                                                      // 'allLocationsData':
                                                      //     allLocationsData,
                                                    },
                                                  );
                                                }
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isValid
                                                ? Colors.white
                                                : Colors.grey,
                                          ),
                                          child: const Text(
                                              "Add another location"),
                                        )
                                      : ElevatedButton(
                                          onPressed:
                                              isValid ? _nextEmployee : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isValid
                                                ? Colors.white
                                                : Colors.grey,
                                          ),
                                          child: const Text("Continue"),
                                        );
                                },
                              ),
                            ],
                          ),
                        ),
                        if (currentIndex == maxPolygons - 1)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: ElevatedButton(
                                onPressed: () async {
                                  await finishSetupRealtime(
                                    context,
                                    userName,
                                    allEmployeesData,
                                    allLocationsData,
                                    _saveEmployeeData,
                                    _showWarning,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isCurrentEmployeeValid()
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                child: const Text("Finish Setup"),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      TextInputType keyboard) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: labelText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(width: 1),
          ),
        ),
      ),
    );
  }
}
