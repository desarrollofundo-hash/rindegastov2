import 'package:flutter/foundation.dart';
import 'dart:io';

/// Configuración de la aplicación
/// Centraliza URLs, timeouts y configuraciones de red
class AppConfig {
  // URLs del servidor - diferentes para emulador y dispositivo real
  static const String _prodBaseUrl = 'http://190.119.200.124:45490';
  static const String _emulatorBaseUrl =
      'http://10.0.2.2:45490'; // Para emulador que redirecciona al host
  // static const String _devBaseUrl =
  //     'http://localhost:3000'; // Para desarrollo local

  /// URL base dependiendo del entorno y dispositivo
  static String get baseUrl {
    // Detectar si estamos en emulador Android
    if (Platform.isAndroid && _isRunningInEmulator()) {
      debugPrint(
        '🤖 Detectado emulador Android - Usando configuración especial',
      );
      return _emulatorBaseUrl;
    }

    // En modo debug, permitir override para desarrollo
    if (kDebugMode) {
      // Cambiar esta línea para probar diferentes configuraciones:
      return _prodBaseUrl; // Usar servidor de producción
      // return _devBaseUrl;   // Usar servidor local
    }

    return _prodBaseUrl;
  }

  /// Detecta si la app está corriendo en un emulador
  static bool _isRunningInEmulator() {
    // En Android, verificar algunos indicadores de emulador
    if (Platform.isAndroid) {
      final bool isEmulator =
          Platform.environment.containsKey('ANDROID_ROOT') &&
          (Platform.environment['ANDROID_ROOT']?.contains('system') ?? false);
      return isEmulator;
    }
    return false;
  }

  /// URLs alternativas para probar conectividad
  static const List<String> alternativeUrls = [
    'http://190.119.200.124:45490',
    'http://10.0.2.2:45490', // Para emulador Android
    'http://127.0.0.1:45490', // Localhost
    'http://localhost:45490', // Localhost explícito
  ];

  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration readTimeout = Duration(seconds: 30);

  // Configuraciones de reintento
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Configuraciones de conectividad
  static const bool enableConnectivityCheck = true;
  static const bool enableDetailedLogging = true;

  /// Obtiene la configuración completa como mapa
  static Map<String, dynamic> get config => {
    'baseUrl': baseUrl,
    'alternativeUrls': alternativeUrls,
    'defaultTimeout': defaultTimeout.inSeconds,
    'connectionTimeout': connectionTimeout.inSeconds,
    'readTimeout': readTimeout.inSeconds,
    'maxRetries': maxRetries,
    'retryDelay': retryDelay.inSeconds,
    'enableConnectivityCheck': enableConnectivityCheck,
    'enableDetailedLogging': enableDetailedLogging,
    'environment': kDebugMode ? 'debug' : 'release',
    'platform': Platform.operatingSystem,
    'isEmulator': _isRunningInEmulator(),
  };

  /// Endpoints específicos
  static const Map<String, String> endpoints = {
    'reportesRendicion': '/reporte/rendiciongasto',
    'reportesCosecha': '/reporte/cosechavalvulas',
    'rendicionPoliticas': '/maestros/rendicion_politica',
    'rendicionCategorias': '/maestros/rendicion_categoria',
    'categorias': '/maestros/categorias',
    'politicas': '/maestros/politicas',
    'usuarios': '/maestros/usuarios',
  };

  /// Obtiene la URL completa para un endpoint
  static String getEndpointUrl(String endpointKey) {
    final endpoint = endpoints[endpointKey];
    if (endpoint == null) {
      throw ArgumentError('Endpoint no encontrado: $endpointKey');
    }
    return '$baseUrl$endpoint';
  }

  /// Método para probar diferentes URLs automáticamente
  static Future<String?> findWorkingUrl() async {
    for (final url in alternativeUrls) {
      try {
        debugPrint('🔍 Probando URL: $url');
        final client = HttpClient();
        final request = await client.getUrl(
          Uri.parse('$url/maestros/rendicion_politica'),
        );
        request.headers.set('Accept', 'application/json');
        final response = await request.close().timeout(Duration(seconds: 5));
        client.close();

        if (response.statusCode == 200 || response.statusCode == 404) {
          debugPrint('✅ URL funcional encontrada: $url');
          return url;
        }
      } catch (e) {
        debugPrint('❌ Fallo en URL $url: $e');
      }
    }
    debugPrint('❌ No se encontró ninguna URL funcional');
    return null;
  }
}
