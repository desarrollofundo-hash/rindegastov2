import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Servicio OPTIMIZADO para extraer datos de facturas con IA y Google ML Kit
/// Incluye sistema de confianza, cache, validación cruzada y logging avanzado
class FacturaIAOptimized {
  static final _textRecognizer = TextRecognizer();
  static bool _modeloInicializado = false;

  // 🚀 SISTEMA DE CACHE INTELIGENTE
  static final Map<String, Map<String, dynamic>> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const int _cacheMaxSize = 100;
  static const Duration _cacheExpiry = Duration(hours: 24);

  // 🎯 SISTEMA DE CONFIANZA AVANZADO
  static const double _confianzaMinima = 0.65;
  static const Map<String, double> _pesosConfianza = {
    'RUC Emisor': 0.95,
    'RUC Cliente': 0.85,
    'Total': 0.90,
    'Serie': 0.85,
    'Número': 0.85,
    'Fecha': 0.75,
    'IGV': 0.80,
    'Moneda': 0.70,
    'Empresa': 0.65,
    'Tipo Comprobante': 0.75,
  };

  // 📊 MÉTRICAS DE RENDIMIENTO
  static int _totalExtracciones = 0;
  static int _cacheHits = 0;
  static int _extracciones_exitosas = 0;
  static final List<double> _tiemposRespuesta = [];

  /// 🚀 FUNCIÓN PRINCIPAL OPTIMIZADA CON SISTEMA DE CONFIANZA
  static Future<Map<String, dynamic>> extraerDatosOptimizado(
    File imagen,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      _totalExtracciones++;

      // 🗂️ VERIFICAR CACHE
      final imageHash = await _generarHashImagen(imagen);
      final resultadoCache = _verificarCache(imageHash);
      if (resultadoCache != null) {
        _cacheHits++;
        _registrarTiempo(stopwatch.elapsedMilliseconds);
        print(
          '💾 Datos obtenidos desde cache (${stopwatch.elapsedMilliseconds}ms)',
        );
        return resultadoCache;
      }

      // 🧠 INICIALIZAR MODELO IA
      await inicializarModelo();

      // 🖼️ PREPROCESAR IMAGEN
      final imagenPreprocesada = await _preprocesarImagen(imagen);

      // 🔍 EXTRAER TEXTO CON OCR
      final inputImage = InputImage.fromFile(imagenPreprocesada);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final texto = recognizedText.text.toUpperCase();
      final lineas = texto
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();

      // 📋 EXTRAER DATOS CON SISTEMA DE CONFIANZA
      Map<String, String> datos = {};
      Map<String, double> confianzas = {};

      // 📝 EXTRACCIÓN DE CAMPOS ESPECÍFICOS CON VALIDACIÓN AVANZADA

      // 1. RUC EMISOR - Máxima prioridad
      final resultRucEmisor = _extraerConConfianza(
        () => _buscarRUCPrincipal(lineas),
        'RUC Emisor',
      );
      if (resultRucEmisor['valor'] != null) {
        datos['RUC Emisor'] = resultRucEmisor['valor']!;
        confianzas['RUC Emisor'] = resultRucEmisor['confianza']!;
      }

      // 2. RUC CLIENTE
      final resultRucCliente = _extraerConConfianza(
        () => _buscarRUCCliente(texto, datos['RUC Emisor']),
        'RUC Cliente',
      );
      if (resultRucCliente['valor'] != null) {
        datos['RUC Cliente'] = resultRucCliente['valor']!;
        confianzas['RUC Cliente'] = resultRucCliente['confianza']!;
      }

      // 3. TIPO DE COMPROBANTE
      final resultTipo = _extraerConConfianza(
        () => _buscarTipoComprobante(lineas),
        'Tipo Comprobante',
      );
      if (resultTipo['valor'] != null) {
        datos['Tipo Comprobante'] = resultTipo['valor']!;
        confianzas['Tipo Comprobante'] = resultTipo['confianza']!;
      }

      // 4. SERIE Y NÚMERO
      final serieNumero = _buscarSerieNumeroOptimizado(texto);
      if (serieNumero['serie'] != null) {
        datos['Serie'] = serieNumero['serie']!;
        confianzas['Serie'] = _validarSerie(serieNumero['serie']!)
            ? 0.95
            : 0.60;
      }
      if (serieNumero['numero'] != null) {
        datos['Número'] = serieNumero['numero']!;
        confianzas['Número'] = _validarNumero(serieNumero['numero']!)
            ? 0.95
            : 0.60;
      }

      // 5. FECHA DE EMISIÓN
      final resultFecha = _extraerConConfianza(
        () => _buscarFechaEmision(texto),
        'Fecha',
      );
      if (resultFecha['valor'] != null) {
        datos['Fecha'] = resultFecha['valor']!;
        confianzas['Fecha'] = resultFecha['confianza']!;
      }

      // 6. TOTAL A PAGAR - Alta prioridad
      final resultTotal = _extraerConConfianza(
        () => _buscarTotalOptimizado(texto),
        'Total',
      );
      if (resultTotal['valor'] != null) {
        datos['Total'] = resultTotal['valor']!;
        confianzas['Total'] = resultTotal['confianza']!;
      }

      // 7. IGV
      final resultIGV = _extraerConConfianza(
        () => _buscarIGVOptimizado(texto),
        'IGV',
      );
      if (resultIGV['valor'] != null) {
        datos['IGV'] = resultIGV['valor']!;
        confianzas['IGV'] = resultIGV['confianza']!;
      }

      // 8. MONEDA
      final resultMoneda = _extraerConConfianza(
        () => _buscarMonedaOptimizada(texto),
        'Moneda',
      );
      if (resultMoneda['valor'] != null) {
        datos['Moneda'] = resultMoneda['valor']!;
        confianzas['Moneda'] = resultMoneda['confianza']!;
      }

      // 9. EMPRESA/RAZÓN SOCIAL
      final resultEmpresa = _extraerConConfianza(
        () => _buscarEmpresa(lineas),
        'Empresa',
      );
      if (resultEmpresa['valor'] != null) {
        datos['Empresa'] = resultEmpresa['valor']!;
        confianzas['Empresa'] = resultEmpresa['confianza']!;
      }

      // 🔄 VALIDACIÓN CRUZADA Y CORRECCIÓN DE ERRORES
      datos = _validacionCruzadaAvanzada(datos);

      // 🎯 CALCULAR CONFIANZA GENERAL
      final confianzaGeneral = _calcularConfianzaGeneral(confianzas);

      // 💾 GUARDAR EN CACHE SI LA CONFIANZA ES ALTA
      if (confianzaGeneral >= _confianzaMinima) {
        _guardarEnCache(imageHash, datos, confianzaGeneral, confianzas);
        _extracciones_exitosas++;
      }

      _registrarTiempo(stopwatch.elapsedMilliseconds);

      // 📊 LOGGING AVANZADO
      _logResultados(datos, confianzaGeneral, stopwatch.elapsedMilliseconds);

      return {
        'datos': datos,
        'confianza': confianzaGeneral,
        'confianzas_detalle': confianzas,
        'tiempo_procesamiento_ms': stopwatch.elapsedMilliseconds,
        'campos_detectados': datos.length,
        'fuente': 'ocr_ia_optimizado',
      };
    } catch (e) {
      _registrarTiempo(stopwatch.elapsedMilliseconds);
      print('❌ Error en OCR optimizado: $e');
      return {
        'datos': {'Error': 'No se pudo procesar la imagen'},
        'confianza': 0.0,
        'error': e.toString(),
        'tiempo_procesamiento_ms': stopwatch.elapsedMilliseconds,
      };
    }
  }

  // ================ FUNCIONES AUXILIARES OPTIMIZADAS ================

  /// Genera hash SHA-256 para cache de imagen
  static Future<String> _generarHashImagen(File imagen) async {
    try {
      final bytes = await imagen.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  /// Verifica cache con expiración automática
  static Map<String, dynamic>? _verificarCache(String hash) {
    if (_cache.containsKey(hash)) {
      final timestamp = _cacheTimestamps[hash];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        return _cache[hash];
      } else {
        // Cache expirado
        _cache.remove(hash);
        _cacheTimestamps.remove(hash);
      }
    }
    return null;
  }

  /// Guarda resultado en cache con limpieza automática
  static void _guardarEnCache(
    String hash,
    Map<String, String> datos,
    double confianza,
    Map<String, double> confianzas,
  ) {
    // Limpiar cache si está lleno
    if (_cache.length >= _cacheMaxSize) {
      _limpiarCacheMasAntiguo();
    }

    _cache[hash] = {
      'datos': datos,
      'confianza': confianza,
      'confianzas_detalle': confianzas,
      'fuente': 'cache',
    };
    _cacheTimestamps[hash] = DateTime.now();
  }

  /// Limpia el elemento más antiguo del cache
  static void _limpiarCacheMasAntiguo() {
    if (_cacheTimestamps.isEmpty) return;

    final hashMasAntiguo = _cacheTimestamps.entries
        .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
        .key;

    _cache.remove(hashMasAntiguo);
    _cacheTimestamps.remove(hashMasAntiguo);
  }

  /// Preprocesa imagen para mejor OCR (placeholder para futuras mejoras)
  static Future<File> _preprocesarImagen(File imagen) async {
    // FUTURAS MEJORAS:
    // - Ajuste automático de contraste
    // - Corrección de perspectiva
    // - Reducción de ruido
    // - Mejora de resolución
    return imagen;
  }

  /// Sistema de extracción con confianza
  static Map<String, dynamic> _extraerConConfianza(
    String? Function() extractor,
    String campo,
  ) {
    try {
      final valor = extractor();
      if (valor != null && valor.trim().isNotEmpty) {
        final confianza = _calcularConfianzaCampo(valor, campo);
        return {'valor': valor.trim(), 'confianza': confianza};
      }
    } catch (e) {
      print('⚠️ Error extrayendo $campo: $e');
    }
    return {'valor': null, 'confianza': 0.0};
  }

  /// Calcula confianza específica por campo con validaciones avanzadas
  static double _calcularConfianzaCampo(String valor, String campo) {
    switch (campo) {
      case 'RUC Emisor':
      case 'RUC Cliente':
        if (_validarRUCCompleto(valor)) return 0.98;
        if (_validarRUC(valor)) return 0.85;
        return 0.30;

      case 'Total':
        if (_validarMontoCompleto(valor)) return 0.95;
        if (_validarMonto(valor)) return 0.75;
        return 0.40;

      case 'IGV':
        if (_validarMontoCompleto(valor)) return 0.90;
        if (_validarMonto(valor)) return 0.70;
        return 0.35;

      case 'Fecha':
        if (_validarFechaCompleta(valor)) return 0.92;
        if (_validarFecha(valor)) return 0.70;
        return 0.30;

      case 'Serie':
        if (_validarSerieCompleta(valor)) return 0.95;
        if (_validarSerie(valor)) return 0.75;
        return 0.40;

      case 'Número':
        if (_validarNumeroCompleto(valor)) return 0.95;
        if (_validarNumero(valor)) return 0.75;
        return 0.40;

      case 'Moneda':
        final monedasValidas = ['PEN', 'USD', 'EUR', 'SOLES', 'DOLARES'];
        if (monedasValidas.contains(valor.toUpperCase())) return 0.95;
        if (valor.length >= 3) return 0.60;
        return 0.30;

      default:
        if (valor.length > 5) return 0.75;
        if (valor.length > 2) return 0.55;
        return 0.35;
    }
  }

  // ================ VALIDACIONES AVANZADAS ================

  static bool _validarRUC(String ruc) {
    final soloNumeros = ruc.replaceAll(RegExp(r'[^\d]'), '');
    return soloNumeros.length == 11 && int.tryParse(soloNumeros) != null;
  }

  static bool _validarRUCCompleto(String ruc) {
    if (!_validarRUC(ruc)) return false;
    final soloNumeros = ruc.replaceAll(RegExp(r'[^\d]'), '');
    // Validar que comience con dígitos válidos para empresas peruanas
    final primerDigito = soloNumeros[0];
    return ['1', '2', '3', '4', '5', '6', '7', '8', '9'].contains(primerDigito);
  }

  static bool _validarMonto(String monto) {
    final soloNumeros = monto.replaceAll(RegExp(r'[^\d.]'), '');
    final numero = double.tryParse(soloNumeros);
    return numero != null && numero > 0;
  }

  static bool _validarMontoCompleto(String monto) {
    if (!_validarMonto(monto)) return false;
    // Validar formato con decimales
    return RegExp(
      r'\d+\.\d{2}$',
    ).hasMatch(monto.replaceAll(RegExp(r'[^\d.]'), ''));
  }

  static bool _validarFecha(String fecha) {
    return RegExp(r'\d{2}[/-]\d{2}[/-]\d{4}').hasMatch(fecha);
  }

  static bool _validarFechaCompleta(String fecha) {
    if (!_validarFecha(fecha)) return false;
    try {
      final partes = fecha.split(RegExp(r'[/-]'));
      if (partes.length != 3) return false;

      final dia = int.parse(partes[0]);
      final mes = int.parse(partes[1]);
      final anio = int.parse(partes[2]);

      return dia >= 1 &&
          dia <= 31 &&
          mes >= 1 &&
          mes <= 12 &&
          anio >= 2020 &&
          anio <= DateTime.now().year + 1;
    } catch (e) {
      return false;
    }
  }

  static bool _validarSerie(String serie) {
    return RegExp(r'^[A-Z]\d{3}$').hasMatch(serie.toUpperCase());
  }

  static bool _validarSerieCompleta(String serie) {
    if (!_validarSerie(serie)) return false;
    final letra = serie.toUpperCase()[0];
    return [
      'F',
      'B',
      'T',
      'E',
    ].contains(letra); // Factura, Boleta, Ticket, Electrónico
  }

  static bool _validarNumero(String numero) {
    final soloNumeros = numero.replaceAll(RegExp(r'[^\d]'), '');
    return soloNumeros.isNotEmpty && soloNumeros.length <= 8;
  }

  static bool _validarNumeroCompleto(String numero) {
    if (!_validarNumero(numero)) return false;
    final soloNumeros = numero.replaceAll(RegExp(r'[^\d]'), '');
    final num = int.tryParse(soloNumeros);
    return num != null && num > 0 && num < 99999999;
  }

  // ================ FUNCIONES DE BÚSQUEDA OPTIMIZADAS ================

  /// Busca RUC principal con patrones mejorados
  static String? _buscarRUCPrincipal(List<String> lineas) {
    // Patrones prioritarios para RUC emisor
    final patronesPrioritarios = [
      RegExp(r'R\.?U\.?C\.?\s*:?\s*(\d{11})', caseSensitive: false),
      RegExp(r'RUC\s*EMISOR\s*:?\s*(\d{11})', caseSensitive: false),
      RegExp(
        r'REGISTRO.*CONTRIBUYENTES?\s*:?\s*(\d{11})',
        caseSensitive: false,
      ),
    ];

    for (final linea in lineas.take(10)) {
      // Solo primeras 10 líneas
      for (final patron in patronesPrioritarios) {
        final match = patron.firstMatch(linea);
        if (match != null) {
          final ruc = match.group(1)!;
          if (_validarRUCCompleto(ruc)) {
            return ruc;
          }
        }
      }
    }

    // Búsqueda general de RUC válido
    for (final linea in lineas) {
      final match = RegExp(r'\b(\d{11})\b').firstMatch(linea);
      if (match != null) {
        final ruc = match.group(1)!;
        if (_validarRUCCompleto(ruc)) {
          return ruc;
        }
      }
    }

    return null;
  }

  /// Busca RUC Cliente excluyendo el emisor
  static String? _buscarRUCCliente(String texto, String? rucEmisor) {
    final patronesCliente = [
      RegExp(r'RUC\s*CLIENTE\s*:?\s*(\d{11})', caseSensitive: false),
      RegExp(r'SEÑOR\(ES\)\s*:?\s*RUC\s*(\d{11})', caseSensitive: false),
      RegExp(r'CLIENTE\s*:?\s*(\d{11})', caseSensitive: false),
    ];

    for (final patron in patronesCliente) {
      final match = patron.firstMatch(texto);
      if (match != null) {
        final ruc = match.group(1)!;
        if (_validarRUCCompleto(ruc) && ruc != rucEmisor) {
          return ruc;
        }
      }
    }

    // Buscar todos los RUCs y excluir el emisor
    final todosRucs = RegExp(r'\b(\d{11})\b').allMatches(texto);
    for (final match in todosRucs) {
      final ruc = match.group(1)!;
      if (_validarRUCCompleto(ruc) && ruc != rucEmisor) {
        return ruc;
      }
    }

    return null;
  }

  /// Busca tipo de comprobante optimizado
  static String? _buscarTipoComprobante(List<String> lineas) {
    final tiposComprobante = {
      RegExp(r'\bFACTURA\b', caseSensitive: false): 'FACTURA',
      RegExp(r'\bBOLETA\b', caseSensitive: false): 'BOLETA',
      RegExp(r'\bTICKET\b', caseSensitive: false): 'TICKET',
      RegExp(r'\bNOTA\s+DE\s+CRÉDITO\b', caseSensitive: false):
          'NOTA DE CRÉDITO',
      RegExp(r'\bNOTA\s+DE\s+DÉBITO\b', caseSensitive: false): 'NOTA DE DÉBITO',
      RegExp(r'\bRECIBO\b', caseSensitive: false): 'RECIBO',
    };

    // Buscar en las primeras líneas primero
    for (final linea in lineas.take(5)) {
      for (final entry in tiposComprobante.entries) {
        if (entry.key.hasMatch(linea)) {
          return entry.value;
        }
      }
    }

    // Búsqueda en todo el texto
    for (final linea in lineas) {
      for (final entry in tiposComprobante.entries) {
        if (entry.key.hasMatch(linea)) {
          return entry.value;
        }
      }
    }

    return null;
  }

  /// Busca serie y número optimizado
  static Map<String, String?> _buscarSerieNumeroOptimizado(String texto) {
    final patronesCompletos = [
      RegExp(
        r'SERIE\s*:?\s*([A-Z]\d{3})\s*-?\s*N[°º]?\s*(\d+)',
        caseSensitive: false,
      ),
      RegExp(r'([FBT]\d{3})\s*-\s*(\d+)', caseSensitive: false),
      RegExp(r'N[°º]?\s*([A-Z]\d{3})\s*-\s*(\d+)', caseSensitive: false),
      RegExp(r'NÚMERO\s*:?\s*([A-Z]\d{3})\s*-\s*(\d+)', caseSensitive: false),
    ];

    for (final patron in patronesCompletos) {
      final match = patron.firstMatch(texto);
      if (match != null) {
        final serie = match.group(1)?.toUpperCase();
        final numero = match.group(2);
        if (serie != null &&
            numero != null &&
            _validarSerieCompleta(serie) &&
            _validarNumeroCompleto(numero)) {
          return {'serie': serie, 'numero': numero};
        }
      }
    }

    // Búsqueda separada
    String? serie;
    String? numero;

    final patronesSerie = [
      RegExp(r'SERIE\s*:?\s*([A-Z]\d{3})', caseSensitive: false),
      RegExp(r'([FBT]\d{3})', caseSensitive: false),
    ];

    for (final patron in patronesSerie) {
      final match = patron.firstMatch(texto);
      if (match != null) {
        final s = match.group(1)?.toUpperCase();
        if (s != null && _validarSerieCompleta(s)) {
          serie = s;
          break;
        }
      }
    }

    final patronesNumero = [
      RegExp(r'N[°º]?\s*\d+-(\d+)', caseSensitive: false),
      RegExp(r'NÚMERO\s*:?\s*(\d+)', caseSensitive: false),
    ];

    for (final patron in patronesNumero) {
      final match = patron.firstMatch(texto);
      if (match != null) {
        final n = match.group(1);
        if (n != null && _validarNumeroCompleto(n)) {
          numero = n;
          break;
        }
      }
    }

    return {'serie': serie, 'numero': numero};
  }

  /// Busca fecha de emisión optimizada
  static String? _buscarFechaEmision(String texto) {
    final patronesFecha = [
      RegExp(
        r'FECHA\s*(?:DE\s+)?EMISIÓN\s*:?\s*(\d{2}[/-]\d{2}[/-]\d{4})',
        caseSensitive: false,
      ),
      RegExp(r'FECHA\s*:?\s*(\d{2}[/-]\d{2}[/-]\d{4})', caseSensitive: false),
      RegExp(r'EMITIDO\s*:?\s*(\d{2}[/-]\d{2}[/-]\d{4})', caseSensitive: false),
      RegExp(r'(\d{2}[/-]\d{2}[/-]\d{4})'),
    ];

    for (final patron in patronesFecha) {
      final match = patron.firstMatch(texto);
      if (match != null) {
        final fecha = match.group(1)!;
        if (_validarFechaCompleta(fecha)) {
          return fecha;
        }
      }
    }
    return null;
  }

  /// Busca total optimizado con múltiples patrones
  static String? _buscarTotalOptimizado(String texto) {
    final patronesPrioritarios = [
      RegExp(
        r'TOTAL\s*A\s*PAGAR\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ),
      RegExp(
        r'IMPORTE\s*TOTAL\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ),
      RegExp(r'TOTAL\s*[:\sS/$]*?\s*([\d,]+\.\d{2})', caseSensitive: false),
      RegExp(
        r'MONTO\s*TOTAL\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ),
      RegExp(
        r'TOTAL\s*GENERAL\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ),
    ];

    for (final patron in patronesPrioritarios) {
      final matches = patron.allMatches(texto);
      if (matches.isNotEmpty) {
        final monto = matches.last.group(1)!.replaceAll(',', '');
        if (_validarMontoCompleto(monto)) {
          return monto;
        }
      }
    }

    return null;
  }

  /// Busca IGV optimizado
  static String? _buscarIGVOptimizado(String texto) {
    final patronesIGV = [
      RegExp(
        r'IGV\s*\(18%\)\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ),
      RegExp(
        r'I\.G\.V\.?\s*18%\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ),
      RegExp(r'IGV\s*18%\s*[:\sS/$]*?\s*([\d,]+\.\d{2})', caseSensitive: false),
      RegExp(r'IGV\s*[:\sS/$]*?\s*([\d,]+\.\d{2})', caseSensitive: false),
      RegExp(r'IMPUESTO\s*[:\sS/$]*?\s*([\d,]+\.\d{2})', caseSensitive: false),
    ];

    for (final patron in patronesIGV) {
      final match = patron.firstMatch(texto);
      if (match != null) {
        final monto = match.group(1)!.replaceAll(',', '');
        if (_validarMontoCompleto(monto)) {
          return monto;
        }
      }
    }
    return null;
  }

  /// Busca moneda optimizada
  static String? _buscarMonedaOptimizada(String texto) {
    final patronesMoneda = [
      RegExp(r'\b(SOLES?)\b', caseSensitive: false),
      RegExp(r'\b(DOLARES?)\b', caseSensitive: false),
      RegExp(r'\b(EUROS?)\b', caseSensitive: false),
      RegExp(r'\b(USD|PEN|EUR)\b', caseSensitive: false),
      RegExp(r'S/\.?', caseSensitive: false),
      RegExp(r'\$', caseSensitive: false),
      RegExp(r'€', caseSensitive: false),
    ];

    final mapaMonedas = {
      'SOLES': 'PEN',
      'SOLE': 'PEN',
      'DOLARES': 'USD',
      'DOLAR': 'USD',
      'EUROS': 'EUR',
      'EURO': 'EUR',
      'S/': 'PEN',
      r'$': 'USD',
      '€': 'EUR',
    };

    for (final patron in patronesMoneda) {
      final match = patron.firstMatch(texto);
      if (match != null) {
        String moneda = match.group(0)!.toUpperCase();
        return mapaMonedas[moneda] ?? moneda;
      }
    }

    // Si no encuentra patrón específico pero hay "S/" asumir PEN
    if (texto.contains('S/')) return 'PEN';
    if (texto.contains('\$')) return 'USD';
    if (texto.contains('€')) return 'EUR';

    return null;
  }

  /// Busca empresa/razón social
  static String? _buscarEmpresa(List<String> lineas) {
    // Buscar en las primeras líneas que suelen contener la razón social
    for (int i = 0; i < min(8, lineas.length); i++) {
      final linea = lineas[i].trim();

      // Saltar líneas que claramente no son empresa
      if (RegExp(
        r'(RUC|FACTURA|BOLETA|FECHA|SERIE|TOTAL)',
        caseSensitive: false,
      ).hasMatch(linea)) {
        continue;
      }

      // Buscar líneas que parezcan nombre de empresa
      if (linea.length > 10 && linea.length < 80) {
        // Verificar que tenga características de nombre empresarial
        if (RegExp(r'[A-Z]{2,}').hasMatch(linea) &&
            !RegExp(r'^\d+$').hasMatch(linea)) {
          return linea;
        }
      }
    }

    return null;
  }

  // ================ VALIDACIÓN CRUZADA AVANZADA ================

  /// Validación cruzada con corrección automática de errores
  static Map<String, String> _validacionCruzadaAvanzada(
    Map<String, String> datos,
  ) {
    final Map<String, String> datosCorregidos = Map.from(datos);

    // 1. VALIDAR COHERENCIA IGV VS TOTAL
    final igvStr = datos['IGV']?.replaceAll(RegExp(r'[^\d.]'), '');
    final totalStr = datos['Total']?.replaceAll(RegExp(r'[^\d.]'), '');

    if (igvStr != null && totalStr != null) {
      final igv = double.tryParse(igvStr);
      final total = double.tryParse(totalStr);

      if (igv != null && total != null) {
        final igvCalculado = total * 0.18;
        final diferencia = (igv - igvCalculado).abs();

        if (diferencia > total * 0.05) {
          print(
            '⚠️ Inconsistencia IGV: $igv vs calculado: ${igvCalculado.toStringAsFixed(2)}',
          );

          // Auto-corrección si la diferencia es muy grande
          if (diferencia > total * 0.1) {
            print(
              '🔧 Auto-corrigiendo IGV a: ${igvCalculado.toStringAsFixed(2)}',
            );
            datosCorregidos['IGV'] = igvCalculado.toStringAsFixed(2);
          }
        }
      }
    }

    // 2. VALIDAR UNICIDAD DE RUCS
    final rucEmisor = datos['RUC Emisor'];
    final rucCliente = datos['RUC Cliente'];

    if (rucEmisor != null && rucCliente != null && rucEmisor == rucCliente) {
      print('⚠️ RUC Emisor y Cliente idénticos, removiendo cliente');
      datosCorregidos.remove('RUC Cliente');
    }

    // 3. VALIDAR COHERENCIA SERIE-TIPO COMPROBANTE
    final tipoComprobante = datos['Tipo Comprobante'];
    final serie = datos['Serie'];

    if (tipoComprobante != null && serie != null) {
      final letraEsperada = _obtenerLetraEsperada(tipoComprobante);
      final letraActual = serie[0];

      if (letraEsperada != null && letraActual != letraEsperada) {
        print('⚠️ Serie "$serie" no coincide con tipo "$tipoComprobante"');
        print('💡 Se esperaba serie con letra: $letraEsperada');
      }
    }

    // 4. VALIDAR FECHA LÓGICA
    final fecha = datos['Fecha'];
    if (fecha != null && _validarFecha(fecha)) {
      try {
        final partes = fecha.split(RegExp(r'[/-]'));
        final fechaObj = DateTime(
          int.parse(partes[2]),
          int.parse(partes[1]),
          int.parse(partes[0]),
        );

        final ahora = DateTime.now();
        final hace5anios = ahora.subtract(Duration(days: 365 * 5));

        if (fechaObj.isAfter(ahora) || fechaObj.isBefore(hace5anios)) {
          print('⚠️ Fecha sospechosa: $fecha');
        }
      } catch (e) {
        print('⚠️ Error validando fecha: $fecha');
      }
    }

    return datosCorregidos;
  }

  /// Obtiene letra esperada para serie según tipo de comprobante
  static String? _obtenerLetraEsperada(String tipoComprobante) {
    final tipo = tipoComprobante.toUpperCase();
    if (tipo.contains('FACTURA')) return 'F';
    if (tipo.contains('BOLETA')) return 'B';
    if (tipo.contains('TICKET')) return 'T';
    if (tipo.contains('NOTA')) return 'N';
    return null;
  }

  /// Calcula confianza general ponderada
  static double _calcularConfianzaGeneral(Map<String, double> confianzas) {
    if (confianzas.isEmpty) return 0.0;

    double sumaConfianzas = 0.0;
    double sumaPesos = 0.0;

    confianzas.forEach((campo, confianza) {
      final peso = _pesosConfianza[campo] ?? 0.5;
      sumaConfianzas += confianza * peso;
      sumaPesos += peso;
    });

    final confianzaBase = sumaPesos > 0 ? sumaConfianzas / sumaPesos : 0.0;

    // Bonus por completitud
    final completitudBonus = confianzas.length >= 7 ? 0.05 : 0.0;

    // Penalty por campos críticos faltantes
    final camposCriticos = ['RUC Emisor', 'Total'];
    final criticos_faltantes = camposCriticos
        .where((campo) => !confianzas.containsKey(campo))
        .length;
    final criticalPenalty = criticos_faltantes * 0.15;

    final confianzaFinal = (confianzaBase + completitudBonus - criticalPenalty)
        .clamp(0.0, 1.0);

    return confianzaFinal;
  }

  // ================ LOGGING Y MÉTRICAS ================

  /// Registra tiempo de respuesta
  static void _registrarTiempo(int milliseconds) {
    _tiemposRespuesta.add(milliseconds.toDouble());
    if (_tiemposRespuesta.length > 100) {
      _tiemposRespuesta.removeAt(0); // Mantener solo últimos 100
    }
  }

  /// Log de resultados con métricas
  static void _logResultados(
    Map<String, String> datos,
    double confianza,
    int tiempoMs,
  ) {
    final estado = confianza >= _confianzaMinima ? '✅' : '⚠️';
    print('\n$estado === RESULTADO OCR OPTIMIZADO ===');
    print('🕒 Tiempo: ${tiempoMs}ms');
    print('🎯 Confianza: ${(confianza * 100).toStringAsFixed(1)}%');
    print('📊 Campos: ${datos.length}/10');
    print('🗂️ Cache: $_cacheHits/$_totalExtracciones hits');

    if (datos.isNotEmpty) {
      print('📋 Detectados: ${datos.keys.join(", ")}');
    }

    // Métricas adicionales
    if (_tiemposRespuesta.isNotEmpty) {
      final promedioTiempo =
          _tiemposRespuesta.reduce((a, b) => a + b) / _tiemposRespuesta.length;
      print('⚡ Promedio: ${promedioTiempo.toStringAsFixed(0)}ms');
    }

    print('==========================================\n');
  }

  // ================ FUNCIONES PÚBLICAS DE UTILIDAD ================

  /// Inicializa el sistema (sin modelo ML externo)
  static Future<bool> inicializarModelo() async {
    if (_modeloInicializado) return true;

    try {
      _modeloInicializado = true;
      print('✅ Sistema de extracción inicializado');
      return true;
    } catch (e) {
      print('⚠️ Error al inicializar sistema: $e');
      return false;
    }
  }

  /// Limpia cache manualmente
  static void limpiarCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    print('🧹 Cache limpiado completamente');
  }

  /// Obtiene estadísticas completas del sistema
  static Map<String, dynamic> obtenerEstadisticasCompletas() {
    final promedio = _tiemposRespuesta.isNotEmpty
        ? _tiemposRespuesta.reduce((a, b) => a + b) / _tiemposRespuesta.length
        : 0.0;

    final tasaExito = _totalExtracciones > 0
        ? (_extracciones_exitosas / _totalExtracciones) * 100
        : 0.0;

    final tasaCache = _totalExtracciones > 0
        ? (_cacheHits / _totalExtracciones) * 100
        : 0.0;

    return {
      'version': '2.0_optimized',
      'modelo_inicializado': _modeloInicializado,
      'cache': {
        'size': _cache.length,
        'max_size': _cacheMaxSize,
        'hits': _cacheHits,
        'hit_rate_percent': tasaCache.toStringAsFixed(1),
      },
      'rendimiento': {
        'total_extracciones': _totalExtracciones,
        'extracciones_exitosas': _extracciones_exitosas,
        'tasa_exito_percent': tasaExito.toStringAsFixed(1),
        'tiempo_promedio_ms': promedio.toStringAsFixed(0),
        'tiempo_minimo_ms': _tiemposRespuesta.isNotEmpty
            ? _tiemposRespuesta.reduce(min).toStringAsFixed(0)
            : '0',
        'tiempo_maximo_ms': _tiemposRespuesta.isNotEmpty
            ? _tiemposRespuesta.reduce(max).toStringAsFixed(0)
            : '0',
      },
      'configuracion': {
        'confianza_minima': _confianzaMinima,
        'cache_expiry_hours': _cacheExpiry.inHours,
        'campos_soportados': _pesosConfianza.keys.toList(),
      },
    };
  }

  /// Resetea todas las métricas
  static void resetearMetricas() {
    _totalExtracciones = 0;
    _cacheHits = 0;
    _extracciones_exitosas = 0;
    _tiemposRespuesta.clear();
    print('📊 Métricas reseteadas');
  }

  /// Libera recursos
  static Future<void> dispose() async {
    try {
      await _textRecognizer.close();
      limpiarCache();
      resetearMetricas();
      print('🧹 Recursos liberados correctamente');
    } catch (e) {
      print('⚠️ Error liberando recursos: $e');
    }
  }
}
