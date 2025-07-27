import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'detector.dart';

class ProximityResult {
  final PoseLandmarkType landmarkType;
  final double distance;
  final int detectionIndex;

  ProximityResult(this.landmarkType, this.distance, this.detectionIndex);
}

List<ProximityResult> calculateProximity({
  required DetectionList detectionList,
  required List<Pose>? poses,
  required double originalImageWidth,
  required double originalImageHeight,
  required double canvasWidth,
  required double canvasHeight,
}) {
  if (poses == null) return [];

  final results = <ProximityResult>[];

  for (final pose in poses) {
    for (final entry in pose.landmarks.entries) {
      final type = entry.key;
      if (type != PoseLandmarkType.rightIndex && type != PoseLandmarkType.leftIndex) {
        continue;
      }

      final landmark = entry.value;

      final scaledX = landmark.x / originalImageWidth * canvasWidth;
      final scaledY = landmark.y / originalImageHeight * canvasHeight;

      for (var i = 0; i < detectionList.detections.length; i++) {
        final detection = detectionList.detections[i];
        final rect = detection.scaledRect(canvasWidth, canvasHeight);
        final centerX = (rect.left + rect.right) / 2;
        final centerY = (rect.top + rect.bottom) / 2;

        final dx = scaledX - centerX;
        final dy = scaledY - centerY;
        final distance = sqrt(dx * dx + dy * dy);

        results.add(ProximityResult(type, distance, i));
      }
    }
  }

  return results;
}