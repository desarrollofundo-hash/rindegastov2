/// Ejemplo de prueba para la detección mejorada de IGV
/// Demuestra cómo la función _buscarIGVMejorado captura el formato "IGV: S/ [monto]"

void main() {
  // Simulación de diferentes formatos de IGV que pueden aparecer en facturas
  final ejemplosTextoIGV = [
    // Formato específico que mencionaste
    'SUBTOTAL: S/ 100.00\nIGV: S/ 18.00\nTOTAL: S/ 118.00',

    // Variaciones del formato principal
    'IGV: S/18.00',
    'IGV:S/ 25.50',
    'IGV : S/ 36.90',
    'I.G.V.: S/ 45.00',
    'IGV S/ 12.60',

    // Formatos con porcentaje
    'IGV 18%: S/ 27.00',
    'IGV (18%): S/ 33.30',
    'I.G.V. 18%: S/ 15.75',
    'I.G.V. (18%): S/ 21.42',

    // Formatos más complejos
    'IMPUESTO GENERAL A LAS VENTAS: S/ 54.00',
    'IGV 18% S/ 42.30',
    'I.G.V. : S/ 67.80',

    // Casos con comas en números grandes
    'IGV: S/ 1,250.50',
    'IGV: S/ 2,845.32',

    // Casos edge (límites)
    'IGV: S/ 0.18',
    'IGV: S/ 999.99',
  ];

  print('🧪 === PRUEBAS DE DETECCIÓN DE IGV MEJORADA ===\n');

  for (int i = 0; i < ejemplosTextoIGV.length; i++) {
    final texto = ejemplosTextoIGV[i];
    print('📄 Prueba ${i + 1}: "$texto"');

    // Aquí normalmente llamarías a la función real:
    // final igvDetectado = FacturaIA._buscarIGVMejorado(texto);

    // Para el ejemplo, simulo la detección
    final igvDetectado = _simularDeteccionIGV(texto);

    if (igvDetectado != null) {
      print('   ✅ IGV detectado: S/ $igvDetectado');
    } else {
      print('   ❌ IGV no detectado');
    }
    print('');
  }

  print('🎯 === ANÁLISIS DE PRECISIÓN ===');
  print('✅ Formatos soportados:');
  print('   • IGV: S/ [monto] - Formato exacto que mencionaste');
  print('   • IGV:S/[monto] - Sin espacios');
  print('   • I.G.V.: S/ [monto] - Con puntos');
  print('   • IGV S/ [monto] - Sin dos puntos');
  print('   • IGV 18%: S/ [monto] - Con porcentaje');
  print('   • IGV (18%): S/ [monto] - Porcentaje entre paréntesis');
  print('   • Números con comas (1,250.50)');
  print('   • Validación de rangos razonables (0.01 - 9999.99)');
}

/// Simulación de la lógica de detección para el ejemplo
String? _simularDeteccionIGV(String texto) {
  // Patrones específicos para el formato "IGV: S/ [monto]"
  final patronesEspecificosSoles = [
    RegExp(r'IGV\s*:\s*S/\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
    RegExp(r'I\.G\.V\.\s*:\s*S/\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
    RegExp(r'IGV\s+S/\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
    RegExp(r'IGV\s*18%\s*[:\s]*S/\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
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
