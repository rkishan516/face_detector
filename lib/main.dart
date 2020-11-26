/*
 * Created by Rishit Dagli on 2/13/20 1:25 PM
 * Copyright (c) 2020.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * You may obtain a copy of the License at-
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License
 */

import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:face_recog/utils.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(
      MaterialApp(
        title: 'Face Recognition',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: FacePage(),
      ),
    );

class FacePage extends StatefulWidget {
  @override
  _FacePageState createState() => _FacePageState();
}

class _FacePageState extends State<FacePage> {
  File _imageFile;
  List<Face> _faces;
  bool isLoading = false, _isDetecting = false;
  CameraController _camera;
  CameraLensDirection _direction = CameraLensDirection.back;
  String text = '';

  @override
  void initState() {
    _faces = List<Face>();
    _initializeCamera();
    super.initState();
  }

  Future<CameraDescription> _getCamera(CameraLensDirection dir) async {
    return await availableCameras().then(
      (List<CameraDescription> cameras) => cameras.firstWhere(
        (CameraDescription camera) => camera.lensDirection == dir,
      ),
    );
  }

  void _toggleCameraDirection() async {
    if (_direction == CameraLensDirection.back) {
      _direction = CameraLensDirection.front;
    } else {
      _direction = CameraLensDirection.back;
    }
    await _camera.stopImageStream();
    await _camera.dispose();

    setState(() {
      _camera = null;
    });

    _initializeCamera();
  }

  _initializeCamera() async {
    CameraDescription description = await _getCamera(_direction);
    _camera = CameraController(
      description,
      defaultTargetPlatform == TargetPlatform.iOS
          ? ResolutionPreset.low
          : ResolutionPreset.low,
    );
    ImageRotation rotation = rotationIntToImageRotation(
      description.sensorOrientation,
    );
    await _camera.initialize();
    _camera.startImageStream((CameraImage image) {
      if (_isDetecting) return;
      _isDetecting = true;
      try {
        // await doOpenCVDectionHere(image)
        detect(image, _getDetectionMethod(), rotation).then((result) {
          print('........................');
          print(result.length);
          print('>>>>>>>>>>>>>>>>>>>...>>>');
          setState(() {
            if (result.length == 0) {
              text = 'No Face Found';
              _faces = List<Face>();
            } else {
              _faces = result;
              text = 'Face Found : ${result.length}';
            }
          });
        });
      } catch (e) {
        print(e);
      } finally {
        _isDetecting = false;
      }
    });
  }

  HandleDetection _getDetectionMethod() {
    final faceDetector = FirebaseVision.instance.faceDetector(
      FaceDetectorOptions(
        mode: FaceDetectorMode.fast,
      ),
    );
    return faceDetector.processImage;
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (_camera != null)
          ? Column(
              children: [
                Expanded(
                  flex: 9,
                  child: Stack(
                    children: [
                      CameraPreview(_camera),
                      ..._faces
                          .map((e) => Positioned(
                                top: e.boundingBox.top,
                                left: e.boundingBox.left,
                                right: e.boundingBox.right,
                                bottom: e.boundingBox.bottom,
                                child: Container(
                                  height: e.boundingBox.height,
                                  width: e.boundingBox.width,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ))
                          .toList()
                    ],
                  ),
                ),
                Expanded(
                  child: Text(text),
                )
              ],
            )
          : Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleCameraDirection,
        tooltip: 'Toogle Camera',
        child: Icon(Icons.flip_camera_android),
      ),
    );
  }
}
