class ReporteRevisionDetalle {
  final int id;
  final int idRev;
  final int idAd;
  final int idAdDet;
  final int idInf;
  final int idRend;
  final int idUser;
  final String? obs;
  final String? estadoActual;
  final String? estado;
  final String? fecCre;

  // Campos adicionales del JSON (tabla gasto)
  final String? politica;
  final String? categoria;
  final String? tipoGasto;
  final String? ruc;
  final String? proveedor;
  final String? tipoComprobante;
  final String? serie;
  final String? numero;
  final double igv;
  final String? fecha;
  final double total;
  final String? moneda;
  final String? rucCliente;
  final String? motivoViaje;
  final String? lugarOrigen;
  final String? lugarDestino;
  final String? tipoMovilidad;

  ReporteRevisionDetalle({
    required this.id,
    required this.idRev,
    required this.idAd,
    required this.idAdDet,
    required this.idInf,
    required this.idRend,
    required this.idUser,
    this.obs,
    this.estadoActual,
    this.estado,
    this.fecCre,
    this.politica,
    this.categoria,
    this.tipoGasto,
    this.ruc,
    this.proveedor,
    this.tipoComprobante,
    this.serie,
    this.numero,
    required this.igv,
    this.fecha,
    required this.total,
    this.moneda,
    this.rucCliente,
    this.motivoViaje,
    this.lugarOrigen,
    this.lugarDestino,
    this.tipoMovilidad,
  });

  factory ReporteRevisionDetalle.fromJson(Map<String, dynamic> json) {
    return ReporteRevisionDetalle(
      id: json['id'] ?? 0,
      idRev: json['idrev'] ?? 0,
      idAd: json['idad'] ?? 0,
      idAdDet: json['idaddet'] ?? 0,
      idInf: json['idinf'] ?? 0,
      idRend: json['idrend'] ?? 0,
      idUser: json['iduser'] ?? 0,
      obs: json['obs'],
      estadoActual: json['estadoactual'],
      estado: json['estado'],
      fecCre: json['feccre'],
      politica: json['politica'],
      categoria: json['categoria'],
      tipoGasto: json['tipogasto'],
      ruc: json['ruc'],
      proveedor: json['proveedor'],
      tipoComprobante: json['tipocombrobante'],
      serie: json['serie'],
      numero: json['numero'],
      igv: (json['igv'] ?? 0.0).toDouble(),
      fecha: json['fecha'],
      total: (json['total'] ?? 0.0).toDouble(),
      moneda: json['moneda'],
      rucCliente: json['ruccliente'],
      motivoViaje: json['motivoviaje'],
      lugarOrigen: json['lugarorigen'],
      lugarDestino: json['lugardestino'],
      tipoMovilidad: json['tipomovilidad'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idrev': idRev,
      'idad': idAd,
      'idaddet': idAdDet,
      'idinf': idInf,
      'idrend': idRend,
      'iduser': idUser,
      'obs': obs,
      'estadoactual': estadoActual,
      'estado': estado,
      'feccre': fecCre,
      'politica': politica,
      'categoria': categoria,
      'tipogasto': tipoGasto,
      'ruc': ruc,
      'proveedor': proveedor,
      'tipocombrobante': tipoComprobante,
      'serie': serie,
      'numero': numero,
      'igv': igv,
      'fecha': fecha,
      'total': total,
      'moneda': moneda,
      'ruccliente': rucCliente,
      'motivoviaje': motivoViaje,
      'lugarorigen': lugarOrigen,
      'lugardestino': lugarDestino,
      'tipomovilidad': tipoMovilidad,
    };
  }

  // Métodos auxiliares
  String get estadoFormatted => estadoActual ?? 'Sin estado';

  String get fechaCreacionFormatted {
    if (fecCre == null || fecCre!.isEmpty) return '----';
    try {
      if (fecCre!.contains('T')) {
        return fecCre!.split('T')[0];
      }
      return fecCre!;
    } catch (_) {
      return '----';
    }
  }

  bool get hasRuc => ruc != null && ruc!.isNotEmpty;
  bool get hasObs => obs != null && obs!.isNotEmpty;

  String get resumenAuditoria {
    final rucStr = hasRuc ? 'RUC: $ruc' : 'Sin RUC';
    final obsStr = hasObs ? obs : 'Sin observaciones';
    return '$rucStr • $estadoFormatted • $obsStr';
  }

  @override
  String toString() {
    return 'ReporteAuditoriaDetalle(id: $id, idAd: $idAd, idAdDet: $idAdDet, categoria: $categoria, total: $total)';
  }
}
