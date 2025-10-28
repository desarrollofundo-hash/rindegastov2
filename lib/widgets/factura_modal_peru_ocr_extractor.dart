import 'dart:io';

import 'package:flutter/material.dart';
import '../models/factura_data_ocr.dart';
// El modal ahora usa el modelo `FacturaOcrData` para leer los campos

/// Modal simple para mostrar y editar los campos extraídos por OCR
class FacturaModalPeruOcrExtractor extends StatefulWidget {
  final FacturaOcrData ocrData;
  final File? evidenciaFile;
  final String politicaSeleccionada;
  final void Function(FacturaOcrData, String?) onSave;
  final VoidCallback onCancel;

  const FacturaModalPeruOcrExtractor({
    super.key,
    required this.ocrData,
    this.evidenciaFile,
    required this.politicaSeleccionada,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<FacturaModalPeruOcrExtractor> createState() =>
      _FacturaModalPeruOcrExtractorState();
}

class _FacturaModalPeruOcrExtractorState
    extends State<FacturaModalPeruOcrExtractor> {
  late TextEditingController rucController;
  late TextEditingController razonController;
  late TextEditingController tipoController;
  late TextEditingController serieController;
  late TextEditingController numeroController;
  late TextEditingController fechaController;
  late TextEditingController subtotalController;
  late TextEditingController igvController;
  late TextEditingController totalController;
  late TextEditingController monedaController;
  late TextEditingController rucClienteController;
  late TextEditingController razonClienteController;

  @override
  void initState() {
    super.initState();
    final d = widget.ocrData;
    // Inicializamos controladores con los valores del modelo (pueden ser null)
    rucController = TextEditingController(text: d.rucEmisor ?? '');
    razonController = TextEditingController(text: d.razonSocialEmisor ?? '');
    tipoController = TextEditingController(text: d.tipoComprobante ?? '');
    serieController = TextEditingController(text: d.serie ?? '');
    numeroController = TextEditingController(text: d.numero ?? '');
    fechaController = TextEditingController(text: d.fecha ?? '');
    subtotalController = TextEditingController(text: d.subtotal ?? '');
    igvController = TextEditingController(text: d.igv ?? '');
    totalController = TextEditingController(text: d.total ?? '');
    monedaController = TextEditingController(text: d.moneda ?? 'PEN');
    rucClienteController = TextEditingController(text: d.rucCliente ?? '');
    razonClienteController = TextEditingController(
      text: d.razonSocialCliente ?? '',
    );
  }

  @override
  void dispose() {
    rucController.dispose();
    razonController.dispose();
    tipoController.dispose();
    serieController.dispose();
    numeroController.dispose();
    fechaController.dispose();
    subtotalController.dispose();
    igvController.dispose();
    totalController.dispose();
    monedaController.dispose();
    rucClienteController.dispose();
    razonClienteController.dispose();
    super.dispose();
  }

  void _onSave() {
    // Validaciones básicas
    final rucText = rucController.text.trim();
    if (rucText.isNotEmpty && !RegExp(r'^\d{11}\$').hasMatch(rucText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('RUC debe tener 11 dígitos')),
      );
      return;
    }

    final fechaText = fechaController.text.trim();
    if (fechaText.isNotEmpty &&
        !RegExp(r'^(\d{2}[\/\-]\d{2}[\/\-]\d{4})\$').hasMatch(fechaText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fecha debe tener formato DD/MM/AAAA')),
      );
      return;
    }

    final totalVal = double.tryParse(
      totalController.text.replaceAll(',', '').replaceAll(' ', ''),
    );

    // Construimos la instancia del modelo actualizando sólo los campos
    final factura = FacturaOcrData();
    factura.rucEmisor = rucText.isEmpty ? null : rucText;
    factura.razonSocialEmisor = razonController.text.isEmpty
        ? null
        : razonController.text;
    factura.tipoComprobante = tipoController.text.isEmpty
        ? null
        : tipoController.text;
    factura.serie = serieController.text.isEmpty ? null : serieController.text;
    factura.numero = numeroController.text.isEmpty
        ? null
        : numeroController.text;
    factura.fecha = fechaText.isEmpty ? null : fechaText;
    factura.total = totalVal == null ? null : totalVal.toString();
    factura.moneda = monedaController.text.isEmpty
        ? 'PEN'
        : monedaController.text;
    factura.rucCliente = rucClienteController.text.isEmpty
        ? null
        : rucClienteController.text;
    factura.razonSocialCliente = razonClienteController.text.isEmpty
        ? null
        : razonClienteController.text;
    // rawData usamos el toString del modelo original
    // (si el modelo original contiene más información, su toString la reflejará)

    widget.onSave(factura, widget.politicaSeleccionada);
  }

  @override
  Widget build(BuildContext context) {
    // Diseño mejorado: header, preview de imagen y campos en tarjeta
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Datos extraídos por OCR',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Preview imagen
                      if (widget.evidenciaFile != null)
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                            image: DecorationImage(
                              image: FileImage(widget.evidenciaFile!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 110,
                          height: 110,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                      const SizedBox(width: 12),
                      // Campos principales en columna: sólo mostramos los que existan
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((widget.ocrData.rucEmisor ?? '')
                                .trim()
                                .isNotEmpty)
                              TextField(
                                controller: rucController,
                                decoration: const InputDecoration(
                                  labelText: 'RUC Emisor',
                                ),
                              ),
                            if ((widget.ocrData.razonSocialEmisor ?? '')
                                .trim()
                                .isNotEmpty)
                              TextField(
                                controller: razonController,
                                decoration: const InputDecoration(
                                  labelText: 'Razón social emisor',
                                ),
                              ),
                            if ((widget.ocrData.tipoComprobante ?? '')
                                .trim()
                                .isNotEmpty)
                              TextField(
                                controller: tipoController,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de comprobante',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Campos adicionales en dos columnas
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        if ((widget.ocrData.serie ?? '').trim().isNotEmpty)
                          TextField(
                            controller: serieController,
                            decoration: const InputDecoration(
                              labelText: 'Serie',
                            ),
                          ),
                        if ((widget.ocrData.fecha ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: fechaController,
                            decoration: const InputDecoration(
                              labelText: 'Fecha',
                            ),
                          ),
                        ],
                        if ((widget.ocrData.subtotal ?? '')
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: subtotalController,
                            decoration: const InputDecoration(
                              labelText: 'Monto (Subtotal)',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        if ((widget.ocrData.numero ?? '').trim().isNotEmpty)
                          TextField(
                            controller: numeroController,
                            decoration: const InputDecoration(
                              labelText: 'Número',
                            ),
                          ),
                        if ((widget.ocrData.igv ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: igvController,
                            decoration: const InputDecoration(labelText: 'IGV'),
                          ),
                        ],
                        if ((widget.ocrData.total ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: totalController,
                            decoration: const InputDecoration(
                              labelText: 'Total',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Moneda y RUC cliente (si existen)
              if ((widget.ocrData.moneda ?? '').trim().isNotEmpty ||
                  (widget.ocrData.rucCliente ?? '').trim().isNotEmpty)
                Row(
                  children: [
                    if ((widget.ocrData.moneda ?? '').trim().isNotEmpty)
                      Expanded(
                        child: TextField(
                          controller: monedaController,
                          decoration: const InputDecoration(
                            labelText: 'Tipo moneda',
                          ),
                        ),
                      ),
                    if ((widget.ocrData.moneda ?? '').trim().isNotEmpty &&
                        (widget.ocrData.rucCliente ?? '').trim().isNotEmpty)
                      const SizedBox(width: 12),
                    if ((widget.ocrData.rucCliente ?? '').trim().isNotEmpty)
                      Expanded(
                        child: TextField(
                          controller: rucClienteController,
                          decoration: const InputDecoration(
                            labelText: 'RUC Cliente',
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              // Razón social cliente (si existe)
              if ((widget.ocrData.razonSocialCliente ?? '').trim().isNotEmpty)
                TextField(
                  controller: razonClienteController,
                  decoration: const InputDecoration(
                    labelText: 'Razón social cliente',
                  ),
                ),

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _onSave,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
