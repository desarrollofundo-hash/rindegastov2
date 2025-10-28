import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ConnectivityHelper {
  /// Prueba la conectividad general a internet
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Prueba la conectividad específica al servidor de la API
  static Future<bool> canReachApiServer(String baseUrl) async {
    try {
      // Extraer solo el host de la URL
      final uri = Uri.parse(baseUrl);
      final host = uri.host;
      final port = uri.port;

      debugPrint('🔍 Probando conectividad a $host:$port');

      final socket = await Socket.connect(
        host,
        port,
        timeout: Duration(seconds: 5),
      );
      socket.destroy();
      debugPrint('✅ Servidor alcanzable');
      return true;
    } catch (e) {
      debugPrint('❌ Error al conectar con servidor: $e');
      return false;
    }
  }

  /// Hace una prueba HTTP básica al endpoint
  static Future<Map<String, dynamic>> testApiEndpoint(String url) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🚀 Probando endpoint: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/1.0',
            },
          )
          .timeout(Duration(seconds: 10));

      stopwatch.stop();

      final result = {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'responseTime': stopwatch.elapsedMilliseconds,
        'contentLength': response.body.length,
        'headers': response.headers,
      };

      debugPrint('📊 Resultado del test: $result');
      return result;
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Error en test de endpoint: $e');

      return {
        'success': false,
        'error': e.toString(),
        'responseTime': stopwatch.elapsedMilliseconds,
      };
    }
  }

  /// Diagnóstico completo de conectividad
  static Future<Map<String, dynamic>> fullConnectivityDiagnostic(
    String apiUrl,
  ) async {
    debugPrint('🔬 Iniciando diagnóstico completo de conectividad...');

    final diagnostic = <String, dynamic>{};

    // Test 1: Conectividad a internet
    diagnostic['internetConnection'] = await hasInternetConnection();
    debugPrint('🌐 Internet: ${diagnostic['internetConnection']}');

    // Test 2: Conectividad al servidor
    diagnostic['serverReachable'] = await canReachApiServer(apiUrl);
    debugPrint('🖥️ Servidor: ${diagnostic['serverReachable']}');

    // Test 3: Test del endpoint específico
    /* diagnostic['endpointTest'] = await testApiEndpoint(
      '$apiUrl/reporte/cosechavalvulas',
    );
    debugPrint('🎯 Endpoint: ${diagnostic['endpointTest']['success']}');
 */
    // Información del dispositivo
    diagnostic['platform'] = Platform.operatingSystem;
    diagnostic['isEmulator'] = !kReleaseMode; // Aproximación

    debugPrint('📋 Diagnóstico completo: $diagnostic');
    return diagnostic;
  }
}
