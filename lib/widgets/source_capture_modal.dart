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
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          // Añadir espacio inferior dinámico: padding del sistema (safe area) + inset del teclado + 16px
          bottom:
              MediaQuery.of(context).viewPadding.bottom +
              MediaQuery.of(context).viewInsets.bottom +
              16,
        ),
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
              LayoutBuilder(
                builder: (context, constraints) {
                  // Calcular altura responsiva según ancho disponible
                  double maxWidth = constraints.maxWidth;
                  double height = (maxWidth * 0.6).clamp(120.0, 420.0);
                  if (_selectedType == 'image') {
                    return SizedBox(
                      height: height,
                      child: Center(
                        child: Image.file(
                          _selectedFile!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      ),
                    );
                  }

                  // Documento: icon + nombre, con tamaño relativo
                  return Column(
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        size: (height * 0.3).clamp(48.0, 96.0),
                        color: Colors.indigo,
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth * 0.9),
                        child: Text(
                          _selectedFile!.path
                              .split(Platform.pathSeparator)
                              .last,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
            ],

            // Botones de selección (camera/gallery/document) - adaptativos
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 520) {
                  // en pantallas anchas usar Row y Expanded para distribuir uniformemente
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickFromCamera,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Tomar foto'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickFromGallery,
                          icon: const Icon(Icons.photo),
                          label: const Text('Elegir foto'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickDocument,
                          icon: const Icon(Icons.insert_drive_file),
                          label: const Text('Documento'),
                        ),
                      ),
                    ],
                  );
                }

                // pantallas pequeñas: Wrap para que los botones fluyan y no se recorten
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth > 360
                          ? constraints.maxWidth * 0.45
                          : constraints.maxWidth * 0.9,
                      child: ElevatedButton.icon(
                        onPressed: _pickFromCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Tomar foto'),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth > 360
                          ? constraints.maxWidth * 0.45
                          : constraints.maxWidth * 0.9,
                      child: ElevatedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo),
                        label: const Text('Elegir foto'),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth > 360
                          ? constraints.maxWidth * 0.45
                          : constraints.maxWidth * 0.9,
                      child: ElevatedButton.icon(
                        onPressed: _pickDocument,
                        icon: const Icon(Icons.insert_drive_file),
                        label: const Text('Documento'),
                      ),
                    ),
                  ],
                );
              },
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
