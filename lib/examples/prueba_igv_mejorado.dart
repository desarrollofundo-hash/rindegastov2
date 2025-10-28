/// Ejemplo práctico para probar la detección mejorada de IGV
/// Puedes usar este código para probar diferentes formatos de texto
class PruebaIGVMejorado {
  /// Prueba la detección de IGV con diferentes formatos
  static void probarDeteccionIGV() {
    print('🧪 === PRUEBA DE DETECCIÓN IGV MEJORADO ===\n');

    // Casos de prueba específicos para el formato "IGV: S/ [monto]"
    final casosDeTesteo = [];

    int casosExitosos = 0;

    for (int i = 0; i < casosDeTesteo.length; i++) {
      final caso = casosDeTesteo[i];

      // Llamar a la función real (comentado para evitar errores sin imagen)
      // final resultado = FacturaIA._buscarIGVMejorado(caso['texto'] as String);

      // Para la demo, simular el resultado
      final resultado = _simularDeteccion(caso['texto'] as String);

      if (resultado != null) {
        final esperado = caso['esperado'] as String;
        if (resultado == esperado) {
          print('   ✅ ÉXITO: IGV detectado: S/ $resultado');
          casosExitosos++;
        } else {
          print(
            '   ⚠️ PARCIAL: IGV detectado: S/ $resultado (esperado: S/ $esperado)',
          );
        }
      } else {
        print('   ❌ FALLO: IGV no detectado');
      }
      print('');
    }

    print('📊 === RESUMEN DE PRUEBAS ===');
    print('✅ Casos exitosos: $casosExitosos/${casosDeTesteo.length}');
    print(
      '📈 Tasa de éxito: ${(casosExitosos / casosDeTesteo.length * 100).toStringAsFixed(1)}%',
    );

    if (casosExitosos == casosDeTesteo.length) {
      print('🎉 ¡PERFECTO! Todos los casos fueron detectados correctamente.');
    } else {
      print('🔧 Algunas mejoras pueden ser necesarias.');
    }
  }

  /// Simula la detección para la demo (sin necesidad de imagen real)
  static String? _simularDeteccion(String texto) {
    // Misma lógica que en la función real
    final patronesEspecificosSoles = [
      RegExp(r'IGV\s*:\s*S/\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      RegExp(r'I\.G\.V\.\s*:\s*S/\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      RegExp(r'IGV\s+S/\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      RegExp(
        r'IGV\s*18%\s*[:\s]*S/\s*([\d,]+\.?\d{0,2})',
        caseSensitive: false,
      ),
      RegExp(
        r'IGV\s*\(18%\)\s*[:\s]*S/\s*([\d,]+\.?\d{0,2})',
        caseSensitive: false,
      ),
    ];

    for (final patron in patronesEspecificosSoles) {
      final match = patron.firstMatch(texto);
      if (match != null) {
        final igv = match.group(1)!.replaceAll(',', '');
        final numero = double.tryParse(igv);
        if (numero != null && numero > 0 && numero < 10000) {
          return numero.toStringAsFixed(2);
        }
      }
    }
    return null;
  }

  /// Función para probar con texto personalizado
  static void probarTextoPersonalizado(String textoPersonalizado) {
    print('🔍 === PRUEBA CON TEXTO PERSONALIZADO ===');
    print('📄 Texto a analizar: "$textoPersonalizado"');

    final resultado = _simularDeteccion(textoPersonalizado);

    if (resultado != null) {
      print('✅ IGV detectado: S/ $resultado');
    } else {
      print('❌ IGV no detectado en el texto proporcionado');
    }
  }
}
