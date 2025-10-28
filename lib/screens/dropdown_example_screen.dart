import 'package:flutter/material.dart';
import '../models/dropdown_option.dart';
import '../widgets/api_dropdown_field.dart';

/// Pantalla de ejemplo que muestra diferentes formas de usar los dropdowns de API
class DropdownExampleScreen extends StatefulWidget {
  const DropdownExampleScreen({super.key});

  @override
  State<DropdownExampleScreen> createState() => _DropdownExampleScreenState();
}

class _DropdownExampleScreenState extends State<DropdownExampleScreen> {
  DropdownOption? _categoriaSeleccionada;
  DropdownOption? _politicaSeleccionada;
  DropdownOption? _usuarioSeleccionado;
  DropdownOption? _customDropdownValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplos de Dropdown API'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dropdowns dinámicos con API',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),

            // Ejemplo 1: Dropdown específico para categorías
            _buildSection(
              'Ejemplo 1: Dropdown específico (Categorías)',
              CategoriasDropdown(
                value: _categoriaSeleccionada,
                onChanged: (categoria) {
                  setState(() {
                    _categoriaSeleccionada = categoria;
                  });
                  _showSnackBar('Categoría seleccionada: ${categoria?.value}');
                },
              ),
            ),

            // Ejemplo 2: Dropdown específico para políticas
            _buildSection(
              'Ejemplo 2: Dropdown específico (Políticas)',
              PoliticasDropdown(
                value: _politicaSeleccionada,
                onChanged: (politica) {
                  setState(() {
                    _politicaSeleccionada = politica;
                  });
                  _showSnackBar('Política seleccionada: ${politica?.value}');
                },
              ),
            ),

            // Ejemplo 3: Dropdown genérico con endpoint personalizado
            _buildSection(
              'Ejemplo 3: Dropdown genérico (SimpleApiDropdown)',
              SimpleApiDropdown(
                endpoint: 'usuarios',
                value: _usuarioSeleccionado,
                onChanged: (usuario) {
                  setState(() {
                    _usuarioSeleccionado = usuario;
                  });
                  _showSnackBar('Usuario seleccionado: ${usuario?.value}');
                },
                hint: 'Seleccionar usuario...',
                label: 'Usuario asignado',
              ),
            ),

            // Ejemplo 4: Dropdown personalizado con configuración avanzada

            // Mostrar valores seleccionados
            _buildSection(
              'Valores actuales seleccionados',
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSelectedValue('Categoría', _categoriaSeleccionada),
                      _buildSelectedValue('Política', _politicaSeleccionada),
                      _buildSelectedValue('Usuario', _usuarioSeleccionado),
                      _buildSelectedValue(
                        'Tipo documento',
                        _customDropdownValue,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botón para limpiar selecciones
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _clearAll,
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar todas las selecciones'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSelectedValue(String label, DropdownOption? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value?.value ?? 'No seleccionado',
              style: TextStyle(
                color: value != null ? Colors.black : Colors.grey,
                fontStyle: value != null ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
          if (value != null)
            Text(
              'ID: ${value.value}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
        ],
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _categoriaSeleccionada = null;
      _politicaSeleccionada = null;
      _usuarioSeleccionado = null;
      _customDropdownValue = null;
    });
    _showSnackBar('Todas las selecciones han sido limpiadas');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
