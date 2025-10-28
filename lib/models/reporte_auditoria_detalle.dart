class ReporteAuditoriaDetalle {
  final int idAd;
  final int idInf;
  final int idInfDet;
  final int idRend;
  final int idUser;
  final String? dni;
  final String? ruc;
  final String? obs;
  final String? estadoActual;
  final String? estado;
  final String? fecCre;
  final int? useReg;
  final String? hostname;
  final String? fecEdit;
  final int? useEdit;
  final int? useElim;

  ReporteAuditoriaDetalle({
    required this.idAd,
    required this.idInf,
    required this.idInfDet,
    required this.idRend,
    required this.idUser,
    required this.dni,
    required this.ruc,
    required this.obs,
    required this.estadoActual,
    required this.estado,
    required this.fecCre,
    required this.useReg,
    required this.hostname,
    required this.fecEdit,
    required this.useEdit,
    required this.useElim,
  });

  Map<String, dynamic> toMap() {
    return {
      'idAd': idAd,
      'idInf': idInf,
      'idInfDet': idInfDet,
      'idRend': idRend,
      'idUser': idUser,
      'dni': dni,
      'ruc': ruc,
      'obs': obs,
      'estadoActual': estadoActual,
      'estado': estado,
      'fecCre': fecCre,
      'useReg': useReg,
      'hostname': hostname,
      'fecEdit': fecEdit,
      'useEdit': useEdit,
      'useElim': useElim,
    };
  }

  factory ReporteAuditoriaDetalle.fromJson(Map<String, dynamic> map) {
    return ReporteAuditoriaDetalle(
      idAd: map['idAd']?.toInt() ?? 0,
      idInf: map['idInf']?.toInt() ?? 0,
      idInfDet: map['idInfDet']?.toInt() ?? 0,
      idRend: map['idRend']?.toInt() ?? 0,
      idUser: map['idUser']?.toInt() ?? 0,
      dni: map['dni'],
      ruc: map['ruc'],
      obs: map['obs'],
      estadoActual: map['estadoActual'],
      estado: map['estado'],
      fecCre: map['fecCre'],
      useReg: map['useReg']?.toInt(),
      hostname: map['hostname'],
      fecEdit: map['fecEdit'],
      useEdit: map['useEdit']?.toInt(),
      useElim: map['useElim']?.toInt(),
    );
  }

  ReporteAuditoriaDetalle copyWith({
    int? idAd,
    int? idInf,
    int? idInfDet,
    int? idRend,
    int? idUser,
    String? dni,
    String? ruc,
    String? obs,
    String? estadoActual,
    String? estado,
    String? fecCre,
    int? useReg,
    String? hostname,
    String? fecEdit,
    int? useEdit,
    int? useElim,
  }) {
    return ReporteAuditoriaDetalle(
      idAd: idAd ?? this.idAd,
      idInf: idInf ?? this.idInf,
      idInfDet: idInfDet ?? this.idInfDet,
      idRend: idRend ?? this.idRend,
      idUser: idUser ?? this.idUser,
      dni: dni ?? this.dni,
      ruc: ruc ?? this.ruc,
      obs: obs ?? this.obs,
      estadoActual: estadoActual ?? this.estadoActual,
      estado: estado ?? this.estado,
      fecCre: fecCre ?? this.fecCre,
      useReg: useReg ?? this.useReg,
      hostname: hostname ?? this.hostname,
      fecEdit: fecEdit ?? this.fecEdit,
      useEdit: useEdit ?? this.useEdit,
      useElim: useElim ?? this.useElim,
    );
  }

  // --- 🔍 MÉTODOS Y CONDICIONES AÑADIDAS ---

  @override
  String toString() {
    return 'ReporteAuditoriaDetalle{idAd: $idAd, idInf: $idInf, idInfDet: $idInfDet, idRend: $idRend, idUser: $idUser, estadoActual: $estadoActual, estado: $estado, fecCre: $fecCre, ruc: $ruc, obs: $obs}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReporteAuditoriaDetalle &&
          runtimeType == other.runtimeType &&
          idAd == other.idAd &&
          idInf == other.idInf &&
          idInfDet == other.idInfDet;

  @override
  int get hashCode => idAd.hashCode ^ idInf.hashCode ^ idInfDet.hashCode;

  // ✅ Formato de estado
  String get estadoFormatted => estadoActual ?? 'Sin estado';

  // ✅ Fecha formateada
  String get fechaCreacionFormatted {
    if (fecCre == null || fecCre!.isEmpty) return '----';
    try {
      if (fecCre!.contains('T')) {
        return fecCre!.split('T')[0];
      }
      return fecCre!;
    } catch (e) {
      return '----';
    }
  }

  // ✅ Verificaciones lógicas
  bool get hasRuc => ruc != null && ruc!.isNotEmpty;
  bool get hasObs => obs != null && obs!.isNotEmpty;

  // ✅ Representación legible
  String get resumenAuditoria {
    final rucStr = hasRuc ? 'RUC: $ruc' : 'Sin RUC';
    final obsStr = hasObs ? obs : 'Sin observaciones';
    return '$rucStr • $estadoFormatted • $obsStr';
  }
}
