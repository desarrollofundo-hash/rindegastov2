import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/factura_data.dart';

/// Controlador para manejar la lógica de escaneo de códigos QR
class QRScannerController extends ChangeNotifier {
  // Controladores de cámara
  MobileScannerController _cameraController = MobileScannerController();

  // Estado del escáner
  FacturaData? _facturaDetectada;
  bool _isScanning = true;
  bool _isTorchOn = false;

  // Getters
  MobileScannerController get cameraController => _cameraController;
  FacturaData? get facturaDetectada => _facturaDetectada;
  bool get isScanning => _isScanning;
  bool get isTorchOn => _isTorchOn;

  /// Inicializar el escáner
  void initializeScanner() {
    _setupScanner();
  }

  /// Configurar el controlador del escáner
  void _setupScanner() {
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      detectionTimeoutMs: 1500,
      returnImage: false,
      facing: CameraFacing.back,
    );
  }

  /// Procesar la detección de códigos de barras
  void onDetect(BarcodeCapture barcodeCapture) {
    if (!_isScanning) return;

    final barcodes = barcodeCapture.barcodes;
    if (barcodes.isEmpty) return;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        _processBarcode(barcode);
        break;
      }
    }
  }

  /// Procesar un código de barras individual
  void _processBarcode(Barcode barcode) {
    _isScanning = false;
    notifyListeners();

    final facturaData = FacturaData.fromBarcode(barcode);

    _facturaDetectada = facturaData;
    // Stop the camera to avoid duplicate detections while UI modal is open
    try {
      _cameraController.stop();
    } catch (_) {}
    notifyListeners();
  }

  /// Reiniciar el escaneo
  void restartScanning() {
    _facturaDetectada = null;
    _isScanning = true;
    _cameraController.start();
    notifyListeners();
  }

  /// Alternar la linterna
  Future<void> toggleTorch() async {
    await _cameraController.toggleTorch();
    _isTorchOn = !_isTorchOn;
    notifyListeners();
  }

  /// Cambiar cámara (frontal/trasera)
  Future<void> switchCamera() async {
    await _cameraController.switchCamera();
  }

  /// Guardar factura (lógica de guardado)
  void saveFactura(FacturaData factura, String? imagePath) {
    // Aquí se puede implementar la lógica de guardado
    // Por ejemplo, guardar en base de datos local, enviar a API, etc.
    print('Guardando factura: ${factura.rawData}');
    if (imagePath != null) {
      print('Con imagen en: $imagePath');
    }
    // Después de guardar, reiniciar el escaneo para permitir nueva detección
    restartScanning();
  }

  /// Limpiar recursos
  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }
}
