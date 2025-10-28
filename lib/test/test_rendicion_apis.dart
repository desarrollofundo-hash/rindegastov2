import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/dropdown_option.dart';

/// Prueba simple para verificar las APIs de rendición
class TestRendicionApis extends StatefulWidget {
  const TestRendicionApis({super.key});

  @override
  State<TestRendicionApis> createState() => _TestRendicionApisState();
}

class _TestRendicionApisState extends State<TestRendicionApis> {
  final ApiService _apiService = ApiService();
  List<DropdownOption> _politicas = [];
  List<DropdownOption> _categorias = [];
  List<DropdownOption> _tiposGasto = [];
  String? _selectedPolitica;

  bool _isLoadingPoliticas = false;
  bool _isLoadingCategorias = false;
  bool _isLoadingTiposGasto = false;

  @override
  void initState() {
    super.initState();
    _loadPoliticas();
    _loadTiposGasto();
  }

  Future<void> _loadPoliticas() async {
    setState(() {
      _isLoadingPoliticas = true;
    });

    try {
      final politicas = await _apiService.getRendicionPoliticas();
      setState(() {
        _politicas = politicas;
        _isLoadingPoliticas = false;
      });
      print('✅ Políticas cargadas: ${politicas.length}');
      for (var pol in politicas) {
        print('  - ${pol.value}');
      }
    } catch (e) {
      setState(() {
        _isLoadingPoliticas = false;
      });
      print('❌ Error cargando políticas: $e');
    }
  }

  Future<void> _loadCategorias({String? politica}) async {
    setState(() {
      _isLoadingCategorias = true;
    });

    try {
      final categorias = await _apiService.getRendicionCategorias(
        politica: politica ?? 'todos',
      );
      setState(() {
        _categorias = categorias;
        _isLoadingCategorias = false;
      });
      print(
        '✅ Categorías cargadas: ${categorias.length} para política: ${politica ?? "todas"}',
      );
      for (var cat in categorias) {
        print('  - ${cat.value}');
      }
    } catch (e) {
      setState(() {
        _isLoadingCategorias = false;
      });
      print('❌ Error cargando categorías: $e');
    }
  }

  Future<void> _loadTiposGasto() async {
    setState(() {
      _isLoadingTiposGasto = true;
    });

    try {
      final tipos = await _apiService.getTiposGasto();
      setState(() {
        _tiposGasto = tipos;
        _isLoadingTiposGasto = false;
      });
      print('✅ Tipos de gasto cargados: ${tipos.length}');
      for (var tipo in tipos) {
        print('  - ${tipo.value}');
      }
    } catch (e) {
      setState(() {
        _isLoadingTiposGasto = false;
      });
      print('❌ Error cargando tipos de gasto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test APIs de Rendición'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown de políticas
            const Text(
              'Políticas:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _isLoadingPoliticas
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: _selectedPolitica,
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar política',
                      border: OutlineInputBorder(),
                    ),
                    items: _politicas.map((pol) {
                      return DropdownMenuItem<String>(
                        value: pol.value,
                        child: Text(pol.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPolitica = value;
                      });
                      if (value != null) {
                        _loadCategorias(politica: value);
                      }
                    },
                  ),

            const SizedBox(height: 20),

            // Dropdown de categorías
            const Text(
              'Categorías:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _isLoadingCategorias
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar categoría',
                      border: OutlineInputBorder(),
                    ),
                    items: _categorias.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.value,
                        child: Text(cat.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      // Manejar selección de categoría
                    },
                  ),

            const SizedBox(height: 20),

            // Dropdown de tipos de gasto
            const Text(
              'Tipos de Gasto:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _isLoadingTiposGasto
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar tipo de gasto',
                      border: OutlineInputBorder(),
                    ),
                    items: _tiposGasto.map((tipo) {
                      return DropdownMenuItem<String>(
                        value: tipo.value,
                        child: Text(tipo.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      // Manejar selección de tipo de gasto
                    },
                  ),

            const SizedBox(height: 20),

            // Botón para cargar todas las categorías
            ElevatedButton(
              onPressed: () => _loadCategorias(),
              child: const Text('Cargar todas las categorías'),
            ),
          ],
        ),
      ),
    );
  }
}
