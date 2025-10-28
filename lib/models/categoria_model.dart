/// Modelo para manejar los datos de categorías obtenidos de la API
class CategoriaModel {
  final String id;
  final String politica;
  final String categoria;
  final String estado;

  CategoriaModel({
    required this.id,
    required this.politica,
    required this.categoria,
    required this.estado,
  });

  /// Constructor desde JSON
  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id']?.toString() ?? '',
      politica: json['politica']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'politica': politica,
      'categoria': categoria,
      'estado': estado,
    };
  }

  /// Verificar si la categoría está activa
  bool get isActive => estado.toLowerCase() == 's';

  @override
  String toString() {
    return 'CategoriaModel(id: $id, politica: $politica, categoria: $categoria, estado: $estado)';
  }
}
