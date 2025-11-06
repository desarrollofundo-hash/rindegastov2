class ApiRuc {
  final String? direccion;
  final String? direccionCompleta;
  final String? ruc;
  final String? nombreRazonSocial;
  final String? estado;
  final String? condicion;
  final String? departamento;
  final String? provincia;
  final String? distrito;
  final String? ubigeoSunat;
  final List<String>? ubigeo;
  final String? esAgenteDeRetencion;
  final String? esAgenteDePercepcion;
  final String? esAgenteDePercepcionCombustible;
  final String? esBuenContribuyente;

  ApiRuc({
    this.direccion,
    this.direccionCompleta,
    this.ruc,
    this.nombreRazonSocial,
    this.estado,
    this.condicion,
    this.departamento,
    this.provincia,
    this.distrito,
    this.ubigeoSunat,
    this.ubigeo,
    this.esAgenteDeRetencion,
    this.esAgenteDePercepcion,
    this.esAgenteDePercepcionCombustible,
    this.esBuenContribuyente,
  });

  factory ApiRuc.fromJson(Map<String, dynamic> json) {
    try {
      return ApiRuc(
        direccion: _parseStringSafe(json['direccion']),
        direccionCompleta: _parseStringSafe(json['direccion_completa']),
        ruc: _parseStringSafe(json['ruc']),
        nombreRazonSocial: _parseStringSafe(json['nombre_o_razon_social']),
        estado: _parseStringSafe(json['estado']),
        condicion: _parseStringSafe(json['condicion']),
        departamento: _parseStringSafe(json['departamento']),
        provincia: _parseStringSafe(json['provincia']),
        distrito: _parseStringSafe(json['distrito']),
        ubigeoSunat: _parseStringSafe(json['ubigeo_sunat']),
        ubigeo: _parseListStringSafe(json['ubigeo']),
        esAgenteDeRetencion: _parseStringSafe(json['es_agente_de_retencion']),
        esAgenteDePercepcion: _parseStringSafe(json['es_agente_de_percepcion']),
        esAgenteDePercepcionCombustible: _parseStringSafe(
          json['es_agente_de_percepcion_combustible'],
        ),
        esBuenContribuyente: _parseStringSafe(json['es_buen_contribuyente']),
      );
    } catch (e) {
      throw Exception('Error al crear ApiRuc desde JSON: $e\nJSON: $json');
    }
  }

  // Métodos auxiliares seguros
  static String? _parseStringSafe(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  static List<String>? _parseListStringSafe(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'direccion': direccion,
      'direccion_completa': direccionCompleta,
      'ruc': ruc,
      'nombre_o_razon_social': nombreRazonSocial,
      'estado': estado,
      'condicion': condicion,
      'departamento': departamento,
      'provincia': provincia,
      'distrito': distrito,
      'ubigeo_sunat': ubigeoSunat,
      'ubigeo': ubigeo,
      'es_agente_de_retencion': esAgenteDeRetencion,
      'es_agente_de_percepcion': esAgenteDePercepcion,
      'es_agente_de_percepcion_combustible': esAgenteDePercepcionCombustible,
      'es_buen_contribuyente': esBuenContribuyente,
    };
  }

  @override
  String toString() {
    return 'ApiRuc{ruc: $ruc, nombreRazonSocial: $nombreRazonSocial, estado: $estado, condicion: $condicion, direccion: $direccionCompleta}';
  }
}
