import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'num_of_location.dart';

class AddEmployeeScreen extends StatefulWidget {
  static const String screenRoute = 'add_employee_screen';

  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  File? _pickedImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  void _saveEmployee() {
    final name = _nameController.text.trim();
    final status = _statusController.text.trim();

    if (name.isEmpty || status.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    Navigator.pop(context, {
      'name': name,
      'status': status,
      'image': _pickedImage?.path ?? 'assets/employees/default.png',
    });
  }

  void _goToSiteSetupScreen() {
    Navigator.pushNamed(context, NumOfLocation.screenRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Employee")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _pickedImage != null
                    ? FileImage(_pickedImage!)
                    : const AssetImage('assets/employees/default.png')
                        as ImageProvider,
                child: _pickedImage == null
                    ? const Icon(Icons.camera_alt, size: 30)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _statusController,
              decoration: const InputDecoration(labelText: 'Status'),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveEmployee,
              icon: const Icon(Icons.save),
              label: const Text("Save"),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            const SizedBox(height: 30),
            OutlinedButton.icon(
              onPressed: _goToSiteSetupScreen,
              icon: const Icon(Icons.location_on_outlined),
              label: const Text("Define Workspace"),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                side: const BorderSide(color: Colors.blueAccent),
              ),
            )
          ],
        ),
      ),
    );
  }
}
