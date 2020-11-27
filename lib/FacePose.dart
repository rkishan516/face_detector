import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';

class FacePose {
  double smileProbThresh;
  double leftEyeOpenProbThresh;
  double rightEyeOpenProbThresh;
  bool goodTilt;
  double eulerYThreshold;

  double motionXThresh;
  double motionYThresh;
  double motionZThresh;
  double eulerZThreshold;
  double distanceFromCenterThresh;
  double sizeToleranceMin;
  double sizeToleranceMax;
  bool goodScale;
  bool goodPicture;
  bool faceDetected;
  bool smiling;
  bool outOfFrame;
  bool eyesOpen;
  bool fastMode;
  bool done;
  bool motion;
  bool centered;
  double zoomlevel;
  double borderThreshold;
  Offset borderConstraint;

  Offset lastCenter;
  Offset currentCenter;
  Offset refCenter;
  Offset refSize;
  Offset previousFaceSize;
  Rect bBox;

  FacePose() {
    this.borderThreshold = 0.1;
    this.sizeToleranceMin = 0.15;
    this.sizeToleranceMax = 0.55;
    this.smileProbThresh = 0.6;
    this.leftEyeOpenProbThresh = 0.65;
    this.rightEyeOpenProbThresh = 0.65;
    this.eulerYThreshold = 5.0;
    this.outOfFrame = true;
    this.eulerZThreshold = 5.0;
    this.zoomlevel = 1.0;
    this.distanceFromCenterThresh = 60;
    this.goodTilt = false;
    this.goodPicture = false;
    this.faceDetected = false;
    this.smiling = false;
    this.eyesOpen = false;
    this.fastMode = true;
    this.done = false;
    this.motion = true;
    this.centered = false;
    this.goodScale = false;
    this.borderConstraint = Offset(0.1, 0.1);
    this.refCenter = Offset(0.0, 0.0);
    this.refSize = Offset(0.0, 0.0);
    this.lastCenter = Offset(0.0, 0.0);
    this.currentCenter = Offset(0.0, 0.0);
    this.previousFaceSize = Offset(0.0, 0.0);
    this.bBox = Rect.zero;
  }

  void update(List<Face> faces) {
    /**
         * Updates FacePose object with information of the current image frame. FacePose.goodPicture determines if the frame has a good picture of the face.
         * @param faces FirebaseVisionFace with faces found in current frame. face includes landmarks,bBox,euler angle z, euler angle y smile and eyes open probabalit-y.
         */

    if (faces.length > 0) {
      this.faceDetected = true;

      Face face = faces[0];
      double percentageOfWH = 10 / 100;
      this.motionXThresh = (percentageOfWH * face.boundingBox.width);
      this.motionYThresh = (percentageOfWH * face.boundingBox.height);
      this.motionZThresh =
          (percentageOfWH * face.boundingBox.width * face.boundingBox.height);

      double currentbBoxArea = this.motionZThresh * (1 / percentageOfWH);
      double previosBbBoxArea = previousFaceSize.dx * previousFaceSize.dy;
      this.bBox = face.boundingBox;
      if (this.bBox.left - this.borderConstraint.dx < 0 ||
          this.bBox.top - this.borderConstraint.dy < 0 ||
          this.bBox.bottom > this.refSize.dy - this.borderConstraint.dy ||
          this.bBox.right > this.refSize.dx - this.borderConstraint.dx) {
        this.outOfFrame = true;
      } else {
        this.outOfFrame = false;
      }
      this.currentCenter = face.boundingBox.center;

      double xMotion = (this.currentCenter.dx - this.lastCenter.dx).abs();
      double yMotion = (this.currentCenter.dy - this.lastCenter.dy).abs();
      double zMotion = (currentbBoxArea - previosBbBoxArea).abs();
      this.lastCenter = face.boundingBox.center;

      double currentSize = (this.bBox.width * this.bBox.height) /
          (this.refSize.dx * this.refSize.dy);

      if (xMotion > this.motionXThresh ||
          yMotion > this.motionYThresh ||
          zMotion > this.motionZThresh) {
        this.motion = true;
      } else {
        this.motion = false;
      }
      if (face.smilingProbability > this.smileProbThresh) {
        this.smiling = true;
      } else {
        this.smiling = false;
      }
      if (face.leftEyeOpenProbability > this.leftEyeOpenProbThresh ||
          face.rightEyeOpenProbability > this.rightEyeOpenProbThresh) {
        this.eyesOpen = true;
      } else {
        this.eyesOpen = false;
      }
      if (face.headEulerAngleZ.abs() < this.eulerZThreshold &&
          face.headEulerAngleY.abs() < this.eulerYThreshold) {
        this.goodTilt = true;
      } else {
        this.goodTilt = false;
      }
      double dist = (this.refCenter - this.currentCenter).distance;
      if (dist > this.distanceFromCenterThresh) {
        this.centered = false;
      } else {
        this.centered = true;
      }

      if (currentSize > this.sizeToleranceMin &&
          currentSize < this.sizeToleranceMax) {
        this.goodScale = true;
      } else {
        this.goodScale = false;
      }

      if (this.faceDetected &&
          this.eyesOpen &&
          !this.smiling &&
          this.goodTilt &&
          !this.motion &&
          this.centered &&
          this.goodScale &&
          !this.outOfFrame) {
        this.goodPicture = true;
      } else {
        this.goodPicture = false;
      }

      this.previousFaceSize =
          new Offset(face.boundingBox.width, face.boundingBox.height);
    } else {
      this.faceDetected = false;
      this.goodPicture = false;
      this.goodTilt = false;
      this.motion = true;
      this.goodScale = false;
      this.centered = false;
    }
  }

  void updateImageInfo(Offset newCenter, Offset newSize) {
    /**
         * Initializes references in the FacePose object with selected Width x Height and center_x,center_y of the Image stream
         * @param newCenter center of image stream
         * @param newSize size of image stream
         */

    this.refCenter = newCenter;
    this.refSize = newSize;
    this.distanceFromCenterThresh = this.refSize.dx * 20 / 100;
    this.borderConstraint = Offset(this.borderThreshold * this.refSize.dx,
        this.borderThreshold * this.refSize.dy);
  }
}
