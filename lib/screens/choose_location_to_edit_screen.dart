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
  bool isLoading = false;

  double _imageWidth = 0;
  double _imageHeight = 0;

  late String userName = '';
  late String employeeName = '';

  bool _isInit = true;

  ///  --- image-stream bookkeeping to clean up in dispose() ---
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
      _isInit = false;
    }
  }

  Future<void> _getImageDimensions(String imageUrl) async {
    final provider = CachedNetworkImageProvider(imageUrl);

    final completer = Completer<void>();
    _stream = provider.resolve(const ImageConfiguration());
    _listener = ImageStreamListener((info, _) {
      if (!mounted) return; // <- protect setState
      setState(() {
        _imageWidth = info.image.width.toDouble();
        _imageHeight = info.image.height.toDouble();
      });
      completer.complete();
    });
    _stream!.addListener(_listener!);

    await completer.future;
  }

  @override
  void dispose() {
    // remove listener to avoid leaks / late callbacks
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
          body: ListView.builder(
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return GestureDetector(
                onTap: () async {
                  if (!mounted) return;
                  setState(() => isLoading = true);

                  await _getImageDimensions(location.imagePath);

                  if (!mounted) return; // may have been disposed mid-await
                  Navigator.pushReplacementNamed(
                    context,
                    LocationToEditScreen.screenRoute,
                    arguments: {
                      'imagePath': location.imagePath,
                      'imageWidth': _imageWidth,
                      'imageHeight': _imageHeight,
                      'userName': userName,
                      'empName': employeeName,
                    },
                  );
                  // no setState(isLoading=false) needed; this widget is gone
                },
                child: Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: CachedNetworkImage(
                      imageUrl: location.imagePath,
                      placeholder: (_, __) => const CircularProgressIndicator(),
                      errorWidget: (_, __, ___) => const Icon(Icons.error),
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
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.4),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
      ],
    );
  }
}
