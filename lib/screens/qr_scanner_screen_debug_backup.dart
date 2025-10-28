import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/factura_data.dart';
import '../controllers/qr_scanner_controller.dart';
import '../widgets/factura_modal_peru.dart';
import '../widgets/politica_selection_modal.dart';
import '../widgets/qr_scanner_overlay.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late QRScannerController _controller;
  bool _isModalOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = QRScannerController();
    _controller.initializeScanner();
  }

  void _showPoliticaSelectionModal(FacturaData facturaData) {
    if (_isModalOpen) return; // Evitar abrir múltiples modales
    _isModalOpen = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Evitar que se cierre tocando fuera
      builder: (context) => PoliticaSelectionModal(
        onPoliticaSelected: (String politicaSeleccionada) {
          // Cerrar el modal actual primero
          Navigator.of(context).pop();

          // Usar un delay más corto y más simple
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              // Verificar que el widget sigue montado
              _showFacturaModal(facturaData, politicaSeleccionada);
            } else {}
          });
        },
        onCancel: () {
          _isModalOpen = false;
          Navigator.of(context).pop();
          _controller.restartScanning();
        },
      ),
    ).then((_) {
      // Solo resetear si no vamos a abrir otro modal
      if (_isModalOpen) {
        print('DEBUG: Modal de política cerrado, esperando siguiente modal');
      }
    });
  }

  void _showFacturaModal(FacturaData facturaData, String politicaSeleccionada) {
    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          // TEMPORAL: Siempre mostrar modal general para probar

          try {
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
          } catch (e) {
            print('DEBUG: ERROR creando modal TEMPORAL: $e');
            return Container(
              height: 400,
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('ERROR: $e'),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ).then((_) {
        _isModalOpen = false; // Reset cuando el modal se cierre
        print('DEBUG: Modal de factura cerrado, reseteando bandera');
      });
    } catch (e) {
      print('DEBUG: ERROR GENERAL en _showFacturaModal: $e');
      _isModalOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner Facturas Perú'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return IconButton(
                icon: Icon(
                  _controller.isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await _controller.toggleTorch();
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller.cameraController,
                  onDetect: (capture) {
                    _controller.onDetect(capture);
                    // Mostrar modal cuando se detecte una factura
                    if (_controller.facturaDetectada != null && !_isModalOpen) {
                      _showPoliticaSelectionModal(
                        _controller.facturaDetectada!,
                      );
                    }
                  },
                ),
                Container(
                  decoration: ShapeDecoration(
                    shape: QrScannerOverlayShape(
                      borderColor: Colors.red,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: 250,
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Enfoca el código QR de la factura electrónica',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.grey[100],
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return _buildResultPanel();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPanel() {
    if (_controller.facturaDetectada != null) {
      final factura = _controller.facturaDetectada!;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 40),
          const SizedBox(height: 10),
          Text(
            'Factura detectada: ${factura.tipoComprobante ?? "Comprobante"}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            'RUC: ${factura.ruc ?? "N/A"} | Serie: ${factura.serie ?? "N/A"}',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            'Total: S/ ${factura.total?.toStringAsFixed(2) ?? "N/A"}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(factura.rawData),
                icon: const Icon(Icons.check),
                label: const Text('Aceptar'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              OutlinedButton.icon(
                onPressed: _controller.restartScanning,
                icon: const Icon(Icons.refresh),
                label: const Text('Nuevo Escaneo'),
              ),
            ],
          ),
        ],
      );
    } else {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, color: Colors.grey, size: 40),
          SizedBox(height: 10),
          Text('Listo para escanear', style: TextStyle(fontSize: 16)),
          Text(
            'facturas electrónicas peruanas',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
