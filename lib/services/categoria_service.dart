import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/categoria_model.dart';

/// Servicio para manejar las operaciones relacionadas con categorías
class CategoriaService {
  static const String _baseUrl = 'http://190.119.200.124:45490';

  /// Obtiene todas las categorías disponibles desde la API
  static Future<List<CategoriaModel>> getCategorias() async {
    try {
      final url = Uri.parse(
        '$_baseUrl/maestros/rendicion_categoria?politica=todos',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        return jsonData
            .map((json) => CategoriaModel.fromJson(json))
            .where((categoria) => categoria.isActive) // Solo categorías activas
            .toList();
      } else {
        throw Exception('Error al obtener categorías: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtiene categorías filtradas por política
  static Future<List<CategoriaModel>> getCategoriasByPolitica(
    String politica,
  ) async {
    final categorias = await getCategorias();

    return categorias
        .where(
          (categoria) =>
              categoria.politica.toLowerCase().contains(politica.toLowerCase()),
        )
        .toList();
  }

  /// Obtiene categorías para política GENERAL
  static Future<List<CategoriaModel>> getCategoriasGeneral() async {
    return getCategoriasByPolitica('GENERAL');
  }

  /// Obtiene categorías para política GASTOS DE MOVILIDAD
  static Future<List<CategoriaModel>> getCategoriasMovilidad() async {
    return getCategoriasByPolitica('GASTOS DE MOVILIDAD');
  }
}
