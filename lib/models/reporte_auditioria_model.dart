// Modelo generado para las auditorías
// Nombre del archivo: auditioria_model.dart

class ReporteAuditoria {
  final int idAd;
  final int idInf;
  final int idUser;
  final String? dni;
  final String? ruc;
  final String? titulo;
  final String? nota;
  final String? politica;
  final String? obs;
  final String? estadoActual;
  final String? estado;
  final DateTime? fecCre;
  final int useReg;
  final String? hostname;
  final DateTime? fecEdit;
  final int useEdit;
  final int useElim;
  final int cantidad;
  final double total;
  final int cantidadAprobado;
  final double totalAprobado;
  final int cantidadDesaprobado;
  final double totalDesaprobado;
  final String? usuario;
  final int idRev;

  ReporteAuditoria({
    required this.idAd,
    required this.idInf,
    required this.idUser,
    required this.dni,
    required this.ruc,
    required this.titulo,
    required this.nota,
    required this.politica,
    required this.obs,
    required this.estadoActual,
    required this.estado,
    required this.fecCre,
    required this.useReg,
    required this.hostname,
    required this.fecEdit,
    required this.useEdit,
    required this.useElim,
    required this.cantidad,
    required this.total,
    required this.cantidadAprobado,
    required this.totalAprobado,
    required this.cantidadDesaprobado,
    required this.totalDesaprobado,
    required this.usuario,
    required this.idRev,
  });

  factory ReporteAuditoria.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    int _i(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    double _d(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return ReporteAuditoria(
      idAd: _i(json['idAd']),
      idInf: _i(json['idInf']),
      idUser: _i(json['idUser']),
      dni: json['dni']?.toString(),
      ruc: json['ruc']?.toString(),
      titulo: json['titulo']?.toString(),
      nota: json['nota']?.toString(),
      politica: json['politica']?.toString(),
      obs: json['obs']?.toString(),
      estadoActual: json['estadoActual']?.toString(),
      estado: json['estado']?.toString(),
      fecCre: _parseDate(json['fecCre']),
      useReg: _i(json['useReg']),
      hostname: json['hostname']?.toString(),
      fecEdit: _parseDate(json['fecEdit']),
      useEdit: _i(json['useEdit']),
      useElim: _i(json['useElim']),
      cantidad: _i(json['cantidad']),
      total: _d(json['total']),
      cantidadAprobado: _i(json['cantidadAprobado']),
      totalAprobado: _d(json['totalAprobado']),
      cantidadDesaprobado: _i(json['cantidadDesaprobado']),
      totalDesaprobado: _d(json['totalDesaprobado']),
      usuario: json['usuario']?.toString(),
      idRev: _i(json['idRev']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idAd': idAd,
      'idInf': idInf,
      'idUser': idUser,
      'dni': dni,
      'ruc': ruc,
      'titulo': titulo,
      'nota': nota,
      'politica': politica,
      'obs': obs,
      'estadoActual': estadoActual,
      'estado': estado,
      'fecCre': fecCre?.toUtc().toIso8601String(),
      'useReg': useReg,
      'hostname': hostname,
      'fecEdit': fecEdit?.toUtc().toIso8601String(),
      'useEdit': useEdit,
      'useElim': useElim,
      'cantidad': cantidad,
      'total': total,
      'cantidadAprobado': cantidadAprobado,
      'totalAprobado': totalAprobado,
      'cantidadDesaprobado': cantidadDesaprobado,
      'totalDesaprobado': totalDesaprobado,
      'usuario': usuario,
      'idRev': idRev,
    };
  }

  // --- 🔍 MÉTODOS Y CONDICIONES AGREGADAS (como en ReporteInforme) ---

  /// Verificar si el informe está activo
  bool get isActive => estado?.toLowerCase() == 's';

  /// Verificar si hay gastos aprobados
  bool get hasAprobados => cantidadAprobado > 0;

  /// Verificar si hay gastos desaprobados
  bool get hasDesaprobados => cantidadDesaprobado > 0;

  /// Obtener porcentaje de aprobación
  double get porcentajeAprobacion {
    if (cantidad == 0) return 0.0;
    return (cantidadAprobado / cantidad) * 100;
  }

  /// Obtener porcentaje de desaprobación
  double get porcentajeDesaprobacion {
    if (cantidad == 0) return 0.0;
    return (cantidadDesaprobado / cantidad) * 100;
  }

  /// Verificar si el informe está completamente procesado
  bool get isCompleted {
    return (cantidadAprobado + cantidadDesaprobado) == cantidad;
  }

  /// Obtener estado formateado para mostrar en la UI
  String get estadoFormateado {
    switch (estadoActual?.toUpperCase()) {
      case 'EN INFORME':
        return 'En Informe';
      case 'PENDIENTE':
        return 'Pendiente';
      case 'APROBADO':
        return 'Aprobado';
      case 'RECHAZADO':
        return 'Rechazado';
      case 'EN REVISION':
        return 'En Revisión';
      default:
        return estadoActual ?? 'Sin Estado';
    }
  }

  /// Sobrescritura de toString para depuración
  @override
  String toString() {
    return 'ReporteAuditoria{idAd: $idAd, idInf: $idInf, titulo: $titulo, total: $total, cantidad: $cantidad}';
  }
}
