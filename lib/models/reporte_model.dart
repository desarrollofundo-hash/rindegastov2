class Reporte {
  final int idrend;
  final int iduser;
  final String? dni;
  final String? politica;
  final String? categoria;
  final String? tipogasto;
  final String? ruc;
  final String? proveedor;
  final String? tipocomprobante;
  final String? serie;
  final String? numero;
  final double? igv;
  final String? fecha;
  final double? total;
  final String? moneda;
  final String? ruccliente;
  final String? desempr;
  final String? dessed;
  final String? gerencia;
  final String? area;
  final String? idcuenta;
  final String? consumidor;
  final String? placa;
  final String? estadoActual;
  final String? glosa;
  final String? motivoviaje;
  final String? lugarorigen;
  final String? lugardestino;
  final String? tipomovilidad;
  final String? obs;
  final String? evidencia;

  Reporte({
    required this.idrend,
    required this.iduser,
    this.dni,
    this.politica,
    this.categoria,
    this.tipogasto,
    this.ruc,
    this.proveedor,
    this.tipocomprobante,
    this.serie,
    this.numero,
    this.igv,
    this.fecha,
    this.total,
    this.moneda,
    this.ruccliente,
    this.desempr,
    this.dessed,
    this.gerencia,
    this.area,
    this.idcuenta,
    this.consumidor,
    this.placa,
    this.estadoActual,
    this.glosa,
    this.motivoviaje,
    this.lugarorigen,
    this.lugardestino,
    this.tipomovilidad,
    this.obs,
    this.evidencia,
  });

  factory Reporte.fromJson(Map<String, dynamic> json) {
    try {
      return Reporte(
        idrend: _parseIntSafe(json['idrend'], 0),
        iduser: _parseIntSafe(json['iduser'], 0),
        dni: _parseStringSafe(json['dni']),
        politica: _parseStringSafe(json['politica']),
        categoria: _parseStringSafe(json['categoria']),
        tipogasto: _parseStringSafe(json['tipogasto']),
        ruc: _parseStringSafe(json['ruc']),
        proveedor: _parseStringSafe(json['proveedor']),
        tipocomprobante: _parseStringSafe(
          json['tipocomprobante'] ?? json['tipocombrobante'],
        ),
        serie: _parseStringSafe(json['serie']),
        numero: _parseStringSafe(json['numero']),
        igv: _parseDoubleSafe(json['igv']),
        fecha: _parseStringSafe(json['fecha']),
        total: _parseDoubleSafe(json['total']),
        moneda: _parseStringSafe(json['moneda']),
        ruccliente: _parseStringSafe(json['ruccliente']),
        desempr: _parseStringSafe(json['desempr']),
        dessed: _parseStringSafe(json['dessed']),
        gerencia: _parseStringSafe(json['gerencia']),
        area: _parseStringSafe(json['area']),
        idcuenta: _parseStringSafe(json['idcuenta']),
        consumidor: _parseStringSafe(json['consumidor']),
        placa: _parseStringSafe(json['placa']),
        estadoActual: _parseStringSafe(json['estadoActual']),
        glosa: _parseStringSafe(json['glosa']),
        motivoviaje: _parseStringSafe(json['motivoviaje']),
        lugarorigen: _parseStringSafe(json['lugarorigen']),
        lugardestino: _parseStringSafe(json['lugardestino']),
        tipomovilidad: _parseStringSafe(json['tipomovilidad']),
        obs: _parseStringSafe(json['obs']),
        evidencia: _parseStringSafe(json['evidencia']),
      );
    } catch (e) {
      throw Exception('Error al crear Reporte desde JSON: $e\nJSON: $json');
    }
  }

  static int _parseIntSafe(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (value is double) return value.toInt();
    return defaultValue;
  }

  static double? _parseDoubleSafe(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  static String? _parseStringSafe(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'idrend': idrend,
      'iduser': iduser,
      'dni': dni,
      'politica': politica,
      'categoria': categoria,
      'tipogasto': tipogasto,
      'ruc': ruc,
      'proveedor': proveedor,
      'tipocomprobante': tipocomprobante,
      'serie': serie,
      'numero': numero,
      'igv': igv,
      'fecha': fecha,
      'total': total,
      'moneda': moneda,
      'ruccliente': ruccliente,
      'desempr': desempr,
      'dessed': dessed,
      'gerencia': gerencia,
      'area': area,
      'idcuenta': idcuenta,
      'consumidor': consumidor,
      'placa': placa,
      'estadoActual': estadoActual,
      'glosa': glosa,
      'motivoviaje': motivoviaje,
      'lugarorigen': lugarorigen,
      'lugardestino': lugardestino,
      'tipomovilidad': tipomovilidad,
      'obs': obs,
      'evidencia': evidencia,
    };
  }

  @override
  String toString() {
    return 'Reporte(idrend: $idrend, iduser: $iduser, proveedor: $proveedor, estadoActual: $estadoActual, total: $total)';
  }
}
