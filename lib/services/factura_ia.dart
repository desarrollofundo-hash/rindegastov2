// Versión mínima de FacturaIA: usa únicamente el texto devuelto por OCR.space
// para extraer unos pocos campos básicos.

class FacturaIA {
  /// Procesa el texto OCR (completo) y devuelve un Map con campos básicos
  /// - 'raw_text': todo el texto original
  /// - 'RUC Emisor', 'Fecha', 'Total' si se encuentran
  static Future<Map<String, String>> extraerDatosDesdeTexto(
    String textoOCR,
  ) async {
    final texto = textoOCR.toUpperCase();
    final result = <String, String>{'raw_text': textoOCR};

    // Buscar RUC (11 dígitos)
    final rucMatch = RegExp(r'\b(\d{11})\b').firstMatch(texto);
    if (rucMatch != null) result['RUC Emisor'] = rucMatch.group(1)!;

    // Buscar fecha (dd/mm/yyyy o dd-mm-yyyy)
    final fechaMatch = RegExp(
      r'\b(\d{2}[\/\-]\d{2}[\/\-]\d{4})\b',
    ).firstMatch(texto);
    if (fechaMatch != null) result['Fecha'] = fechaMatch.group(1)!;

    // Buscar montos (formatos comunes: 1234.56 o 1,234.56)
    final montoMatches = RegExp(
      r'(\d{1,3}(?:,?\d{3})*\.\d{2})',
    ).allMatches(texto).toList();
    if (montoMatches.isNotEmpty) {
      double? mayor;
      for (final m in montoMatches) {
        final s = m.group(1)!.replaceAll(',', '');
        final v = double.tryParse(s);
        if (v != null) {
          if (mayor == null || v > mayor) mayor = v;
        }
      }
      if (mayor != null) result['Total'] = mayor.toStringAsFixed(2);
    }

    return result;
  }

  /// Extrae campos clave a partir del JSON completo devuelto por OCR.space
  /// [ocrJson] es el Map<String,dynamic> retornado por la API (ParsedResults, TextOverlay, etc.)
  static Future<Map<String, String>> extraerDatosDesdeParsedResults(
    Map<String, dynamic> ocrJson,
  ) async {
    final result = <String, String>{};

    String parsedText = '';
    try {
      if (ocrJson.containsKey('ParsedResults')) {
        final pr = ocrJson['ParsedResults'];
        if (pr is List && pr.isNotEmpty) {
          parsedText = (pr[0]['ParsedText'] ?? '').toString();
        }
      }
    } catch (e) {
      parsedText = '';
    }

    result['raw_text'] = parsedText;
    final texto = parsedText.toUpperCase();

    // Dividir en líneas limpias para búsquedas contextuales
    final lines = parsedText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Helper: extraer primer número decimal plausible de una línea
    double? _extractAmountFromString(String s) {
      final line = s.trim();
      final up = line.toUpperCase();

      // Evitar líneas que claramente contienen RUCs
      if (up.contains('RUC') || RegExp(r'\b\d{11}\b').hasMatch(line))
        return null;

      // 1) Buscar montos con decimales (formato con punto o coma y 2 decimales)
      final decMatch = RegExp(
        r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2}))',
      ).firstMatch(line);
      if (decMatch != null) {
        var raw = decMatch.group(1)!;
        raw = raw.replaceAll(RegExp(r'[ \u00A0]'), '');
        raw = raw.replaceAll(',', '.');
        // Normalizar miles: si hay más de one '.', keep only last as decimal
        final parts = raw.split('.');
        if (parts.length > 2) {
          final decimal = parts.removeLast();
          raw = parts.join('') + '.' + decimal;
        }
        final v = double.tryParse(raw);
        if (v != null) return v;
      }

      // 2) Patrones tipo '37 80' -> tratar como 37.80
      final spaceDec = RegExp(r'\b(\d{1,4})\s+(\d{2})\b').firstMatch(line);
      if (spaceDec != null) {
        final candidate = '${spaceDec.group(1)}.${spaceDec.group(2)}';
        final v = double.tryParse(candidate);
        if (v != null) return v;
      }

      // 3) Montos sin decimales pero con etiqueta de moneda o contexto
      if (up.contains('S/') ||
          up.contains('SOLES') ||
          up.contains('PAGA') ||
          up.contains('TOTAL')) {
        final intMatch = RegExp(r'\b(\d{1,9})\b').firstMatch(line);
        if (intMatch != null) {
          final raw = intMatch.group(1)!;
          // Evitar tratar RUC (11 dígitos) como monto
          if (raw.length < 11) {
            final v = double.tryParse(raw.replaceAll(',', '.'));
            if (v != null) return v;
          }
        }
      }

      // 4) Último recurso: números cortos (<8 dígitos) en la línea
      final fallback = RegExp(r'\b(\d{1,7})\b').firstMatch(line);
      if (fallback != null) {
        final raw = fallback.group(1)!;
        final v = double.tryParse(raw);
        if (v != null) return v;
      }

      return null;
    }

    // RUCs: buscar todos los números de 11 dígitos y su línea
    final rucMatches = <Map<String, dynamic>>[];
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      final m = RegExp(r'\b(\d{11})\b').firstMatch(l);
      if (m != null) {
        rucMatches.add({'ruc': m.group(1)!, 'line': i, 'lineText': l});
      }
    }
    if (rucMatches.isNotEmpty) {
      result['RUC Emisor'] = rucMatches[0]['ruc'];
      result['RUC'] = rucMatches[0]['ruc'];
      // intentar razon social emisor: buscar la línea anterior no vacía que no contenga 'RUC'
      for (var j = rucMatches[0]['line'] - 1; j >= 0; j--) {
        final cand = lines[j];
        final up = cand.toUpperCase();
        if (up.contains('RUC')) continue;
        result['Razón Social'] = cand;
        result['Proveedor'] = cand;
        break;
      }
      if (rucMatches.length > 1) {
        result['RUC Cliente'] = rucMatches[1]['ruc'];
        // intentar razon social cliente: buscar la línea anterior al segundo RUC
        for (var j = rucMatches[1]['line'] - 1; j >= 0; j--) {
          final cand = lines[j];
          final up = cand.toUpperCase();
          if (up.contains('RUC') || up.contains('R.U.C')) continue;
          result['Razón Social Cliente'] = cand;
          result['Razon Social Cliente'] = cand;
          result['Proveedor Cliente'] = cand;
          break;
        }
      }
    }

    // Razón social / Proveedor: intentar la primera línea del texto que no sea RUC ni tenga la palabra RUC
    try {
      for (final l in lines) {
        final up = l.toUpperCase();
        if (RegExp(r'\b\d{11}\b').hasMatch(up)) continue;
        if (up.contains('RUC') || up.contains('R.U.C') || up.contains('R.U.C.'))
          continue;
        // Primera línea plausible
        result['Razón Social'] = l;
        result['Proveedor'] = l;
        break;
      }
    } catch (e) {}

    // Fecha emisión
    final fechaMatch = RegExp(
      r'(\d{2}[\/\-]\d{2}[\/\-]\d{4})',
    ).firstMatch(texto);
    if (fechaMatch != null) {
      result['Fecha'] = fechaMatch.group(1)!;
      result['Fecha Emisión'] = fechaMatch.group(1)!;
    }

    // Tipo de comprobante por palabras clave
    if (texto.contains('FACTURA')) {
      result['Tipo de comprobante'] = 'FACTURA';
      result['Tipo Comprobante'] = 'FACTURA';
    } else if (texto.contains('BOLETA')) {
      result['Tipo de comprobante'] = 'BOLETA';
      result['Tipo Comprobante'] = 'BOLETA';
    } else if (texto.contains('NOTA DE CR')) {
      result['Tipo de comprobante'] = 'NOTA DE CRÉDITO';
      result['Tipo Comprobante'] = 'NOTA DE CRÉDITO';
    }

    // Serie y número: tratar de localizar en líneas cercanas a 'FACTURA' o 'BOLETA'
    bool foundDoc = false;
    for (var i = 0; i < lines.length && !foundDoc; i++) {
      final up = lines[i].toUpperCase();
      if (up.contains('FACTURA') ||
          up.contains('BOLETA') ||
          up.contains('COMPROBANTE')) {
        // buscar en las 3 siguientes líneas patrón tipo F009-00018163 o similar
        for (var j = i; j <= i + 3 && j < lines.length; j++) {
          final l = lines[j];
          final m = RegExp(r'([A-Z0-9]{1,6})[- ]?0*([0-9]{1,8})').firstMatch(l);
          if (m != null) {
            result['Serie'] = m.group(1)!.replaceAll(RegExp(r'\s'), '');
            result['Número'] = m.group(2)!;
            foundDoc = true;
            break;
          }
        }
      }
    }
    // fallback: buscar en todo el texto
    if (!foundDoc) {
      final docMatch = RegExp(
        r'([A-Z]{1,3}\d{0,3})[- ]?0*([0-9]{1,8})',
      ).firstMatch(texto);
      if (docMatch != null) {
        result['Serie'] = docMatch.group(1)!.replaceAll(RegExp(r'\s'), '');
        result['Número'] = docMatch.group(2)!;
      } else {
        final hyphenMatch = RegExp(
          r'([A-Z0-9]{2,10})[-](\d{2,8})',
        ).firstMatch(texto);
        if (hyphenMatch != null) {
          result['Serie'] = hyphenMatch.group(1)!;
          result['Número'] = hyphenMatch.group(2)!;
        }
      }
    }

    // Montos: extraer todas las posibles ocurrencias con decimales desde líneas
    final montoMatches = <double>[];
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      final am = _extractAmountFromString(l);
      if (am != null) montoMatches.add(am);
    }
    montoMatches.sort();
    double? mayor = montoMatches.isNotEmpty ? montoMatches.last : null;
    if (mayor != null) result['Total'] = mayor.toStringAsFixed(2);

    // Intentar extraer Subtotal e IGV buscando líneas con etiquetas
    try {
      // Buscar IGV: buscar línea con 'IGV' y tomar un número cercano
      for (var i = 0; i < lines.length; i++) {
        final up = lines[i].toUpperCase();
        if (up.contains('IGV')) {
          // intentar mismo renglón
          final igvSame = _extractAmountFromString(lines[i]);
          if (igvSame != null) {
            result['IGV'] = igvSame.toStringAsFixed(2);
            break;
          }
          // buscar en las siguientes 3 líneas
          for (var j = i + 1; j <= (i + 3) && j < lines.length; j++) {
            final cand = _extractAmountFromString(lines[j]);
            if (cand != null) {
              result['IGV'] = cand.toStringAsFixed(2);
              break;
            }
          }
          if (result.containsKey('IGV')) break;
        }
      }

      // Subtotal: buscar línea con SUBTOTAL, IMPORTE o VALOR VENTA
      for (var i = 0; i < lines.length; i++) {
        final up = lines[i].toUpperCase();
        if (up.contains('SUBTOTAL') ||
            up.contains('IMPORTE') ||
            up.contains('VALOR VENTA')) {
          final sub = _extractAmountFromString(lines[i]);
          if (sub != null) {
            result['Subtotal'] = sub.toStringAsFixed(2);
            break;
          }
          // mirar línea siguiente
          if (i + 1 < lines.length) {
            final sub2 = _extractAmountFromString(lines[i + 1]);
            if (sub2 != null) {
              result['Subtotal'] = sub2.toStringAsFixed(2);
              break;
            }
          }
        }
      }
    } catch (e) {}

    // Si no encontramos Subtotal, como fallback tomar el segundo mayor monto (si existe)
    if (!result.containsKey('Subtotal') && montoMatches.length > 1) {
      result['Subtotal'] = montoMatches[montoMatches.length - 2]
          .toStringAsFixed(2);
    }

    // Moneda
    if (texto.contains('S/') || texto.contains('SOLES')) {
      result['Moneda'] = 'Soles';
    } else if (texto.contains('USD') || texto.contains('\$')) {
      result['Moneda'] = 'USD';
    }

    // Mejor heurística para Total: buscar 'Importe Total', 'Total a Pagar' o 'Importe Total S/'
    for (var i = 0; i < lines.length; i++) {
      final up = lines[i].toUpperCase();
      if (up.contains('IMPORTE TOTAL') ||
          up.contains('TOTAL A PAGAR') ||
          up.contains('TOTAL PAGA')) {
        // buscar número en las siguientes 3 líneas
        for (var j = i; j <= i + 3 && j < lines.length; j++) {
          final cand = _extractAmountFromString(lines[j]);
          if (cand != null) {
            result['Total'] = cand.toStringAsFixed(2);
            break;
          }
        }
        if (result.containsKey('Total')) break;
      }
    }

    // Si no encontramos Total por heurística, usar el mayor monto detectado
    if (!result.containsKey('Total') && mayor != null) {
      result['Total'] = mayor.toStringAsFixed(2);
    }

    return result;
  }
}
