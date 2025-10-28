/// Modelo para manejar los datos de tipos de gasto obtenidos de la API
class TipoGastoModel {
  final String id;
  final String tipoGasto;
  final String estado;

  TipoGastoModel({
    required this.id,
    required this.tipoGasto,
    required this.estado,
  });

  /// Constructor desde JSON
  factory TipoGastoModel.fromJson(Map<String, dynamic> json) {
    return TipoGastoModel(
      id: json['id']?.toString() ?? '',
      tipoGasto: json['tipogasto']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'tipogasto': tipoGasto, 'estado': estado};
  }

  /// Verificar si el tipo de gasto está activo
  bool get isActive => estado.toLowerCase() == 's';

  @override
  String toString() {
    return 'TipoGastoModel(id: $id, tipoGasto: $tipoGasto, estado: $estado)';
  }
}
