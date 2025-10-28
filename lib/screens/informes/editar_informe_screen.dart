import 'package:flutter/material.dart';
import '../../models/gasto_model.dart';

class EditarInformeScreen extends StatefulWidget {
  final Gasto informe;
  const EditarInformeScreen({super.key, required this.informe});

  @override
  State<EditarInformeScreen> createState() => _EditarInformeScreenState();
}

class _EditarInformeScreenState extends State<EditarInformeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _montoController;
  late TextEditingController _descripcionController;
  late String _categoria;
  late String _estado;
  late String _fechaText;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.informe.titulo);
    _montoController = TextEditingController(
      text: widget.informe.monto.replaceAll(" PEN", ""),
    );
    _descripcionController = TextEditingController(
      text: widget.informe.descripcion ?? '',
    );
    _categoria = widget.informe.categoria;
    _estado = widget.informe.estado;
    _fechaText = widget.informe.fecha;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Informe"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: "Título / Factura",
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Ingresa el número" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(labelText: "Monto (S/)"),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? "Ingresa el monto" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: TextEditingController(text: _fechaText),
                decoration: const InputDecoration(
                  labelText: "Fecha (dd/mm/yyyy)",
                ),
                onChanged: (v) => _fechaText = v,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categoria,
                items: const [
                  DropdownMenuItem(
                    value: "Alimentación",
                    child: Text("Alimentación"),
                  ),
                  DropdownMenuItem(
                    value: "Hospedaje",
                    child: Text("Hospedaje"),
                  ),
                  DropdownMenuItem(
                    value: "Transporte",
                    child: Text("Transporte"),
                  ),
                  DropdownMenuItem(value: "Otros", child: Text("Otros")),
                ],
                onChanged: (v) => setState(() => _categoria = v ?? "Otros"),
                decoration: const InputDecoration(labelText: "Categoría"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _estado,
                items: const [
                  DropdownMenuItem(
                    value: "Pendiente",
                    child: Text("Pendiente"),
                  ),
                  DropdownMenuItem(value: "Borrador", child: Text("Borrador")),
                  DropdownMenuItem(
                    value: "En Informe",
                    child: Text("En Informe"),
                  ),
                  DropdownMenuItem(value: "Enviados", child: Text("Enviados")),
                ],
                onChanged: (v) => setState(() => _estado = v ?? "Pendiente"),
                decoration: const InputDecoration(labelText: "Estado"),
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
                label: const Text("Guardar cambios"),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final actualizado = widget.informe.copyWith(
                      titulo: _tituloController.text,
                      monto: "${_montoController.text} PEN",
                      fecha: _fechaText,
                      categoria: _categoria,
                      estado: _estado,
                      descripcion: _descripcionController.text,
                    );
                    Navigator.pop(context, actualizado);
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
