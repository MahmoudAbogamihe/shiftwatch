import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

// Upload compressed image to Azure (reusable function)
Future<String?> uploadCompressedImageToAzure({
  required File file,
  required String containerName,
  required String fileName,
}) async {
  final String accountName = 'gp1storage2';
  final String sasToken =
      'sv=2024-11-04&ss=bfqt&srt=co&sp=rwdlacupiytfx&se=2027-02-16T22:26:06Z&st=2025-05-09T13:26:06Z&spr=https,http&sig=H%2BJaeH5Yu2EBBoblfSEfn%2BHWHZCPRza1XzAdhKZYCzE%3D';

  final safeContainerName =
      containerName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]'), '');

  final safeFileName = Uri.encodeComponent(fileName);

  final String url =
      'https://$accountName.blob.core.windows.net/$safeContainerName/$safeFileName?$sasToken';

  try {
    final imageBytes = await file.readAsBytes();
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return null;

    final resized = img.copyResize(decoded, width: 512);
    final compressedBytes = img.encodeJpg(resized, quality: 60);

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
      return url.split('?').first;
    } else {
      print('Failed to upload image to Azure: ${response.statusCode}');
      print('Response body: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Error uploading image to Azure: $e');
    return null;
  }
}

class EditProfileScreen extends StatefulWidget {
  static const String screenRoute = 'edit_profile_screen';
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late String username;
  late String oldEmployeeName;
  late Map<String, dynamic> info;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController salaryController;
  late TextEditingController hoursController;
  late TextEditingController positionController;

  String? photoUrl;
  File? newImageFile;

  final ImagePicker picker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route == null) return;

    final args = route.settings.arguments;
    if (args == null || args is! Map<String, dynamic>) return;

    final Map<String, dynamic> arguments = args;

    username = arguments['username'] ?? '';
    oldEmployeeName = arguments['empName'] ?? '';
    info = Map<String, dynamic>.from(arguments['info'] ?? {});

    nameController = TextEditingController(text: oldEmployeeName);
    phoneController = TextEditingController(text: info['phone'] ?? '');
    addressController = TextEditingController(text: info['address'] ?? '');
    salaryController =
        TextEditingController(text: info['salary']?.toString() ?? '');
    hoursController =
        TextEditingController(text: info['working_hours']?.toString() ?? '');
    positionController = TextEditingController(text: info['position'] ?? '');
    photoUrl = info['photo_url'] ?? '';
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        newImageFile = File(pickedFile.path);
      });
    }
  }

  // Upload image to Azure instead of Firebase Storage
  Future<String?> uploadImageToAzure(
      File imageFile, String employeeName) async {
    return await uploadCompressedImageToAzure(
      file: imageFile,
      containerName: '$username-images',
      fileName: '$employeeName.jpg',
    );
  }

  Future<void> renameEmployeeIfNeeded(String oldName, String newName) async {
    if (oldName == newName.trim()) return; // no need to rename

    final dbRef = FirebaseDatabase.instance.ref();

    final oldSnapshot = await dbRef.child("employees/$oldName").get();

    if (!oldSnapshot.exists) {
      print("Old employee does not exist");
      return;
    }

    final oldData = oldSnapshot.value;

    // Create new node with new name and copy old data
    await dbRef.child("employees/$newName").set(oldData);

    // Remove old node
    await dbRef.child("employees/$oldName").remove();

    print("Renamed employee from $oldName to $newName");
  }

  void updateData() async {
    if (_formKey.currentState!.validate()) {
      final newEmployeeName = nameController.text.trim();
      bool nameChanged = newEmployeeName != oldEmployeeName;
      bool imageChanged = newImageFile != null;

      if (nameChanged) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Name Change'),
            content: const Text(
                'Are you sure you want to change the employee name? The data will be copied to the new name, old data will remain.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );

        if (confirm != true) {
          return;
        }
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final oldRef = FirebaseDatabase.instance
            .ref('$username/employees/$oldEmployeeName');
        final newRef = FirebaseDatabase.instance
            .ref('$username/employees/$newEmployeeName');

        if (nameChanged) {
          final snapshot = await newRef.get();
          if (snapshot.exists) {
            Navigator.of(context).pop(); // hide loading
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'The new name already exists. Please choose another name.'),
              ),
            );
            return;
          }

          final oldSnapshot = await oldRef.get();
          if (oldSnapshot.exists) {
            await newRef.set(oldSnapshot.value);
            await oldRef.remove();
          }
        }

        String? updatedPhotoUrl = photoUrl;

        if (imageChanged) {
          final imageName = newEmployeeName;
          final uploadedUrl =
              await uploadImageToAzure(newImageFile!, imageName);
          if (uploadedUrl != null) {
            updatedPhotoUrl = uploadedUrl;
          }
        } else if (nameChanged && photoUrl != null && photoUrl!.isNotEmpty) {
          try {
            final response = await http.get(Uri.parse(photoUrl!));
            if (response.statusCode == 200) {
              final tempDir = Directory.systemTemp;
              final tempFile = File('${tempDir.path}/temp.jpg');
              await tempFile.writeAsBytes(response.bodyBytes);

              final newUrl =
                  await uploadImageToAzure(tempFile, newEmployeeName);
              if (newUrl != null) {
                updatedPhotoUrl = newUrl;
              }
            }
          } catch (e) {
            print('Failed to copy old image to new name: $e');
          }
        }

        await newRef.child('info').update({
          'phone': phoneController.text.trim(),
          'address': addressController.text.trim(),
          'salary': salaryController.text.trim(),
          'working_hours': hoursController.text.trim(),
          'position': positionController.text.trim(),
          'photo_url': updatedPhotoUrl ?? '',
        });

        Navigator.of(context).pop(); // hide loading
        Navigator.pop(context, true);
      } catch (e) {
        Navigator.of(context).pop(); // hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating data: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    // Or initialize with existing value:
    // nameController = TextEditingController(text: existingName);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    salaryController.dispose();
    hoursController.dispose();
    positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Colors.grey.shade100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Employee Profile'),
        centerTitle: true,
      ),
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: newImageFile != null
                      ? FileImage(newImageFile!)
                      : (photoUrl != null && photoUrl!.isNotEmpty)
                          ? NetworkImage(photoUrl!) as ImageProvider
                          : null,
                  child: (newImageFile == null &&
                          (photoUrl == null || photoUrl!.isEmpty))
                      ? const Icon(Icons.add_a_photo,
                          size: 40, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the employee name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: salaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Salary',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Working Hours',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: positionController,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: updateData,
                child: const Text('Save'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
