import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Modelo para datos de factura de Perú
class FacturaData {
  // DATOS GENERALES
  final String? ruc;
  final String? tipoComprobante;
  final String? serie;
  final String? numero;
  final String? codigo; // Código (posición 5)
  final String? fechaEmision;
  final double? total;
  final String? moneda;
  final String? rucCliente;

  final String rawData;
  final BarcodeFormat format;

  FacturaData({
    // Datos generales
    this.ruc,
    this.tipoComprobante,
    this.serie,
    this.numero,
    this.codigo,
    this.fechaEmision,
    this.total,
    this.moneda,
    this.rucCliente,

    required this.rawData,
    required this.format,
  });

  factory FacturaData.fromBarcode(Barcode barcode) {
    final qrData = barcode.rawValue ?? '';

    try {
      // PARSEAR FORMATO CON PIPE (|)
      if (qrData.contains('|')) {
        return _parsePipeFormat(qrData, barcode.format);
      }

      // Si no es formato pipe, intentar otros formatos
      return _parseOtherFormats(qrData, barcode.format);
    } catch (e) {
      print('Error en parsing: $e');
      return FacturaData(rawData: qrData, format: barcode.format);
    }
  }

  // PARSER PARA FORMATO PIPE (|)
  static FacturaData _parsePipeFormat(String qrData, BarcodeFormat format) {
    final parts = qrData.split('|');

    // Asignar valores según la posición en el formato pipe
    return FacturaData(
      // Posición 0: RUC del emisor
      ruc: parts.isNotEmpty ? parts[0].trim() : null,

      // Posición 1: Tipo de comprobante (01=Factura, 03=Boleta, etc.)
      tipoComprobante: parts.length > 1
          ? _getTipoComprobante(parts[1].trim())
          : null,

      // Posición 2: Serie (F001, B001, etc.)
      serie: parts.length > 2 ? parts[2].trim() : null,

      // Posición 3: Número del comprobante
      numero: parts.length > 3 ? parts[3].trim() : null,

      // Posición 4: Código (generalmente 0)
      codigo: parts.length > 4 ? parts[4].trim() : null,

      // Posición 5: Monto (puede ser el total)
      total: parts.length > 5 ? _safeParseDouble(parts[5].trim()) : null,

      // Posición 6: Fecha de emisión (YYYY-MM-DD)
      fechaEmision: parts.length > 6 ? parts[6].trim() : null,

      // Posición 7: IGV u otro impuesto
      // igv: parts.length > 7 ? _safeParseDouble(parts[7].trim()) : null,

      // Posición 8: RUC del cliente
      rucCliente: parts.length > 8 ? parts[8].trim() : null,

      moneda: 'PEN', // Por defecto para Perú
      rawData: qrData,
      format: format,
    );
  }

  // PARSER PARA OTROS FORMATOS (mantener compatibilidad)
  static FacturaData _parseOtherFormats(String qrData, BarcodeFormat format) {
    return FacturaData(rawData: qrData, format: format);
  }

  // HELPER: Determinar tipo de comprobante según código SUNAT
  static String? _getTipoComprobante(String codigo) {
    final tipos = {
      '01': 'FACTURA ELECTRÓNICA',
      '03': 'BOLETA DE VENTA',
      '07': 'NOTA DE CRÉDITO',
      '08': 'NOTA DE DÉBITO',
      '09': 'GUÍA DE REMISIÓN',
    };
    return tipos[codigo] ?? 'COMPROBANTE ($codigo)';
  }

  // HELPER: Parse seguro de double
  static double? _safeParseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return double.tryParse(value.replaceAll(',', ''));
    } catch (e) {
      return null;
    }
  }

  // Método para obtener mapa de datos
  Map<String, String> toDisplayMap() {
    return {
      'RUC Emisor': ruc ?? 'N/A',
      'Tipo Comprobante': tipoComprobante ?? 'N/A',
      'Serie': serie ?? 'N/A',
      'Número': numero ?? 'N/A',
      'Código': codigo ?? 'N/A',
      'Fecha Emisión': fechaEmision ?? 'N/A',
      'Total': total?.toStringAsFixed(2) ?? 'N/A',
      'Moneda': moneda ?? 'PEN',
      'RUC Cliente': rucCliente ?? 'N/A',
    };
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  FacturaData? facturaDetectada;
  bool isScanning = true;
  bool _isTorchOn = false; // Estado local para la linterna

  @override
  void initState() {
    super.initState();
    _setupScanner();
  }

  void _setupScanner() {
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 3000,
      returnImage: false,
    );
  }

  void _onDetect(BarcodeCapture barcodeCapture) {
    if (!isScanning) return;

    final barcodes = barcodeCapture.barcodes;
    if (barcodes.isEmpty) return;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        _processBarcode(barcode);
        break;
      }
    }
  }

  void _processBarcode(Barcode barcode) {
    setState(() {
      isScanning = false;
    });

    final facturaData = FacturaData.fromBarcode(barcode);

    setState(() {
      facturaDetectada = facturaData;
    });

    _showFacturaModal(facturaData);
  }

  void _restartScanning() {
    setState(() {
      facturaDetectada = null;
      isScanning = true;
    });
    cameraController.start();
  }

  void _showFacturaModal(FacturaData facturaData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FacturaModalPeru(
        facturaData: facturaData,
        onSave: (factura, imagePath) {
          _saveFactura(factura, imagePath);
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
        onCancel: _restartScanning,
      ),
    );
  }

  void _saveFactura(FacturaData factura, String? imagePath) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Factura peruana guardada exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner Facturas Perú'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () async {
              await cameraController.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => cameraController.switchCamera(),
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
                  controller: cameraController,
                  onDetect: _onDetect,
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
              child: _buildResultPanel(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPanel() {
    if (facturaDetectada != null) {
      final factura = facturaDetectada!;
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
                onPressed: _restartScanning,
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
    cameraController.dispose();
    super.dispose();
  }
}

class FacturaModalPeru extends StatefulWidget {
  final FacturaData facturaData;
  final Function(FacturaData, String?) onSave;
  final VoidCallback onCancel;

  const FacturaModalPeru({
    super.key,
    required this.facturaData,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<FacturaModalPeru> createState() => _FacturaModalPeruState();
}

class _FacturaModalPeruState extends State<FacturaModalPeru> {
  // Controladores para cada campo
  late TextEditingController _politicaController;
  late TextEditingController _rucController;
  late TextEditingController _tipoComprobanteController;
  late TextEditingController _serieController;
  late TextEditingController _numeroController;
  late TextEditingController _igvController;
  late TextEditingController _fechaEmisionController;
  late TextEditingController _totalController;
  late TextEditingController _monedaController;
  late TextEditingController _rucClienteController;
  late TextEditingController _notaController;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();

    // Inicializar controladores con los datos parseados del QR
    _politicaController = TextEditingController(text: '');
    _rucController = TextEditingController(text: widget.facturaData.ruc ?? '');
    _tipoComprobanteController = TextEditingController(
      text: widget.facturaData.tipoComprobante ?? '',
    );
    _serieController = TextEditingController(
      text: widget.facturaData.serie ?? '',
    );
    _numeroController = TextEditingController(
      text: widget.facturaData.numero ?? '',
    );
    _igvController = TextEditingController(
      text: widget.facturaData.codigo ?? '',
    );
    _fechaEmisionController = TextEditingController(
      text: widget.facturaData.fechaEmision ?? '',
    );
    _totalController = TextEditingController(
      text: widget.facturaData.total?.toStringAsFixed(2) ?? '',
    );
    _monedaController = TextEditingController(
      text: widget.facturaData.moneda ?? 'PEN',
    );
    _rucClienteController = TextEditingController(
      text: widget.facturaData.rucCliente ?? '',
    );
    _notaController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    // Dispose de todos los controladores
    _politicaController.dispose();
    _rucController.dispose();
    _tipoComprobanteController.dispose();
    _serieController.dispose();
    _numeroController.dispose();
    _igvController.dispose();
    _fechaEmisionController.dispose();
    _totalController.dispose();
    _monedaController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al capturar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _saveFactura() {
    final facturaData = FacturaData(
      ruc: _rucController.text.isEmpty ? null : _rucController.text,
      tipoComprobante: _tipoComprobanteController.text.isEmpty
          ? null
          : _tipoComprobanteController.text,
      serie: _serieController.text.isEmpty ? null : _serieController.text,
      numero: _numeroController.text.isEmpty ? null : _numeroController.text,
      codigo: _igvController.text.isEmpty ? null : _igvController.text,
      fechaEmision: _fechaEmisionController.text.isEmpty
          ? null
          : _fechaEmisionController.text,
      total: double.tryParse(_totalController.text),
      moneda: _monedaController.text.isEmpty ? 'PEN' : _monedaController.text,
      rucCliente: _rucClienteController.text.isEmpty
          ? null
          : _rucClienteController.text,
      rawData: widget.facturaData.rawData,
      format: widget.facturaData.format,
    );

    widget.onSave(facturaData, _selectedImage?.path);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade700, Colors.red.shade400],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Factura Electrónica - Perú',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Datos extraídos del QR',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección de imagen
                  _buildImageSection(),
                  const SizedBox(height: 20),

                  // Datos del QR parseados
                  const Text(
                    'Politica',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Primera fila: RUC y Tipo Comprobante
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Política',
                            prefixIcon: Icon(Icons.policy),
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _politicaController.text.isNotEmpty
                              ? _politicaController.text
                              : null,
                          items: const [
                            DropdownMenuItem(
                              value: 'General',
                              child: Text('General'),
                            ),
                            DropdownMenuItem(
                              value: 'Gastos de movilidad',
                              child: Text('Gastos de movilidad'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _politicaController.text = value;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Primera fila: RUC y Tipo Comprobante
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            prefixIcon: Icon(Icons.category),
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _politicaController.text.isNotEmpty
                              ? _politicaController.text
                              : null,
                          items: const [
                            DropdownMenuItem(
                              value: 'General',
                              child: Text('Transporte'),
                            ),
                            DropdownMenuItem(
                              value: 'Alimentacion',
                              child: Text('Alimentacion'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _politicaController.text = value;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Datos del QR parseados
                  const Text(
                    'Datos de la Factura',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Primera fila: RUC y Tipo Comprobante
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _rucController,
                          'RUC Emisor',
                          Icons.business,
                          TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _tipoComprobanteController,
                          'Tipo Comprobante',
                          Icons.description,
                          TextInputType.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Segunda fila: Serie y Número
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _serieController,
                          'Serie',
                          Icons.tag,
                          TextInputType.text,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _numeroController,
                          'Número',
                          Icons.confirmation_number,
                          TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tercera fila: Código y Fecha
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _igvController,
                          'IGV',
                          Icons.code,
                          TextInputType.text,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _fechaEmisionController,
                          'Fecha Emisión',
                          Icons.calendar_today,
                          TextInputType.datetime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Cuarta fila: Total y Moneda
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _totalController,
                          'Total',
                          Icons.attach_money,
                          TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _monedaController,
                          'Moneda',
                          Icons.currency_exchange,
                          TextInputType.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quinta fila: RUC Cliente
                  _buildTextField(
                    _rucClienteController,
                    'RUC Cliente',
                    Icons.person,
                    TextInputType.number,
                  ),
                  const SizedBox(height: 20),

                  // Primera fila: RUC y Tipo Comprobante
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _notaController,
                          'Nota',
                          Icons.comment,
                          TextInputType.text,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Datos raw originales
                  ExpansionTile(
                    title: const Text('Datos Originales del QR'),
                    leading: const Icon(Icons.qr_code),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          widget.facturaData.rawData,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Botones
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 244, 54, 54),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveFactura,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Factura'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 19, 126, 32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Imagen de la Factura',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(
                      _selectedImage == null ? Icons.add_a_photo : Icons.edit,
                    ),
                    label: Text(_selectedImage == null ? 'Agregar' : 'Cambiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedImage != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_outlined, color: Colors.grey, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Sin imagen de factura',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    TextInputType keyboardType,
  ) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}

// Mantener la clase QrScannerOverlayShape igual...
// Resto del código (QrScannerOverlayShape) se mantiene igual...

// Clase para crear el overlay del marco de escaneo
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

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
    Path path = Path()..addRect(rect);
    Path oval = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );
    return Path.combine(PathOperation.difference, path, oval);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final boxSize = cutOutSize + borderOffset * 2;
    final boxRect = Rect.fromLTWH(
      (width - boxSize) / 2,
      (height - boxSize) / 2,
      boxSize,
      boxSize,
    );

    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(getOuterPath(rect), paint);

    // Draw the border lines
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(boxRect.left, boxRect.top + borderLength)
        ..lineTo(boxRect.left, boxRect.top + borderRadius)
        ..arcToPoint(
          Offset(boxRect.left + borderRadius, boxRect.top),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(boxRect.left + borderLength, boxRect.top),
      borderPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(boxRect.right - borderLength, boxRect.top)
        ..lineTo(boxRect.right - borderRadius, boxRect.top)
        ..arcToPoint(
          Offset(boxRect.right, boxRect.top + borderRadius),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(boxRect.right, boxRect.top + borderLength),
      borderPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(boxRect.left, boxRect.bottom - borderLength)
        ..lineTo(boxRect.left, boxRect.bottom - borderRadius)
        ..arcToPoint(
          Offset(boxRect.left + borderRadius, boxRect.bottom),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(boxRect.left + borderLength, boxRect.bottom),
      borderPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(boxRect.right - borderLength, boxRect.bottom)
        ..lineTo(boxRect.right - borderRadius, boxRect.bottom)
        ..arcToPoint(
          Offset(boxRect.right, boxRect.bottom - borderRadius),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(boxRect.right, boxRect.bottom - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
