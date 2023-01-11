import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'camera_view.dart';
import 'painters/face_detector_painter.dart';

class FaceDetectorView extends StatefulWidget {
  @override
  _FaceDetectorViewState createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: true,
      enableLandmarks: false,
      enableTracking: true,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.fast,
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;

  String rightEye = "Fit your face in the box";
  String leftEye = "Fit your face in the box";

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: 'Face Detector',
      customPaint: _customPaint,
      text: _text,
      onImage: (inputImage) {
        processImage(inputImage);
        if (kDebugMode) {
          // print(inputImage.toJson());
        }
      },
      initialDirection: CameraLensDirection.front,
      rightEyesStatus: rightEye,
      leftEyesStatus: leftEye,
    );
  }

  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final faces = await _faceDetector.processImage(inputImage);
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = FaceDetectorPainter(
          faces,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
      _customPaint = CustomPaint(painter: painter);

      for (final face in faces) {
        if (face.leftEyeOpenProbability! >= 0.5) {
          setState(() {
            rightEye = "Right Eye is Open";
          });
          print("Eye Open");
        } else {
          setState(() {
            rightEye = "Right Eye is Closed";
          });
          print("Eye Close");
        }
        if (face.rightEyeOpenProbability! >= 0.5) {
          setState(() {
            leftEye = "Left Eye is Open";
          });
        } else {
          setState(() {
            leftEye = "Left Eye is Closed";
          });
          print("Eye Close");
        }
      }
    } else {
      String text = 'Faces found: ${faces.length}\n\n';
      for (final face in faces) {
        text += 'face: ${face.boundingBox}\n\n';
      }
      _text = text;
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
