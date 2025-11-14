import 'package:flu2/utils/navigation_utils.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';

void main() {
  // Desactiva todos los debugPrint en modo release
  debugPrint = (String? message, {int? wrapWidth}) {};
  // Desactiva print
  DeviceUtils.init(); // precarga datos
  runApp(const MyApp());
}
