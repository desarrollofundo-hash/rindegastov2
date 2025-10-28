import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TestDocumentScannerApp extends StatelessWidget {
  const TestDocumentScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Document Scanner',
      home: Scaffold(
        appBar: AppBar(title: const Text('Test Scanner')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              try {
                final picker = ImagePicker();
                final xfile = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (xfile != null) {
                  final file = File(xfile.path);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Resultado: ${file.path}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error capturando imagen: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Capturar documento (camera)'),
          ),
        ),
      ),
    );
  }
}
