import 'dart:io';
import '../services/factura_ia_optimized.dart';

/// Ejemplo de uso del servicio FacturaIA Optimizado
/// Demuestra las nuevas funcionalidades y mejoras implementadas
class EjemploFacturaIAOptimizada {
  /// Ejemplo completo de extracción de datos de factura
  static Future<void> ejemploCompletoExtraccion(File imagen) async {
    print('🚀 === FACTURA IA OPTIMIZADA - DEMO ===\n');

    // 1. Verificar estadísticas iniciales
    print('📊 Estadísticas iniciales:');
    final estadisticasIniciales =
        FacturaIAOptimized.obtenerEstadisticasCompletas();
    _mostrarEstadisticas(estadisticasIniciales);

    // 2. Extraer datos con la versión optimizada
    print('\n🔍 Iniciando extracción optimizada...');
    final resultado = await FacturaIAOptimized.extraerDatosOptimizado(imagen);

    // 3. Mostrar resultados detallados
    _mostrarResultados(resultado);

    // 4. Ejecutar segunda extracción para demostrar cache
    print('\n💾 Segunda extracción para demostrar cache...');
    final resultadoCache = await FacturaIAOptimized.extraerDatosOptimizado(
      imagen,
    );
    _mostrarResultados(resultadoCache);

    // 5. Estadísticas finales
    print('\n📊 Estadísticas finales:');
    final estadisticasFinales =
        FacturaIAOptimized.obtenerEstadisticasCompletas();
    _mostrarEstadisticas(estadisticasFinales);
  }

  /// Muestra resultados de extracción de forma formateada
  static void _mostrarResultados(Map<String, dynamic> resultado) {
    print('\n📋 === RESULTADOS DE EXTRACCIÓN ===');

    final datos = resultado['datos'] as Map<String, String>? ?? {};
    final confianza = resultado['confianza'] as double? ?? 0.0;
    final tiempoMs = resultado['tiempo_procesamiento_ms'] as int? ?? 0;
    final fuente = resultado['fuente'] as String? ?? 'unknown';

    print('🎯 Confianza General: ${(confianza * 100).toStringAsFixed(1)}%');
    print('⏱️ Tiempo de Procesamiento: ${tiempoMs}ms');
    print('📍 Fuente: $fuente');
    print('📊 Campos Detectados: ${datos.length}/10');

    if (datos.isNotEmpty) {
      print('\n📄 DATOS EXTRAÍDOS:');
      datos.forEach((campo, valor) {
        final icono = _obtenerIconoCampo(campo);
        print('$icono $campo: $valor');
      });
    }

    // Mostrar confianzas por campo si están disponibles
    final confianzasDetalle =
        resultado['confianzas_detalle'] as Map<String, double>?;
    if (confianzasDetalle != null && confianzasDetalle.isNotEmpty) {
      print('\n🎯 CONFIANZA POR CAMPO:');
      confianzasDetalle.forEach((campo, confianza) {
        final porcentaje = (confianza * 100).toStringAsFixed(1);
        final estado = confianza >= 0.7
            ? '✅'
            : confianza >= 0.5
            ? '⚠️'
            : '❌';
        print('$estado $campo: $porcentaje%');
      });
    }

    if (resultado.containsKey('error')) {
      print('❌ Error: ${resultado['error']}');
    }

    print('=' * 40);
  }

  /// Obtiene icono representativo para cada campo
  static String _obtenerIconoCampo(String campo) {
    switch (campo.toLowerCase()) {
      case 'ruc emisor':
        return '🏢';
      case 'ruc cliente':
        return '👤';
      case 'tipo comprobante':
        return '📄';
      case 'serie':
        return '🔢';
      case 'número':
        return '#️⃣';
      case 'fecha':
        return '📅';
      case 'total':
        return '💰';
      case 'igv':
        return '📈';
      case 'moneda':
        return '💱';
      case 'empresa':
        return '🏪';
      default:
        return '📋';
    }
  }

  /// Muestra estadísticas del sistema de forma formateada
  static void _mostrarEstadisticas(Map<String, dynamic> stats) {
    print('Version: ${stats['version']}');
    print(
      'Modelo TensorFlow: ${stats['modelo_inicializado'] ? "✅ Activo" : "❌ Inactivo"}',
    );

    final cache = stats['cache'] as Map<String, dynamic>;
    print(
      'Cache: ${cache['size']}/${cache['max_size']} (${cache['hit_rate_percent']}% hits)',
    );

    final rendimiento = stats['rendimiento'] as Map<String, dynamic>;
    print(
      'Extracciones: ${rendimiento['extracciones_exitosas']}/${rendimiento['total_extracciones']} (${rendimiento['tasa_exito_percent']}% éxito)',
    );
    print('Tiempo promedio: ${rendimiento['tiempo_promedio_ms']}ms');

    final config = stats['configuracion'] as Map<String, dynamic>;
    print(
      'Confianza mínima: ${(config['confianza_minima'] * 100).toStringAsFixed(0)}%',
    );
    print('Campos soportados: ${(config['campos_soportados'] as List).length}');
  }

  /// Ejemplo de comparación entre versión original y optimizada
  static Future<void> ejemploComparacion(File imagen) async {
    print('🔄 === COMPARACIÓN DE VERSIONES ===\n');

    try {
      // Importar la versión original
      // Nota: Necesitarías importar FacturaIA para esta comparación
      // import '../services/factura_ia.dart';

      print('📊 Extrayendo con versión ORIGINAL...');
      final tiempoInicioOriginal = DateTime.now();

      // final resultadoOriginal = await FacturaIA.extraerDatos(imagen);
      // Para este ejemplo, simularemos el resultado original
      final resultadoOriginal = <String, String>{
        'RUC Emisor': '20123456789',
        'Total': '118.00',
        'IGV': '18.00',
      };

      final tiempoOriginal = DateTime.now()
          .difference(tiempoInicioOriginal)
          .inMilliseconds;

      print('🚀 Extrayendo con versión OPTIMIZADA...');
      final resultadoOptimizado =
          await FacturaIAOptimized.extraerDatosOptimizado(imagen);

      // Comparar resultados
      print('\n📊 === COMPARACIÓN DE RESULTADOS ===');
      print(
        'Original: ${resultadoOriginal.length} campos en ${tiempoOriginal}ms',
      );

      final datosOptimizados =
          resultadoOptimizado['datos'] as Map<String, String>;
      final tiempoOptimizado =
          resultadoOptimizado['tiempo_procesamiento_ms'] as int;
      final confianzaOptimizada = resultadoOptimizado['confianza'] as double;

      print(
        'Optimizada: ${datosOptimizados.length} campos en ${tiempoOptimizado}ms',
      );
      print('Confianza: ${(confianzaOptimizada * 100).toStringAsFixed(1)}%');

      // Análisis de mejoras
      final mejoraCampos = datosOptimizados.length - resultadoOriginal.length;
      final mejoraVelocidad =
          ((tiempoOriginal - tiempoOptimizado) / tiempoOriginal * 100);

      print('\n✨ === MEJORAS OBTENIDAS ===');
      print('📈 Campos adicionales: +$mejoraCampos');
      print('⚡ Mejora de velocidad: ${mejoraVelocidad.toStringAsFixed(1)}%');
      print('🎯 Sistema de confianza: Nuevo');
      print('💾 Cache inteligente: Nuevo');
      print('🔍 Validación cruzada: Nuevo');
    } catch (e) {
      print('❌ Error en comparación: $e');
    }
  }

  /// Ejemplo de uso con múltiples imágenes para benchmark
  static Future<void> ejemploBenchmark(List<File> imagenes) async {
    print('📊 === BENCHMARK FACTURA IA OPTIMIZADA ===\n');

    final resultados = <Map<String, dynamic>>[];

    for (int i = 0; i < imagenes.length; i++) {
      print('🔍 Procesando imagen ${i + 1}/${imagenes.length}...');

      final resultado = await FacturaIAOptimized.extraerDatosOptimizado(
        imagenes[i],
      );
      resultados.add(resultado);

      final datos = resultado['datos'] as Map<String, String>;
      final confianza = resultado['confianza'] as double;
      final tiempo = resultado['tiempo_procesamiento_ms'] as int;

      print(
        '   ✅ ${datos.length} campos, ${(confianza * 100).toStringAsFixed(1)}% confianza, ${tiempo}ms',
      );
    }

    // Análisis de resultados
    _analizarBenchmark(resultados);
  }

  /// Analiza resultados del benchmark
  static void _analizarBenchmark(List<Map<String, dynamic>> resultados) {
    print('\n📊 === ANÁLISIS DE BENCHMARK ===');

    final tiempos = resultados
        .map((r) => r['tiempo_procesamiento_ms'] as int)
        .toList();
    final confianzas = resultados.map((r) => r['confianza'] as double).toList();
    final camposCounts = resultados
        .map((r) => (r['datos'] as Map<String, String>).length)
        .toList();

    // Estadísticas de tiempo
    final tiempoPromedio = tiempos.reduce((a, b) => a + b) / tiempos.length;
    final tiempoMin = tiempos.reduce((a, b) => a < b ? a : b);
    final tiempoMax = tiempos.reduce((a, b) => a > b ? a : b);

    // Estadísticas de confianza
    final confianzaPromedio =
        confianzas.reduce((a, b) => a + b) / confianzas.length;
    final confianzaMin = confianzas.reduce((a, b) => a < b ? a : b);
    final confianzaMax = confianzas.reduce((a, b) => a > b ? a : b);

    // Estadísticas de campos
    final camposPromedio =
        camposCounts.reduce((a, b) => a + b) / camposCounts.length;
    final camposMin = camposCounts.reduce((a, b) => a < b ? a : b);
    final camposMax = camposCounts.reduce((a, b) => a > b ? a : b);

    print('⏱️ TIEMPO:');
    print('   Promedio: ${tiempoPromedio.toStringAsFixed(0)}ms');
    print('   Rango: ${tiempoMin}ms - ${tiempoMax}ms');

    print('🎯 CONFIANZA:');
    print('   Promedio: ${(confianzaPromedio * 100).toStringAsFixed(1)}%');
    print(
      '   Rango: ${(confianzaMin * 100).toStringAsFixed(1)}% - ${(confianzaMax * 100).toStringAsFixed(1)}%',
    );

    print('📋 CAMPOS DETECTADOS:');
    print('   Promedio: ${camposPromedio.toStringAsFixed(1)}');
    print('   Rango: $camposMin - $camposMax');

    // Tasa de éxito
    final exitosos = confianzas.where((c) => c >= 0.65).length;
    final tasaExito = (exitosos / confianzas.length) * 100;
    print(
      '✅ TASA DE ÉXITO: ${tasaExito.toStringAsFixed(1)}% (${exitosos}/${confianzas.length})',
    );
  }

  /// Ejemplo de gestión de cache
  static Future<void> ejemploGestionCache() async {
    print('💾 === GESTIÓN DE CACHE ===\n');

    // Mostrar estadísticas del cache
    final stats = FacturaIAOptimized.obtenerEstadisticasCompletas();
    final cache = stats['cache'] as Map<String, dynamic>;

    print('📊 Estado actual del cache:');
    print('   Tamaño: ${cache['size']}/${cache['max_size']}');
    print('   Hits: ${cache['hits']} (${cache['hit_rate_percent']}%)');

    // Limpiar cache si es necesario
    if (cache['size'] > cache['max_size'] * 0.8) {
      print('\n🧹 Cache cerca del límite, limpiando...');
      FacturaIAOptimized.limpiarCache();
      print('✅ Cache limpiado');
    }

    // Resetear métricas para análisis fresco
    print('\n📊 Reseteando métricas para análisis fresco...');
    FacturaIAOptimized.resetearMetricas();
    print('✅ Métricas reseteadas');
  }

  /// Ejemplo de liberación de recursos
  static Future<void> ejemploLiberacionRecursos() async {
    print('🧹 === LIBERACIÓN DE RECURSOS ===\n');

    print('💾 Liberando cache...');
    print('🤖 Cerrando modelo TensorFlow...');
    print('📷 Cerrando reconocedor de texto...');

    await FacturaIAOptimized.dispose();

    print('✅ Todos los recursos han sido liberados correctamente');
  }
}
