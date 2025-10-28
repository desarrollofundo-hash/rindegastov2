import 'package:flutter/material.dart';
import '../models/dropdown_option.dart';
import '../widgets/api_dropdown_field.dart';

/// Pantalla de ejemplo específica para mostrar los dropdowns de rendición
class RendicionExampleScreen extends StatefulWidget {
  const RendicionExampleScreen({super.key});

  @override
  State<RendicionExampleScreen> createState() => _RendicionExampleScreenState();
}

class _RendicionExampleScreenState extends State<RendicionExampleScreen> {
  DropdownOption? _politicaSeleccionada;
  DropdownOption? _categoriaSeleccionada;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplo: Rendición con APIs'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título y descripción
              Text(
                'Sistema de Rendición',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Este formulario utiliza tus APIs específicas:\n'
                '• http://190.119.200.124:45490/maestros/rendicion_politica\n'
                '• http://190.119.200.124:45490/maestros/rendicion_categoria?politica=...',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Dropdowns combinados de rendición
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selección de Política y Categoría',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      RendicionDropdownsCombinados(
                        politicaSeleccionada: _politicaSeleccionada,
                        categoriaSeleccionada: _categoriaSeleccionada,
                        onPoliticaChanged: (politica) {
                          setState(() {
                            _politicaSeleccionada = politica;
                          });
                          _showSnackBar(
                            'Política seleccionada: ${politica?.value ?? "Ninguna"}\n'
                            'Las categorías se actualizarán automáticamente.',
                          );
                        },
                        onCategoriaChanged: (categoria) {
                          setState(() {
                            _categoriaSeleccionada = categoria;
                          });
                          _showSnackBar(
                            'Categoría seleccionada: ${categoria?.value ?? "Ninguna"}',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Ejemplo usando dropdowns individuales
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'O usa dropdowns individuales',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Dropdown individual de políticas
                      RendicionPoliticasDropdown(
                        value: null, // Separado del anterior
                        onChanged: (politica) {
                          _showSnackBar(
                            'Política individual: ${politica?.value}',
                          );
                        },
                        label: 'Política (individual)',
                      ),

                      const SizedBox(height: 16),

                      // Dropdown individual de categorías (todas)
                      RendicionCategoriasDropdown(
                        value: null,
                        onChanged: (categoria) {
                          _showSnackBar(
                            'Categoría individual: ${categoria?.value}',
                          );
                        },
                        label: 'Categoría (todas)',
                        politicaNombre: 'todos', // Obtiene todas las categorías
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Campos adicionales del formulario
              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto a rendir',
                  prefixText: 'S/. ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el monto';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción de la rendición',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // Información actual seleccionada
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selección Actual',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Política:', _politicaSeleccionada),
                      _buildInfoRow('Categoría:', _categoriaSeleccionada),
                      _buildInfoRow(
                        'Monto:',
                        _montoController.text.isEmpty
                            ? null
                            : DropdownOption(
                                value: 'S/. ${_montoController.text}', id: '',
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _limpiarFormulario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _procesarRendicion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                      ),
                      child: const Text('Procesar Rendición'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, DropdownOption? option) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              option?.value ?? 'No seleccionado',
              style: TextStyle(
                color: option != null ? Colors.black : Colors.grey,
                fontStyle: option != null ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
          if (option != null)
            Text(
              'ID: ${option.value}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
        ],
      ),
    );
  }

  void _limpiarFormulario() {
    setState(() {
      _politicaSeleccionada = null;
      _categoriaSeleccionada = null;
    });
    _montoController.clear();
    _descripcionController.clear();
    _showSnackBar('Formulario limpiado');
  }

  void _procesarRendicion() {
    if (_formKey.currentState!.validate()) {
      if (_politicaSeleccionada == null) {
        _showSnackBar('Por favor selecciona una política');
        return;
      }
      if (_categoriaSeleccionada == null) {
        _showSnackBar('Por favor selecciona una categoría');
        return;
      }

      // Aquí procesarías la rendición
      final rendicion = {
        'politica_nombre': _politicaSeleccionada!.value,
        'categoria_nombre': _categoriaSeleccionada!.value,
        'monto': double.tryParse(_montoController.text) ?? 0.0,
        'descripcion': _descripcionController.text,
        'fecha': DateTime.now().toIso8601String(),
        // Información adicional de las APIs
        'politica_metadata': _politicaSeleccionada!.metadata,
        'categoria_metadata': _categoriaSeleccionada!.metadata,
      };

      _showDialog(
        'Rendición Procesada',
        'Los datos se han preparado correctamente:\n\n'
            'Política: ${rendicion['politica_nombre']}\n'
            'Categoría: ${rendicion['categoria_nombre']}\n'
            'Monto: S/. ${rendicion['monto']}\n'
            'Descripción: ${rendicion['descripcion']}\n\n'
            'Aquí enviarías estos datos a tu API para procesar la rendición.',
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
}
