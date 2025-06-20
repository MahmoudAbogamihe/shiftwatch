import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class LocationToEditScreen extends StatefulWidget {
  static String screenRoute = 'location_to_edit_screen';

  const LocationToEditScreen({super.key});

  @override
  State<LocationToEditScreen> createState() => _LocationToEditScreenState();
}

class _LocationToEditScreenState extends State<LocationToEditScreen> {
  final List<List<Offset>> _polygons = [];
  final List<Offset> _currentPolygon = [];
  final List<List<Offset>> _undoStack = [];
  final List<List<Offset>> _redoStack = [];
  Offset? _currentDraggingPoint;
  List<String> polygonDimensions = [];
  int currentEmployeeIndex = 1;
  int maxPolygons = 1;
  late String empName = '';
  late String imagePath = '';
  late String userName = '';
  // ignore: prefer_typing_uninitialized_variables
  var allLocationsData;
  Uint8List? theEditionVariable; // Store the captured image
  final GlobalKey repaintBoundaryKey = GlobalKey(); // Key for RepaintBoundary
  final GlobalKey _imageKey = GlobalKey();
  List<String> polygonListString = [];
  double _originalImageWidth = 0;
  double _originalImageHeight = 0;
  Map<String, dynamic>? empData;
  bool isLoading = true;

  Future<void> _captureImage() async {
    try {
      setState(() {}); // Ensure UI updates before capturing

      await Future.delayed(
          Duration(milliseconds: 200)); // Allow last draw to render

      RenderRepaintBoundary boundary = repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      if (boundary.debugNeedsPaint) {
        await Future.delayed(Duration(milliseconds: 100));
      }

      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      setState(() {
        theEditionVariable = pngBytes; // Store the captured image
      });

      print("Image saved successfully!");
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  final List<Color> _polygonColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.amber,
    Colors.brown,
    Colors.lightBlue,
    Colors.deepPurpleAccent,
  ];

  String _formatPolygonForNumpy(List<List<Offset>> polygons) {
    return polygons
        .map((polygon) =>
            "[${polygon.map((p) => "[${p.dx.toInt()}, ${p.dy.toInt()}]").join(', ')}]")
        .join(',\n');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null) {
        if (args.containsKey('imagePath')) {
          setState(() {
            imagePath = args['imagePath'] as String;
          });
        }
        if (args.containsKey('userName')) {
          setState(() {
            userName = args['userName'] as String;
          });
        }
        if (args.containsKey('empName')) {
          setState(() {
            empName = args['empName'] as String;
          });
        }
        if (args.containsKey('imageWidth')) {
          setState(() {
            _originalImageWidth = args['imageWidth'];
          });
        }
        if (args.containsKey('imageHeight')) {
          setState(() {
            _originalImageHeight = args['imageHeight'];
          });
        }
      }
    });
  }

  void fetchEmployeeData() async {
    setState(() {
      isLoading = true;
    });

    final dbRef = FirebaseDatabase.instance.ref('$userName/employees/$empName');
    final snapshot = await dbRef.get();

    if (snapshot.exists) {
      setState(() {
        empData = Map<String, dynamic>.from(snapshot.value as Map);
        isLoading = false;
      });
    } else {
      setState(() {
        empData = null;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Employee data not found.")),
      );
    }
  }

  bool _isPointInsidePolygon(Offset point, List<Offset> polygon) {
    int intersections = 0;
    for (int i = 0; i < polygon.length; i++) {
      Offset p1 = polygon[i];
      Offset p2 = polygon[(i + 1) % polygon.length];

      // Check if the ray from the point crosses this polygon edge
      if ((p1.dy > point.dy) != (p2.dy > point.dy)) {
        double intersectX =
            p1.dx + (point.dy - p1.dy) * (p2.dx - p1.dx) / (p2.dy - p1.dy);
        if (point.dx < intersectX) {
          intersections++;
        }
      }
    }
    // Odd number of intersections means inside, even means outside
    return (intersections % 2) == 1;
  }

  bool _isOverlapping(List<Offset> newPolygon) {
    for (var existingPolygon in _polygons) {
      for (var point in newPolygon) {
        if (_isPointInsidePolygon(point, existingPolygon)) {
          return true;
        }
      }
      for (var point in existingPolygon) {
        if (_isPointInsidePolygon(point, newPolygon)) {
          return true;
        }
      }
    }
    return false;
  }

  void _showOverlapAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Invalid Polygon"),
        content: Text("Polygons cannot overlap. Please draw a separate area."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showMaxPolygonsAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Polygon Limit Reached"),
        content: Text("You can only draw $maxPolygons polygons."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _addPoint(Offset point) async {
    setState(() {
      if (_polygons.length >= maxPolygons && _currentPolygon.isEmpty) {
        _showMaxPolygonsAlert();
        return;
      }

      if (_currentPolygon.length >= 3 &&
          (point - _currentPolygon.first).distance < 15) {
        if (_polygons.length >= maxPolygons) {
          _showMaxPolygonsAlert();
          return;
        }
        _currentPolygon.add(_currentPolygon.first);
        List<Offset> newPolygon = List.from(_currentPolygon);

        if (_isOverlapping(newPolygon)) {
          _showOverlapAlert();
          _currentPolygon.clear();
          return;
        }
        setState(() {
          _polygons.add(newPolygon);
        });

        // Format and save the polygon's dimensions
        String polygonDimension = _formatPolygonForNumpy([newPolygon]);
        polygonDimensions.add(polygonDimension);

        _currentPolygon.clear();

        if (_polygons.length == maxPolygons) {
          _captureImage(); // Capture the image when the last polygon is drawn
        }
      } else {
        _currentPolygon.add(point);
      }
    });
  }

  void _showDrawingConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Employee dimensions not drawn'),
          content: Text(
            'You are not drawing a polygon. You must draw the all polygons first.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('ok'),
            ),
          ],
        );
      },
    );
  }

  void _undo() {
    if (_currentPolygon.isNotEmpty) {
      // Move the last point to the undo stack
      _redoStack.add([_currentPolygon.removeLast()]);
    } else if (_polygons.isNotEmpty) {
      // Move the last completed polygon to the undo stack
      _redoStack.add(_polygons.removeLast());
    }
    setState(() {}); // Update UI
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      var lastItem = _redoStack.removeLast();

      if (lastItem.length == 1) {
        // Restore a single point
        _currentPolygon.add(lastItem.first);
      } else {
        // Restore a full polygon
        _polygons.add(lastItem);
      }
      setState(() {}); // Update UI
    }
  }

  void _erase() {
    setState(() {
      _undoStack.add([..._currentPolygon]); // Save current polygon for undo
      _undoStack.addAll(_polygons); // Save all polygons for undo
      _currentPolygon.clear();
      _polygons.clear();
      _redoStack.clear(); // Clear redo since erase is irreversible without undo
    });
  }

  List<List<List<double>>> convertPolygonsToListDouble({
    required List<List<Offset>>
        polygons, // تأكد من استخدام List<Offset> وليس List<List<Offset>>
    required double originalImageWidth,
    required double originalImageHeight,
    required double displayedImageWidth,
    required double displayedImageHeight,
  }) {
    List<List<List<double>>> polygonList = [];

    for (var polygon in polygons) {
      List<List<double>> convertedPolygon = polygon.map((point) {
        // التأكد من أن النقطة هي Offset وبالتالي يمكنك الوصول لـ dx و dy
        double originalX =
            point.dx * (originalImageWidth / displayedImageWidth);
        double originalY =
            point.dy * (originalImageHeight / displayedImageHeight);
        return [originalX, originalY];
      }).toList();

      polygonList.add(convertedPolygon);
    }

    return polygonList;
  }

  List<String> convertPolygonsToListString({
    required List<List<List<double>>> polygons,
    required double originalImageWidth,
    required double originalImageHeight,
    required double displayedImageWidth,
    required double displayedImageHeight,
  }) {
    List<String> polygonList = [];

    for (var polygon in polygons) {
      List<String> coordinates = polygon
          .map((point) =>
              '${point[0]}-${point[1]}') // تحويل النقاط إلى سلسلة على هيئة "x-y"
          .toList();
      polygonList.add(coordinates.join(","));
    }

    return polygonList;
  }

  List<List<List<int>>> convertFlatListToPolygons(
      List<String> flatList, List<int> pointCounts) {
    List<List<List<int>>> polygons = [];
    int index = 0;

    for (int count in pointCounts) {
      List<List<int>> polygon = [];
      for (int i = 0; i < count; i++) {
        double x = double.parse(flatList[index++]);
        double y = double.parse(flatList[index++]);
        polygon
            .add([x.round(), y.round()]); // ✅ نستخدم round أو toInt حسب ما تحب
      }
      polygons.add(polygon);
    }

    return polygons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 211, 211, 243),
        title: Center(
          child: Text(
            'Locate these $maxPolygons employees.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Color.fromARGB(255, 211, 211, 243),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              height: 80,
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _toolbarIconButton(Icons.undo, 'Undo', _undo),
                  _toolbarIconButton(Icons.redo, 'Redo', _redo),
                  _toolbarIconButton(Icons.delete, 'Clear All', _erase),
                ],
              ),
            ),
          ),
          SizedBox(height: 5),
          Expanded(
            child: InteractiveViewer(
              child: RepaintBoundary(
                key: repaintBoundaryKey,
                child: GestureDetector(
                  onTapDown: (details) {
                    _addPoint(details.localPosition);
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _currentDraggingPoint = details.localPosition;
                    });
                  },
                  onPanEnd: (details) {
                    setState(() {
                      _currentDraggingPoint = null;
                    });
                  },
                  child: SizedBox(
                    child: Stack(
                      children: [
                        Container(
                          key: _imageKey,
                          width: _originalImageWidth,
                          height: _originalImageHeight,
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 211, 211, 243),
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(imagePath),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        // رسم المضلعات
                        for (int i = 0; i < _polygons.length; i++)
                          CustomPaint(
                            painter: PolygonPainter(
                              _polygons[i],
                              true,
                              _polygonColors[i % _polygonColors.length],
                              null,
                              i + 1,
                            ),
                          ),
                        // رسم المضلع الحالي
                        if (_currentPolygon.isNotEmpty ||
                            _currentDraggingPoint != null)
                          CustomPaint(
                            painter: PolygonPainter(
                              [
                                ..._currentPolygon,
                                if (_currentDraggingPoint != null)
                                  _currentDraggingPoint!,
                              ],
                              false,
                              Colors.blue,
                              _currentDraggingPoint,
                              null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 200,
            padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 120),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 15,
                ),
              ),
              onPressed: () async {
                final RenderBox renderBox =
                    _imageKey.currentContext?.findRenderObject() as RenderBox;
                final Size displayedSize = renderBox.size;

                final double displayedImageWidth = displayedSize.width;
                final double displayedImageHeight = displayedSize.height;

                List<List<List<double>>> polygonDimensions =
                    convertPolygonsToListDouble(
                  polygons:
                      _polygons, // تأكد أن _polygons هو List<List<Offset>>
                  originalImageWidth: _originalImageWidth,
                  originalImageHeight: _originalImageHeight,
                  displayedImageWidth: displayedImageWidth,
                  displayedImageHeight: displayedImageHeight,
                );

                if (_polygons.isEmpty || _polygons.length != maxPolygons) {
                  _showDrawingConfirmationDialog();
                  return;
                }

                // تحويل الإحداثيات إلى int
                List<List<List<int>>> finalPolygons = polygonDimensions
                    .map((polygon) => polygon
                        .map((point) => [point[0].round(), point[1].round()])
                        .toList())
                    .toList();

                Map<String, dynamic> polygonsMap = {};
                for (int i = 0; i < finalPolygons.length; i++) {
                  final polygon = finalPolygons[i];
                  Map<String, Map<String, int>> pointsMap = {};
                  for (int j = 0; j < polygon.length; j++) {
                    pointsMap[j.toString()] = {
                      '0': polygon[j][0], // x
                      '1': polygon[j][1], // y
                    };
                  }
                  polygonsMap[i.toString()] = pointsMap;
                }

                print('Polygons as Map: $polygonsMap');

                // ترجع الإحداثيات مباشرة للشاشة السابقة (ChooseLocationScreen)
                Navigator.pop(context, {
                  'points': polygonsMap['0'],
                });
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarIconButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        IconButton(icon: Icon(icon, color: Colors.white), onPressed: onPressed),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

class PolygonPainter extends CustomPainter {
  final List<Offset> points;
  final bool isCompleted;
  final Color color;
  final Offset? draggingPoint;
  final int? polygonNumber; // Make this nullable

  PolygonPainter(this.points, this.isCompleted, this.color, this.draggingPoint,
      this.polygonNumber);

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Draw the polygon
    if (points.isNotEmpty) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var point in points) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, strokePaint);

      if (isCompleted) {
        final fillPaint = Paint()
          // ignore: deprecated_member_use
          ..color = Colors.black.withOpacity(0.5)
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, fillPaint);
      }

      // Draw the polygon number ONLY if it is completed
      if (polygonNumber != null) {
        final center = _calculatePolygonCenter(points);
        final textPainter = TextPainter(
          text: TextSpan(
            text: polygonNumber.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas,
            center - Offset(textPainter.width / 2, textPainter.height / 2));
      }
    }

    // Draw a dashed line while the user is dragging a point
    if (points.isNotEmpty && draggingPoint != null) {
      final dashedPaint = Paint()
        // ignore: deprecated_member_use
        ..color = Colors.grey.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      drawDashedLine(canvas, dashedPaint, points.last, draggingPoint!);
    }
  }

  Offset _calculatePolygonCenter(List<Offset> points) {
    double sumX = 0, sumY = 0;
    for (var point in points) {
      sumX += point.dx;
      sumY += point.dy;
    }
    return Offset(sumX / points.length, sumY / points.length);
  }

  void drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    const double dashWidth = 10;
    const double dashSpace = 5;
    double distance = (end - start).distance;
    double dashCount = distance / (dashWidth + dashSpace);
    Offset direction = (end - start) / distance;

    for (int i = 0; i < dashCount; i++) {
      Offset drawStart = start + direction * (i * (dashWidth + dashSpace));
      Offset drawEnd = drawStart + direction * dashWidth;
      canvas.drawLine(drawStart, drawEnd, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
