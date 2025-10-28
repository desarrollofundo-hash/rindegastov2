import 'dart:convert';
import 'package:flu2/models/factura_data_ocr.dart';
import 'package:http/http.dart' as http;

/// Envía la imagen al servicio OCR y devuelve un modelo [FacturaOcrData].
Future<FacturaOcrData> procesarFactura(String imagePath) async {
  const apiUrl = "https://api.ocr.space/parse/image";
  const apiKey = "K81691375688957"; // Reemplaza con tu API key real

  var request = http.MultipartRequest('POST', Uri.parse(apiUrl))
    ..fields['language'] = 'spa'
    ..fields['isCreateSearchablePdf'] = 'true'
    ..fields['isSearchablePdfHideTextLayer'] = 'false'
    ..fields['OCREngine'] = '2'
    ..fields['apikey'] = apiKey
    ..files.add(await http.MultipartFile.fromPath('file', imagePath));

  var response = await request.send();
  var responseData = await response.stream.bytesToString();
  var data = jsonDecode(responseData);

  String texto = data["ParsedResults"]?[0]?["ParsedText"] ?? "";

  return extraerDatosFactura(texto);
}

FacturaOcrData extraerDatosFactura(String texto) {
  final factura = FacturaOcrData();

  // Normalizar y dividir en líneas para parsing por proximidad
  texto = texto.replaceAll('\r', '\n').replaceAll('\t', ' ');
  // Normalizaciones adicionales para variantes OCR comunes
  texto = texto.replaceAll('S/.', 'S/');
  texto = texto.replaceAll('·', '.');
  texto = texto.replaceAll(RegExp(r'\s+'), ' ');
  final rawLines = texto
      .split(RegExp(r'[\n]+'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  // helper: buscar todas las ocurrencias de 11 dígitos (RUC)
  final allRucs = <String>[];
  for (final m in RegExp(r'\b(\d{11})\b').allMatches(texto)) {
    allRucs.add(m.group(1)!);
  }
  if (allRucs.isNotEmpty) {
    factura.rucEmisor = allRucs.first;
    if (allRucs.length > 1) factura.rucCliente = allRucs.last;
  }

  // funciones utilitarias
  String? firstLineMatching(RegExp rx) {
    for (final l in rawLines) {
      final m = rx.firstMatch(l);
      if (m != null) return m.groupCount >= 1 ? (m.group(1) ?? l) : l;
    }
    return null;
  }

  String? findLineContains(String token) {
    final tn = token.toLowerCase();
    for (final l in rawLines) {
      if (l.toLowerCase().contains(tn)) return l;
    }
    return null;
  }

  String? extractCurrency(String line) {
    final m = RegExp(
      r'([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{2}))',
    ).firstMatch(line);
    return m?.group(1);
  }

  // Parse number string to double (normalize comma to dot)
  double? _toDouble(String? s) {
    if (s == null) return null;
    final cleaned = s.replaceAll(RegExp(r'[^0-9,\.]'), '').replaceAll(',', '.');
    try {
      return double.parse(cleaned);
    } catch (e) {
      return null;
    }
  }

  // Get currency-like values from last N lines (normalized as doubles)
  List<double> tailCurrencyValues(int n) {
    final values = <double>[];
    final start = rawLines.length - n;
    for (int i = (start < 0 ? 0 : start); i < rawLines.length; i++) {
      final l = rawLines[i];
      for (final m in RegExp(r'([0-9]+[.,][0-9]{2})').allMatches(l)) {
        final d = _toDouble(m.group(1));
        if (d != null) values.add(d);
      }
    }
    return values;
  }

  // Tipo de comprobante
  final tipo = firstLineMatching(
    RegExp(
      r'\b(FACTURA|BOLETA|NOTA\s+DE\s+CR[ÉE]DITO|NOTA\s+DE\s+D[ÉE]BITO)\b',
      caseSensitive: false,
    ),
  );
  factura.tipoComprobante = tipo?.toUpperCase();

  // Serie y número: permitir letras y números en la serie como FPP1-002358
  final serieNumMatch = RegExp(
    r'([A-Z0-9]{1,6})[-–](\d{3,8})',
    caseSensitive: false,
  ).firstMatch(texto);
  if (serieNumMatch != null) {
    factura.serie = serieNumMatch.group(1);
    factura.numero = serieNumMatch.group(2);
  } else {
    // buscar en líneas individuales (por si OCR separó)
    for (final l in rawLines) {
      final m = RegExp(
        r'([A-Z0-9]{1,6})[-–](\d{3,8})',
        caseSensitive: false,
      ).firstMatch(l);
      if (m != null) {
        factura.serie = m.group(1);
        factura.numero = m.group(2);
        break;
      }
    }
  }

  // Fecha: buscar dd/mm/yyyy o variantes cercanas a la palabra FECHA
  final dateRx = RegExp(r'([0-3]?\d[/\-.][0-1]?\d[/\-.][12]\d{3})');
  final fechaEncontrada =
      firstLineMatching(dateRx) ??
      (() {
        final idx = rawLines.indexWhere(
          (l) => l.toLowerCase().contains('fecha'),
        );
        if (idx >= 0) {
          final maybe =
              dateRx.firstMatch(rawLines[idx])?.group(1) ??
              (idx + 1 < rawLines.length
                  ? dateRx.firstMatch(rawLines[idx + 1])?.group(1)
                  : null);
          return maybe;
        }
        return null;
      })();
  factura.fecha = fechaEncontrada;

  // Moneda
  final monedaLine =
      findLineContains('S/') ??
      findLineContains('SOLES') ??
      findLineContains('USD') ??
      findLineContains('\$');
  if (monedaLine != null) {
    if (monedaLine.toUpperCase().contains('USD') ||
        monedaLine.contains(r'\$')) {
      factura.moneda = 'USD';
    } else if (monedaLine.toUpperCase().contains('S') ||
        monedaLine.toUpperCase().contains('SOLES') ||
        monedaLine.contains('S/')) {
      factura.moneda = 'S';
    }
  }

  // Subtotal: buscar SUBTOTAL, GRAVADA, OP. GRAVADAS o línea antes de IGV
  String? subtotal;
  subtotal = firstLineMatching(
    RegExp(
      r'(?:SUBTOTAL|OP\.?\s*GRAVADAS?|OP\.?GRAVADAS|OP\.GRAVADAS|GRAVADA)[\s:\-–]*?(?:S\/\.?\s*)?([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{2}))',
      caseSensitive: false,
    ),
  );
  if (subtotal == null) {
    // Buscar líneas que contengan variantes de GRAVADAS u OP.GRAVADAS y tomar el número
    for (final l in rawLines) {
      if (RegExp(r'OP\.?\s*GRAVAD|GRAVAD', caseSensitive: false).hasMatch(l)) {
        // Si la línea contiene múltiples valores (OP.GRAVADAS ... IGV ... TOTAL),
        // intentamos extraer el número que aparece después de la palabra 'OP' o 'GRAV'
        final idx = l.toLowerCase().indexOf('op');
        if (idx >= 0) {
          final after = l.substring(idx);
          final m = RegExp(
            r'([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{2}))',
          ).firstMatch(after);
          if (m != null) {
            subtotal = m.group(1);
            break;
          }
        }
        // fallback simple: busco cualquier importe en la línea
        subtotal = extractCurrency(l);
        if (subtotal != null) break;
      }
    }
  }
  // fallback: if still null, try to infer from last numeric values (second largest)
  factura.subtotal = subtotal;

  // IGV: buscar tanto valor monetario (S/ 0.77) como porcentaje
  String? igv;
  igv = firstLineMatching(
    RegExp(
      r'(?:I\.?G\.?V|IGV)[:\s\-–]*?(?:S\/\.?\s*)?([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{2}))',
      caseSensitive: false,
    ),
  );
  if (igv == null) {
    final igvLine = rawLines.firstWhere(
      (l) => l.toLowerCase().contains('igv'),
      orElse: () => '',
    );
    if (igvLine.isNotEmpty)
      igv =
          extractCurrency(igvLine) ??
          (RegExp(r'(\d{1,2}(?:[.,]\d{1,2})?)%').firstMatch(igvLine)?.group(1));
  }
  factura.igv = igv;

  // Total: buscar TOTAL con moneda o importe total
  String? total;
  total = firstLineMatching(
    RegExp(
      r'(?:IMP(?:ORTE)?\.?\s*TOTAL|IMP\.?\s*TOTAL|TOTAL\s*(?:A\s*PAGAR)?|TOTAL\s*PAGADO|IMP\.TOTAL)[\s:\-–]*?(?:S\/\.?\s*)?([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{2}))',
      caseSensitive: false,
    ),
  );
  if (total == null) {
    final totalLine = rawLines.firstWhere(
      (l) => RegExp(r'\bTOTAL\b', caseSensitive: false).hasMatch(l),
      orElse: () => '',
    );
    if (totalLine.isNotEmpty) total = extractCurrency(totalLine);
  }
  // Fallback: if still null, take the largest currency like value in the last 8 lines
  factura.total = total;
  if (factura.total == null) {
    final tailVals = tailCurrencyValues(8);
    if (tailVals.isNotEmpty) {
      tailVals.sort();
      final maxv = tailVals.last;
      factura.total = maxv.toStringAsFixed(2);
      // If subtotal is missing, try to take second largest as subtotal
      if (factura.subtotal == null && tailVals.length > 1) {
        final second = tailVals.length >= 2
            ? tailVals[tailVals.length - 2]
            : null;
        if (second != null) factura.subtotal = second.toStringAsFixed(2);
      }
    }
  }

  // Razón social emisor: heurística — línea(s) antes del RUC emisor
  if (factura.rucEmisor != null) {
    final idx = rawLines.indexWhere((l) => l.contains(factura.rucEmisor!));
    if (idx > 0) {
      final candidate = rawLines[idx - 1];
      // si candidate tiene más letras que dígitos, usarlo
      if (RegExp(r'[A-Za-z]').hasMatch(candidate)) {
        factura.razonSocialEmisor = candidate;
      }
    }
  }
  // fallback: buscar etiquetas RAZON SOCIAL o NOMBRE
  factura.razonSocialEmisor ??= firstLineMatching(
    RegExp(
      r'(?:(?:RAZ[ÓO]N\s+SOCIAL|NOMBRE)[\s:\-]*)\s*(.+)',
      caseSensitive: false,
    ),
  );

  // Razón social cliente: buscar línea tras el RUC cliente o tras la etiqueta CLIENTE
  if (factura.rucCliente != null) {
    final idx = rawLines.indexWhere((l) => l.contains(factura.rucCliente!));
    if (idx >= 0) {
      // buscar la siguiente línea que contenga letras significativas
      for (int i = idx + 1; i < rawLines.length; i++) {
        final cand = rawLines[i];
        if (cand.trim().isEmpty) continue;
        if (RegExp(r'[A-Za-z]').hasMatch(cand) &&
            !RegExp(r'RUC', caseSensitive: false).hasMatch(cand)) {
          factura.razonSocialCliente = cand;
          break;
        }
      }
    }
  }
  factura.razonSocialCliente ??= (() {
    final idx = rawLines.indexWhere((l) => l.toLowerCase().contains('cliente'));
    if (idx >= 0 && idx + 2 < rawLines.length) return rawLines[idx + 2];
    return null;
  })();

  return factura;
}
