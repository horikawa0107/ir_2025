import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'detector.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';


class DetectorPreview extends StatefulWidget {
  final DetectionList detectionList;
  final List<Pose>? poses;
  final double originalImageWidth;
  final double originalImageHeight;
  final ui.Image file_image;

  const DetectorPreview({
    super.key,
    required this.detectionList,
    this.poses,
    required this.originalImageWidth,
    required this.originalImageHeight,
    required this.file_image,
  });

  @override
  _DetectorPreviewState createState() => _DetectorPreviewState();
}

class _DetectorPreviewState extends State<DetectorPreview> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool _proximityDetected = false;

  // Future<void> _addDataToFirestore() async {
  //   await firestore.collection('messages').add({
  //     'text': 'A室：スマホの内職を発見',
  //     'createdAt': FieldValue.serverTimestamp(),
  //   });
  //   print('Document added!');
  // }

  Future<void> _sendDetectionAlert() async {
    final storage = FirebaseStorage.instance;
    final firestore = FirebaseFirestore.instance;

    try {
      // 1️⃣ ファイル名を UUID で決める
      final String uniqueId = const Uuid().v4();
      final String fileName = "detections/$uniqueId.png";

      // 2️⃣ ui.Image → ByteData → File に変換
      final byteData = await widget.file_image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        print('Failed to convert image to ByteData');
        return;
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$uniqueId.png');
      await file.writeAsBytes(pngBytes);

      // 3️⃣ Storage にアップロード
      final ref = storage.ref().child(fileName);
      final uploadTask = await ref.putFile(file);

      // 4️⃣ アップロード後に downloadURL を取得
      final downloadUrl = await ref.getDownloadURL();

      // 5️⃣ Firestore にメッセージと画像 URL を一緒に保存
      await firestore.collection('notions').add({
        'text': 'A室：スマホの内職を発見',
        'imageUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Message and image uploaded!');
    } catch (e) {
      print('Error during alert send: $e');
    }
  }


  // Future<void> _uploadImageToFirebase() async {
  //   final FirebaseStorage storage = FirebaseStorage.instance;
  //
  //   try {
  //     // ui.Image を PNG にエンコード
  //     final ByteData? byteData = await widget.file_image.toByteData(format: ui.ImageByteFormat.png);
  //     if (byteData == null) {
  //       print('Failed to convert image to ByteData');
  //       return;
  //     }
  //     final Uint8List pngBytes = byteData.buffer.asUint8List();
  //
  //     // 一時ファイルとして保存
  //     final tempDir = await getTemporaryDirectory();
  //     final file = File('${tempDir.path}/detected_image.png');
  //     await file.writeAsBytes(pngBytes);
  //     // Firebase Storage にアップロード
  //     final ref = storage.ref().child('detections/${DateTime.now().millisecondsSinceEpoch}.png');
  //     await ref.putFile(file);
  //
  //     print('Image uploaded to Firebase Storage!');
  //   } catch (e) {
  //     print('Error uploading image: $e');
  //   }
  // }
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _DetectorPreviewPainter(
        widget.detectionList,
        widget.poses,
        widget.originalImageWidth,
        widget.originalImageHeight,
        _sendDetectionAlert, /// 👈 コールバックを渡す
      ),
    );
  }
}



class _DetectorPreviewPainter extends CustomPainter {
  final DetectionList detections;
  final List<Pose>? poses; // ← 追加
  final double originalImageWidth;
  final double originalImageHeight;
  final Future<void> Function() onProximityDetected;

  // _DetectorPreviewPainter(this.detections, this.poses, this.originalImageWidth, this.originalImageHeight);

  _DetectorPreviewPainter(
      this.detections,
      this.poses,
      this.originalImageWidth,
      this.originalImageHeight,
      this.onProximityDetected,
      );

  bool _called = false;

  @override
  void paint(Canvas canvas, Size size) {
    // バウンディングボックス用のペイント
    final boxPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final cornerPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final textBackgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    const TextStyle textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
    );

    // スマホ検出結果を描画
    for (var i = 0; i < detections.detections.length; i++) {
      var detection = detections.detections[i];
      final rect = detection.scaledRect(size.width, size.height);
      canvas.drawRect(rect, boxPaint);

      final cornerLength = 20.0;

      // 各角をL字型で描画
      canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left + cornerLength, rect.top), cornerPaint);
      canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left, rect.top + cornerLength), cornerPaint);
      canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right - cornerLength, rect.top), cornerPaint);
      canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.top + cornerLength), cornerPaint);
      canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left + cornerLength, rect.bottom), cornerPaint);
      canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left, rect.bottom - cornerLength), cornerPaint);
      canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right - cornerLength, rect.bottom), cornerPaint);
      canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right, rect.bottom - cornerLength), cornerPaint);

      // ラベルテキスト（信頼度を削除）
      final labelText = '📱 ${detection.label}';
      final textSpan = TextSpan(
        text: labelText,
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      final textWidth = textPainter.width;
      final textHeight = textPainter.height;
      final padding = 8.0;

      var textX = rect.left;
      var textY = rect.top - textHeight - padding * 2;
      if (textY < 0) textY = rect.bottom + padding;
      if (textX + textWidth + padding * 2 > size.width) {
        textX = size.width - textWidth - padding * 2;
      }
      if (textX < 0) textX = 0;

      final backgroundRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(textX - padding, textY - padding, textWidth + padding * 2, textHeight + padding * 2),
        const Radius.circular(6.0),
      );
      canvas.drawRRect(backgroundRect, textBackgroundPaint);
      textPainter.paint(canvas, Offset(textX, textY));

      if (detections.detections.length > 1) {
        final numberText = '${i + 1}';
        final numberTextSpan = TextSpan(
          text: numberText,
          style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
        );
        final numberTextPainter = TextPainter(text: numberTextSpan, textDirection: TextDirection.ltr);
        numberTextPainter.layout();
        final numberRadius = 12.0;
        final numberCenter = Offset(rect.right - numberRadius, rect.top + numberRadius);

        final numberBackgroundPaint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;
        canvas.drawCircle(numberCenter, numberRadius, numberBackgroundPaint);

        numberTextPainter.paint(
          canvas,
          Offset(numberCenter.dx - numberTextPainter.width / 2, numberCenter.dy - numberTextPainter.height / 2),
        );
      }
    }

    // ======== ここから Pose の描画 ========
    if (poses != null) {
      final landmarkPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill
        ..strokeWidth = 4.0;

      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
      );

      bool proximityDetected = false;

      for (final pose in poses!) {
        for (final entry in pose.landmarks.entries) {
          final type = entry.key;
          final landmark = entry.value;

          if (type == PoseLandmarkType.leftIndex || type == PoseLandmarkType.rightIndex) {
            final scaledX = landmark.x / originalImageWidth * size.width;
            final scaledY = landmark.y / originalImageHeight * size.height;

            canvas.drawCircle(Offset(scaledX, scaledY), 4.0, landmarkPaint);

            // === スマホ矩形との距離を判定 ===
            for (var detection in detections.detections) {
              final rect = detection.scaledRect(size.width, size.height);

              final centerX = (rect.left + rect.right) / 2;
              final centerY = (rect.top + rect.bottom) / 2;

              final dx = scaledX - centerX;
              final dy = scaledY - centerY;
              final distance = sqrt(dx * dx + dy * dy);

              if (distance < 50) {
                proximityDetected = true;
                if (!_called) {
                  _called = true; // 連続で呼ばないようにフラグ
                  onProximityDetected();
                }
              }
            }
          }
        }
      }

      // 内職発見を写真の左上に表示
      if (proximityDetected) {
        final label = '内職発見';
        final span = TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.orangeAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.text = span;
        textPainter.layout();

        textPainter.paint(canvas, const Offset(10, 10));
      }
    }
    else{
      print('_poses is empty');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
