import 'package:flu2/utils/navigation_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/app.dart';

Future<void> main() async {
  // Cargar variables de entorno desde .env
  await dotenv.load(fileName: ".env");

  // Desactiva todos los debugPrint en modo release
  debugPrint = (String? message, {int? wrapWidth}) {};
  // Desactiva print
  DeviceUtils.init(); // precarga datos
  runApp(const MyApp());
}
