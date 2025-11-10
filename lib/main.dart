import 'package:flutter/material.dart';
import 'app/app.dart';

void main() {
  // Desactiva todos los debugPrint en modo release
  debugPrint = (String? message, {int? wrapWidth}) {};
  // Desactiva print

  runApp(const MyApp());
}
