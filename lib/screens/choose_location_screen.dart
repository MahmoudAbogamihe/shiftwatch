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
  bool isLoading = false; // فقط متغير واحد للتحميل

  double _imageWidth = 0;
  double _imageHeight = 0;

  String userName = '';
  Map<String, dynamic>? allLocationsData;

  bool _isInit = true;
  List<Location> _locations = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final routeArgs = ModalRoute.of(context)?.settings.arguments;
      if (routeArgs != null && routeArgs is Map<String, dynamic>) {
        userName = routeArgs['userName'] ?? '';
        allLocationsData = routeArgs['allLocationsData'];
      }
      _fetchLocations();
      _isInit = false;
    }
  }

  Future<void> _fetchLocations() async {
    setState(() => isLoading = true);
    try {
      final fetched = await fetchLocationsFromAzure();
      if (!mounted) return;
      setState(() => _locations = fetched);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل تحميل الصور')),
      );
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _getImageDimensions(String imageUrl) async {
    final image = Image.network(imageUrl);
    final completer = Completer<void>();
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        _imageWidth = info.image.width.toDouble();
        _imageHeight = info.image.height.toDouble();
        completer.complete();
      }),
    );
    await completer.future;
  }

  String _extractFileName(String url) {
    return Uri.parse(url).pathSegments.last;
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
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _locations.isEmpty
                  ? const Center(child: Text('لا توجد مواقع متاحة'))
                  : ListView.builder(
                      itemCount: _locations.length,
                      itemBuilder: (context, index) {
                        final location = _locations[index];
                        return GestureDetector(
                          onTap: () async {
                            setState(() => isLoading = true);

                            await _getImageDimensions(location.imagePath);
                            final imageFileName =
                                _extractFileName(location.imagePath);

                            if (!mounted) return;

                            setState(() => isLoading =
                                false); // أولاً أوقف التحميل قبل التنقل

// ثم انتقل بعد فاصل زمني بسيط للتأكد أن setState تم تطبيقها
                            await Future.delayed(Duration(milliseconds: 100));

                            Navigator.pushReplacementNamed(
                              context,
                              NumOfLocation.screenRoute,
                              arguments: {
                                'locationNum': location.name,
                                'imagePath': location.imagePath,
                                'imageFileName': imageFileName,
                                'imageWidth': _imageWidth,
                                'imageHeight': _imageHeight,
                                'allLocationsData': allLocationsData,
                                'userName': userName,
                              },
                            );
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
