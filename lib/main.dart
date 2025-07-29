import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detector.dart'; // スマホ検知クラス

// ページインジケーター
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'preview.dart';
import 'firebase_options.dart';


// void main() => runApp(const MyApp());
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '内職検出アプリ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainPageView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
class MainPageView extends StatefulWidget {
  const MainPageView({super.key});

  @override
  State<MainPageView> createState() => _MainPageViewState();
}

class _MainPageViewState extends State<MainPageView> {
  final PageController _controller = PageController();

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          HomePage(),
          MessagesPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _controller.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: '通知',
          ),
        ],
      ),
    );
  }
}
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> implements DetectorListener {
  final ImagePicker _picker = ImagePicker();
  Detector? _detector;
  File? _imageFile;
  List<Pose>? _poses;
  DetectionList _detections = DetectionList(detections: []);
  bool _isLoading = false;
  String _statusMessage = 'AI モデルを初期化中...';
  ui.Image? _uiImage;
  double? _originalImageWidth;
  double? _originalImageHeight;

  @override
  void initState() {
    super.initState();
    _initializeDetector();
  }
  Future<void> _initializeDetector() async {
    try {
      _detector = await Detector.create(
        modelPath: 'assets/model.tflite',
        labelsPath: 'assets/labels.txt',
        listener: this,
        confidenceThreshold: 0.3,
      );

      if (mounted) {
        setState(() {
          _statusMessage = '写真を選択して内職を検出してください';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = '初期化エラー: $e';
        });
      }
    }
  }


  /// ギャラリーから画像を選択し検出を実行
  Future<void> _pickFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _loadUiImage(File file) async {
    final bytes = await file.readAsBytes();
    final image = await decodeImageFromList(bytes);
    setState(() {
      _uiImage = image;
      _originalImageWidth = image.width.toDouble();
      _originalImageHeight = image.height.toDouble();
    });
  }

  Future<void> _detectPose(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final poseDetector = PoseDetector(options: PoseDetectorOptions());
    final poses = await poseDetector.processImage(inputImage);

    setState(() {
      _poses = poses;
    });
    print('pose: $_poses');
    // === ログ表示 ===
    for (int i = 0; i < poses.length; i++) {
      final pose = poses[i];
      print('Pose #$i:');
      pose.landmarks.forEach((type, landmark) {
        print(
            '  ${type.name}: (x: ${landmark.x.toStringAsFixed(2)}, y: ${landmark.y.toStringAsFixed(2)}, z: ${landmark.z.toStringAsFixed(2)})');
      });
    }

    await poseDetector.close();
  }

  /// カメラで撮影し検出を実行
  Future<void> _pickFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_detector == null || !_detector!.isInitialized()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI モデルの初期化が完了していません')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _statusMessage = '画像を処理中...';
      });

      final XFile? picked = await _picker.pickImage(source: source);
      if (picked == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = '写真を選択して内職を検出してください';
        });
        return;
      }

      final file = File(picked.path);
      setState(() {
        _imageFile = file;
        _detections = DetectionList(detections: []);
        _statusMessage = '内職を検出中...';
      });
      await _loadUiImage(file);

      // 静止画検出を実行
      await _detectPose(file);
      await _detector!.detectWithImageProvider(FileImage(file));



    } catch (e) {
      setState(() {
        _statusMessage = 'エラー: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像処理エラー: $e')),
      );
    }
  }

  /// 検出結果コールバック
  @override
  void onDetect(DetectionList result) {
    if (mounted) {
      setState(() {
        // スマホ関連のクラスを検出（cell phone, mobile phone等）
        var phoneDetections = result.detections.where((d) =>
        d.label.toLowerCase().contains('phone') ||
            d.label.toLowerCase().contains('cell') ||
            d.label.toLowerCase().contains('mobile')
        ).toList();

        _detections = DetectionList(detections: phoneDetections)
            .filterByConfidence(0.3)
            .nms(0.5); // 重複する検出結果を統合

        _isLoading = false;

        if (_detections.isEmpty) {
          _statusMessage = '画像を解析しました';
        } else {
          _statusMessage = '画像を解析しました';
        }
      });
    }
  }

  Widget _buildImageArea() {
    if (_imageFile == null) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '写真がありません',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 400,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 元画像の表示
            Image.file(
              _imageFile!,
              fit: BoxFit.contain,
            ),
            // 検出結果のオーバーレイ描画
            if (!_isLoading )
              DetectorPreview(detectionList: _detections,poses: _poses,originalImageWidth: _originalImageWidth!,
                  originalImageHeight: _originalImageHeight!,file_image:_uiImage! ),
            // ローディング表示
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultInfo() {
    if (_detections.isEmpty) {
      return Container();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '検出結果',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ...(_detections.detections.map((detection) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    detection.label,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📱内職検知アプリ'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ステータスメッセージ
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: Row(
                children: [
                  Icon(
                    _isLoading ? Icons.hourglass_empty : Icons.info,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 画像選択ボタン
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('ギャラリーから選択'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('カメラで撮影'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 画像表示エリア
            _buildImageArea(),
            const SizedBox(height: 16),

            // 検出結果情報
            _buildResultInfo(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _detector?.close();
    super.dispose();
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

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('通知ページ')),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('notions') // ← コレクション名を合わせてね
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
              final imageUrl = data['imageUrl'] as String?;

              return ListTile(
                leading: imageUrl != null
                    ? Image.network(
                  imageUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                )
                    : const Icon(Icons.image_not_supported),
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
