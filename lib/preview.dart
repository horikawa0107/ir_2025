// import 'package:flutter/material.dart';
// import 'detector.dart';
//
// class DetectorPreview extends StatefulWidget {
//   final DetectionList detectionList;
//
//   const DetectorPreview({
//     super.key,
//     required this.detectionList,
//   });
//
//   @override
//   _DetectorPreviewState createState() => _DetectorPreviewState();
// }
//
// class _DetectorPreviewState extends State<DetectorPreview> {
//   @override
//   Widget build(BuildContext context) {
//     return CustomPaint(
//       size: Size.infinite,
//       painter: _DetectorPreviewPainter(widget.detectionList),
//     );
//   }
// }
//
// class _DetectorPreviewPainter extends CustomPainter {
//   final DetectionList detections;
//
//   _DetectorPreviewPainter(this.detections);
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     // バウンディングボックス用のペイント（太い赤線）
//     final boxPaint = Paint()
//       ..color = Colors.red
//       ..strokeWidth = 3.0
//       ..style = PaintingStyle.stroke;
//
//     // 角マーカー用のペイント（より太い線）
//     final cornerPaint = Paint()
//       ..color = Colors.red
//       ..strokeWidth = 4.0
//       ..style = PaintingStyle.stroke;
//
//     // テキスト背景用のペイント（半透明の黒）
//     final textBackgroundPaint = Paint()
//       ..color = Colors.black.withOpacity(0.8)
//       ..style = PaintingStyle.fill;
//
//     // テキストスタイル（より大きく見やすく）
//     const TextStyle textStyle = TextStyle(
//       color: Colors.white,
//       fontSize: 14.0,
//       fontWeight: FontWeight.bold,
//     );
//
//     for (var i = 0; i < detections.detections.length; i++) {
//       var detection = detections.detections[i];
//
//       // バウンディングボックスの計算
//       final rect = detection.scaledRect(size.width, size.height);
//
//       // バウンディングボックスの描画
//       canvas.drawRect(rect, boxPaint);
//
//       // 角マーカーの描画（四隅にL字型マーカー）
//       final cornerLength = 20.0;
//
//       // 左上角
//       canvas.drawLine(
//         Offset(rect.left, rect.top),
//         Offset(rect.left + cornerLength, rect.top),
//         cornerPaint,
//       );
//       canvas.drawLine(
//         Offset(rect.left, rect.top),
//         Offset(rect.left, rect.top + cornerLength),
//         cornerPaint,
//       );
//
//       // 右上角
//       canvas.drawLine(
//         Offset(rect.right, rect.top),
//         Offset(rect.right - cornerLength, rect.top),
//         cornerPaint,
//       );
//       canvas.drawLine(
//         Offset(rect.right, rect.top),
//         Offset(rect.right, rect.top + cornerLength),
//         cornerPaint,
//       );
//
//       // 左下角
//       canvas.drawLine(
//         Offset(rect.left, rect.bottom),
//         Offset(rect.left + cornerLength, rect.bottom),
//         cornerPaint,
//       );
//       canvas.drawLine(
//         Offset(rect.left, rect.bottom),
//         Offset(rect.left, rect.bottom - cornerLength),
//         cornerPaint,
//       );
//
//       // 右下角
//       canvas.drawLine(
//         Offset(rect.right, rect.bottom),
//         Offset(rect.right - cornerLength, rect.bottom),
//         cornerPaint,
//       );
//       canvas.drawLine(
//         Offset(rect.right, rect.bottom),
//         Offset(rect.right, rect.bottom - cornerLength),
//         cornerPaint,
//       );
//
//       // ラベルテキストの準備
//       final labelText = '📱 ${detection.label}';
//       final confidenceText = '${(detection.confidence * 100).toStringAsFixed(1)}%';
//
//       final textSpan = TextSpan(
//         children: [
//           TextSpan(
//             text: '$labelText\n',
//             style: textStyle,
//           ),
//           TextSpan(
//             text: confidenceText,
//             style: textStyle.copyWith(fontSize: 12.0),
//           ),
//         ],
//       );
//
//       final textPainter = TextPainter(
//         text: textSpan,
//         textDirection: TextDirection.ltr,
//         textAlign: TextAlign.center,
//       );
//       textPainter.layout();
//
//       // テキストの位置を計算（バウンディングボックスの上部）
//       final textWidth = textPainter.width;
//       final textHeight = textPainter.height;
//       final padding = 8.0;
//
//       // テキストボックスの位置を調整（画面外に出ないように）
//       var textX = rect.left;
//       var textY = rect.top - textHeight - padding * 2;
//
//       // 画面上部に収まらない場合は下に配置
//       if (textY < 0) {
//         textY = rect.bottom + padding;
//       }
//
//       // 画面右端に収まらない場合は左にシフト
//       if (textX + textWidth + padding * 2 > size.width) {
//         textX = size.width - textWidth - padding * 2;
//       }
//
//       // 画面左端より左に行かないように
//       if (textX < 0) {
//         textX = 0;
//       }
//
//       // テキスト背景の描画（角丸四角形）
//       final backgroundRect = RRect.fromRectAndRadius(
//         Rect.fromLTWH(
//           textX - padding,
//           textY - padding,
//           textWidth + padding * 2,
//           textHeight + padding * 2,
//         ),
//         const Radius.circular(6.0),
//       );
//       canvas.drawRRect(backgroundRect, textBackgroundPaint);
//
//       // テキストの描画
//       textPainter.paint(canvas, Offset(textX, textY));
//
//       // 検出番号を右上に表示
//       if (detections.detections.length > 1) {
//         final numberText = '${i + 1}';
//         final numberTextSpan = TextSpan(
//           text: numberText,
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 16.0,
//             fontWeight: FontWeight.bold,
//           ),
//         );
//
//         final numberTextPainter = TextPainter(
//           text: numberTextSpan,
//           textDirection: TextDirection.ltr,
//         );
//         numberTextPainter.layout();
//
//         // 番号の背景（円形）
//         final numberRadius = 12.0;
//         final numberCenter = Offset(rect.right - numberRadius, rect.top + numberRadius);
//
//         final numberBackgroundPaint = Paint()
//           ..color = Colors.red
//           ..style = PaintingStyle.fill;
//
//         canvas.drawCircle(numberCenter, numberRadius, numberBackgroundPaint);
//
//         // 番号のテキスト
//         numberTextPainter.paint(
//           canvas,
//           Offset(
//             numberCenter.dx - numberTextPainter.width / 2,
//             numberCenter.dy - numberTextPainter.height / 2,
//           ),
//         );
//       }
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'detector.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';


class DetectorPreview extends StatefulWidget {
  final DetectionList detectionList;
  final List<Pose>? poses;
  final double originalImageWidth;
  final double originalImageHeight;

  const DetectorPreview({
    super.key,
    required this.detectionList,
    this.poses,
    required this.originalImageWidth,
    required this.originalImageHeight,
  });

  @override
  _DetectorPreviewState createState() => _DetectorPreviewState();
}

class _DetectorPreviewState extends State<DetectorPreview> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> _addDataToFirestore() async {
    await firestore.collection('messages').add({
      'text': 'A室：スマホの内職を発見',
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('Document added!');
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _DetectorPreviewPainter(
        widget.detectionList,
        widget.poses,
        widget.originalImageWidth,
        widget.originalImageHeight,
        _addDataToFirestore,  // 👈 コールバックを渡す
      ),
    );
  }
}

//   @override
//   Widget build(BuildContext context) {
//     return CustomPaint(
//       size: Size.infinite,
//       painter: _DetectorPreviewPainter(widget.detectionList, widget.poses,widget.originalImageWidth,widget.originalImageHeight), // ← poses 追加
//     );
//   }
// }

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

      // ラベルテキスト
      final labelText = '📱 ${detection.label}';
      final confidenceText = '${(detection.confidence * 100).toStringAsFixed(1)}%';
      final textSpan = TextSpan(
        children: [
          TextSpan(text: '$labelText\n', style: textStyle),
          TextSpan(text: confidenceText, style: textStyle.copyWith(fontSize: 12.0)),
        ],
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
        textAlign: TextAlign.center,
      );

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
                // 距離が近い場合はテキストを描画
                final label = type == PoseLandmarkType.leftIndex ? 'Left Index' : 'Right Index';
                final span = TextSpan(
                  text: label,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
                textPainter.text = span;
                textPainter.layout();
                if (!_called) {
                  _called = true; // 連続で呼ばないようにフラグ
                  onProximityDetected();
                }
                textPainter.paint(
                  canvas,
                  Offset(scaledX - textPainter.width / 2, scaledY - 20),
                );
              }
            }
          }
        }
      }
    }
    else{
      print('_poses is empty');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}