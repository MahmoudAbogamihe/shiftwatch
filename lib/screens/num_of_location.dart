import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'choose_location_screen.dart';
import 'location_screen.dart';

class NumOfLocation extends StatefulWidget {
  static String screenRoute = 'num_of_location';

  const NumOfLocation({super.key});

  @override
  State<NumOfLocation> createState() => _NumOfLocationState();
}

class _NumOfLocationState extends State<NumOfLocation> {
  String locationNum = '';
  String imagePath = '';
  String userName = '';
  var allLocationsData;
  late double imageWidth;
  late double imageHeight;
  final TextEditingController _polygonController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
      setState(() {
        locationNum = args['locationNum'] ?? '';
        imagePath = args['imagePath'] ?? '';
        userName = args['userName'] ?? '';
        allLocationsData = args['allLocationsData'];
        imageWidth = args['imageWidth'];
        imageHeight = args['imageHeight'];
      });
    });
  }

  @override
  void dispose() {
    _polygonController.dispose();
    super.dispose();
  }

  void _navigateToLocationScreen() async {
    int? maxPolygons = int.tryParse(_polygonController.text);
    if (maxPolygons != null && maxPolygons > 0) {
      setState(() => isLoading = true);

      await Future.delayed(const Duration(seconds: 2));

      setState(() => isLoading = false);

      print(imagePath);

      Navigator.pushNamed(
        context,
        LocationScreen.screenRoute,
        arguments: {
          'imageWidth': imageWidth,
          'imageHeight': imageHeight,
          'imagePath': imagePath,
          'maxPolygons': maxPolygons,
          'locationNum': locationNum,
          'userName': userName,
          if (allLocationsData != null) 'allLocationsData': allLocationsData,
        },
      );
    } else {
      _showErrorDialog();
    }
    print('imageWidth $imageWidth');
    print('imageHeight $imageHeight');
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Invalid Number"),
        content: const Text("Please enter a valid number greater than 0."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 211, 211, 243),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 211, 211, 243),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacementNamed(
                  context, ChooseLocationScreen.screenRoute);
            },
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    locationNum,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: MediaQuery.of(context).size.width * 0.8,
                    width: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(imagePath),
                        fit: BoxFit.fill,
                      ),
                      border: Border.all(color: Colors.grey.shade400, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _polygonController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Number of Employee Locations',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _navigateToLocationScreen,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
