import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// Firestore 用
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PoseDetectionPage(),
    );
  }
}

class PoseDetectionPage extends StatefulWidget {
  const PoseDetectionPage({super.key});

  @override
  State<PoseDetectionPage> createState() => _PoseDetectionPageState();
}

class _PoseDetectionPageState extends State<PoseDetectionPage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  List<Pose>? _poses;

  ui.Image? _loadedImage;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final data = await pickedFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      setState(() {
        _imageFile = imageFile;
        _loadedImage = frame.image;
        _poses = null;
      });
      await _detectPose(imageFile);
    }
  }

  Future<void> _detectPose(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final poseDetector = PoseDetector(options: PoseDetectorOptions());
    final poses = await poseDetector.processImage(inputImage);

    setState(() {
      _poses = poses;
    });

    await poseDetector.close();
  }

  Future<void> _addDataToFirestore() async {
    await firestore.collection('messages').add({
      'text': 'Hello Firestore!',
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('Document added!');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('データを送信しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pose Detection')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Pick Image'),
                  ),
                  if (_loadedImage != null)
                    Expanded(
                      child: FittedBox(
                        child: SizedBox(
                          width: _loadedImage!.width.toDouble(),
                          height: _loadedImage!.height.toDouble(),
                          child: CustomPaint(
                            painter: PosePainter(_loadedImage!, _poses),
                          ),
                        ),
                      ),
                    )
                  else
                    const Text('No image selected'),
                ],
              ),
            ),
          ),
          // 🔽 Firestore 送信ボタンを下部に配置
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addDataToFirestore,
                child: const Text('Add to Firestore'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PosePainter extends CustomPainter {
  final ui.Image image;
  final List<Pose>? poses;

  PosePainter(this.image, this.poses);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawImage(image, Offset.zero, paint);

    if (poses == null) return;

    final landmarkPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final armLandmarks = {
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
    };

    for (final pose in poses!) {
      for (final landmarkEntry in pose.landmarks.entries) {
        final type = landmarkEntry.key;
        final landmark = landmarkEntry.value;

        if (armLandmarks.contains(type)) {
          final x = landmark.x;
          final y = landmark.y;
          canvas.drawCircle(Offset(x, y), 20, landmarkPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.poses != poses;
  }
}