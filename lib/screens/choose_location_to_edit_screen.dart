import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/locations.dart';
import 'location_to_edit_screen.dart';

class ChooseLocationToEditScreen extends StatefulWidget {
  static const String screenRoute = 'choose_location_to_edit_screen';

  const ChooseLocationToEditScreen({super.key});

  @override
  State<ChooseLocationToEditScreen> createState() =>
      _ChooseLocationToEditScreenState();
}

class _ChooseLocationToEditScreenState
    extends State<ChooseLocationToEditScreen> {
  bool isFetchingLocations = false;
  bool isLoadingOnTap = false;

  double _imageWidth = 0;
  double _imageHeight = 0;

  late String userName = '';
  late String employeeName = '';

  bool _isInit = true;
  List<Location> _locations = [];

  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        userName = args['userName'] ?? '';
        employeeName = args['employeeName'] ?? '';
      }
      _loadLocations();
      _isInit = false;
    }
  }

  Future<void> _loadLocations() async {
    setState(() => isFetchingLocations = true);
    try {
      final fetched = await fetchLocationsFromAzure();
      if (!mounted) return;
      setState(() => _locations = fetched);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل تحميل الصور من Azure')),
        );
      }
    } finally {
      if (mounted) setState(() => isFetchingLocations = false);
    }
  }

  Future<void> _getImageDimensions(String imageUrl) async {
    final provider = CachedNetworkImageProvider(imageUrl);
    final completer = Completer<void>();
    _stream = provider.resolve(const ImageConfiguration());
    _listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      _imageWidth = info.image.width.toDouble();
      _imageHeight = info.image.height.toDouble();
      completer.complete();
    });
    _stream!.addListener(_listener!);
    await completer.future;
  }

  @override
  void dispose() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    super.dispose();
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
          body: isFetchingLocations
              ? const Center(child: CircularProgressIndicator())
              : _locations.isEmpty
                  ? const Center(child: Text("لا توجد مواقع حالياً"))
                  : ListView.builder(
                      itemCount: _locations.length,
                      itemBuilder: (context, index) {
                        final location = _locations[index];
                        return GestureDetector(
                          onTap: () async {
                            if (!mounted) return;
                            setState(() => isLoadingOnTap = true);

                            await _getImageDimensions(location.imagePath);

                            if (!mounted) return;
                            final result = await Navigator.pushNamed(
                              context,
                              LocationToEditScreen.screenRoute,
                              arguments: {
                                'imagePath': location.imagePath,
                                'loccam': location.name,
                                'imageWidth': _imageWidth,
                                'imageHeight': _imageHeight,
                                'userName': userName,
                                'empName': employeeName,
                              },
                            );

                            if (!mounted) return;
                            if (result != null &&
                                result is Map<String, dynamic>) {
                              final points =
                                  result['points']; // إحداثيات المضلع
                              final loccam = result['loccam']; // اسم الموقع

                              Navigator.pop(context, {
                                'points': points,
                                'loccam': loccam,
                              });
                            } else {
                              setState(() => isLoadingOnTap = false);
                            }

                            print('hi your ${location.name}');
                          },
                          child: Card(
                            margin: const EdgeInsets.all(10),
                            child: ListTile(
                              leading: CachedNetworkImage(
                                imageUrl: location.imagePath,
                                placeholder: (_, __) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (_, __, ___) =>
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
        if (isLoadingOnTap)
          Container(
            color: Colors.black.withOpacity(0.4),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
      ],
    );
  }
}
