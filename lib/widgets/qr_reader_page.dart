import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_tools/qr_code_tools.dart';

class QrReaderPage extends StatefulWidget {
  final String? imagePath;

  const QrReaderPage({Key? key, this.imagePath}) : super(key: key);

  @override
  _QrReaderPageState createState() => _QrReaderPageState();
}

class _QrReaderPageState extends State<QrReaderPage> {
  String qrText = '';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    // Si se pasó una ruta de imagen, intentar decodificarla inmediatamente
    if (widget.imagePath != null) {
      _decodeFromPath(widget.imagePath!);
    }
  }

  Future<void> _decodeFromPath(String path) async {
    setState(() {
      loading = true;
      qrText = '';
    });
    try {
      final data = await QrCodeToolsPlugin.decodeFrom(path);
      setState(() => qrText = data ?? 'No se encontró QR');
    } catch (e) {
      setState(() => qrText = 'Error leyendo QR: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _readQrFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      await _decodeFromPath(picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leer QR desde imagen')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                qrText.isEmpty
                    ? 'Toma una foto con QR o usa la imagen'
                    : 'QR: $qrText',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _readQrFromCamera,
                child: const Text('Tomar foto y leer QR'),
              ),
              const SizedBox(height: 8),
              if (qrText.isNotEmpty && !loading)
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(qrText),
                  child: const Text('Usar resultado'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
