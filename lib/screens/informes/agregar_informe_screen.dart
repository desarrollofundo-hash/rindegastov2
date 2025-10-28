import 'package:flutter/material.dart';
import '../../models/gasto_model.dart';
import '../../models/dropdown_option.dart';
import '../../widgets/api_dropdown_field.dart';

class AgregarInformeScreen extends StatefulWidget {
  const AgregarInformeScreen({super.key});

  @override
  State<AgregarInformeScreen> createState() => _AgregarInformeScreenState();
}

class _AgregarInformeScreenState extends State<AgregarInformeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _facturaController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  DropdownOption? _politicaSeleccionada;
  DropdownOption? _categoriaSeleccionada;
  DropdownOption? _estadoSeleccionado;
  DateTime? _fechaSeleccionada;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  String _formatFecha(DateTime? dt) {
    if (dt == null) return "";
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return "$d/$m/$y";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar Informe"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _facturaController,
                decoration: const InputDecoration(
                  labelText: "Número de factura",
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Ingrese número de factura" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Monto (PEN)"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Ingrese el monto" : null,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: "Fecha",
                      hintText: _fechaSeleccionada == null
                          ? "Seleccionar fecha"
                          : _formatFecha(_fechaSeleccionada),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    validator: (v) => _fechaSeleccionada == null
                        ? "Seleccione la fecha"
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Dropdowns combinados de rendición (política y categoría dependiente)
              RendicionDropdownsCombinados(
                politicaSeleccionada: _politicaSeleccionada,
                categoriaSeleccionada: _categoriaSeleccionada,
                onPoliticaChanged: (politica) {
                  setState(() {
                    _politicaSeleccionada = politica;
                    // La categoría se limpia automáticamente en el widget combinado
                  });
                },
                onCategoriaChanged: (categoria) {
                  setState(() {
                    _categoriaSeleccionada = categoria;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Dropdown simple para estados
              SimpleApiDropdown(
                endpoint: 'estados',
                value: _estadoSeleccionado,
                onChanged: (estado) {
                  setState(() {
                    _estadoSeleccionado = estado;
                  });
                },
                hint: 'Seleccionar estado...',
                label: 'Estado',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Descripción"),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Guardar Informe"),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final nuevo = Gasto(
                      titulo: "Factura ${_facturaController.text}",
                      categoria:
                          _categoriaSeleccionada?.value ?? "Sin categoría",
                      fecha: _formatFecha(_fechaSeleccionada),
                      monto: "${_montoController.text} PEN",
                      estado: _estadoSeleccionado?.value ?? "Sin estado",
                      descripcion:
                          "${_descripcionController.text}\nPolítica: ${_politicaSeleccionada?.value ?? 'No especificada'}",
                      factura: _facturaController.text,
                    );
                    Navigator.pop(context, nuevo);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
