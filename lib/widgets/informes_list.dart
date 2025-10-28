import 'package:flu2/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import '../models/gasto_model.dart';
import '../screens/informes/detalle_informe_screen.dart';

class InformesList extends StatelessWidget {
  final List<Gasto> informes;
  final Function(Gasto) onInformeUpdated;
  final Function(Gasto) onInformeDeleted;
  final bool showEmptyStateButton;
  final VoidCallback? onEmptyStateButtonPressed;

  const InformesList({
    super.key,
    required this.informes,
    required this.onInformeUpdated,
    required this.onInformeDeleted,
    this.showEmptyStateButton = true,
    this.onEmptyStateButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (informes.isEmpty) {
      return EmptyState(
        message: "No hay informes disponibles",
        buttonText: showEmptyStateButton ? "Agregar Informe" : null,
        onButtonPressed: showEmptyStateButton
            ? onEmptyStateButtonPressed
            : null,
        icon: Icons.description,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: informes.length,
      itemBuilder: (context, index) {
        final inf = informes[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: Text(
                inf.titulo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inf.categoria,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Text(
                    inf.fecha,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    inf.monto,
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Chip(
                    label: Text(
                      inf.estado,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: inf.estado == "Borrador"
                        ? Colors.orange[100]
                        : Colors.green[100],
                  ),
                ],
              ),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalleInformeScreen(informe: inf),
                  ),
                );
                _handleInformeResult(result, inf);
              },
            ),
          ),
        );
      },
    );
  }

  void _handleInformeResult(dynamic result, Gasto informe) {
    if (result != null && result is Map) {
      if (result["accion"] == "eliminar") {
        onInformeDeleted(informe);
      } else if (result["accion"] == "editar" && result["data"] is Gasto) {
        onInformeUpdated(result["data"]);
      }
    }
  }
}
