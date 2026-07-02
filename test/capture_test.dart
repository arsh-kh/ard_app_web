import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

void main() {
  ScreenshotController().captureFromWidget(Container(), targetSize: const Size(800, 2000));
}
