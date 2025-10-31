// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flu2/widgets/qr_reader_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:printing/printing.dart';
import '../models/reporte_model.dart';
import '../models/dropdown_option.dart';
import '../models/estado_reporte.dart';
import '../screens/qr_scanner_screen.dart';
import '../widgets/qr_reader_page.dart';
import '../services/factura_ia.dart';
import '../services/ocr_service.dart';
import '../models/factura_data_ocr.dart';
import '../widgets/politica_selector_modal.dart';
import '../widgets/factura_modal_peru_ocr.dart';
import '../widgets/nuevo_gasto_modal.dart';
import '../widgets/nuevo_gasto_movilidad.dart';
// NOTE: ya no abrimos `factura_modal_peru_ocr_extractor.dart` desde aquí.

class ReportesListController {
  // Abre el escáner QR y muestra SnackBar con resultado
  Future<void> abrirEscaneadorQR(
    BuildContext context,
    bool Function() mounted,
  ) async {
    try {
      final String? resultado = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QRScannerScreen()),
      );

      if (resultado != null && mounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código escaneado: $resultado'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Copiar',
              textColor: Colors.white,
              onPressed: () {
                print('Código QR: $resultado');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir escáner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Mostrar modal de política y continuar con la selección
  Future<void> escanerIA(BuildContext context, bool Function() mounted) async {
    try {
      // Mostrar modal de políticas y obtener la selección
      final seleccion = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => PoliticaSelectionModal(
          onPoliticaSelected: (politica) {
            Navigator.of(ctx).pop(politica);
          },
          onCancel: () {
            Navigator.of(ctx).pop(null);
          },
        ),
      );

      if (seleccion == null) return; // usuario canceló

      if (!mounted()) return;

      // Después de seleccionar la política, mostrar opciones de fuente
      // (Tomar foto, Elegir de galería, Seleccionar documento)
      final sourceSelection = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.28,
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
                    'Agregar documento IA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.indigo),
                  title: const Text('Tomar foto'),
                  onTap: () => Navigator.of(ctx).pop('camera'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo, color: Colors.indigo),
                  title: const Text('Elegir foto'),
                  onTap: () => Navigator.of(ctx).pop('gallery'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.insert_drive_file,
                    color: Colors.indigo,
                  ),
                  title: const Text('Seleccionar documento (PDF)'),
                  onTap: () => Navigator.of(ctx).pop('document'),
                ),
              ],
            ),
          );
        },
      );

      //antes de la previsualizacion  añadir esta funcionalidad
      //despues que tome la foto buscar en la foto el codigo qr y mostrar los campos que tiene ese codigo qr en un modal simple ,solo has eso y no modiques nada mas

      if (sourceSelection == null) return; // usuario canceló el selector

      if (!mounted()) return;

      if (sourceSelection == 'camera' || sourceSelection == 'gallery') {
        final picker = ImagePicker();
        final source = sourceSelection == 'camera'
            ? ImageSource.camera
            : ImageSource.gallery;
        try {
          final xfile = await picker.pickImage(
            source: source,
            imageQuality: 85,
          );
          if (xfile == null) return; // usuario no seleccionó imagen
          final file = File(xfile.path);

          // Mostrar previsualización y confirmar
          //final confirmed = await _mostrarPrevisualizacionImagen(context, file);
          //if (confirmed == true) {
          // Procesar con IA pasando la política seleccionada
          //  await procesarFacturaConIA(context, file, seleccion);
          //}

          final resultMap = await _mostrarPrevisualizacionImagen(context, file);

          if (resultMap != null) {
            final qrRaw = resultMap['qr'] as String?;
            if (qrRaw != null && qrRaw.trim().isNotEmpty) {
              final parts = qrRaw.split('|').map((s) => s.trim()).toList();
              final qrMap = <String, String>{
                'RUC Emisor': parts.length > 0 ? parts[0] : '',
                'Razón Social': '',
                'Tipo Comprobante': parts.length > 1 ? parts[1] : '',
                'Serie': parts.length > 2 ? parts[2] : '',
                'Número': parts.length > 3 ? parts[3] : '',
                'Subtotal': '',
                'IGV': parts.length > 4 ? parts[4] : '',
                'Total': parts.length > 5 ? parts[5] : '',
                'Fecha': parts.length > 6 ? parts[6] : '',
                'RUC Cliente': parts.length > 8 ? parts[8] : '',
                'Razón Social Cliente': '',
                'raw_text': qrRaw,
              };

              final ocrMap = {
                'RUC Emisor': qrMap['RUC Emisor']!,
                'Razón Social': qrMap['Razón Social']!,
                'Tipo Comprobante': qrMap['Tipo Comprobante']!,
                'Serie': qrMap['Serie']!,
                'Número': qrMap['Número']!,
                'Fecha': qrMap['Fecha']!,
                'Subtotal': qrMap['Subtotal']!,
                'IGV': qrMap['IGV']!,
                'Total': qrMap['Total']!,
                'Moneda': '',
                'RUC Cliente': qrMap['RUC Cliente']!,
                'Razón Social Cliente': qrMap['Razón Social Cliente']!,
                'raw_text': qrMap['raw_text']!,
              };

              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => FacturaModalPeruOCR(
                  ocrData: ocrMap,
                  evidenciaFile: file,
                  politicaSeleccionada: seleccion,
                  onSave: (facturaData, _) {
                    Navigator.of(context).pop();
                  },
                  onCancel: () => Navigator.of(context).pop(),
                ),
              );
            } else {
              if (mounted()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CODIGO QR NO ENCONTRADO EN IMAGEN'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        } catch (e) {
          if (mounted()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al capturar/seleccionar imagen: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else if (sourceSelection == 'document') {
        try {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );
          if (result == null) return; // cancelado
          final path = result.files.single.path;
          if (path == null) return;
          final file = File(path);

          final resultMap = await _mostrarPrevisualizacionDocumento(
            context,
            file,
          );

          if (resultMap != null) {
            final qrRaw = resultMap['qr'] as String?;
            if (qrRaw != null && qrRaw.trim().isNotEmpty) {
              final parts = qrRaw.split('|').map((s) => s.trim()).toList();
              final qrMap = <String, String>{
                'RUC Emisor': parts.length > 0 ? parts[0] : '',
                'Razón Social': '',
                'Tipo Comprobante': parts.length > 1 ? parts[1] : '',
                'Serie': parts.length > 2 ? parts[2] : '',
                'Número': parts.length > 3 ? parts[3] : '',
                'Subtotal': '',
                'IGV': parts.length > 4 ? parts[4] : '',
                'Total': parts.length > 5 ? parts[5] : '',
                'Fecha': parts.length > 6 ? parts[6] : '',
                'RUC Cliente': parts.length > 8 ? parts[8] : '',
                'Razón Social Cliente': '',
                'raw_text': qrRaw,
              };

              final ocrMap = {
                'RUC Emisor': qrMap['RUC Emisor']!,
                'Razón Social': qrMap['Razón Social']!,
                'Tipo Comprobante': qrMap['Tipo Comprobante']!,
                'Serie': qrMap['Serie']!,
                'Número': qrMap['Número']!,
                'Fecha': qrMap['Fecha']!,
                'Subtotal': qrMap['Subtotal']!,
                'IGV': qrMap['IGV']!,
                'Total': qrMap['Total']!,
                'Moneda': '',
                'RUC Cliente': qrMap['RUC Cliente']!,
                'Razón Social Cliente': qrMap['Razón Social Cliente']!,
                'raw_text': qrMap['raw_text']!,
              };

              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => FacturaModalPeruOCR(
                  ocrData: ocrMap,
                  evidenciaFile: file,
                  politicaSeleccionada: seleccion,
                  onSave: (facturaData, _) {
                    Navigator.of(context).pop();
                  },
                  onCancel: () => Navigator.of(context).pop(),
                ),
              );
            } else {
              if (mounted()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CODIGO QR NO ENCONTRADO EN DOCUMENTO'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        } catch (e) {
          if (mounted()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al seleccionar documento: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir selección de política: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Mostrar modal de política y continuar con la selección
  // Mostrar modal de política y continuar con la selección
  Future<void> crearGasto(BuildContext context, bool Function() mounted) async {
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (modalContext) => PoliticaSelectionModal(
          onPoliticaSelected: (politica) {
            // cerramos el selector usando el contexto del bottom sheet
            Navigator.of(modalContext).pop();

            // Abrir el modal correspondiente después de que el selector se cierre.
            // Future.microtask evita problemas al abrir un nuevo bottom sheet
            // mientras se está cerrando otro.
            Future.microtask(() {
              if (!mounted()) return;
              navegarSegunPolitica(context, politica);
            });
          },
          onCancel: () {
            Navigator.of(modalContext).pop();
          },
        ),
      );
    } catch (e) {
      if (mounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir selección de política: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Navegar y abrir modal según la política seleccionada
  /// Acepta `DropdownOption` o un `String` y lo normaliza a `DropdownOption`.
  void navegarSegunPolitica(BuildContext context, dynamic politica) {
    // Normalizar a DropdownOption si es necesario
    final DropdownOption politicaObj = (politica is DropdownOption)
        ? politica
        : DropdownOption(value: politica?.toString() ?? '', id: '');

    final key = politicaObj.value.toUpperCase();
    switch (key) {
      case 'GENERAL':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => NuevoGastoModal(
            politicaSeleccionada: politicaObj,
            onCancel: () => Navigator.of(ctx).pop(),
            onSave: (data) {
              Navigator.of(ctx).pop();
              // opcional: manejar resultado saved data si es necesario
            },
          ),
        );
        break;
      case 'GASTOS DE MOVILIDAD':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => NuevoGastoMovilidad(
            politicaSeleccionada: politicaObj,
            onCancel: () => Navigator.of(ctx).pop(),
            onSave: (data) {
              Navigator.of(ctx).pop();
            },
          ),
        );
        break;
      default:
        // Para políticas no contempladas, mostrar mensaje
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Política no implementada: ${politicaObj.value}'),
            backgroundColor: Colors.orange,
          ),
        );
        break;
    }
  }

  // Muestra un modal para elegir fuente (tomar foto, elegir foto, documento), luego previsualizar
  Future<void> mostrarModalCaptura(
    BuildContext context,
    DropdownOption politica,
    bool Function() mounted,
  ) async {
    try {
      final selection = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.28,
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
                    'Agregar documento',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.indigo),
                  title: const Text('Tomar foto'),
                  onTap: () => Navigator.of(ctx).pop('camera'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo, color: Colors.indigo),
                  title: const Text('Elegir foto'),
                  onTap: () => Navigator.of(ctx).pop('gallery'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.insert_drive_file,
                    color: Colors.indigo,
                  ),
                  title: const Text('Seleccionar documento (PDF)'),
                  onTap: () => Navigator.of(ctx).pop('document'),
                ),
              ],
            ),
          );
        },
      );

      if (selection == null) return; // user cancelled

      if (!mounted()) return;

      if (selection == 'camera' || selection == 'gallery') {
        final picker = ImagePicker();
        final source = selection == 'camera'
            ? ImageSource.camera
            : ImageSource.gallery;
        try {
          final xfile = await picker.pickImage(
            source: source,
            imageQuality: 85,
          );
          if (xfile == null) return;
          final file = File(xfile.path);

          // Mostrar previsualización y confirmar
          //final confirmed = await _mostrarPrevisualizacionImagen(context, file);
          //if (confirmed == true) {
          // Procesar con IA (o la acción que corresponda) usando política por defecto
          //  await procesarFacturaConIA(context, file, 'GENERAL');
          //}

          final resultMap = await _mostrarPrevisualizacionImagen(context, file);

          if (resultMap != null) {
            final qrRaw = resultMap['qr'] as String?;
            if (qrRaw != null && qrRaw.trim().isNotEmpty) {
              final parts = qrRaw.split('|').map((s) => s.trim()).toList();
              final qrMap = <String, String>{
                'RUC Emisor': parts.length > 0 ? parts[0] : '',
                'Razón Social': '',
                'Tipo Comprobante': parts.length > 1 ? parts[1] : '',
                'Serie': parts.length > 2 ? parts[2] : '',
                'Número': parts.length > 3 ? parts[3] : '',
                'Subtotal': '',
                'IGV': parts.length > 4 ? parts[4] : '',
                'Total': parts.length > 5 ? parts[5] : '',
                'Fecha': parts.length > 6 ? parts[6] : '',
                'RUC Cliente': parts.length > 8 ? parts[8] : '',
                'Razón Social Cliente': '',
                'raw_text': qrRaw,
              };

              final ocrMap = {
                'RUC Emisor': qrMap['RUC Emisor']!,
                'Razón Social': qrMap['Razón Social']!,
                'Tipo Comprobante': qrMap['Tipo Comprobante']!,
                'Serie': qrMap['Serie']!,
                'Número': qrMap['Número']!,
                'Fecha': qrMap['Fecha']!,
                'Subtotal': qrMap['Subtotal']!,
                'IGV': qrMap['IGV']!,
                'Total': qrMap['Total']!,
                'Moneda': '',
                'RUC Cliente': qrMap['RUC Cliente']!,
                'Razón Social Cliente': qrMap['Razón Social Cliente']!,
                'raw_text': qrMap['raw_text']!,
              };

              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => FacturaModalPeruOCR(
                  ocrData: ocrMap,
                  evidenciaFile: file,
                  politicaSeleccionada: 'GENERAL',
                  onSave: (facturaData, _) {
                    Navigator.of(context).pop();
                  },
                  onCancel: () => Navigator.of(context).pop(),
                ),
              );
            } else {
              if (mounted()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Documento seleccionado'),
                    backgroundColor: Colors.indigo,
                  ),
                );
              }
            }
          }
        } catch (e) {
          if (mounted()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al seleccionar imagen: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else if (selection == 'document') {
        try {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );
          if (result == null) return;
          final path = result.files.single.path;
          if (path == null) return;
          final file = File(path);

          final resultMap = await _mostrarPrevisualizacionDocumento(
            context,
            file,
          );

          if (resultMap != null) {
            final qrRaw = resultMap['qr'] as String?;
            if (qrRaw != null && qrRaw.trim().isNotEmpty) {
              final parts = qrRaw.split('|').map((s) => s.trim()).toList();
              final qrMap = <String, String>{
                'RUC Emisor': parts.length > 0 ? parts[0] : '',
                'Razón Social': '',
                'Tipo Comprobante': parts.length > 1 ? parts[1] : '',
                'Serie': parts.length > 2 ? parts[2] : '',
                'Número': parts.length > 3 ? parts[3] : '',
                'Subtotal': '',
                'IGV': parts.length > 4 ? parts[4] : '',
                'Total': parts.length > 5 ? parts[5] : '',
                'Fecha': parts.length > 6 ? parts[6] : '',
                'RUC Cliente': parts.length > 8 ? parts[8] : '',
                'Razón Social Cliente': '',
                'raw_text': qrRaw,
              };

              final ocrMap = {
                'RUC Emisor': qrMap['RUC Emisor']!,
                'Razón Social': qrMap['Razón Social']!,
                'Tipo Comprobante': qrMap['Tipo Comprobante']!,
                'Serie': qrMap['Serie']!,
                'Número': qrMap['Número']!,
                'Fecha': qrMap['Fecha']!,
                'Subtotal': qrMap['Subtotal']!,
                'IGV': qrMap['IGV']!,
                'Total': qrMap['Total']!,
                'Moneda': '',
                'RUC Cliente': qrMap['RUC Cliente']!,
                'Razón Social Cliente': qrMap['Razón Social Cliente']!,
                'raw_text': qrMap['raw_text']!,
              };

              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => FacturaModalPeruOCR(
                  ocrData: ocrMap,
                  evidenciaFile: file,
                  politicaSeleccionada: 'GENERAL',
                  onSave: (facturaData, _) {
                    Navigator.of(context).pop();
                  },
                  onCancel: () => Navigator.of(context).pop(),
                ),
              );
            } else {
              if (mounted()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Documento seleccionado'),
                    backgroundColor: Colors.indigo,
                  ),
                );
              }
            }
          }
        } catch (e) {
          if (mounted()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al seleccionar documento: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en selector de captura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Muestra un diálogo con previsualización de imagen y devuelve true si el usuario confirma
  Future<Map<String, dynamic>?> _mostrarPrevisualizacionImagen(
    BuildContext context,
    File file,
  ) async {
    ui.Image? uiImage;
    String? qrText;

    try {
      // Cargar la imagen del archivo como ui.Image (para devolverla al final)
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      uiImage = frame.image;
    } catch (e) {
      debugPrint('Error cargando imagen como ui.Image: $e');
    }

    // Variable que muestra el texto del QR en el diálogo
    String analisis = '';
    bool _decodingStarted = false;

    return showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setState) {
            // Iniciar decodificación QR solo una vez
            if (!_decodingStarted) {
              _decodingStarted = true;
              _decodeQrPreferMlKit(file.path)
                  .then((data) {
                    setState(() {
                      analisis = data ?? 'No se encontró QR';
                      qrText = data;
                    });
                  })
                  .catchError((e) {
                    setState(() {
                      analisis = 'Error leyendo QR: $e';
                      qrText = null;
                    });
                  });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Container(
                width: double.maxFinite,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: const Text(
                  'Previsualización',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (analisis.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Análisis QR:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: SelectableText(
                            analisis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                      SizedBox(
                        width: MediaQuery.of(ctx2).size.width * 0.8,
                        height: MediaQuery.of(ctx2).size.height * 0.6,
                        child: InteractiveViewer(
                          panEnabled: true,
                          scaleEnabled: true,
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: Image.file(file, fit: BoxFit.contain),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx2).pop(null),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(ctx2).pop({'image': uiImage, 'qr': qrText}),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Muestra una previsualización de PDF (miniatura de la primera página)
  /// y devuelve {'image': ui.Image?, 'qr': String?} si el usuario confirma.
  Future<Map<String, dynamic>?> _mostrarPrevisualizacionDocumento(
    BuildContext context,
    File file,
  ) async {
    // Rasterizar primera página del PDF (segura para dispositivos con poca memoria)
    Future<Map<String, dynamic>?> _rasterFirstPage() async {
      try {
        final bytes = await file.readAsBytes();
        const int maxSizeForRaster = 2 * 1024 * 1024; // 2 MB
        if (bytes.lengthInBytes > maxSizeForRaster) {
          debugPrint(
            '⚠️ PDF demasiado grande (${bytes.lengthInBytes} bytes), usando fallback.',
          );
          return null;
        }

        final stream = Printing.raster(bytes, pages: [0], dpi: 24.0);
        final raster = await stream.first.timeout(const Duration(seconds: 8));
        final uiImage = await raster.toImage();

        // Decodificar QR desde la imagen generada
        String? qrText;
        try {
          final bd = await uiImage.toByteData(format: ui.ImageByteFormat.png);
          if (bd != null) {
            final tmpDir = await Directory.systemTemp.createTemp('pdf_preview');
            final tmpFile = File('${tmpDir.path}/preview.png');
            await tmpFile.writeAsBytes(bd.buffer.asUint8List());
            qrText = await _decodeQrPreferMlKit(tmpFile.path);
            await tmpFile.delete();
            await tmpDir.delete();
          }
        } catch (e) {
          debugPrint('Error extrayendo QR desde PDF: $e');
        }

        return {'image': uiImage, 'qr': qrText};
      } catch (e, st) {
        debugPrint('❌ No se pudo rasterizar PDF: $e\n$st');
        return null;
      }
    }

    final map = await _rasterFirstPage();

    return showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final img = map?['image'] as ui.Image?;
        final qr = map?['qr'] as String?;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Previsualización de Documento',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (qr != null && qr.trim().isNotEmpty) ...[
                const Text(
                  'Datos extraídos (QR):',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                SelectableText(qr, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: MediaQuery.of(ctx).size.width * 0.7,
                height: MediaQuery.of(ctx).size.height * 0.5,
                child: img != null
                    ? InteractiveViewer(
                        panEnabled: true,
                        scaleEnabled: true,
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: RawImage(image: img, fit: BoxFit.contain),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.insert_drive_file,
                            size: 64,
                            color: Colors.indigo,
                          ),
                          const SizedBox(height: 8),
                          Text(file.path.split(Platform.pathSeparator).last),
                        ],
                      ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop({
                  'image': img,
                  'qr': qr, // 👈 Envía el código QR leído
                });
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  // Escanear documento y procesar con IA si es un File
  Future<void> escanearDocumento(
    BuildContext context,
    bool Function() mounted,
  ) async {
    try {
      // Antes: navegábamos a DocumentScannerScreen. Ahora capturamos imagen
      // directamente con image_picker para evitar dependencia en la pantalla.
      try {
        final picker = ImagePicker();
        final xfile = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (xfile != null && mounted()) {
          final file = File(xfile.path);
          await procesarFacturaConIA(context, file, 'GENERAL');
        }
      } catch (e) {
        if (mounted()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al capturar imagen: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al escanear documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> procesarFacturaConIA(
    BuildContext context,
    File imagenFactura,
    String politicaSeleccionada, // nueva política a usar al abrir modal
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('🤖 Procesando factura con IA...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );

    try {
      // Comprimir la imagen para que no supere 1MB antes de enviarla a OCR.space
      File imageToSend = imagenFactura;

      try {
        final originalSize = await imagenFactura.length();
        debugPrint(
          'Imagen original: ${imagenFactura.path} -> ${originalSize} bytes',
        );

        if (originalSize > 1024 * 1024) {
          // Intentar comprimir decrementando la calidad
          int quality = 85;
          File? compressed;
          while (quality >= 20) {
            try {
              final targetPath = imagenFactura.path.replaceFirstMapped(
                RegExp(r'(\.[^.]+)$'),
                (m) => '_cmp_q${quality}${m[0]}',
              );
              final resultBytes = await FlutterImageCompress.compressWithFile(
                imagenFactura.path,
                quality: quality,
                format: CompressFormat.jpeg,
              );
              if (resultBytes != null) {
                compressed = await File(targetPath).writeAsBytes(resultBytes);
                final newSize = await compressed.length();
                debugPrint('Compresión q=$quality -> $newSize bytes');
                if (newSize <= 1024 * 1024) {
                  imageToSend = compressed;
                  break;
                }
              }
            } catch (e) {
              debugPrint('Error al comprimir q=$quality: $e');
            }
            quality -= 10;
          }
          // Si no se logró comprimir por calidad, usar la última comprimida si existe
          if (imageToSend == imagenFactura && compressed != null)
            imageToSend = compressed;
        }
      } catch (e) {
        debugPrint('No se pudo calcular/comprimir imagen: $e');
      }

      // Intentar primero el OCR local (procesarFactura) y mapear el resultado
      // a una estructura similar a la que usa el resto del flujo. Si falla,
      // se hace fallback a OcrSpaceService.parseImage.
      Map<String, dynamic> ocrResult;
      try {
        final facturaOcr = await procesarFactura(imageToSend.path);
        debugPrint('Factura OCR: ${facturaOcr.toString()}');

        ocrResult = {
          'ParsedResults': [
            {'ParsedText': facturaOcr.toString()},
          ],
          'FacturaOcrData': {
            'rucEmisor': facturaOcr.rucEmisor ?? '',
            'razonSocialEmisor': facturaOcr.razonSocialEmisor ?? '',
            'tipoComprobante': facturaOcr.tipoComprobante ?? '',
            'serie': facturaOcr.serie ?? '',
            'numero': facturaOcr.numero ?? '',
            'fecha': facturaOcr.fecha ?? '',
            'subtotal': facturaOcr.subtotal ?? '',
            'igv': facturaOcr.igv ?? '',
            'total': facturaOcr.total ?? '',
            'moneda': facturaOcr.moneda ?? '',
            'rucCliente': facturaOcr.rucCliente ?? '',
            'razonSocialCliente': facturaOcr.razonSocialCliente ?? '',
          },
        };
      } catch (e) {
        debugPrint('Error procesando con OCR local: $e');
        // No usamos el servicio externo como fallback aquí.
        // Devolvemos un resultado con clave Error para que el flujo
        // superior lo detecte y muestre el diálogo correspondiente.
        ocrResult = {'Error': e.toString()};
      }

      // Eliminado diálogo de JSON por petición del usuario: no mostramos
      // el JSON crudo. Continuamos directamente con la lógica que usa
      // 'FacturaOcrData' para abrir el modal si corresponde.
      bool openedFromJsonDialog = false;
      if (ocrResult.containsKey('FacturaOcrData')) {
        final f = ocrResult['FacturaOcrData'];
        if (f is Map) {
          final facturaFromJson = FacturaOcrData();
          facturaFromJson.rucEmisor = (f['rucEmisor'] as String?)?.trim();
          facturaFromJson.razonSocialEmisor =
              (f['razonSocialEmisor'] as String?)?.trim();
          facturaFromJson.tipoComprobante = (f['tipoComprobante'] as String?)
              ?.trim();
          facturaFromJson.serie = (f['serie'] as String?)?.trim();
          facturaFromJson.numero = (f['numero'] as String?)?.trim();
          facturaFromJson.fecha = (f['fecha'] as String?)?.trim();
          facturaFromJson.subtotal = (f['subtotal'] as String?)?.trim();
          facturaFromJson.igv = (f['igv'] as String?)?.trim();
          facturaFromJson.total = (f['total'] as String?)?.trim();
          facturaFromJson.moneda = (f['moneda'] as String?)?.trim();
          facturaFromJson.rucCliente = (f['rucCliente'] as String?)?.trim();
          facturaFromJson.razonSocialCliente =
              (f['razonSocialCliente'] as String?)?.trim();

          // Abrir modal sólo si al menos un campo está presente
          final hasAny = [
            facturaFromJson.rucEmisor,
            facturaFromJson.razonSocialEmisor,
            facturaFromJson.tipoComprobante,
            facturaFromJson.serie,
            facturaFromJson.numero,
            facturaFromJson.fecha,
            facturaFromJson.subtotal,
            facturaFromJson.igv,
            facturaFromJson.total,
            facturaFromJson.moneda,
            facturaFromJson.rucCliente,
            facturaFromJson.razonSocialCliente,
          ].any((v) => v != null && v.toString().trim().isNotEmpty);

          if (hasAny) {
            openedFromJsonDialog = true;
            // Intentar leer y descomponer QR de la imagen primero.
            // Si se obtiene una trama válida, enviar esos campos al modal.
            Map<String, String> ocrMap = {
              'RUC Emisor': facturaFromJson.rucEmisor ?? '',
              'Razón Social': facturaFromJson.razonSocialEmisor ?? '',
              'Tipo Comprobante': facturaFromJson.tipoComprobante ?? '',
              'Serie': facturaFromJson.serie ?? '',
              'Número': facturaFromJson.numero ?? '',
              'Fecha': facturaFromJson.fecha ?? '',
              'Subtotal': facturaFromJson.subtotal ?? '',
              'IGV': facturaFromJson.igv ?? '',
              'Total': facturaFromJson.total ?? '',
              'Moneda': facturaFromJson.moneda ?? '',
              'RUC Cliente': facturaFromJson.rucCliente ?? '',
              'Razón Social Cliente': facturaFromJson.razonSocialCliente ?? '',
              'raw_text': facturaFromJson.toString(),
            };

            try {
              final qrRaw = await QrCodeToolsPlugin.decodeFrom(
                imageToSend.path,
              );

              if (qrRaw != null && qrRaw.trim().isNotEmpty) {
                final parts = qrRaw.split('|').map((s) => s.trim()).toList();

                // Mapear posiciones de la trama QR a los campos esperados.
                // Ejemplo esperado de trama:
                // RUC|Tipo|Serie|Número|Subtotal|Total|Fecha|Moneda|RUCCliente|...

                final qrMap = <String, String>{
                  'RUC Emisor': parts.length > 0 ? parts[0] : '',
                  'Razón Social': '',
                  'Tipo Comprobante': parts.length > 1 ? parts[1] : '',
                  'Serie': parts.length > 2 ? parts[2] : '',
                  'Número': parts.length > 3 ? parts[3] : '',
                  'Subtotal': '',
                  'IGV': parts.length > 4 ? parts[4] : '',
                  'Total': parts.length > 5 ? parts[5] : '',
                  'Fecha': parts.length > 6 ? parts[6] : '',
                  'RUC Cliente': parts.length > 8 ? parts[8] : '',
                  'Razón Social Cliente': '',
                  'raw_text': qrRaw,
                };
                ocrMap = Map<String, String>.from(qrMap);

                // Usar los valores del QR para poblar el mapa que se enviará
                // al modal (sobrescribiendo donde exista información).
              }
            } catch (e) {
              debugPrint(
                'No se pudo leer QR desde imagen para poblar modal: $e',
              );
            }

            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => FacturaModalPeruOCR(
                ocrData: ocrMap,
                evidenciaFile: imagenFactura,
                politicaSeleccionada: politicaSeleccionada,
                onSave: (facturaData, _) {
                  Navigator.of(context).pop();
                },
                onCancel: () => Navigator.of(context).pop(),
              ),
            );
          }
        }
      }
      String parsedText = '';
      if (ocrResult.containsKey('ParsedResults')) {
        final results = ocrResult['ParsedResults'];
        if (results is List && results.isNotEmpty) {
          final first = results[0];
          parsedText = (first['ParsedText'] ?? '').toString();
        }
      } else if (ocrResult.containsKey('Error')) {
        debugPrint('OCR Error: ${ocrResult['Error']}');
      }

      Map<String, String> datosExtraidos = {};

      if (parsedText.isNotEmpty) {
        // Usar el JSON completo (ParsedResults) para una extracción más robusta
        datosExtraidos = await FacturaIA.extraerDatosDesdeParsedResults(
          ocrResult,
        );

        // Si el extractor no logró identificar campos pero sí hay texto OCR,
        // abrimos el modal con el texto bruto para que el usuario pueda
        // revisar/editar manualmente. Esto evita el mensaje genérico.
        if (datosExtraidos.isEmpty) {
          datosExtraidos = {'raw_text': parsedText};
          // Mensaje corto para debug/UX
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Texto OCR detectado, abriendo modal para revisión',
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Si OCR.space no entrega texto, informar y no procesar con otro motor
        final err =
            ocrResult['Error'] ??
            'OCR.space no devolvió texto para esta imagen';
        datosExtraidos = {'Error': err.toString()};
      }

      if (!openedFromJsonDialog &&
          datosExtraidos.isNotEmpty &&
          !datosExtraidos.containsKey('Error')) {
        // Abrir modal prellenado con los datos extraídos por OCR (nuevo extractor)
        // Convertir el mapa `datosExtraidos` a `FacturaOcrData` y pasar el modelo
        String? getVal(String key, [String? alt]) {
          final v =
              datosExtraidos[key] ?? (alt != null ? datosExtraidos[alt] : null);
          if (v == null) return null;
          final t = v.trim();
          return t.isEmpty ? null : t;
        }

        final facturaModel = FacturaOcrData();
        facturaModel.rucEmisor = getVal('rucEmisor', 'RUC Emisor');
        facturaModel.razonSocialEmisor = getVal(
          'razonSocialEmisor',
          'Razón Social',
        );
        facturaModel.tipoComprobante = getVal(
          'tipoComprobante',
          'Tipo Comprobante',
        );
        facturaModel.serie = getVal('serie', 'Serie');
        facturaModel.numero = getVal('numero', 'Número');
        facturaModel.fecha = getVal('fecha', 'Fecha');
        facturaModel.subtotal = getVal('subtotal', 'Subtotal');
        facturaModel.igv = getVal('igv', 'IGV');
        facturaModel.total = getVal('total', 'Total');
        facturaModel.moneda = getVal('moneda', 'Moneda');
        facturaModel.rucCliente = getVal('rucCliente', 'RUC Cliente');
        facturaModel.razonSocialCliente = getVal(
          'razonSocialCliente',
          'Razón Social Cliente',
        );

        final ocrMap = <String, String>{
          'RUC Emisor': facturaModel.rucEmisor ?? '',
          'Razón Social': facturaModel.razonSocialEmisor ?? '',
          'Tipo Comprobante': facturaModel.tipoComprobante ?? '',
          'Serie': facturaModel.serie ?? '',
          'Número': facturaModel.numero ?? '',
          'Fecha': facturaModel.fecha ?? '',
          'Subtotal': facturaModel.subtotal ?? '',
          'IGV': facturaModel.igv ?? '',
          'Total': facturaModel.total ?? '',
          'Moneda': facturaModel.moneda ?? '',
          'RUC Cliente': facturaModel.rucCliente ?? '',
          'Razón Social Cliente': facturaModel.razonSocialCliente ?? '',
          'raw_text': facturaModel.toString(),
        };

        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => FacturaModalPeruOCR(
            ocrData: ocrMap,
            evidenciaFile: imagenFactura,
            politicaSeleccionada: politicaSeleccionada,
            onSave: (facturaData, _) {
              // El modal nuevo llama onSave con la factura creada.
              Navigator.of(context).pop();
            },
            onCancel: () => Navigator.of(context).pop(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error procesando con IA: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void mostrarDatosExtraidos(BuildContext context, Map<String, String> datos) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.psychology, color: Colors.green),
              SizedBox(width: 8),
              Text('🤖 Datos Extraídos por IA'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Campos detectados para el modal peruano:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ...datos.entries
                    .map(
                      (entry) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                '${entry.key}:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estos datos se pueden usar automáticamente en el modal de factura peruana',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ ${datos.length} campos extraídos listos para usar',
                    ),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(
                      label: 'Abrir Modal',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.assignment),
              label: const Text('Usar en Modal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // Filtrar reportes por estado
  List<Reporte> filtrarReportes(List<Reporte> reportes, EstadoReporte filtro) {
    // Helper para detectar estado del reporte en diferentes campos/formatos
    bool isBorrador(Reporte r) {
      final candidates = [r.destino, r.obs, r.glosa];
      for (final v in candidates) {
        if (v == null) continue;
        final s = v.trim().toUpperCase();
        if (s == 'B' || s == 'BORRADOR' || s.contains('BORRADOR')) return true;
      }
      return false;
    }

    // Nota: el filtro de 'enviado' ahora usa !isBorrador, por lo que
    // no se necesita una función separada isEnviado.

    switch (filtro) {
      case EstadoReporte.borrador:
        return reportes.where((r) => isBorrador(r)).toList();
      case EstadoReporte.enviado:
        // Incluir cualquier reporte que NO sea borrador. Esto agrupa
        // estados como 'ENVIADO', 'EN INFORME', 'APROBADO', etc.
        return reportes.where((r) => !isBorrador(r)).toList();
      case EstadoReporte.todos:
        return reportes;
    }
  }

  // Decodifica QR usando Google ML Kit (BarcodeScanner). Retorna el rawValue
  // del primer barcode encontrado, o null si no se detecta ninguno.
  Future<String?> _decodeQrWithMlKit(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final scanner = BarcodeScanner();
      final barcodes = await scanner.processImage(inputImage);
      await scanner.close();
      for (final b in barcodes) {
        final v = b.rawValue;
        if (v != null && v.trim().isNotEmpty) return v;
      }
    } catch (e) {
      debugPrint('ML Kit barcode scan error: $e');
    }
    return null;
  }

  // Intenta primero con ML Kit (más robusto) y si no devuelve nada, usa
  // QrCodeToolsPlugin como fallback (si está disponible).
  Future<String?> _decodeQrPreferMlKit(String imagePath) async {
    // Intento ML Kit primero
    final fromMl = await _decodeQrWithMlKit(imagePath);
    if (fromMl != null && fromMl.trim().isNotEmpty) return fromMl;

    // Fallback a qr_code_tools
    try {
      final fromQt = await QrCodeToolsPlugin.decodeFrom(imagePath);
      if (fromQt != null && fromQt.trim().isNotEmpty) return fromQt;
    } catch (e) {
      debugPrint('Fallback qr_code_tools error: $e');
    }

    return null;
  }
}
