import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

/// Modal para capturar/seleccionar una imagen o documento y previsualizarla.
class SourceCaptureModal extends StatefulWidget {
  const SourceCaptureModal({Key? key}) : super(key: key);

  @override
  State<SourceCaptureModal> createState() => _SourceCaptureModalState();
}

class _SourceCaptureModalState extends State<SourceCaptureModal> {
  File? _selectedFile;
  String? _selectedType; // 'image' | 'document'
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromCamera() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (xfile == null) return;
    setState(() {
      _selectedFile = File(xfile.path);
      _selectedType = 'image';
    });
  }

  Future<void> _pickFromGallery() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xfile == null) return;
    setState(() {
      _selectedFile = File(xfile.path);
      _selectedType = 'image';
    });
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;
    final path = result.files.single.path;
    if (path == null) return;
    setState(() {
      _selectedFile = File(path);
      _selectedType = 'document';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Agregar documento',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Previsualización
            if (_selectedFile != null) ...[
              if (_selectedType == 'image')
                SizedBox(
                  height: 200,
                  child: Image.file(_selectedFile!, fit: BoxFit.contain),
                )
              else
                Column(
                  children: [
                    const Icon(
                      Icons.insert_drive_file,
                      size: 64,
                      color: Colors.indigo,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFile!.path.split(Platform.pathSeparator).last,
                    ),
                  ],
                ),
              const SizedBox(height: 12),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Tomar foto'),
                ),
                ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo),
                  label: const Text('Elegir foto'),
                ),
                ElevatedButton.icon(
                  onPressed: _pickDocument,
                  icon: const Icon(Icons.insert_drive_file),
                  label: const Text('Documento'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedFile == null
                      ? null
                      : () {
                          Navigator.of(context).pop({
                            'path': _selectedFile!.path,
                            'type': _selectedType,
                          });
                        },
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
