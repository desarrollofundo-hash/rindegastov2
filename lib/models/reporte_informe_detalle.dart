class ReporteInformeDetalle {
  final int id;
  final int idinf;
  final int idrend;
  final int iduser;
  final String? obs;
  final String? estadoactual;
  final String? estado;
  final String? feccre;
  final String? politica;
  final String? categoria;
  final String? tipogasto;
  final String? ruc;
  final String? proveedor;
  final String? tipocombrobante;
  final String? serie;
  final String? numero;
  final double igv;
  final String? fecha;
  final double total;
  final String? moneda;
  final String? ruccliente;
  final String? motivoviaje;
  final String? lugarorigen;
  final String? lugardestino;
  final String? tipomovilidad;

  ReporteInformeDetalle({
    required this.id,
    required this.idinf,
    required this.idrend,
    required this.iduser,
    this.obs,
    this.estadoactual,
    this.estado,
    this.feccre,
    this.politica,
    this.categoria,
    this.tipogasto,
    this.ruc,
    this.proveedor,
    this.tipocombrobante,
    this.serie,
    this.numero,
    required this.igv,
    this.fecha,
    required this.total,
    this.moneda,
    this.ruccliente,
    this.motivoviaje,
    this.lugarorigen,
    this.lugardestino,
    this.tipomovilidad,
  });

  factory ReporteInformeDetalle.fromJson(Map<String, dynamic> json) {
    return ReporteInformeDetalle(
      id: json['id'] ?? 0,
      idinf: json['idinf'] ?? 0,
      idrend: json['idrend'] ?? 0,
      iduser: json['iduser'] ?? 0,
      obs: json['obs'],
      estadoactual: json['estadoactual'],
      estado: json['estado'],
      feccre: json['feccre'],
      politica: json['politica'],
      categoria: json['categoria'],
      tipogasto: json['tipogasto'],
      ruc: json['ruc'],
      proveedor: json['proveedor'],
      tipocombrobante: json['tipocombrobante'],
      serie: json['serie'],
      numero: json['numero'],
      igv: (json['igv'] ?? 0.0).toDouble(),
      fecha: json['fecha'],
      total: (json['total'] ?? 0.0).toDouble(),
      moneda: json['moneda'],
      ruccliente: json['ruccliente'],
      motivoviaje: json['motivoviaje'],
      lugarorigen: json['lugarorigen'],
      lugardestino: json['lugardestino'],
      tipomovilidad: json['tipomovilidad'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idinf': idinf,
      'idrend': idrend,
      'iduser': iduser,
      'obs': obs,
      'estadoactual': estadoactual,
      'estado': estado,
      'feccre': feccre,
      'politica': politica,
      'categoria': categoria,
      'tipogasto': tipogasto,
      'ruc': ruc,
      'proveedor': proveedor,
      'tipocombrobante': tipocombrobante,
      'serie': serie,
      'numero': numero,
      'igv': igv,
      'fecha': fecha,
      'total': total,
      'moneda': moneda,
      'ruccliente': ruccliente,
      'motivoviaje': motivoviaje,
      'lugarorigen': lugarorigen,
      'lugardestino': lugardestino,
      'tipomovilidad': tipomovilidad,
    };
  }

  @override
  String toString() {
    return 'ReporteInformeDetalle{id: $id, idinf: $idinf, idrend: $idrend, iduser: $iduser, obs: $obs, estadoactual: $estadoactual, estado: $estado, feccre: $feccre, politica: $politica, categoria: $categoria, tipogasto: $tipogasto, ruc: $ruc, proveedor: $proveedor, tipocombrobante: $tipocombrobante, serie: $serie, numero: $numero, igv: $igv, fecha: $fecha, total: $total, moneda: $moneda, ruccliente: $ruccliente, motivoviaje: $motivoviaje, lugarorigen: $lugarorigen, lugardestino: $lugardestino, tipomovilidad: $tipomovilidad}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReporteInformeDetalle &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          idinf == other.idinf &&
          idrend == other.idrend;

  @override
  int get hashCode => id.hashCode ^ idinf.hashCode ^ idrend.hashCode;

  // Helper methods
  String get estadoFormatted => estadoactual ?? 'Sin estado';
  String get fechaCreacionFormatted {
    if (feccre == null || feccre!.isEmpty) return '----';
    try {
      if (feccre!.contains('T')) {
        return feccre!.split('T')[0];
      }
      return feccre!;
    } catch (e) {
      return '----';
    }
  }

  String get fechaFormatted {
    if (fecha == null || fecha!.isEmpty) return '----';
    try {
      if (fecha!.contains('T')) {
        return fecha!.split('T')[0];
      }
      return fecha!;
    } catch (e) {
      return '----';
    }
  }

  String get totalFormatted => '${total.toStringAsFixed(2)} ${moneda ?? 'PEN'}';
  String get igvFormatted => '${igv.toStringAsFixed(2)} ${moneda ?? 'PEN'}';

  bool get hasRuc => ruc != null && ruc!.isNotEmpty;
  bool get hasProveedor => proveedor != null && proveedor!.isNotEmpty;
  bool get hasComprobante =>
      (serie != null && serie!.isNotEmpty) ||
      (numero != null && numero!.isNotEmpty);

  String get comprobanteCompleto {
    final serieStr = serie ?? '';
    final numeroStr = numero ?? '';
    if (serieStr.isNotEmpty && numeroStr.isNotEmpty) {
      return '$serieStr-$numeroStr';
    } else if (numeroStr.isNotEmpty) {
      return numeroStr;
    }
    return 'Sin comprobante';
  }

  String get proveedorOrRuc {
    if (hasProveedor) return proveedor!;
    if (hasRuc) return 'RUC: $ruc';
    return 'Sin proveedor';
  }
}
