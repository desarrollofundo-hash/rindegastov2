import 'dart:io';

import 'package:flu2/models/factura_data_ocr.dart';
import 'package:flutter/material.dart';
// no se requiere mobile_scanner aquí
import '../widgets/factura_modal_peru_evid.dart';

/// Modal alternativo que recibe datos extraídos por OCR y muestra
/// una versión prellenada del modal de factura peruana.
class FacturaModalPeruOCR extends StatelessWidget {
  final Map<String, String> ocrData;
  final File? evidenciaFile;
  final String politicaSeleccionada;
  final void Function(FacturaOcrData, String?) onSave;
  final VoidCallback onCancel;

  const FacturaModalPeruOCR({
    super.key,
    required this.ocrData,
    this.evidenciaFile,
    required this.politicaSeleccionada,
    required this.onSave,
    required this.onCancel,
  });

  /// Helper para convertir el mapa OCR a FacturaData compatible
  FacturaOcrData _facturaFromOcr() {
    final ruc = ocrData['RUC Emisor'] ?? ocrData['RUC'] ?? '';
    final tipo = ocrData['Tipo Comprobante'] ?? '';
    final serie = ocrData['Serie'] ?? '';
    final numero = ocrData['Número'] ?? ocrData['Numero'] ?? '';
    // final codigo = ocrData['Código'] ?? ''; // no usado por ahora
    final fecha = ocrData['Fecha'] ?? ocrData['Fecha Emisión'] ?? '';
    double? total, igv;
    if (ocrData['Total'] != null) {
      total = double.tryParse(
        ocrData['Total']!.replaceAll(',', '').replaceAll(' ', ''),
      );
    }
    if (ocrData['Igv'] != null) {
      igv = double.tryParse(
        ocrData['Igv']!.replaceAll(',', '').replaceAll(' ', ''),
      );
    }
    final moneda = ocrData['Moneda'] ?? 'PEN';
    final rucCliente = ocrData['RUC Cliente'] ?? '';
    final f = FacturaOcrData();
    f.rucEmisor = ruc.isEmpty ? null : ruc;
    f.razonSocialEmisor =
        (ocrData['Razón Social'] ?? '').toString().trim().isEmpty
        ? null
        : (ocrData['Razón Social'] ?? '').toString();
    f.tipoComprobante = tipo.isEmpty
        ? null
        : FacturaOcrData.getTipoComprobante(tipo);
    f.serie = serie.isEmpty ? null : serie;
    f.numero = numero.isEmpty ? null : numero;
    f.fecha = fecha.isEmpty ? null : fecha;
    f.subtotal = ocrData['Subtotal'] ?? null;
    f.igv = igv != null ? igv.toString() : (ocrData['IGV'] ?? ocrData['Igv']);
    f.total = total != null ? total.toString() : (ocrData['Total'] ?? null);
    f.moneda = FacturaOcrData.getTipoMoneda(moneda);
    f.rucCliente = rucCliente.isEmpty ? null : rucCliente;
    f.razonSocialCliente =
        (ocrData['Razón Social Cliente'] ?? '').toString().trim().isEmpty
        ? null
        : (ocrData['Razón Social Cliente'] ?? '').toString();

    // Nota: FacturaOcrData no tiene rawData ni format; usamos toString() para
    // representar los datos originales cuando sea necesario.
    return f;
  }

  @override
  Widget build(BuildContext context) {
    final factura = _facturaFromOcr();

    return FacturaModalPeruEvid(
      facturaData: factura,
      selectedFile: evidenciaFile,
      politicaSeleccionada: politicaSeleccionada,
      onSave: onSave,
      onCancel: onCancel,
    );
  }
}
