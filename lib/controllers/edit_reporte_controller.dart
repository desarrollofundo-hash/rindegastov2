import 'dart:io';
import 'dart:convert';

import '../models/reporte_model.dart';
import '../services/api_service.dart';
import '../services/company_service.dart';

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
    File? selectedImage,
    String? apiEvidencia,
  }) async {
    try {
      // Formatear fecha para SQL Server (solo fecha, sin hora)
      String fechaSQL = "";
      if (fechaEmision.isNotEmpty) {
        try {
          final fecha = DateTime.parse(fechaEmision);
          fechaSQL =
              "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
        } catch (e) {
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
        "politica": politica.length > 80 ? politica.substring(0, 80) : politica,
        "categoria": categoria.isEmpty
            ? "GENERAL"
            : (categoria.length > 80 ? categoria.substring(0, 80) : categoria),
        "tipoGasto": tipoGasto.isEmpty
            ? "GASTO GENERAL"
            : (tipoGasto.length > 80 ? tipoGasto.substring(0, 80) : tipoGasto),
        "ruc": ruc.isEmpty
            ? ""
            : (ruc.length > 80 ? ruc.substring(0, 80) : ruc),
        "proveedor": "",
        "tipoCombrobante": tipoComprobante.isEmpty
            ? ""
            : (tipoComprobante.length > 180
                  ? tipoComprobante.substring(0, 180)
                  : tipoComprobante),
        "serie": serie.isEmpty
            ? ""
            : (serie.length > 80 ? serie.substring(0, 80) : serie),
        "numero": numero.isEmpty
            ? ""
            : (numero.length > 80 ? numero.substring(0, 80) : numero),
        "igv": double.tryParse(igv) ?? 0.0,
        "fecha": fechaSQL,
        "total": double.tryParse(total) ?? 0.0,
        "moneda": moneda.isEmpty
            ? "PEN"
            : (moneda.length > 80 ? moneda.substring(0, 80) : moneda),
        "rucCliente": rucCliente.isEmpty
            ? ""
            : (rucCliente.length > 80
                  ? rucCliente.substring(0, 80)
                  : rucCliente),
        "desEmp": CompanyService().currentCompany?.empresa ?? '',
        "desSed": "",
        "idCuenta": "",
        "consumidor": "",
        "regimen": "",
        "destino": "",
        "glosa": "",
        "motivoViaje": motivoViaje == null
            ? ""
            : (motivoViaje.length > 50
                  ? motivoViaje.substring(0, 50)
                  : motivoViaje),
        "lugarOrigen": lugarOrigen == null
            ? ""
            : (lugarOrigen.length > 50
                  ? lugarOrigen.substring(0, 50)
                  : lugarOrigen),
        "lugarDestino": lugarDestino == null
            ? ""
            : (lugarDestino.length > 50
                  ? lugarDestino.substring(0, 50)
                  : lugarDestino),
        "tipoMovilidad": tipoMovilidad == null
            ? ""
            : (tipoMovilidad.length > 50
                  ? tipoMovilidad.substring(0, 50)
                  : tipoMovilidad),
        "obs": nota.length > 1000 ? nota.substring(0, 1000) : nota,
        "estado": "S",
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": reporte.iduser,
        "hostname": "FLUTTER",
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": reporte.iduser,
        "useElim": 0,
      };

      final evidenciaString = selectedImage != null
          ? await convertImageToBase64(selectedImage)
          : (apiEvidencia ?? "");

      final facturaDataEvidencia = {
        "idRend": reporte.idrend,
        "evidencia": evidenciaString,
        "obs": nota.length > 1000 ? nota.substring(0, 1000) : nota,
        "estado": "S",
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": reporte.iduser,
        "hostname": "FLUTTER",
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": reporte.iduser,
        "useElim": 0,
      };

      await _apiService.saveupdateRendicionGasto(facturaData);
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
