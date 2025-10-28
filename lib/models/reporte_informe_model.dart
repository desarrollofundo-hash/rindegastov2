class ReporteInforme {
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
  final String? fecCre;
  final int useReg;
  final String? hostname;
  final String? fecEdit;
  final int useEdit;
  final int useElim;
  final int cantidad;
  final double total;
  final int cantidadAprobado;
  final double totalAprobado;
  final int cantidadDesaprobado;
  final double totalDesaprobado;

  ReporteInforme({
    required this.idInf,
    required this.idUser,
    this.dni,
    this.ruc,
    this.titulo,
    this.nota,
    this.politica,
    this.obs,
    this.estadoActual,
    this.estado,
    this.fecCre,
    required this.useReg,
    this.hostname,
    this.fecEdit,
    required this.useEdit,
    required this.useElim,
    required this.cantidad,
    required this.total,
    required this.cantidadAprobado,
    required this.totalAprobado,
    required this.cantidadDesaprobado,
    required this.totalDesaprobado,
  });

  factory ReporteInforme.fromJson(Map<String, dynamic> json) {
    try {
      return ReporteInforme(
        idInf: _parseIntSafe(json['idInf'], 0),
        idUser: _parseIntSafe(json['idUser'], 0),
        dni: _parseStringSafe(json['dni']),
        ruc: _parseStringSafe(json['ruc']),
        titulo: _parseStringSafe(json['titulo']),
        nota: _parseStringSafe(json['nota']),
        politica: _parseStringSafe(json['politica']),
        obs: _parseStringSafe(json['obs']),
        estadoActual: _parseStringSafe(json['estadoActual']),
        estado: _parseStringSafe(json['estado']),
        fecCre: _parseStringSafe(json['fecCre']),
        useReg: _parseIntSafe(json['useReg'], 0),
        hostname: _parseStringSafe(json['hostname']),
        fecEdit: _parseStringSafe(json['fecEdit']),
        useEdit: _parseIntSafe(json['useEdit'], 0),
        useElim: _parseIntSafe(json['useElim'], 0),
        cantidad: _parseIntSafe(json['cantidad'], 0),
        total: _parseDoubleSafe(json['total']) ?? 0.0,
        cantidadAprobado: _parseIntSafe(json['cantidadAprobado'], 0),
        totalAprobado: _parseDoubleSafe(json['totalAprobado']) ?? 0.0,
        cantidadDesaprobado: _parseIntSafe(json['cantidadDesaprobado'], 0),
        totalDesaprobado: _parseDoubleSafe(json['totalDesaprobado']) ?? 0.0,
      );
    } catch (e) {
      throw Exception(
        'Error al crear ReporteInforme desde JSON: $e\nJSON: $json',
      );
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
      'fecCre': fecCre,
      'useReg': useReg,
      'hostname': hostname,
      'fecEdit': fecEdit,
      'useEdit': useEdit,
      'useElim': useElim,
      'cantidad': cantidad,
      'total': total,
      'cantidadAprobado': cantidadAprobado,
      'totalAprobado': totalAprobado,
      'cantidadDesaprobado': cantidadDesaprobado,
      'totalDesaprobado': totalDesaprobado,
    };
  }

  @override
  String toString() {
    return 'ReporteInforme{idInf: $idInf, idUser: $idUser, titulo: $titulo, total: $total, cantidad: $cantidad}';
  }

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

  /// Obtener estado formateado para mostrar
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

  get idInfDet => null;
}
