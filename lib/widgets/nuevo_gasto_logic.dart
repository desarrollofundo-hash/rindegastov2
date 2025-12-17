import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../models/dropdown_option.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/company_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class NuevoGastoLogic {
  /// Obtiene categorías desde el servicio API
  Future<List<DropdownOption>> fetchCategorias(
    ApiService apiService,
    String politica,
  ) async {
    return await apiService.getRendicionCategorias(politica: politica);
  }

  /// Obtiene tipos de gasto desde el servicio API
  Future<List<DropdownOption>> fetchTiposGasto(ApiService apiService) async {
    return await apiService.getTiposGasto();
  }

  /// Obtiene tipos de gasto desde el servicio API
  Future<List<DropdownOption>> fetchTipoMovilidad(ApiService apiService) async {
    return await apiService.getTiposMovilidad();
  }

  /// Comprime una imagen si supera 1MB
  Future<File?> compressImage(File file) async {
    final fileSize = await file.length();
    if (fileSize <= 1024 * 1024) {
      return file;
    }

    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 85,
      minWidth: 1024,
      minHeight: 1024,
    );

    if (result != null) {
      return File(result.path);
    }
    return null;
  }

  /// Convierte una imagen a PDF
  Future<File?> convertImageToPdf(File imageFile) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(imageFile.readAsBytesSync());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(child: pw.Image(image));
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Convertir PDF a imagen (primera página)
  /// Retorna un archivo de imagen PNG o null si falla
  Future<File?> convertirPdfAImagen(File pdfFile) async {
    try {
      debugPrint('🔄 Iniciando conversión de PDF a imagen...');

      // Leer los bytes del PDF
      final pdfBytes = await pdfFile.readAsBytes();

      // Verificar tamaño del PDF (limitar a 5MB para evitar problemas de memoria)
      const int maxSizeForConversion = 5 * 1024 * 1024; // 5 MB
      if (pdfBytes.lengthInBytes > maxSizeForConversion) {
        debugPrint(
          '⚠️ PDF demasiado grande (${pdfBytes.lengthInBytes} bytes), omitiendo conversión',
        );
        return null;
      }

      // Rasterizar la primera página del PDF con calidad media
      debugPrint('📄 Rasterizando primera página del PDF...');
      final stream = Printing.raster(pdfBytes, pages: [0], dpi: 150);
      final raster = await stream.first.timeout(const Duration(seconds: 15));
      final uiImage = await raster.toImage();

      // Convertir la imagen UI a bytes PNG
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        debugPrint('❌ No se pudo convertir la imagen a bytes');
        return null;
      }

      // Guardar la imagen como archivo temporal
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = '${tempDir.path}/pdf_converted_$timestamp.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(byteData.buffer.asUint8List());

      debugPrint('✅ Imagen guardada en: $imagePath');
      debugPrint('📊 Tamaño de la imagen: ${await imageFile.length()} bytes');

      return imageFile;
    } catch (e, stackTrace) {
      debugPrint('❌ Error al convertir PDF a imagen: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Prepara el mapa de datos del gasto para la API manteniendo las mismas reglas de truncado y defaults
  Map<String, dynamic> prepareGastoData({
    required String politica,
    required String categoria,
    required String tipoGasto,
    required String ruc,
    required String tipoComprobante,
    required String serie,
    required String numero,
    required String igv,
    required String fecha,
    required String total,
    required String moneda,
    required String nota,
    required String motivoviaje,
    required String origen,
    required String destino,
    required String movilidad,
    required String placa,
    required String razonSocial,
  }) {
    final companyService = CompanyService();

    final gastoData = <String, dynamic>{
      "idUser": UserService().currentUserCode,
      "dni": UserService().currentUserDni,
      "politica": politica.length > 80 ? politica.substring(0, 80) : politica,
      "categoria": categoria.isEmpty
          ? "GENERAL"
          : (categoria.length > 80 ? categoria.substring(0, 80) : categoria),
      "tipoGasto": tipoGasto.isEmpty
          ? "GASTO GENERAL"
          : (tipoGasto.length > 80 ? tipoGasto.substring(0, 80) : tipoGasto),
      "ruc": ruc.isEmpty ? "" : (ruc.length > 80 ? ruc.substring(0, 80) : ruc),
      "proveedor": razonSocial,
      "tipoCombrobante": tipoComprobante,
      "serie": serie,
      "numero": numero,
      "igv": double.tryParse(igv) ?? 0.0,
      "fecha": fecha,
      "total": double.tryParse(total) ?? 0.0,
      "moneda": moneda,
      "rucCliente": companyService.currentCompany?.ruc ?? "",
      "desEmp": companyService.currentCompany?.empresa ?? '',
      "desSed": "",
      "gerencia": companyService.currentCompany?.gerencia ?? '',
      "area": companyService.currentCompany?.area ?? '',
      "idCuenta": "",
      "consumidor": CompanyService().currentCompany?.consumidor ?? '',
      "placa": placa,
      "estadoActual": "BORRADOR",
      "glosa": "CREAR GASTO",
      "motivoViaje": motivoviaje,
      "lugarOrigen": origen,
      "lugarDestino": destino,
      "tipoMovilidad": movilidad,
      "obs": nota,
      "estado": "S",
      "fecCre": DateTime.now().toIso8601String(),
      "useReg": UserService().currentUserCode,
      "hostname": "FLUTTER",
      "fecEdit": DateTime.now().toIso8601String(),
      "useEdit": 0,
      "useElim": 0,
    };

    if (gastoData['total'] <= 0) {
      throw Exception('El monto debe ser mayor a 0');
    }

    if ((gastoData['razon'] != null) &&
        gastoData['razon'].toString().length > 100) {
      gastoData['razon'] = gastoData['razon'].toString().substring(0, 100);
    }

    return gastoData;
  }

  /// Guarda el gasto y la evidencia (si existe). Retorna el idRend obtenido.
  Future<int?> saveGastoWithEvidencia(
    ApiService apiService,
    Map<String, dynamic> gastoData,
    File? selectedFile,
  ) async {
    final idRend = await apiService.saveRendicionGasto(gastoData);

    if (idRend == null) {
      throw Exception(
        'No se pudo guardar la factura principal o no se obtuvo el ID autogenerado',
      );
    }

    String? driveId;
    // 2️⃣ Si hay archivo, lo subimos
    if (selectedFile != null) {
      final extension = p.extension(selectedFile.path);

      // 🔄 Si es un PDF, convertirlo a imagen
      File archivoASubir = selectedFile;
      String extensionFinal = extension;

      if (selectedFile.path.toLowerCase().endsWith('.pdf')) {
        debugPrint('📄 Detectado PDF, convirtiendo a imagen...');
        try {
          final imagenConvertida = await convertirPdfAImagen(selectedFile);
          if (imagenConvertida != null) {
            archivoASubir = imagenConvertida;
            extensionFinal = '.png';
            debugPrint('✅ PDF convertido a imagen exitosamente');
          } else {
            debugPrint('⚠️ No se pudo convertir PDF, subiendo PDF original');
          }
        } catch (e) {
          debugPrint('❌ Error al convertir PDF: $e');
          debugPrint('⚠️ Subiendo PDF original');
        }
      }

      final nombreArchivo =
          '${idRend}_${gastoData['ruc']}_${gastoData['serie']}_${gastoData['numero']}$extensionFinal';

      driveId = await apiService.subirArchivo(
        archivoASubir.path,
        nombreArchivo: nombreArchivo,
      );
    } else {
      debugPrint("⚠️ No se adjuntó evidencia. Se guardará sin archivo.");
    }

    final facturaDataEvidencia = {
      "idRend": idRend,
      "evidencia": null,
      "obs": driveId,
      "estado": "S",
      "fecCre": DateTime.now().toIso8601String(),
      "useReg": UserService().currentUserCode,
      "hostname": "FLUTTER",
      "fecEdit": DateTime.now().toIso8601String(),
      "useEdit": 0,
      "useElim": 0,
    };

    final successEvidencia = await apiService.saveRendicionGastoEvidencia(
      facturaDataEvidencia,
    );

    if (!successEvidencia) {
      debugPrint("ERROR AL ENVIAR EVIDENCIA");
      // No lanzar excepción por evidencia fallida, solo loguear
      return idRend;
    }

    return idRend;
  }

  /// Extrae mensaje del servidor (mismos patrones que en la UI original)
  String extractServerMessage(String errorMessage) {
    try {
      if (errorMessage.contains('Exception:')) {
        final parts = errorMessage.split('Exception:');
        if (parts.length > 1) {
          return parts[1].trim();
        }
      }

      if (errorMessage.contains('Error:')) {
        final parts = errorMessage.split('Error:');
        if (parts.length > 1) {
          return parts[1].trim();
        }
      }

      return errorMessage;
    } catch (e) {
      return 'Error desconocido al procesar la solicitud';
    }
  }

  bool isFacturaDuplicada(String message) {
    final messageLower = message.toLowerCase();
    return messageLower.contains('ya existe') ||
        messageLower.contains('duplicad') ||
        messageLower.contains('already exists') ||
        messageLower.contains('ya registrada') ||
        messageLower.contains('duplicate') ||
        messageLower.contains('constraint') ||
        messageLower.contains('primary key');
  }

  bool isFacturaDuplicadaMonto(String message) {
    final messageLower = message.toLowerCase();
    return messageLower.contains('ya excedio') ||
        messageLower.contains('limite') ||
        messageLower.contains('44 soeles');
  }

  /// Normaliza fechas (mismo comportamiento que la implementación original)
  String normalizarFecha(String fechaOriginal) {
    try {
      String fechaLimpia = fechaOriginal.trim();

      final formatosPosibles = [
        'yyyy-MM-dd',
        'dd/MM/yyyy',
        'dd-MM-yyyy',
        'yyyy/MM/dd',
        'MM/dd/yyyy',
        'dd.MM.yyyy',
        'yyyyMMdd',
        'dd/MM/yy',
        'yyyy-M-d',
        'dd/M/yyyy',
        'd/MM/yyyy',
        'd/M/yyyy',
      ];

      DateTime? fechaParseada;

      for (String formato in formatosPosibles) {
        try {
          fechaParseada = DateFormat(formato).parseStrict(fechaLimpia);
          break;
        } catch (e) {
          continue;
        }
      }

      if (fechaParseada == null) {
        try {
          fechaParseada = DateTime.parse(fechaLimpia);
        } catch (e) {
          try {
            String soloNumeros = fechaLimpia.replaceAll(RegExp(r'[^0-9]'), '');
            if (soloNumeros.length == 8) {
              String year = soloNumeros.substring(0, 4);
              String month = soloNumeros.substring(4, 6);
              String day = soloNumeros.substring(6, 8);
              fechaParseada = DateTime.parse('$year-$month-$day');
            }
          } catch (e2) {}
        }
      }

      if (fechaParseada != null) {
        final ahora = DateTime.now();
        final hace5Anos = ahora.subtract(const Duration(days: 365 * 5));
        final en1Ano = ahora.add(const Duration(days: 365));

        if (fechaParseada.isBefore(hace5Anos) ||
            fechaParseada.isAfter(en1Ano)) {
          return DateFormat('yyyy-MM-dd').format(ahora);
        }

        return DateFormat('yyyy-MM-dd').format(fechaParseada);
      }

      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    } catch (e) {
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }
}
