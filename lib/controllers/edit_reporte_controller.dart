import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/reporte_model.dart';
import '../services/api_service.dart';
import '../services/company_service.dart';
import 'package:path/path.dart' as p;

class EditReporteController {
  final ApiService _apiService;

  EditReporteController({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Verificar si una string es base64 válido
  bool isBase64(String str) {
    try {
      String cleanStr = str.trim();
      if (cleanStr.length < 4) return false;

      bool looksLikeBase64 =
          cleanStr.contains('data:image') ||
          cleanStr.startsWith('/9j/') ||
          cleanStr.startsWith('iVBOR') ||
          cleanStr.startsWith('R0lGOD') ||
          cleanStr.length > 100;

      if (looksLikeBase64) {
        base64Decode(cleanStr);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Validar si una URL es válida
  bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Convertir imagen a base64
  Future<String> convertImageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }

  /// Preparar y enviar los datos de la factura y evidencia al API
  /// Retorna true si la operación fue exitosa
  Future<bool> updateFacturaAPI({
    required Reporte reporte,
    required Map<String, dynamic> facturaData,
    required Map<String, dynamic> facturaDataEvidencia,
  }) async {
    // Llama a los métodos del ApiService
    await _apiService.saveupdateRendicionGasto(facturaData);
    final successEvidencia = await _apiService.saveRendicionGastoEvidencia(
      facturaDataEvidencia,
    );
    return successEvidencia;
  }

  /// Construye los payloads (factura y evidencia) y hace el flujo completo
  /// Retorna true si la operación fue exitosa
  Future<bool> saveReporte({
    required Reporte reporte,
    required String politica,
    required String categoria,
    required String tipoGasto,
    required String ruc,
    required String razonsocial,
    required String tipoComprobante,
    required String serie,
    required String numero,
    required String igv,
    required String fechaEmision,
    required String total,
    required String moneda,
    required String rucCliente,
    required String nota,
    // Campos adicionales de movilidad
    String? motivoViaje,
    String? lugarOrigen,
    String? lugarDestino,
    String? tipoMovilidad,
    String? placa,
    File? selectedImage,
    String? apiEvidencia,
  }) async {
    try {
      // Formatear fecha para SQL Server (solo fecha, sin hora)
      String fechaSQL = "";
      if (fechaEmision.isNotEmpty) {
        try {
          DateTime fecha;

          // Intentar parsear como DD/MM/YYYY (formato del DatePicker)
          if (fechaEmision.contains('/')) {
            final parts = fechaEmision.split('/');
            if (parts.length == 3) {
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              fecha = DateTime(year, month, day);
            } else {
              fecha = DateTime.now();
            }
          } else {
            // Intentar parsear como ISO 8601
            fecha = DateTime.parse(fechaEmision);
          }

          fechaSQL =
              "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
        } catch (e) {
          debugPrint('Error parseando fecha: $e');
          final fecha = DateTime.now();
          fechaSQL =
              "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
        }
      } else {
        final fecha = DateTime.now();
        fechaSQL =
            "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
      }

      final facturaData = {
        "idRend": reporte.idrend,
        "idUser": reporte.iduser,
        "dni": reporte.dni,
        "politica": politica,
        "categoria": categoria,
        "tipoGasto": tipoGasto,
        "ruc": ruc,
        "proveedor": razonsocial,
        "tipoCombrobante": tipoComprobante,
        "serie": serie,
        "numero": numero,
        "igv": double.tryParse(igv) ?? 0.0,
        "fecha": fechaSQL,
        "total": double.tryParse(total) ?? 0.0,
        "moneda": moneda,
        "rucCliente": rucCliente,
        "desEmp":
            reporte.desempr, //CompanyService().currentCompany?.empresa ?? '',
        "desSed": "",
        //"gerencia": CompanyService().currentCompany?.gerencia ?? '',
        //"area": CompanyService().currentCompany?.area ?? '',
        "idCuenta": "",
        "consumidor": "",
        "placa": placa,
        "estadoActual": "",
        "glosa": "",
        "motivoViaje": motivoViaje,
        "lugarOrigen": lugarOrigen,
        "lugarDestino": lugarDestino,
        "tipoMovilidad": tipoMovilidad,
        "obs": nota.length > 1000 ? nota.substring(0, 1000) : nota,
        "estado": "S",
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": reporte.iduser,
        "hostname": "FLUTTER",
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": reporte.iduser,
        "useElim": 0,
      };

      final extension = p.extension(
        selectedImage!.path,
      ); // obtiene la extensión, e.g. ".pdf", ".png", ".jpg"

      String nombreArchivo =
          '${reporte.idrend}_${ruc}_${serie}_${numero.toString()}$extension';

      final driveId = await _apiService.subirArchivo(
        selectedImage.path,
        nombreArchivo: nombreArchivo,
      );

      debugPrint('ID de archivo en Drive: $driveId');

      final facturaDataEvidencia = {
        "idRend": reporte.idrend,
        "evidencia": null,
        "obs": driveId,
        "estado": "S",
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": reporte.iduser,
        "hostname": "FLUTTER",
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": reporte.iduser,
        "useElim": 0,
      };

      debugPrint('Guardando factura');

      await _apiService.saveupdateRendicionGasto(facturaData);

      debugPrint('Guardando evidencia');

      final success = await _apiService.saveRendicionGastoEvidencia(
        facturaDataEvidencia,
      );
      return success;
    } catch (e) {
      rethrow;
    }
  }

  String getCompanyRuc() => CompanyService().companyRuc;
  String getCurrentCompanyName() => CompanyService().currentUserCompany;

  void dispose() {
    _apiService.dispose();
  }
}
