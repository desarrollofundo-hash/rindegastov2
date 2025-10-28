import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/qr_scanner_controller.dart';
import '../models/factura_data.dart';
import '../widgets/factura_modal_peru.dart';
import '../widgets/factura_modal_movilidad.dart';
import '../widgets/politica_selection_modal.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  QRScannerScreenState createState() => QRScannerScreenState();
}

class QRScannerScreenState extends State<QRScannerScreen> {
  late QRScannerController _controller;
  late MobileScannerController _mobileScannerController;
  bool _showCaptureFlash = false;
  bool _isModalOpen = false;
  bool _isTorchOn = false;
  bool _isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    _controller = QRScannerController();
    _controller.initializeScanner();
    _mobileScannerController = _controller.cameraController;
  }

  @override
  void dispose() {
    _controller.dispose();
    // _mobileScannerController is owned by the controller; controller.dispose() already disposes it
    super.dispose();
  }

  void _onDetect(BarcodeCapture barcodeCapture) {
    if (_isModalOpen) return;

    // Let controller handle duplicate suppression
    _controller.onDetect(barcodeCapture);

    // If controller detected and set facturaDetectada, proceed
    final factura = _controller.facturaDetectada;
    if (factura != null) {
      _isModalOpen = true;

      // Haptic and vibration feedback
      HapticFeedback.mediumImpact();
      if (Platform.isAndroid) {
        _platformVibrate(80);
      }

      // Visual flash
      setState(() => _showCaptureFlash = true);
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) setState(() => _showCaptureFlash = false);
      });

      _showPoliticaSelectionModal(factura);
    }
  }

  static const MethodChannel _platformChannel = MethodChannel(
    'rindegasto/vibrate',
  );

  Future<void> _platformVibrate(int durationMs) async {
    try {
      await _platformChannel.invokeMethod('vibrate', {'duration': durationMs});
    } on PlatformException {
      // fallback: do nothing, HapticFeedback already provided
    }
  }

  void _showPoliticaSelectionModal(FacturaData facturaData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PoliticaSelectionModal(
        onPoliticaSelected: (politica) {
          Navigator.of(context).pop();
          _showFacturaModal(facturaData, politica);
        },
        onCancel: () {
          _isModalOpen = false;
          _controller.restartScanning();
        },
      ),
    ).then((_) {
      // When the politica modal is dismissed (by selection or back), ensure scanning restarts
      _isModalOpen = false;
      _controller.restartScanning();
    });
  }

  void _showFacturaModal(FacturaData facturaData, String politicaSeleccionada) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        if (politicaSeleccionada.toLowerCase().contains('movilidad')) {
          return FacturaModalMovilidad(
            facturaData: facturaData,
            politicaSeleccionada: politicaSeleccionada,
            onSave: (factura, imagePath) {
              _controller.saveFactura(factura, imagePath);
              _isModalOpen = false;
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Factura de movilidad guardada exitosamente'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            onCancel: () {
              _isModalOpen = false;
              _controller.restartScanning();
            },
          );
        } else {
          return FacturaModalPeru(
            facturaData: facturaData,
            politicaSeleccionada: politicaSeleccionada,
            onSave: (factura, imagePath) {
              _controller.saveFactura(factura, imagePath);
              _isModalOpen = false;
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Factura peruana guardada exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onCancel: () {
              _isModalOpen = false;
              _controller.restartScanning();
            },
          );
        }
      },
    ).then((_) {
      // When the factura modal is dismissed, make sure scanning restarts so user can scan again
      _isModalOpen = false;
      _controller.restartScanning();
    });
  }

  void _toggleTorch() {
    _controller.toggleTorch();
    setState(() {
      _isTorchOn = _controller.isTorchOn;
    });
  }

  void _switchCamera() {
    _controller.switchCamera();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Escáner QR',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Scanner de cámara
          MobileScanner(
            controller: _mobileScannerController,
            onDetect: _onDetect,
          ),

          // Capture flash overlay
          if (_showCaptureFlash)
            Positioned.fill(
              child: Container(color: Colors.white.withOpacity(0.25)),
            ),

          // Overlay del escáner
          _buildScannerOverlay(),

          // Header con instrucciones
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
            child: _buildInstructions(),
          ),

          // Controles en la parte inferior
          Positioned(bottom: 60, left: 0, right: 0, child: _buildControls()),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: _ModernScannerOverlay(
          borderColor: Colors.white,
          scannerColor: Colors.blue,
          borderRadius: 20,
          borderLength: 40,
          borderWidth: 4,
          cutOutSize: 280,
          animationValue: _isModalOpen ? 0.0 : 1.0,
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: const Text(
            'Encuadre el código QR en el área de escaneo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 280,
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.5),
                Colors.blue,
                Colors.blue.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isTorchOn ? Icons.flash_off : Icons.flash_on,
            label: _isTorchOn ? 'Apagar' : 'Encender',
            onPressed: _toggleTorch,
            backgroundColor: _isTorchOn ? Colors.amber : Colors.white,
            iconColor: _isTorchOn ? Colors.black : Colors.blue,
          ),
          _buildControlButton(
            icon: _isFrontCamera ? Icons.camera_rear : Icons.camera_front,
            label: _isFrontCamera ? 'Trasera' : 'Frontal',
            onPressed: _switchCamera,
            backgroundColor: Colors.white,
            iconColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, size: 28, color: iconColor),
            style: IconButton.styleFrom(shape: const CircleBorder()),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModernScannerOverlay extends ShapeBorder {
  const _ModernScannerOverlay({
    this.borderColor = Colors.white,
    this.scannerColor = Colors.blue,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 150),
    this.borderRadius = 16,
    this.borderLength = 40,
    this.animationValue = 1.0,
    double? cutOutSize,
    double? cutOutHeight,
    double? cutOutWidth,
    double? cutOutBottomOffset,
  }) : cutOutWidth = cutOutWidth ?? cutOutSize ?? 250,
       cutOutHeight = cutOutHeight ?? cutOutSize ?? 250,
       cutOutBottomOffset = cutOutBottomOffset ?? 0;

  final Color borderColor;
  final Color scannerColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double animationValue;
  final double cutOutWidth;
  final double cutOutHeight;
  final double cutOutBottomOffset;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;

    final cutOutWidth = this.cutOutWidth < width
        ? this.cutOutWidth
        : width - borderWidth;
    final cutOutHeight = this.cutOutHeight < height
        ? this.cutOutHeight
        : height - borderWidth;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    // borderPaint removed (unused) - cornerPaint used for corner borders

    final scannerPaint = Paint()
      ..color = scannerColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final cutOutRect = Rect.fromLTWH(
      rect.left + (width - cutOutWidth) / 2,
      rect.top + (height - cutOutHeight) / 2 - cutOutBottomOffset,
      cutOutWidth,
      cutOutHeight,
    );

    // Draw overlay background
    canvas
      ..saveLayer(rect, backgroundPaint)
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        backgroundPaint..blendMode = BlendMode.clear,
      )
      ..restore();

    // Draw animated scanner line
    if (animationValue > 0) {
      final lineHeight = 4.0;
      final lineRect = Rect.fromLTWH(
        cutOutRect.left + 10,
        cutOutRect.top + 10 + (cutOutRect.height - 20) * animationValue,
        cutOutRect.width - 20,
        lineHeight,
      );

      canvas.drawRect(lineRect, scannerPaint);

      // Scanner line glow effect
      final glowPaint = Paint()
        ..color = scannerColor.withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawRect(
        Rect.fromLTWH(
          lineRect.left - 4,
          lineRect.top - 2,
          lineRect.width + 8,
          lineRect.height + 4,
        ),
        glowPaint,
      );
    }

    // Draw corner borders
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path()
      // Top-left corner
      ..moveTo(cutOutRect.left, cutOutRect.top + borderLength)
      ..lineTo(cutOutRect.left, cutOutRect.top + 8)
      ..quadraticBezierTo(
        cutOutRect.left,
        cutOutRect.top,
        cutOutRect.left + 8,
        cutOutRect.top,
      )
      ..lineTo(cutOutRect.left + borderLength, cutOutRect.top)
      // Top-right corner
      ..moveTo(cutOutRect.right - borderLength, cutOutRect.top)
      ..lineTo(cutOutRect.right - 8, cutOutRect.top)
      ..quadraticBezierTo(
        cutOutRect.right,
        cutOutRect.top,
        cutOutRect.right,
        cutOutRect.top + 8,
      )
      ..lineTo(cutOutRect.right, cutOutRect.top + borderLength)
      // Bottom-right corner
      ..moveTo(cutOutRect.right, cutOutRect.bottom - borderLength)
      ..lineTo(cutOutRect.right, cutOutRect.bottom - 8)
      ..quadraticBezierTo(
        cutOutRect.right,
        cutOutRect.bottom,
        cutOutRect.right - 8,
        cutOutRect.bottom,
      )
      ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom)
      // Bottom-left corner
      ..moveTo(cutOutRect.left + borderLength, cutOutRect.bottom)
      ..lineTo(cutOutRect.left + 8, cutOutRect.bottom)
      ..quadraticBezierTo(
        cutOutRect.left,
        cutOutRect.bottom,
        cutOutRect.left,
        cutOutRect.bottom - 8,
      )
      ..lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, cornerPaint);

    // Draw outer border
    final outerBorderPaint = Paint()
      ..color = borderColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      outerBorderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return _ModernScannerOverlay(
      borderColor: borderColor,
      scannerColor: scannerColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
