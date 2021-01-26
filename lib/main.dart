import 'package:face_recog/FaceCapture.dart';
import 'package:flutter/material.dart';

void main() => runApp(
      MaterialApp(
        title: 'Face Recognition',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: FacePage(),
      ),
    );
