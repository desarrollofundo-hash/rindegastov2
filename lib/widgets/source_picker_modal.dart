import 'package:flutter/material.dart';

typedef SourcePickCallback = void Function(String source);

// Removed duplicate import and unnecessary closing brace
/// Modal simple para elegir fuente de escaneo: cámara, galería o documento
class SourcePickerModal extends StatelessWidget {
  final SourcePickCallback onPick;
  const SourcePickerModal({Key? key, required this.onPick}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.28,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '¿Cómo quieres agregar el documento?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.indigo),
            title: const Text('Tomar foto'),
            onTap: () => onPick('camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo, color: Colors.indigo),
            title: const Text('Elegir foto'),
            onTap: () => onPick('gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.insert_drive_file, color: Colors.indigo),
            title: const Text('Seleccionar documento (PDF)'),
            onTap: () => onPick('document'),
          ),
        ],
      ),
    );
  }
}
