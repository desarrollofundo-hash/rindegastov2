import 'package:mobile_scanner/mobile_scanner.dart';

/// Modelo para datos de factura de Perú
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
      '01': 'FACTURA ELECTRONICA',
      '03': 'BOLETA DE VENTA',
      '07': 'NOTA DE CREDITO',
      '08': 'NOTA DE DEBITO',
      '09': 'GUÍA DE REMISION',
    };
    return tipos[codigo] ?? 'COMPROBANTE ($codigo)';
  }

  // HELPER: Determinar tipo de comprobante según código SUNAT
  static String? getTipoMoneda(String moneda) {
    final tipos = {
      '()': 'PEN',
      'PEN': 'PEN',
      'USD': 'USD',
      'S': 'PEN',
      'D': 'USD',
    };
    return tipos[moneda] ?? '($moneda)';
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
