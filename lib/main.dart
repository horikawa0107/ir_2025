import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// Firestore
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ページインジケーター
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
      title: 'Pose & Firestore Demo',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            children: const [
              PoseDetectionPage(),
              MessagesPage(),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: 2,
                effect: WormEffect(
                  dotHeight: 12,
                  dotWidth: 12,
                  activeDotColor: Colors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------
// PoseDetectionPage
// ----------------------------

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
      'text': 'A室：スマホの内職を発見',
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('Document added!');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('データを送信')),
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
                    child: const Text('画像を選択'),
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
          // 下部の Firestore 送信ボタン
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

// ----------------------------
// MessagesPage
// ----------------------------

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('通知ページ')),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading data'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No messages yet'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final text = data['text'] ?? 'No text';
              final timestamp = data['createdAt'] != null
                  ? (data['createdAt'] as Timestamp).toDate().toString()
                  : 'No timestamp';

              return ListTile(
                title: Text(text),
                subtitle: Text(timestamp),
              );
            },
          );
        },
      ),
    );
  }
}