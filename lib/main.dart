import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' as vector;

void main() => runApp(const MaterialApp(home: Scaffold(body: CreateApp())));

num map(num value,
        [num iStart = 0, num iEnd = pi * 2, num oStart = 0, num oEnd = 1.0]) =>
    ((oEnd - oStart) / (iEnd - iStart)) * (value - iStart) + oStart;

class CreateApp extends StatefulWidget {
  const CreateApp({super.key});

  @override
  CreateAppState createState() => CreateAppState();
}

class CreateAppState extends State<CreateApp> with TickerProviderStateMixin {
  final List<Widget> _list = <Widget>[];
  final double _size = 140.0;

  double _x = pi * 0.25, _y = pi * 0.25;
  double _targetX = 0.0;
  double _targetY = 0.0;

  late AnimationController _controller;
  late Animation<double> _animation;

  int get size => _list.length;

  late Future<List<ui.Image>> _texturesFuture;

  final Map<int, List<double>> _diceTargets = {
    1: [0.0014453505001021938, 6.281445350500216],
    2: [0.0030651695470051976, 3.1430651695470244],
    3: [6.277241538843701, 4.710574872176998],
    4: [3.1424590163327863, 4.715792349666156],
    5: [1.5651143068670197, 3.14163294737987],
    6: [4.709375064263648, 3.1427083975969454],
  };

  Future<ui.Image> loadImage(String assetPath) async {
    // Load the image data as bytes
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();

    // Decode the bytes into an image
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image image) {
      completer.complete(image);
    });

    return completer.future;
  }

  double _lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }

  void _animateToDice(int diceNumber) {
    if (_diceTargets.containsKey(diceNumber)) {
      final target = _diceTargets[diceNumber]!;
      setState(() {
        _targetX = target[0];
        _targetY = target[1];
        _controller.forward(from: 0.0);
      });
    }
  }

  static const int skinType = 1;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticInOut,
    );
    _controller.addListener(() {
      setState(() {
        final double progress = _animation.value;
        _x = _lerp(_x, _targetX, progress);
        _y = _lerp(_y, _targetY, progress);
      });
    });

    //dice positions:
    //dice 1 - 0.0014453505001021938, 6.281445350500216
    //dice 2 - 0.0030651695470051976, 3.1430651695470244
    //dice 3 - 6.277241538843701, 4.710574872176998
    //dice 4 - 3.1424590163327863, 4.715792349666156
    //dice 5 - 1.5651143068670197, 3.14163294737987
    //dice 6 - 4.709375064263648, 3.1427083975969454

    _texturesFuture = Future.wait([
      loadImage('assets/skin$skinType/face1.png'),
      loadImage('assets/skin$skinType/face2.png'),
      loadImage('assets/skin$skinType/face3.png'),
      loadImage('assets/skin$skinType/face4.png'),
      loadImage('assets/skin$skinType/face5.png'),
      loadImage('assets/skin$skinType/face6.png'),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rollDice() {
    //_controller.forward(from: 0.0);
    _x = pi * 0.25;
    _y = pi * 0.25;
    _animateToDice(6);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      GestureDetector(
        onPanUpdate: (DragUpdateDetails u) => setState(() {
          _x = (_x + -u.delta.dy / 150) % (pi * 2);
          _y = (_y + -u.delta.dx / 150) % (pi * 2);
        }),
        child: Center(
          child: Container(
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Cube(
                  color: Colors.blue,
                  x: _x,
                  y: _y,
                  size: _size,
                  skinType: skinType,
                ),
                SizedBox(width: _size * 0.6),
                Cube(
                  color: Colors.blue,
                  x: _x,
                  y: _y,
                  size: _size,
                  skinType: skinType,
                ),
              ],
            ),
          ),
        ),
      ),

      // Roll Dice Button
      Positioned(
        bottom: 20,
        left: 20,
        child: FloatingActionButton(
          onPressed: () {
            debugPrint("$_x, $_y");
          },
          child: const Icon(Icons.map),
        ),
      ),
      Positioned(
        bottom: 20,
        right: 20,
        child: FloatingActionButton(
          onPressed: _rollDice,
          child: const Icon(Icons.casino),
        ),
      ),
      Transform.translate(
        offset: const Offset(0, -180),
        child: Center(
          child: Text("X: $_x Y: $_y"),
        ),
      ),
    ]);
  }
}

class Cube extends StatelessWidget {
  const Cube(
      {super.key,
      required this.x,
      required this.y,
      required this.color,
      required this.size,
      required this.skinType,
      this.rainbow = false});

  static const double _halfPi = pi / 2, _oneHalfPi = pi + pi / 2;

  final double x, y, size;
  final Color color;
  final bool rainbow;
  final int skinType;

  @override
  Widget build(BuildContext context) {
    final visibleFaces = _calculateVisibleFaces();

    return Center(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..rotateX(x)
          ..rotateY(y),
        child: Stack(
          children: <Widget>[
            if (visibleFaces.contains(1))
              _side(
                  translateX: 0,
                  translateY: 0,
                  translateZ: -size / 2,
                  sideNumber: 1,
                  skinType: skinType), // Front
            if (visibleFaces.contains(2))
              _side(
                  translateX: 0,
                  translateY: 0,
                  translateZ: size / 2,
                  rotateY: pi,
                  sideNumber: 2,
                  skinType: skinType), // Back
            if (visibleFaces.contains(3))
              _side(
                  translateX: -size / 2,
                  translateY: 0,
                  translateZ: 0,
                  rotateY: -_halfPi,
                  sideNumber: 3,
                  skinType: skinType), // Left
            if (visibleFaces.contains(4))
              _side(
                  translateX: size / 2,
                  translateY: 0,
                  translateZ: 0,
                  rotateY: _halfPi,
                  sideNumber: 4,
                  skinType: skinType), // Right
            if (visibleFaces.contains(5))
              _side(
                  translateX: 0,
                  translateY: -size / 2,
                  translateZ: 0,
                  rotateX: _halfPi,
                  sideNumber: 5,
                  skinType: skinType), // Top
            if (visibleFaces.contains(6))
              _side(
                  translateX: 0,
                  translateY: size / 2,
                  translateZ: 0,
                  rotateX: -_halfPi,
                  sideNumber: 6,
                  skinType: skinType), // Bottom
          ],
        ),
      ),
    );
  }

  List<int> _calculateVisibleFaces() {
    List<int> visibleFaces = [];

    // Define face normals for each face
    final faceNormals = {
      1: vector.Vector3(0, 0, -1), // Front
      2: vector.Vector3(0, 0, 1), // Back
      3: vector.Vector3(-1, 0, 0), // Left
      4: vector.Vector3(1, 0, 0), // Right
      5: vector.Vector3(0, -1, 0), // Top
      6: vector.Vector3(0, 1, 0), // Bottom
    };

    // Compute rotation matrix
    final vector.Matrix4 rotation = vector.Matrix4.identity()
      ..rotateX(x)
      ..rotateY(y);

    // Check each face
    for (var entry in faceNormals.entries) {
      final faceNumber = entry.key;
      final normal = entry.value;

      // Rotate the normal vector by the rotation matrix
      final rotatedNormal = rotation.transform3(normal);

      // Determine visibility by checking if the rotated normal has a positive Z value
      // (This implies the face is facing towards the viewer)
      if (rotatedNormal.z < 0) {
        visibleFaces.add(faceNumber);
      }
    }

    return visibleFaces;
  }

  Widget _side({
    required double translateX,
    required double translateY,
    required double translateZ,
    double rotateX = 0,
    double rotateY = 0,
    double rotateZ = 0,
    required int sideNumber,
    required int skinType,
  }) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..translate(translateX, translateY, translateZ)
        ..rotateX(rotateX)
        ..rotateY(rotateY)
        ..rotateZ(rotateZ),
      child: Container(
        alignment: Alignment.center,
        constraints: BoxConstraints.expand(width: size, height: size),
        color: color,
        foregroundDecoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            border: Border.all(
                width: 0.8,
                color: rainbow ? color.withOpacity(0.9) : Colors.black)),
        child: Center(
            child: /*Text(
            sideNumber.toString(),
            style: TextStyle(color: Colors.white, fontSize: 30),
          ),*/
                Image.asset("assets/skin$skinType/face$sideNumber.png")),
      ),
    );
  }
}
