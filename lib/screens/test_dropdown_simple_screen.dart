import 'package:flutter/material.dart';
import '../models/dropdown_option.dart';
import '../widgets/api_dropdown_field.dart';

/// Pantalla simple para probar que los dropdowns funcionan
class TestDropdownSimpleScreen extends StatefulWidget {
  const TestDropdownSimpleScreen({super.key});

  @override
  State<TestDropdownSimpleScreen> createState() => _TestDropdownSimpleScreenState();
}

class _TestDropdownSimpleScreenState extends State<TestDropdownSimpleScreen> {
  DropdownOption? _politicaSeleccionada;
  DropdownOption? _categoriaSeleccionada;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Dropdown Simple'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Prueba de dropdowns arreglados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Test dropdown de políticas
            RendicionPoliticasDropdown(
              value: _politicaSeleccionada,
              onChanged: (politica) {
                setState(() {
                  _politicaSeleccionada = politica;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Política: ${politica?.value ?? "Ninguna"}')),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Test dropdown de categorías dependiente
            RendicionCategoriasDropdown(
              value: _categoriaSeleccionada,
              onChanged: (categoria) {
                setState(() {
                  _categoriaSeleccionada = categoria;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Categoría: ${categoria?.value ?? "Ninguna"}')),
                );
              },
              politicaNombre: _politicaSeleccionada?.value,
            ),
            
            const SizedBox(height: 20),
            
            // Mostrar selección actual
            if (_politicaSeleccionada != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Política seleccionada:'),
                      Text('ID: ${_politicaSeleccionada!.id}'),
                      Text('Nombre: ${_politicaSeleccionada!.value}'),
                      Text('Metadata: ${_politicaSeleccionada!.metadata}'),
                    ],
                  ),
                ),
              ),
              
            if (_categoriaSeleccionada != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Categoría seleccionada:'),
                      Text('ID: ${_categoriaSeleccionada!.id}'),
                      Text('Nombre: ${_categoriaSeleccionada!.value}'),
                      Text('Metadata: ${_categoriaSeleccionada!.metadata}'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}