import 'dart:convert';
import 'dart:io';
import 'package:flu2/models/apiruc_model.dart';
import 'package:flu2/models/reporte_auditioria_model.dart';
import 'package:flu2/models/reporte_auditoria_detalle.dart';
import 'package:flu2/models/reporte_informe_detalle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../models/reporte_model.dart';
import '../models/reporte_informe_model.dart';
import '../models/dropdown_option.dart';
import 'connectivity_helper.dart';
import 'package:path/path.dart' as path;

class ApiService {
  /// Base URL de la API
  static const String baseUrl = 'http://190.119.200.124:45490';
  static const String baseUrlApi = 'https://apiperu.dev';
  static const Duration timeout = Duration(seconds: 60);

  final http.Client client;

  // APISERVICE CLIENTE
  ApiService({http.Client? client}) : client = client ?? http.Client();
  //RENDICION GASTO
  Future<List<Reporte>> getReportesRendicionGasto({
    required String id,
    required String idrend,
    required String user,
    required String ruc,
  }) async {
    /*     debugPrint('🚀 Iniciando petición a API...');
    debugPrint('📍 URL base: $baseUrl/reporte/rendiciongasto');
    debugPrint('🏗️ Plataforma: ${Platform.operatingSystem}');
    debugPrint('🔧 Modo: ${kReleaseMode ? 'Release' : 'Debug'}'); */

    try {
      // Diagnóstico de conectividad en debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        debugPrint('🔬 Diagnóstico completo: $diagnostic');

        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }

        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      // Construir la URL con los parámetros dinámicos
      final uri = Uri.parse('$baseUrl/reporte/rendiciongasto').replace(
        queryParameters: {'id': id, 'idrend': idrend, 'user': user, 'ruc': ruc},
      );
      /* 
      debugPrint('📡 Realizando petición HTTP GET...');
      debugPrint('🌍 URL final: $uri');
 */
      final response = await client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);
      /* 
      debugPrint('📊 Respuesta recibida - Status: ${response.statusCode}');
      debugPrint('📦 Headers: ${response.headers}');
      debugPrint('📏 Tamaño de respuesta: ${response.body.length} bytes'); */

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando JSON...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        // Loguear un preview del body para depuración (máx 2000 chars)
        try {
          final raw = response.body;
          final preview = raw.length > 2000
              ? raw.substring(0, 2000) + '... [truncated]'
              : raw;
          debugPrint('📄 Response body preview (first 2000 chars): $preview');
        } catch (e) {
          debugPrint('⚠️ No se pudo imprimir preview del body: $e');
        }

        try {
          final List<dynamic> jsonData = json.decode(response.body);
          /*   debugPrint(
            '🎯 JSON parseado correctamente. Items: ${jsonData.length}',
          ); */

          if (jsonData.isEmpty) {
            debugPrint('⚠️ La API devolvió una lista vacía');
            return [];
          }

          final reportes = <Reporte>[];
          int errores = 0;

          for (int i = 0; i < jsonData.length; i++) {
            try {
              final reporte = Reporte.fromJson(jsonData[i]);
              reportes.add(reporte);
            } catch (e) {
              errores++;
              /*               debugPrint('⚠️ Error al parsear item $i: $e');
 */
              if (errores < 5) {
                debugPrint('📄 JSON problemático: ${jsonData[i]}');
              }
            }
          }

          if (errores > 0) {
            /*             debugPrint('⚠️ Se encontraron $errores errores de parsing');
 */
          }

          /*    debugPrint(
            '✅ ${reportes.length} reportes procesados correctamente ($errores errores)',
          ); */
          return reportes;
        } catch (e) {
          debugPrint('❌ Error al parsear JSON: $e');
          debugPrint(
            '📄 Tipo de respuesta: ${response.headers['content-type']}',
          );
          debugPrint(
            '📄 Respuesta raw (primeros 500 chars): '
            '${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
          );
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        debugPrint('❌ Status ${response.statusCode}');
        debugPrint('📄 Response body (server error): ${response.body}');

        // Intentar extraer un mensaje útil del body si viene en JSON
        String serverMessage = response.reasonPhrase ?? '';
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map && decoded.containsKey('message')) {
            serverMessage = decoded['message'].toString();
          } else if (decoded is Map && decoded.containsKey('error')) {
            serverMessage = decoded['error'].toString();
          } else if (decoded is String) {
            serverMessage = decoded;
          }
        } catch (_) {
          // body no JSON, dejar serverMessage tal cual
        }

        // Añadir parte del body (si existe) para facilitar depuración en UI
        final rawBody = response.body;
        final preview = rawBody.isEmpty
            ? ''
            : (rawBody.length > 800
                  ? rawBody.substring(0, 800) + '... [truncated]'
                  : rawBody);

        throw Exception(
          'Error del servidor (${response.statusCode}): ${serverMessage.isNotEmpty ? serverMessage : response.reasonPhrase}. BodyPreview: $preview',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión (SocketException): $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet y que el servidor esté disponible.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } on Exception catch (e) {
      debugPrint('❌ Error general: $e');
      rethrow;
    } catch (e) {
      debugPrint('💥 Error no manejado: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  //RENDICION INFORME
  Future<List<ReporteInforme>> getReportesRendicionInforme({
    required String id,
    required String idrend,
    required String user,
    required String ruc,
  }) async {
    /*     debugPrint('🚀 Iniciando petición a API...');
    debugPrint('📍 URL base: $baseUrl/reporte/rendiciongasto');
    debugPrint('🏗️ Plataforma: ${Platform.operatingSystem}');
    debugPrint('🔧 Modo: ${kReleaseMode ? 'Release' : 'Debug'}'); */

    try {
      // Diagnóstico de conectividad en debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        debugPrint('🔬 Diagnóstico completo: $diagnostic');

        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }

        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      // Construir la URL con los parámetros dinámicos
      final uri = Uri.parse('$baseUrl/reporte/rendicioninforme').replace(
        queryParameters: {'id': id, 'idrend': idrend, 'user': user, 'ruc': ruc},
      );
      /* 
      debugPrint('📡 Realizando petición HTTP GET...');
      debugPrint('🌍 URL final: $uri');
 */
      final response = await client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);
      /* 
      debugPrint('📊 Respuesta recibida - Status: ${response.statusCode}');
      debugPrint('📦 Headers: ${response.headers}');
      debugPrint('📏 Tamaño de respuesta: ${response.body.length} bytes'); */

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando JSON...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final List<dynamic> jsonData = json.decode(response.body);
          /*   debugPrint(
            '🎯 JSON parseado correctamente. Items: ${jsonData.length}',
          ); */

          if (jsonData.isEmpty) {
            debugPrint('⚠️ La API devolvió una lista vacía');
            return [];
          }

          final reportes = <ReporteInforme>[];
          int errores = 0;

          for (int i = 0; i < jsonData.length; i++) {
            try {
              final reporte = ReporteInforme.fromJson(jsonData[i]);
              reportes.add(reporte);
            } catch (e) {
              errores++;
              /*               debugPrint('⚠️ Error al parsear item $i: $e');
 */
              if (errores < 5) {
                debugPrint('📄 JSON problemático: ${jsonData[i]}');
              }
            }
          }

          if (errores > 0) {
            /*             debugPrint('⚠️ Se encontraron $errores errores de parsing');
 */
          }

          /*    debugPrint(
            '✅ ${reportes.length} reportes procesados correctamente ($errores errores)',
          ); */
          return reportes;
        } catch (e) {
          debugPrint('❌ Error al parsear JSON: $e');
          debugPrint(
            '📄 Tipo de respuesta: ${response.headers['content-type']}',
          );
          debugPrint(
            '📄 Respuesta raw (primeros 500 chars): '
            '${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
          );
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        /*      debugPrint('❌ Status ${response.statusCode}');
        debugPrint('📄 Response body: ${response.body}'); */
        throw Exception(
          'Error del servidor (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión (SocketException): $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet y que el servidor esté disponible.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } on Exception catch (e) {
      debugPrint('❌ Error general: $e');
      rethrow;
    } catch (e) {
      debugPrint('💥 Error no manejado: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  // REPORTES RENDICION INFORME DETALLE
  Future<List<ReporteInformeDetalle>> getReportesRendicionInforme_Detalle({
    required String idinf,
  }) async {
    /*     debugPrint('🚀 Iniciando petición a API...');
    debugPrint('📍 URL base: $baseUrl/reporte/rendiciongasto');
    debugPrint('🏗️ Plataforma: ${Platform.operatingSystem}');
    debugPrint('🔧 Modo: ${kReleaseMode ? 'Release' : 'Debug'}'); */

    try {
      // Diagnóstico de conectividad en debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        debugPrint('🔬 Diagnóstico completo: $diagnostic');

        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }

        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      // Construir la URL con los parámetros dinámicos
      final uri = Uri.parse(
        '$baseUrl/reporte/rendicioninforme_detalle',
      ).replace(queryParameters: {'idinf': idinf});
      /* 
      debugPrint('📡 Realizando petición HTTP GET...');
      debugPrint('🌍 URL final: $uri');
 */
      final response = await client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);
      /* 
      debugPrint('📊 Respuesta recibida - Status: ${response.statusCode}');
      debugPrint('📦 Headers: ${response.headers}');
      debugPrint('📏 Tamaño de respuesta: ${response.body.length} bytes'); */

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando JSON...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final List<dynamic> jsonData = json.decode(response.body);
          /*   debugPrint(
            '🎯 JSON parseado correctamente. Items: ${jsonData.length}',
          ); */

          if (jsonData.isEmpty) {
            debugPrint('⚠️ La API devolvió una lista vacía');
            return [];
          }

          final reportes = <ReporteInformeDetalle>[];
          int errores = 0;

          for (int i = 0; i < jsonData.length; i++) {
            try {
              final reporte = ReporteInformeDetalle.fromJson(jsonData[i]);
              reportes.add(reporte);
            } catch (e) {
              errores++;
              /*               debugPrint('⚠️ Error al parsear item $i: $e');
 */
              if (errores < 5) {
                debugPrint('📄 JSON problemático: ${jsonData[i]}');
              }
            }
          }

          if (errores > 0) {
            /*             debugPrint('⚠️ Se encontraron $errores errores de parsing');
 */
          }

          /*    debugPrint(
            '✅ ${reportes.length} reportes procesados correctamente ($errores errores)',
          ); */
          return reportes;
        } catch (e) {
          debugPrint('❌ Error al parsear JSON: $e');
          debugPrint(
            '📄 Tipo de respuesta: ${response.headers['content-type']}',
          );
          debugPrint(
            '📄 Respuesta raw (primeros 500 chars): '
            '${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
          );
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        /*      debugPrint('❌ Status ${response.statusCode}');
        debugPrint('📄 Response body: ${response.body}'); */
        throw Exception(
          'Error del servidor (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión (SocketException): $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet y que el servidor esté disponible.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } on Exception catch (e) {
      debugPrint('❌ Error general: $e');
      rethrow;
    } catch (e) {
      debugPrint('💥 Error no manejado: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  //RENDICION AUDITORIA
  Future<List<ReporteAuditoria>> getReportesRendicionAuditoria({
    required String id,
    required String idad,
    required String user,
    required String ruc,
  }) async {
    /*     debugPrint('🚀 Iniciando petición a API...');
    debugPrint('📍 URL base: $baseUrl/reporte/rendiciongasto');
    debugPrint('🏗️ Plataforma: ${Platform.operatingSystem}');
    debugPrint('🔧 Modo: ${kReleaseMode ? 'Release' : 'Debug'}'); */

    try {
      // Diagnóstico de conectividad en debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        debugPrint('🔬 Diagnóstico completo: $diagnostic');

        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }

        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      // Construir la URL con los parámetros dinámicos
      final uri = Uri.parse('$baseUrl/reporte/rendicionauditoria').replace(
        queryParameters: {'id': id, 'idad': idad, 'user': user, 'ruc': ruc},
      );
      debugPrint('📍 Request URL: $uri');
      /* 
      debugPrint('📡 Realizando petición HTTP GET...');
      debugPrint('🌍 URL final: $uri');
 */
      final response = await client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);
      /* 
      debugPrint('📊 Respuesta recibida - Status: ${response.statusCode}');
      debugPrint('📦 Headers: ${response.headers}');
      debugPrint('📏 Tamaño de respuesta: ${response.body.length} bytes'); */

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando JSON...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final List<dynamic> jsonData = json.decode(response.body);
          /*   debugPrint(
            '🎯 JSON parseado correctamente. Items: ${jsonData.length}',
          ); */

          if (jsonData.isEmpty) {
            debugPrint('⚠️ La API devolvió una lista vacía');
            return [];
          }

          final reportes = <ReporteAuditoria>[];
          int errores = 0;

          for (int i = 0; i < jsonData.length; i++) {
            try {
              final reporte = ReporteAuditoria.fromJson(jsonData[i]);
              reportes.add(reporte);
            } catch (e) {
              errores++;
              /*               debugPrint('⚠️ Error al parsear item $i: $e');
 */
              if (errores < 5) {
                debugPrint('📄 JSON problemático: ${jsonData[i]}');
              }
            }
          }

          if (errores > 0) {
            /*             debugPrint('⚠️ Se encontraron $errores errores de parsing');
 */
          }

          /*    debugPrint(
            '✅ ${reportes.length} reportes procesados correctamente ($errores errores)',
          ); */
          return reportes;
        } catch (e) {
          debugPrint('❌ Error al parsear JSON: $e');
          debugPrint(
            '📄 Tipo de respuesta: ${response.headers['content-type']}',
          );
          debugPrint(
            '📄 Respuesta raw (primeros 500 chars): '
            '${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
          );
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        /*      debugPrint('❌ Status ${response.statusCode}');
        debugPrint('📄 Response body: ${response.body}'); */
        throw Exception(
          'Error del servidor (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión (SocketException): $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet y que el servidor esté disponible.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } on Exception catch (e) {
      debugPrint('❌ Error general: $e');
      rethrow;
    } catch (e) {
      debugPrint('💥 Error no manejado: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  // REPORTES RENDICION INFORME DETALLE
  Future<List<ReporteAuditoriaDetalle>> getReportesRendicionAuditoria_Detalle({
    required String idAd,
  }) async {
    /*     debugPrint('🚀 Iniciando petición a API...');
    debugPrint('📍 URL base: $baseUrl/reporte/rendiciongasto');
    debugPrint('🏗️ Plataforma: ${Platform.operatingSystem}');
    debugPrint('🔧 Modo: ${kReleaseMode ? 'Release' : 'Debug'}'); */

    try {
      // Diagnóstico de conectividad en debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        debugPrint('🔬 Diagnóstico completo: $diagnostic');

        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }

        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      // Construir la URL con los parámetros dinámicos
      final uri = Uri.parse(
        '$baseUrl/reporte/rendicionauditoria_detalle',
      ).replace(queryParameters: {'idad': idAd});
      /* 
      debugPrint('📡 Realizando petición HTTP GET...');
      debugPrint('🌍 URL final: $uri');
 */
      final response = await client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);
      /* 
      debugPrint('📊 Respuesta recibida - Status: ${response.statusCode}');
      debugPrint('📦 Headers: ${response.headers}');
      debugPrint('📏 Tamaño de respuesta: ${response.body.length} bytes'); */

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando JSON...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final List<dynamic> jsonData = json.decode(response.body);
          /*   debugPrint(
            '🎯 JSON parseado correctamente. Items: ${jsonData.length}',
          ); */

          if (jsonData.isEmpty) {
            debugPrint('⚠️ La API devolvió una lista vacía');
            return [];
          }

          final reportes = <ReporteAuditoriaDetalle>[];
          int errores = 0;

          for (int i = 0; i < jsonData.length; i++) {
            try {
              final reporte = ReporteAuditoriaDetalle.fromJson(jsonData[i]);
              reportes.add(reporte);
            } catch (e) {
              errores++;
              /*               debugPrint('⚠️ Error al parsear item $i: $e');
 */
              if (errores < 5) {
                debugPrint('📄 JSON problemático: ${jsonData[i]}');
              }
            }
          }

          if (errores > 0) {
            /*             debugPrint('⚠️ Se encontraron $errores errores de parsing');
 */
          }

          /*    debugPrint(
            '✅ ${reportes.length} reportes procesados correctamente ($errores errores)',
          ); */
          return reportes;
        } catch (e) {
          debugPrint('❌ Error al parsear JSON: $e');
          debugPrint(
            '📄 Tipo de respuesta: ${response.headers['content-type']}',
          );
          debugPrint(
            '📄 Respuesta raw (primeros 500 chars): '
            '${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
          );
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        /*      debugPrint('❌ Status ${response.statusCode}');
        debugPrint('📄 Response body: ${response.body}'); */
        throw Exception(
          'Error del servidor (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión (SocketException): $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet y que el servidor esté disponible.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } on Exception catch (e) {
      debugPrint('❌ Error general: $e');
      rethrow;
    } catch (e) {
      debugPrint('💥 Error no manejado: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  // DROPDOWNS OPCIONES POLITICAS
  /// Método genérico para obtener opciones de dropdown desde la API
  /// [endpoint] - La ruta del endpoint (ej: 'categorias', 'politicas', 'usuarios')
  Future<List<DropdownOption>> getDropdownOptionsPolitica(
    String endpoint,
  ) async {
    debugPrint('🚀 Obteniendo opciones de dropdown para: $endpoint');
    debugPrint('📍 URL: $baseUrl/$endpoint');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      debugPrint('📡 Realizando petición HTTP para dropdown...');
      final response = await client
          .get(
            Uri.parse('$baseUrl/$endpoint'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);

      debugPrint('📊 Respuesta dropdown - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando JSON de dropdown...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final jsonData = json.decode(response.body);

          // Si la respuesta es una lista directa
          if (jsonData is List) {
            final options = jsonData
                .map<DropdownOption>((item) => DropdownOption.fromJson(item))
                .where((option) => option.isActive)
                .toList();

            debugPrint('✅ ${options.length} opciones de dropdown cargadas');
            return options;
          }

          // Si la respuesta tiene estructura de objeto
          final dropdownResponse = DropdownOptionsResponse.fromJson(jsonData);
          debugPrint(
            '✅ ${dropdownResponse.options.length} opciones de dropdown cargadas',
          );
          return dropdownResponse.options;
        } catch (e) {
          debugPrint('❌ Error al parsear JSON de dropdown: $e');
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        debugPrint('❌ Status ${response.statusCode}');
        throw Exception(
          'Error del servidor (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión en dropdown: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP en dropdown: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato en dropdown: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      debugPrint('💥 Error no manejado en dropdown: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  // DROPDOWNS OPCIONES CATEGORIAS
  /// Método genérico para obtener opciones de dropdown desde la API
  /// [endpoint] - La ruta del endpoint (ej: 'categorias', 'politicas', 'usuarios')
  Future<List<DropdownOption>> getDropdownOptionsCategoria(
    String endpoint,
  ) async {
    debugPrint('🚀 Obteniendo opciones de dropdown para: $endpoint');
    debugPrint('📍 URL: $baseUrl/$endpoint');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      debugPrint('📡 Realizando petición HTTP para dropdown...');
      final response = await client
          .get(
            Uri.parse('$baseUrl/$endpoint'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);

      debugPrint('📊 Respuesta dropdown - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando JSON de dropdown...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final jsonData = json.decode(response.body);

          // Si la respuesta es una lista directa
          if (jsonData is List) {
            final options = jsonData
                .map<DropdownOption>((item) => DropdownOption.fromJson(item))
                .where((option) => option.isActive)
                .toList();

            debugPrint('✅ ${options.length} opciones de dropdown cargadas');
            return options;
          }

          // Si la respuesta tiene estructura de objeto
          final dropdownResponse = DropdownOptionsResponse.fromJson(jsonData);
          debugPrint(
            '✅ ${dropdownResponse.options.length} opciones de dropdown cargadas',
          );
          return dropdownResponse.options;
        } catch (e) {
          debugPrint('❌ Error al parsear JSON de dropdown: $e');
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        debugPrint('❌ Status ${response.statusCode}');
        throw Exception(
          'Error del servidor (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión en dropdown: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP en dropdown: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato en dropdown: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      debugPrint('💥 Error no manejado en dropdown: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  /// ==================== ENDPOINTS ESPECÍFICOS DE DROPDOWNS ====================
  /// OBTENER CATEGORIAS
  Future<List<DropdownOption>> getCategorias() async {
    return await getDropdownOptionsCategoria('categoria');
  }

  /// OBTENER POLITICAS
  Future<List<DropdownOption>> getPoliticas() async {
    return await getDropdownOptionsPolitica('politicas');
  }

  // OBTENER USUARIOS
  Future<List<DropdownOption>> getUsuarios() async {
    return await getDropdownOptionsPolitica('usuarios');
  }

  /// ==================== ENDPOINTS ESPECÍFICOS DE RENDICIÓN ====================

  /// Obtener políticas de rendición
  Future<List<DropdownOption>> getRendicionPoliticas() async {
    debugPrint('🚀 Obteniendo políticas de rendición...');
    debugPrint('📍 URL: $baseUrl/maestros/rendicion_politica');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      final response = await client
          .get(
            Uri.parse('$baseUrl/maestros/rendicion_politica'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);

      debugPrint(
        '📊 Respuesta políticas rendición - Status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando políticas de rendición...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final jsonData = json.decode(response.body);

          // Si la respuesta es una lista directa
          if (jsonData is List) {
            final options = jsonData
                .map<DropdownOption>((item) => DropdownOption.fromJson(item))
                .where((option) => option.isActive)
                .toList();

            debugPrint('✅ ${options.length} políticas de rendición cargadas');
            return options;
          }

          // Si la respuesta tiene estructura de objeto
          final dropdownResponse = DropdownOptionsResponse.fromJson(jsonData);
          debugPrint(
            '✅ ${dropdownResponse.options.length} políticas de rendición cargadas',
          );
          return dropdownResponse.options;
        } catch (e) {
          debugPrint('❌ Error al parsear JSON de políticas: $e');
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        debugPrint('❌ Status ${response.statusCode}');
        throw Exception(
          'Error del servidor (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión en políticas: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP en políticas: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato en políticas: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      debugPrint('💥 Error no manejado en políticas: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  /// Obtener categorías de rendición según la política seleccionada
  /// [politica] - NOMBRE de la política o "todos" para obtener todas las categorías
  Future<List<DropdownOption>> getRendicionCategorias({
    String politica = 'todos',
  }) async {
    debugPrint(
      '🚀 Obteniendo categorías de rendición para política: $politica',
    );
    debugPrint(
      '📍 URL: $baseUrl/maestros/rendicion_categoria?politica=$politica',
    );

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      final uri = Uri.parse(
        '$baseUrl/maestros/rendicion_categoria',
      ).replace(queryParameters: {'politica': politica});

      final response = await client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);

      debugPrint(
        '📊 Respuesta categorías rendición - Status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando categorías de rendición...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final jsonData = json.decode(response.body);

          // Si la respuesta es una lista directa
          if (jsonData is List) {
            final options = jsonData
                .map<DropdownOption>((item) => DropdownOption.fromJson(item))
                .where((option) => option.isActive)
                .toList();

            debugPrint(
              '✅ ${options.length} categorías de rendición cargadas para política: $politica',
            );
            debugPrint('✅ ${options.length} opciones: $options');
            return options;
          }

          // Si la respuesta tiene estructura de objeto
          final dropdownResponse = DropdownOptionsResponse.fromJson(jsonData);
          debugPrint(
            '✅ ${dropdownResponse.options.length} categorías de rendición cargadas para política: $politica',
          );
          return dropdownResponse.options;
        } catch (e) {
          debugPrint('❌ Error al parsear JSON de categorías: $e');
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        debugPrint('❌ Status ${response.statusCode}');
        throw Exception(
          'Error del servidor (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión en categorías: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP en categorías: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato en categorías: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      debugPrint('💥 Error no manejado en categorías: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  /// Obtener tipos de gasto
  Future<List<DropdownOption>> getTiposGasto() async {
    debugPrint('🚀 Obteniendo tipos de gasto...');
    debugPrint('📍 URL: $baseUrl/maestros/rendicion_tipogasto');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      final response = await client
          .get(
            Uri.parse('$baseUrl/maestros/rendicion_tipogasto'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);

      debugPrint(
        '📊 Respuesta tipos de gasto - Status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando tipos de gasto...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final jsonData = json.decode(response.body);
          debugPrint('📄 JSON tipos de gasto decodificado: $jsonData');

          if (jsonData is! List) {
            throw Exception(
              '❌ Formato de respuesta inesperado para tipos de gasto',
            );
          }

          // Convertir cada item a DropdownOption
          final List<DropdownOption> tiposGasto = [];
          for (final item in jsonData) {
            if (item is Map<String, dynamic>) {
              // Verificar que el estado sea activo
              final estado = item['estado']?.toString() ?? '';
              if (estado.toLowerCase() == 's') {
                final tipogasto = item['tipogasto']?.toString() ?? '';
                final id = item['id']?.toString() ?? '';

                if (tipogasto.isNotEmpty) {
                  tiposGasto.add(DropdownOption(id: id, value: tipogasto));
                }
              }
            }
          }

          debugPrint(
            '✅ ${tiposGasto.length} tipos de gasto activos encontrados',
          );
          return tiposGasto;
        } catch (e) {
          debugPrint('❌ Error al parsear JSON de tipos de gasto: $e');
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        debugPrint('❌ Status ${response.statusCode}');
        throw Exception(
          'Error del servidor (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión en tipos de gasto: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP en tipos de gasto: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato en tipos de gasto: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      debugPrint('💥 Error no manejado en tipos de gasto: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  /// Obtener tipos movilidad
  Future<List<DropdownOption>> getTiposMovilidad() async {
    debugPrint('🚀 Obteniendo tipos movilidad...');
    debugPrint('📍 URL: $baseUrl/maestros/rendicion_movilidad');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      final response = await client
          .get(
            Uri.parse('$baseUrl/maestros/rendicion_movilidad'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);

      debugPrint(
        '📊 Respuesta tipos de movilidad - Status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando tipos de movilidad...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final jsonData = json.decode(response.body);
          debugPrint('📄 JSON tipos de gasto decodificado: $jsonData');

          if (jsonData is! List) {
            throw Exception('❌ Formato de respuesta tipo movilidad');
          }

          // Convertir cada item a DropdownOption
          final List<DropdownOption> tipoMovilidad = [];
          for (final item in jsonData) {
            if (item is Map<String, dynamic>) {
              // Verificar que el estado sea activo
              final estado = item['estado']?.toString() ?? '';
              if (estado.toLowerCase() == 's') {
                final tipomovilidad = item['movilidad']?.toString() ?? '';
                final id = item['id']?.toString() ?? '';

                if (tipomovilidad.isNotEmpty) {
                  tipoMovilidad.add(
                    DropdownOption(id: id, value: tipomovilidad),
                  );
                }
              }
            }
          }

          debugPrint(
            '✅ ${tipoMovilidad.length} tipos movilidad activos encontrados',
          );
          return tipoMovilidad;
        } catch (e) {
          debugPrint('❌ Error al parsear JSON de movilidad: $e');
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        debugPrint('❌ Status ${response.statusCode}');
        throw Exception(
          'Error del servidor (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión en tipos movilidad: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    }
  }

  //-------------------SAVE RENDICION GASTO------------------------//
  /// Guardar factura/rendición de gasto
  /// [facturaData] - Map con los datos de la factura a guardar
  /// Retorna el idRend generado si se guardó exitosamente, null en caso contrario
  Future<int?> saveRendicionGasto(Map<String, dynamic> facturaData) async {
    debugPrint('🚀 Guardando factura/rendición de gasto...');
    debugPrint('📍 URL: $baseUrl/saveupdate/saverendiciongasto');
    debugPrint('📦 Datos a enviar: $facturaData');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      final response = await client
          .post(
            Uri.parse('$baseUrl/saveupdate/saverendiciongasto?returnId=true'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'X-Return-Format': 'json',
              'X-Return-Id': 'true',
            },
            body: json.encode([facturaData]),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '📊 Respuesta guardar factura - Status: ${response.statusCode}',
      );
      debugPrint('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Verificar si la respuesta contiene errores
        if (response.body.contains('Error') ||
            response.body.contains('error')) {
          debugPrint('❌ Error en respuesta del servidor: ${response.body}');
          throw Exception('Error del servidor: ${response.body}');
        }

        debugPrint('✅ Factura guardada exitosamente');

        // Verificar si la respuesta es solo el mensaje de texto esperado
        if (response.body.trim() == "UPSERT realizado correctamente.") {
          debugPrint('📝 Respuesta de texto plano detectada');
          debugPrint('🔍 Intentando buscar el registro por datos únicos...');

          // Extraer datos únicos para la búsqueda
          final ruc = facturaData['ruc']?.toString().trim() ?? '';
          final serie = facturaData['serie']?.toString().trim() ?? '';
          final numero = facturaData['numero']?.toString().trim() ?? '';
          final userCode = facturaData['useReg']?.toString().trim() ?? '';

          if (ruc.isNotEmpty &&
              serie.isNotEmpty &&
              numero.isNotEmpty &&
              userCode.isNotEmpty) {
            debugPrint(
              '� Buscando con: RUC=$ruc, Serie=$serie, Número=$numero, Usuario=$userCode',
            );

            // Buscar el registro por datos únicos
            final foundId = await findFacturaByUniqueData(
              ruc: ruc,
              serie: serie,
              numero: numero,
              userCode: userCode,
            );

            if (foundId != null) {
              debugPrint('✅ Factura encontrada con ID: $foundId');
              return foundId;
            } else {
              debugPrint('❌ No se pudo encontrar la factura guardada');
            }
          } else {
            debugPrint('❌ Datos insuficientes para búsqueda única');
            debugPrint(
              '   RUC: "$ruc", Serie: "$serie", Número: "$numero", Usuario: "$userCode"',
            );
          }

          throw Exception(
            'El servidor guardó los datos pero no devolvió el ID generado.\n\n'
            'Tampoco se pudo encontrar el registro mediante búsqueda.\n\n'
            'SOLUCIÓN REQUERIDA:\n'
            'El backend debe modificarse para devolver:\n'
            '{"idRend": 12345, "message": "UPSERT realizado correctamente"}\n\n'
            'O implementar el endpoint:\n'
            'GET /query/findbydata?ruc=...&serie=...&numero=...&userCode=...\n\n'
            'Contacta al desarrollador del backend.',
          );
        }

        // Intentar extraer el idRend de la respuesta JSON
        try {
          final responseData = json.decode(response.body);
          int? idRend;

          // La respuesta puede ser un objeto con idRend o un array con un objeto que tiene idRend
          if (responseData is Map<String, dynamic>) {
            idRend = responseData['idRend'] ?? responseData['id'];
          } else if (responseData is List && responseData.isNotEmpty) {
            final firstItem = responseData[0];
            if (firstItem is Map<String, dynamic>) {
              idRend = firstItem['idRend'] ?? firstItem['id'];
            }
          }

          if (idRend != null) {
            debugPrint('🆔 idRend obtenido desde JSON: $idRend');
            return idRend;
          } else {
            debugPrint('⚠️ JSON válido pero sin idRend');
            debugPrint('📄 Estructura de respuesta: $responseData');

            throw Exception(
              'El servidor devolvió JSON pero sin el campo idRend requerido.\n\n'
              'Respuesta recibida: $responseData\n\n'
              'El backend debe incluir el campo "idRend" o "id" en la respuesta.',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error al parsear la respuesta JSON: $e');
          debugPrint('📄 Response body: ${response.body}');

          throw Exception(
            'El servidor devolvió una respuesta que no se puede procesar.\n\n'
            'Respuesta del servidor: "${response.body}"\n'
            'Error de parsing: $e\n\n'
            'El backend debe devolver JSON válido con el ID generado.',
          );
        }
      } else {
        debugPrint('❌ Error del servidor: ${response.statusCode}');
        debugPrint('📄 Response headers: ${response.headers}');
        debugPrint(
          '📍 Request URL: ${Uri.parse('$baseUrl/saveupdate/saverendicionauditoria')}',
        );
        throw Exception(
          'Error del servidor: ${response.statusCode}\nRespuesta: ${response.body}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión al guardar factura: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP al guardar factura: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato al guardar factura: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      debugPrint('💥 Error no manejado al guardar factura: $e');
      rethrow;
    }
  }

  //-------------------VERIFY RECORD EXISTS------------------------//
  /// Verificar si un registro con idRend específico existe en la base de datos
  /// [idRend] - ID del registro a verificar
  /// Retorna true si existe, false si no existe
  Future<bool> verifyRecordExists(int idRend) async {
    debugPrint('🔍 Verificando si existe registro con idRend: $idRend');
    debugPrint('📍 URL: $baseUrl/query/verify/$idRend');

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/query/verify/$idRend'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
        '📊 Respuesta verificación registro - Status: ${response.statusCode}',
      );
      debugPrint('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          // Verificar diferentes formatos de respuesta
          bool exists = false;
          if (responseData is Map<String, dynamic>) {
            exists =
                responseData['exists'] == true ||
                responseData['found'] == true ||
                responseData['count'] != null && responseData['count'] > 0;
          } else if (responseData is bool) {
            exists = responseData;
          } else if (responseData is List && responseData.isNotEmpty) {
            exists = true; // Si devuelve una lista con datos, existe
          }

          debugPrint(
            '✅ Registro ${exists ? 'EXISTE' : 'NO EXISTE'} en la base de datos',
          );
          return exists;
        } catch (e) {
          debugPrint('⚠️ Error al parsear respuesta de verificación: $e');
          return false;
        }
      } else if (response.statusCode == 404) {
        debugPrint('❌ Registro no encontrado (404)');
        return false;
      } else {
        debugPrint(
          '❌ Error del servidor al verificar registro: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('💥 Error al verificar registro: $e');
      return false;
    }
  }

  //-------------------FIND FACTURA BY UNIQUE DATA------------------------//
  /// Buscar ID de factura por datos únicos (RUC, serie, número)
  /// [ruc] - RUC del emisor
  /// [serie] - Serie del comprobante
  /// [numero] - Número del comprobante
  /// [userCode] - Código del usuario que insertó
  /// Retorna el idRend si encuentra la factura, null si no existe
  Future<int?> findFacturaByUniqueData({
    required String ruc,
    required String serie,
    required String numero,
    required String userCode,
  }) async {
    debugPrint('🔍 Buscando factura por datos únicos:');
    debugPrint('   - RUC: $ruc');
    debugPrint('   - Serie: $serie');
    debugPrint('   - Número: $numero');
    debugPrint('   - Usuario: $userCode');

    try {
      // Construir la URL con parámetros de consulta
      final uri = Uri.parse('$baseUrl/query/findbydata').replace(
        queryParameters: {
          'ruc': ruc.trim(),
          'serie': serie.trim(),
          'numero': numero.trim(),
          'userCode': userCode.trim(),
        },
      );

      debugPrint('📍 URL consulta: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('📊 Respuesta búsqueda - Status: ${response.statusCode}');
      debugPrint('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          int? idRend;

          if (responseData is Map<String, dynamic>) {
            idRend =
                responseData['idRend'] ??
                responseData['id'] ??
                responseData['idRendicion'];
          } else if (responseData is List && responseData.isNotEmpty) {
            final firstItem = responseData[0];
            if (firstItem is Map<String, dynamic>) {
              idRend =
                  firstItem['idRend'] ??
                  firstItem['id'] ??
                  firstItem['idRendicion'];
            }
          } else if (responseData is int) {
            idRend = responseData;
          }

          if (idRend != null) {
            debugPrint('✅ Factura encontrada con idRend: $idRend');
            return idRend;
          } else {
            debugPrint('⚠️ Respuesta válida pero sin idRend');
            return null;
          }
        } catch (e) {
          debugPrint('⚠️ Error al parsear respuesta de búsqueda: $e');
          return null;
        }
      } else if (response.statusCode == 404) {
        debugPrint('❌ Factura no encontrada (404)');
        return null;
      } else {
        debugPrint('❌ Error del servidor en búsqueda: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('💥 Error en búsqueda por datos únicos: $e');
      return null;
    }
  }

  /// Obtener el último ID generado para un usuario específico
  /// [userCode] - Código del usuario que insertó el registro
  /// Retorna el último idRend generado o null si no se encuentra
  Future<int?> getLastInsertedId(String userCode) async {
    debugPrint('🔍 Obteniendo último ID insertado para usuario: $userCode');
    debugPrint('📍 URL: $baseUrl/query/lastinsertedid/$userCode');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/query/lastinsertedid/$userCode'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('📊 Respuesta último ID - Status: ${response.statusCode}');
      debugPrint('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          int? idRend;

          // La respuesta puede ser un objeto con idRend, id, o lastId
          if (responseData is Map<String, dynamic>) {
            idRend =
                responseData['idRend'] ??
                responseData['id'] ??
                responseData['lastId'] ??
                responseData['lastInsertedId'];
          } else if (responseData is List && responseData.isNotEmpty) {
            final firstItem = responseData[0];
            if (firstItem is Map<String, dynamic>) {
              idRend =
                  firstItem['idRend'] ??
                  firstItem['id'] ??
                  firstItem['lastId'] ??
                  firstItem['lastInsertedId'];
            }
          } else if (responseData is int) {
            // Si la respuesta es directamente un número
            idRend = responseData;
          }

          if (idRend != null) {
            debugPrint('🆔 Último ID obtenido: $idRend');
            return idRend;
          } else {
            debugPrint('⚠️ No se pudo obtener el último ID de la respuesta');
            debugPrint('📄 Estructura de respuesta: $responseData');
            return null;
          }
        } catch (e) {
          debugPrint('⚠️ Error al parsear la respuesta del último ID: $e');
          debugPrint('📄 Response body: ${response.body}');
          return null;
        }
      } else {
        debugPrint(
          '❌ Error del servidor al obtener último ID: ${response.statusCode}',
        );
        return null;
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión al obtener último ID: $e');
      return null;
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP al obtener último ID: $e');
      return null;
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato al obtener último ID: $e');
      return null;
    } catch (e) {
      debugPrint('💥 Error no manejado al obtener último ID: $e');
      return null;
    }
  }

  //-------------------SAVE RENDICION GASTO EVIDENCIA------------------------//
  /// Guardar factura/rendición de gasto
  /// [facturaEvidenciaData] - Map con los datos de la factura a guardar
  /// SAVE RENDICION GASTO EVIDENCIA
  Future<bool> saveRendicionGastoEvidencia(
    Map<String, dynamic> facturaEvidenciaData,
  ) async {
    debugPrint('🚀 Guardando evidencia de factura/rendición de gasto...');
    debugPrint('📍 URL: $baseUrl/saveupdate/saverendiciongastoevidencia');

    // Logging detallado de los datos (sin mostrar la imagen completa)
    final dataCopy = Map<String, dynamic>.from(facturaEvidenciaData);
    if (dataCopy.containsKey('evidencia') && dataCopy['evidencia'] != null) {
      final evidenciaLength = dataCopy['evidencia'].toString().length;
      dataCopy['evidencia'] = 'BASE64_IMAGE_${evidenciaLength}_CHARS';
    }
    debugPrint('📦 Datos a enviar (estructura): $dataCopy');

    // Validaciones adicionales
    final idRend = facturaEvidenciaData['idRend'];
    if (idRend == null) {
      throw Exception('❌ idRend es requerido para guardar la evidencia');
    }
    debugPrint('🆔 idRend para evidencia: $idRend');

    final evidencia = facturaEvidenciaData['evidencia'];
    if (evidencia != null && evidencia.toString().isNotEmpty) {
      final evidenciaSize = evidencia.toString().length;
      debugPrint('📷 Tamaño de evidencia: ${evidenciaSize} caracteres');

      // Verificar si parece ser base64 válido
      if (evidenciaSize > 0 &&
          !evidencia.toString().contains(RegExp(r'^[A-Za-z0-9+/]*={0,2}$'))) {
        debugPrint('⚠️ La evidencia no parece ser base64 válido');
      }

      // Verificar tamaño razonable (máximo ~50MB en base64)
      if (evidenciaSize > 70000000) {
        throw Exception(
          '❌ La imagen es demasiado grande (${(evidenciaSize / 1000000).toStringAsFixed(1)}MB)',
        );
      }
    } else {
      debugPrint('📷 Sin evidencia de imagen');
    }

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      debugPrint('🌐 Enviando request al servidor...');
      final response = await client
          .post(
            Uri.parse('$baseUrl/saveupdate/saverendiciongastoevidencia'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
            },
            body: json.encode([facturaEvidenciaData]),
          )
          .timeout(
            const Duration(seconds: 60),
          ); // Aumentar timeout para imágenes

      debugPrint(
        '📊 Respuesta guardar evidencia - Status: ${response.statusCode}',
      );
      debugPrint('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Verificar si la respuesta contiene errores
        if (response.body.contains('Error') ||
            response.body.contains('error')) {
          debugPrint('❌ Error en respuesta del servidor: ${response.body}');
          throw Exception('Error del servidor: ${response.body}');
        }

        debugPrint('✅ Evidencia de factura guardada exitosamente');
        return true;
      } else if (response.statusCode == 400) {
        // Manejo específico para errores 400 (Bad Request)
        debugPrint('❌ Error 400 - Bad Request al guardar evidencia');
        debugPrint('📄 Detalles del error: ${response.body}');

        // Analizar posibles causas del error
        if (response.body.contains('SQL')) {
          debugPrint('🗄️ Error SQL detectado - posibles causas:');
          debugPrint('   - idRend no existe en la tabla principal');
          debugPrint('   - Constraint de foreign key');
          debugPrint('   - Datos muy largos para las columnas');
          debugPrint('   - Formato de fecha inválido');
        }

        throw Exception(
          'Error 400 al guardar evidencia:\n${response.body}\n\n'
          'Posibles causas:\n'
          '• El idRend ($idRend) no existe en la tabla principal\n'
          '• La imagen es demasiado grande\n'
          '• Problema con los datos enviados',
        );
      } else {
        debugPrint(
          '❌ Error del servidor al guardar evidencia: ${response.statusCode}',
        );
        throw Exception(
          'Error del servidor: ${response.statusCode}\nRespuesta: ${response.body}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión al guardar evidencia: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP al guardar evidencia: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato al guardar evidencia: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      debugPrint('💥 Error no manejado al guardar evidencia: $e');
      // Verificar si es un error de timeout
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('timeout')) {
        throw Exception(
          'La operación tardó demasiado. La imagen podría ser muy grande.',
        );
      }
      rethrow;
    }
  }

  //-------------------LOGIN CREDENCIAL------------------------//
  /// [usuario] - Nombre de usuario o DNI
  /// [contrasena] - Contraseña del usuario
  /// [app] - ID de la aplicación (por defecto 12)
  /// LOGIN CREDENCIAL - INGRESO AL LOGIN
  Future<Map<String, dynamic>> loginCredencial({
    required String usuario,
    required String contrasena,
    int app = 12,
  }) async {
    debugPrint('🚀 Iniciando autenticación de usuario...');
    debugPrint('📍 URL: $baseUrl/login/credencial');
    debugPrint('👤 Usuario: $usuario');
    debugPrint('📱 App ID: $app');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      final uri = Uri.parse('$baseUrl/login/credencial').replace(
        queryParameters: {
          'usuario': usuario,
          'contrasena': contrasena,
          'app': app.toString(),
        },
      );

      final response = await client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📊 Respuesta login - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando respuesta de login...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final List<dynamic> jsonResponse = json.decode(response.body);

          if (jsonResponse.isNotEmpty) {
            final userData = jsonResponse[0];

            // Verificar que el usuario esté activo
            if (userData['estado'] == 'S') {
              debugPrint('✅ Usuario autenticado exitosamente');
              debugPrint('👤 Usuario: ${userData['usenam']}');
              return userData;
            } else {
              debugPrint('❌ Usuario inactivo');
              throw Exception('Usuario inactivo. Contacta al administrador.');
            }
          } else {
            debugPrint('❌ Lista de usuarios vacía');
            throw Exception('Usuario o contraseña incorrectos');
          }
        } catch (e) {
          if (e.toString().contains('Usuario inactivo') ||
              e.toString().contains('Usuario o contraseña incorrectos')) {
            rethrow;
          }
          debugPrint('❌ Error al parsear JSON de login: $e');
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        debugPrint('❌ Error del servidor: ${response.statusCode}');
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión en login: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP en login: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato en login: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      if (e.toString().contains('Usuario inactivo') ||
          e.toString().contains('Usuario o contraseña incorrectos') ||
          e.toString().contains('Sin conexión') ||
          e.toString().contains('Error del servidor')) {
        rethrow;
      }
      debugPrint('💥 Error no manejado en login: $e');
      throw Exception('Error inesperado en login: $e');
    }
  }

  //-------------------GET USER COMPANIES------------------------//
  /// [userId] - ID del usuario para consultar sus empresas
  /// GET USUARIO COMPANIES
  Future<List<Map<String, dynamic>>> getUserCompanies(int userId) async {
    debugPrint('🚀 Obteniendo empresas del usuario...');
    debugPrint('📍 URL: $baseUrl/reporte/usuarioconsumidor');
    debugPrint('👤 User ID: $userId');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      final uri = Uri.parse(
        '$baseUrl/reporte/usuarioconsumidor',
      ).replace(queryParameters: {'id': userId.toString()});

      final response = await client
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '📊 Respuesta empresas usuario - Status: ${response.statusCode}',
      );
      debugPrint('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando empresas del usuario...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final List<dynamic> jsonData = json.decode(response.body);

          if (jsonData.isEmpty) {
            debugPrint('⚠️ No se encontraron empresas asociadas al usuario');
            return [];
          }

          debugPrint(
            '✅ ${jsonData.length} empresas encontradas para el usuario',
          );
          return jsonData.cast<Map<String, dynamic>>();
        } catch (e) {
          debugPrint('❌ Error al parsear JSON de empresas: $e');
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        debugPrint('❌ Error del servidor: ${response.statusCode}');
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión al obtener empresas: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    }
  }

  //-------------------SAVE RENDICION GASTOMOVILIDAD------------------------//
  /// [movilidadData] - Map con los datos del gasto de movilidad a guardar
  /// SAVE RENDICION GASTO MOVILIDAD- GUARDAR GASTO MOVILIDAD
  Future<bool> saveRendicionGastoMovilidad(
    Map<String, dynamic> movilidadData,
  ) async {
    debugPrint('🚀 Guardando gasto de movilidad...');
    debugPrint('📍 URL: $baseUrl/saveupdate/saverendiciongasto');
    debugPrint('📦 Datos a enviar: $movilidadData');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      final response = await client
          .post(
            Uri.parse('$baseUrl/saveupdate/saverendiciongasto'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode([movilidadData]),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '📊 Respuesta guardar movilidad - Status: ${response.statusCode}',
      );
      debugPrint('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Verificar si la respuesta contiene errores
        if (response.body.contains('Error') ||
            response.body.contains('error')) {
          debugPrint('❌ Error en respuesta del servidor: ${response.body}');
          throw Exception('Error del servidor: ${response.body}');
        }

        debugPrint('✅ Gasto de movilidad guardado exitosamente');
        return true;
      } else {
        debugPrint('❌ Error del servidor: ${response.statusCode}');
        debugPrint('📄 Response headers: ${response.headers}');
        debugPrint(
          '📍 Request URL: ${Uri.parse('$baseUrl/saveupdate/saverendicionauditoria_detalle')}',
        );
        throw Exception(
          'Error del servidor: ${response.statusCode}\nRespuesta: ${response.body}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🌐 Error de conexión al guardar movilidad: $e');
      throw Exception('Error de conexión: $e');
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP al guardar movilidad: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato al guardar movilidad: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      if (e.toString().contains('Sin conexión') ||
          e.toString().contains('Error del servidor') ||
          e.toString().contains('Respuesta vacía') ||
          e.toString().contains('Error al procesar')) {
        rethrow;
      }
      debugPrint('💥 Error no manejado al guardar movilidad: $e');
      throw Exception('Error inesperado al guardar movilidad: $e');
    }
  }

  //-------------------SAVE RENDICION INFORME------------------------//
  /// [informeData] - Map con los datos del informe a guardar
  /// SAVE RENDICION INFORME - GUARDAR INFORME RENDICION
  Future<int?> saveRendicionInforme(Map<String, dynamic> informeData) async {
    debugPrint('🚀 Guardando informe de rendición...');
    debugPrint('📍 URL: $baseUrl/saveupdate/saverendicioninforme');
    debugPrint('📦 Datos a enviar: $informeData');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      final response = await client
          .post(
            Uri.parse('$baseUrl/saveupdate/saverendicioninforme?returnId=true'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'X-Return-Format': 'json',
              'X-Return-Id': 'true',
            },
            body: json.encode([informeData]),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '📊 Respuesta guardar informe - Status: ${response.statusCode}',
      );
      debugPrint('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Verificar si la respuesta contiene errores
        if (response.body.contains('Error') ||
            response.body.contains('error')) {
          debugPrint('❌ Error en respuesta del servidor: ${response.body}');
          throw Exception('Error del servidor: ${response.body}');
        }

        debugPrint('✅ Informe de rendición guardado exitosamente');

        // Verificar si la respuesta es solo el mensaje de texto esperado
        if (response.body.trim() == "UPSERT realizado correctamente.") {
          debugPrint('📝 Respuesta de texto plano detectada para informe');
          throw Exception(
            'El servidor guardó el informe pero no devolvió el IdInf generado.\n\n'
            'SOLUCIÓN REQUERIDA:\n'
            'El backend debe modificarse para devolver:\n'
            '{"idInf": 12345, "message": "UPSERT realizado correctamente"}\n\n'
            'Contacta al desarrollador del backend.',
          );
        }

        // Intentar extraer el idInf de la respuesta JSON
        try {
          final responseData = json.decode(response.body);
          int? idInf;

          // La respuesta puede ser un objeto con idInf o un array con un objeto que tiene idInf
          if (responseData is Map<String, dynamic>) {
            idInf = responseData['idInf'] ?? responseData['id'];
          } else if (responseData is List && responseData.isNotEmpty) {
            final firstItem = responseData[0];
            if (firstItem is Map<String, dynamic>) {
              idInf = firstItem['idInf'] ?? firstItem['id'];
            }
          }

          if (idInf != null) {
            debugPrint('🆔 idInf obtenido desde JSON: $idInf');
            return idInf;
          } else {
            debugPrint('⚠️ JSON válido pero sin idInf');
            debugPrint('📄 Estructura de respuesta: $responseData');

            throw Exception(
              'El servidor devolvió JSON pero sin el campo idInf requerido.\n\n'
              'Respuesta recibida: $responseData\n\n'
              'El backend debe incluir el campo "idInf" o "id" en la respuesta.',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error al parsear la respuesta JSON: $e');
          debugPrint('📄 Response body: ${response.body}');

          throw Exception(
            'El servidor devolvió una respuesta que no se puede procesar.\n\n'
            'Respuesta del servidor: "${response.body}"\n'
            'Error de parsing: $e\n\n'
            'El backend debe devolver JSON válido con el IdInf generado.',
          );
        }
      } else {
        debugPrint('❌ Error del servidor: ${response.statusCode}');
        throw Exception(
          'Error del servidor: ${response.statusCode}\nRespuesta: ${response.body}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión al guardar informe: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP al guardar informe: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato al guardar informe: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      debugPrint('💥 Error no manejado al guardar informe: $e');
      rethrow;
    }
  }

  //-------------------SAVE RENDICION INFORME DETALLE------------------------//
  /// [informeDetalleData] - Map con los datos del detalle del informe a guardar
  /// SAVE RENDICION INFORME DETALLE - GUARDAR DETALLE INFORME RENDICION
  Future<bool> saveRendicionInformeDetalle(
    Map<String, dynamic> informeDetalleData,
  ) async {
    debugPrint('🚀 Guardando detalle de informe de rendición...');
    debugPrint('📍 URL: $baseUrl/saveupdate/saverendicioninforme_detalle');
    debugPrint('📦 Datos a enviar: $informeDetalleData');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      final response = await client
          .post(
            Uri.parse('$baseUrl/saveupdate/saverendicioninforme_detalle'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
            },
            body: json.encode([informeDetalleData]),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '📊 Respuesta guardar detalle informe - Status: ${response.statusCode}',
      );
      debugPrint('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Verificar si la respuesta contiene errores
        if (response.body.contains('Error') ||
            response.body.contains('error')) {
          debugPrint('❌ Error en respuesta del servidor: ${response.body}');
          throw Exception('Error del servidor: ${response.body}');
        }

        debugPrint('✅ Detalle de informe de rendición guardado exitosamente');
        return true;
      } else {
        debugPrint('❌ Error del servidor: ${response.statusCode}');
        throw Exception(
          'Error del servidor: ${response.statusCode}\nRespuesta: ${response.body}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión al guardar detalle informe: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP al guardar detalle informe: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato al guardar detalle informe: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      if (e.toString().contains('Sin conexión') ||
          e.toString().contains('Error del servidor') ||
          e.toString().contains('Respuesta vacía') ||
          e.toString().contains('Error al procesar')) {
        rethrow;
      }
      debugPrint('💥 Error no manejado al guardar detalle informe: $e');
      throw Exception('Error inesperado al guardar detalle informe: $e');
    }
  }

  //-------------------UPDATE RENDICION INFORME DETALLE------------------------//
  Future<bool> saveupdateRendicionGasto(
    Map<String, dynamic> informeDetalleData,
  ) async {
    debugPrint('🚀 Guardando detalle de informe de rendición...');
    debugPrint('📍 URL: $baseUrl/saveupdate/updaterendiciongasto');
    debugPrint('📦 Datos a enviar: $informeDetalleData');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      final response = await client
          .post(
            Uri.parse('$baseUrl/saveupdate/updaterendiciongasto'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
            },
            body: json.encode([informeDetalleData]),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '📊 Respuesta guardar detalle informe - Status: ${response.statusCode}',
      );
      debugPrint('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Verificar si la respuesta contiene errores
        if (response.body.contains('Error') ||
            response.body.contains('error')) {
          debugPrint('❌ Error en respuesta del servidor: ${response.body}');
          throw Exception('Error del servidor: ${response.body}');
        }

        debugPrint('✅ Detalle de informe de rendición guardado exitosamente');
        return true;
      } else {
        debugPrint('❌ Error del servidor: ${response.statusCode}');
        throw Exception(
          'Error del servidor: ${response.statusCode}\nRespuesta: ${response.body}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión al guardar detalle informe: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP al guardar detalle informe: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato al guardar detalle informe: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      if (e.toString().contains('Sin conexión') ||
          e.toString().contains('Error del servidor') ||
          e.toString().contains('Respuesta vacía') ||
          e.toString().contains('Error al procesar')) {
        rethrow;
      }
      debugPrint('💥 Error no manejado al guardar detalle informe: $e');
      throw Exception('Error inesperado al guardar detalle informe: $e');
    }
  }

  //------------------- GUARDAR RENDICIÓN AUDITORÍA (CABECERA) ------------------------//
  Future<int?> saveRendicionAuditoria(
    Map<String, dynamic> informeDetalleData,
  ) async {
    debugPrint('🚀 Guardando cabecera de rendición auditoría...');
    debugPrint('📍 URL: $baseUrl/saveupdate/saverendicionauditoria');
    debugPrint('📦 Datos a enviar: $informeDetalleData');

    try {
      final uri = Uri.parse('$baseUrl/saveupdate/saverendicionauditoria');
      final encodedBody = json.encode([informeDetalleData]);

      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: encodedBody,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📊 Respuesta - Status: ${response.statusCode}');
      debugPrint('📄 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);

        if (decoded['success'] == true) {
          debugPrint('✅ Cabecera guardada correctamente');
          return decoded['idAd']; // ID retornado por el backend
        } else {
          throw Exception('❌ Error del servidor: ${decoded['message']}');
        }
      } else {
        throw Exception(
          '❌ Error del servidor (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('💥 Error en saveRendicionAuditoria: $e');
      rethrow;
    }
  }

  //------------------- GUARDAR RENDICIÓN AUDITORÍA DETALLE ------------------------//
  Future<bool> saveRendicionAuditoriaDetalle(
    Map<String, dynamic> informeDetalleData,
  ) async {
    debugPrint('🚀 Guardando detalle de rendición auditoría...');
    debugPrint('📍 URL: $baseUrl/saveupdate/saverendicionauditoria_detalle');
    debugPrint('📦 Datos a enviar: $informeDetalleData');

    try {
      final uri = Uri.parse(
        '$baseUrl/saveupdate/saverendicionauditoria_detalle',
      );
      final encodedBody = json.encode([informeDetalleData]);

      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: encodedBody,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📊 Respuesta detalle - Status: ${response.statusCode}');
      debugPrint('📄 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          debugPrint('✅ Detalle guardado correctamente');
          return true;
        } else {
          throw Exception('❌ Error del servidor: ${decoded['message']}');
        }
      } else {
        throw Exception(
          '❌ Error del servidor (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('💥 Error en saveRendicionAuditoriaDetalle: $e');
      rethrow;
    }
  }

  Future<String?> subirArchivo(String filePath, {String? nombreArchivo}) async {
    debugPrint('🚀 Guardando archivo en servidor local...');
    debugPrint('📍 URL: $baseUrl/recibir/uploadlocal');

    try {
      final bytes = await File(filePath).readAsBytes();
      final base64Data = base64Encode(bytes);

      // Usa el nombre proporcionado o el original
      final fileName = nombreArchivo ?? path.basename(filePath);

      final response = await http.post(
        Uri.parse('$baseUrl/recibir/uploadlocal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fileName': fileName, 'base64': base64Data}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final fullPath = data['path'];
          debugPrint('✅ Archivo guardado correctamente en: $fullPath');
          return fullPath;
        } else {
          debugPrint('⚠️ Error lógico del servidor: ${data['message']}');
        }
      } else {
        debugPrint('❌ Error HTTP: ${response.statusCode}');
        debugPrint('Respuesta: ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('🔥 Error subiendo archivo: $e');
      debugPrint(stack.toString());
    }

    return null;
  }

  // Método para obtener una imagen desde el servidor
  Future<Image?> obtenerImagen(String fileName) async {
    debugPrint('🚀 Obteniendo imagen desde el servidor...');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recibir/getimage/$fileName'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Imagen obtenida correctamente');

        // Convertir los bytes de la respuesta a una imagen
        return Image.memory(Uint8List.fromList(response.bodyBytes));
      } else {
        debugPrint('❌ Error HTTP al obtener la imagen: ${response.statusCode}');
        debugPrint('Respuesta: ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('🔥 Error obteniendo la imagen: $e');
      debugPrint(stack.toString());
    }

    return null;
  }

  /// Obtener los bytes crudos de una imagen guardada en el servidor
  /// Retorna null si no está disponible o ocurre un error.
  Future<Uint8List?> obtenerImagenBytes(String fileName) async {
    debugPrint('🚀 Descargando bytes de imagen desde servidor: $fileName');
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/recibir/getimage/$fileName'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(
          '✅ Bytes de imagen recibidos: ${response.bodyBytes.length} bytes',
        );
        return response.bodyBytes;
      } else {
        debugPrint(
          '❌ Error HTTP al descargar bytes de imagen: ${response.statusCode}',
        );
        debugPrint('Respuesta: ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('🔥 Error descargando bytes de imagen: $e');
      debugPrint(stack.toString());
    }
    return null;
  }

  // Cerrar el cliente cuando ya no se necesite
  void dispose() {
    client.close();
  }

  Future<ApiRuc> getApiRuc({required String ruc}) async {
    try {
      // 🔍 Diagnóstico solo en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrlApi,
        );
        debugPrint('🔬 Diagnóstico completo: $diagnostic');

        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }

        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrlApi');
        }
      }

      // 🌍 Construcción de URL dinámica
      final uri = Uri.parse('$baseUrlApi/api/ruc/$ruc');

      debugPrint('📡 Realizando petición HTTP GET...');
      debugPrint('🌍 URL final: $uri');

      // 🚀 Petición GET
      final response = await client
          .get(
            uri,
            headers: {
              'Authorization':
                  'Bearer a22c04e4b06e3244195120f8f0d20b7be66de8688ced6124f89d9f63dae98ddc', // 🔑 Token del API
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);

      debugPrint('📊 Respuesta recibida - Status: ${response.statusCode}');
      debugPrint('📦 Headers: ${response.headers}');
      debugPrint('📏 Tamaño de respuesta: ${response.body.length} bytes');

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando JSON...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        // Mostrar un preview del body (solo para debug)
        try {
          final raw = response.body;
          final preview = raw.length > 2000
              ? raw.substring(0, 2000) + '... [truncated]'
              : raw;
          debugPrint('📄 Response body preview (first 2000 chars): $preview');
        } catch (e) {
          debugPrint('⚠️ No se pudo imprimir preview del body: $e');
        }

        // 🔄 Decodificar JSON
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);

          if (jsonData['success'] == true && jsonData['data'] != null) {
            final empresa = ApiRuc.fromJson(jsonData['data']);
            return empresa;
          } else {
            throw Exception('⚠️ La respuesta no contiene datos válidos');
          }
        } catch (e) {
          debugPrint('❌ Error al parsear JSON: $e');
          debugPrint(
            '📄 Tipo de respuesta: ${response.headers['content-type']}',
          );
          debugPrint(
            '📄 Respuesta raw (primeros 500 chars): '
            '${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
          );
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        debugPrint('❌ Status ${response.statusCode}');
        debugPrint('📄 Response body (server error): ${response.body}');

        // Extraer mensaje del servidor si está disponible
        String serverMessage = response.reasonPhrase ?? '';
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map && decoded.containsKey('message')) {
            serverMessage = decoded['message'].toString();
          } else if (decoded is Map && decoded.containsKey('error')) {
            serverMessage = decoded['error'].toString();
          } else if (decoded is String) {
            serverMessage = decoded;
          }
        } catch (_) {}

        final rawBody = response.body;
        final preview = rawBody.isEmpty
            ? ''
            : (rawBody.length > 800
                  ? rawBody.substring(0, 800) + '... [truncated]'
                  : rawBody);

        throw Exception(
          'Error del servidor (${response.statusCode}): ${serverMessage.isNotEmpty ? serverMessage : response.reasonPhrase}. BodyPreview: $preview',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión (SocketException): $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet o al servidor.',
      );
    }
  }
}
