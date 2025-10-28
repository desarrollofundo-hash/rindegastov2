import 'package:flutter/material.dart';
import '../../models/gasto_model.dart';
import 'editar_informe_screen.dart';

class DetalleInformeScreen extends StatelessWidget {
  final Gasto informe;

  const DetalleInformeScreen({super.key, required this.informe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle del Informe"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              informe.titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Categoría: ${informe.categoria}"),
            const SizedBox(height: 4),
            Text("Fecha: ${informe.fecha}"),
            const SizedBox(height: 4),
            Text("Monto: ${informe.monto}"),
            const SizedBox(height: 8),
            Text("Estado: ${informe.estado}"),
            const SizedBox(height: 12),
            Text("Descripción:\n${informe.descripcion ?? ''}"),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Editar"),
                  onPressed: () async {
                    final actualizado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditarInformeScreen(informe: informe),
                      ),
                    );
                    if (actualizado != null && actualizado is Gasto) {
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context, {
                        "accion": "editar",
                        "data": actualizado,
                      });
                    }
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text("Eliminar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Eliminar informe"),
                        content: const Text(
                          "¿Estás seguro de eliminar este informe?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancelar"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context, {"accion": "eliminar"});
                            },
                            child: const Text(
                              "Eliminar",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
