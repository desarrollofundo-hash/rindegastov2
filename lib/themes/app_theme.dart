import 'package:flutter/material.dart';
// Global font family set to 'Parkinsonianos'.

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.indigo,
    brightness: Brightness.light,
    useMaterial3: true,
    fontFamily: 'Titillium',
    textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Titillium'),
  );

  static final ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.indigo,
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'Titillium',
    textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Titillium'),
  );
}
