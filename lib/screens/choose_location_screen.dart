import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/locations.dart';
import 'num_of_location.dart';

class ChooseLocationScreen extends StatefulWidget {
  static const String screenRoute = 'choose_location_screen';

  const ChooseLocationScreen({super.key});

  @override
  State<ChooseLocationScreen> createState() => _ChooseLocationScreenState();
}

class _ChooseLocationScreenState extends State<ChooseLocationScreen> {
  bool isLoading = false;

  // تخزين الأبعاد الأصلية
  double _imageWidth = 0;
  double _imageHeight = 0;

  // لتخزين البيانات التي نستلمها من الروت
  String userName = '';
  Map<String, dynamic>? allLocationsData;

  bool _isInit = true; // لمنع إعادة التنفيذ في didChangeDependencies

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final routeArgs = ModalRoute.of(context)?.settings.arguments;

      if (routeArgs != null && routeArgs is Map<String, dynamic>) {
        userName = routeArgs['userName'] ?? '';
        allLocationsData = routeArgs['allLocationsData'];
      }
      _isInit = false;
    }
  }

  // دالة لتحميل الصورة واستخراج الأبعاد
  Future<void> _getImageDimensions(String imageUrl) async {
    final image = Image.network(imageUrl);
    final completer = Completer<void>();

    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          setState(() {
            _imageWidth = info.image.width.toDouble();
            _imageHeight = info.image.height.toDouble();
          });
          completer.complete();
        },
      ),
    );

    await completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color.fromARGB(255, 211, 211, 243),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color.fromARGB(255, 211, 211, 243),
            title: const Center(child: Text("Choose Location")),
          ),
          body: ListView.builder(
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return GestureDetector(
                onTap: () async {
                  setState(() {
                    isLoading = true;
                  });

                  // تحميل الصورة واستخراج الأبعاد قبل الانتقال
                  await _getImageDimensions(location.imagePath);

                  // Navigate to NumOfLocation with data
                  Navigator.pushReplacementNamed(
                    context,
                    NumOfLocation.screenRoute,
                    arguments: {
                      'locationNum': location.name,
                      'imagePath': location.imagePath,
                      'imageWidth': _imageWidth,
                      'imageHeight': _imageHeight,
                      'allLocationsData': allLocationsData,
                      'userName': userName,
                    },
                  );

                  setState(() {
                    isLoading = false;
                  });
                },
                child: Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: CachedNetworkImage(
                      imageUrl: location.imagePath,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                    title: Center(
                      child: Text(
                        location.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Full-screen loading overlay
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
